-- 【谜谱】使命技：在正常的游戏结束结算 *之前*，允许安娜猜测摸牌堆
-- 中基本牌、锦囊牌、装备牌的数量。三项都正确则其单独胜利。
--
-- FreeKill 的 fk.GameFinished 是在 Room:gameOver 销毁 RequestTimer 后触发的，
-- 而且它的 data 是不可直接替换的胜者字符串，所以不能在那里进行交互猜测。
-- 这里只为本局 room 安装 gameOver 的前置包装，绝不修改全局 Room 类。
local U = dofile("./packages/XY/anna_utils.lua")
local skill = fk.CreateSkill{
  name = "xy__mipu",
  tags = {Skill.Quest},
}

local SPECIAL_ROLE = "xy__mipu_winner"
local HOOK_TAG = "xy__mipu_gameover_installed"
local BUSY_TAG = "xy__mipu_gameover_busy"

local function countsToText(counts)
  return string.format("%d / %d / %d",
    counts[Card.TypeBasic] or 0,
    counts[Card.TypeTrick] or 0,
    counts[Card.TypeEquip] or 0)
end

-- 游戏结束也可能由安娜本人死亡触发。此时 p.dead 已经为 true，
-- 而普通 hasSkill 会因角色已阵亡而返回 false。
-- 第三个参数 ignoreAlive=true 用于按技能归属检查：死亡不会剥夺本使命技的结算资格。
-- 仍在结束时检查技能本身，避免已真正失去【谜谱】的角色凭旧名单发动。
local function findEligible(room)
  local players = {}
  for _, p in ipairs(room.players or {}) do
    if U.isAnna(p) and p:hasSkill("xy__mipu", false, true) then
      players[#players + 1] = p
    end
  end
  return players
end

local function resolveBeforeGameOver(room, normal_winner, originalGameOver)
  if room:getTag(BUSY_TAG) then
    return originalGameOver(room, normal_winner)
  end
  -- 不允许在房间尚未真正开始或已经结束后弹窗。**不要**限制身份模式：
  -- 旧代码的 U.isRoleMode 会导致其它游戏模式完全跳过本技能。
  if not room.game_started or room.game_finished then
    return originalGameOver(room, normal_winner)
  end

  local eligible = findEligible(room)
  if #eligible == 0 then
    return originalGameOver(room, normal_winner)
  end
  room:setTag(BUSY_TAG, true)

  -- 先固定本次正确答案，避免多个安娜依次猜测时受其它流程影响。
  local actualCounts = U.typeCounts(room.draw_pile)
  local attempts = {}
  for _, p in ipairs(eligible) do
    local choice = room:askToChoice(p, {
      choices = {"xy__mipu_yes", "xy__mipu_no"},
      skill_name = "xy__mipu",
      prompt = "#xy__mipu-ask",
      cancelable = false,
    })
    if choice == "xy__mipu_yes" then
      local guess = U.askThreeNumbers(room, p, "xy__mipu", "#xy__mipu-number")
      attempts[#attempts + 1] = {
        player = p,
        guess = guess,
        success = U.allCorrect(guess, actualCounts),
      }
    end
  end

  -- 所有人完成猜测后，再一起公开答案。
  for _, attempt in ipairs(attempts) do
    room:sendLog({
      type = "#xy__mipu-guess", from = attempt.player.id,
      arg = countsToText(attempt.guess),
    })
  end
  if #attempts > 0 then
    room:sendLog({type = "#xy__mipu-answer", arg = countsToText(actualCounts)})
  end

  local winners = {}
  for _, attempt in ipairs(attempts) do
    if attempt.success then
      winners[#winners + 1] = attempt.player
      if type(room.updateQuestSkillState) == "function" then
        room:updateQuestSkillState(attempt.player, "xy__mipu", false)
      end
      room:sendLog({type = "#xy__mipu-success", from = attempt.player.id})
    else
      room:sendLog({type = "#xy__mipu-failure", from = attempt.player.id})
    end
  end

  if #winners == 0 then
    return originalGameOver(room, normal_winner)
  end

  -- 当前 FreeKill gameOver(winner) 接受的是胜利 **身份字符串**，不是玩家 ID。
  -- 使用独立的角色胜利身份；只改本房间的获胜者并跳过这场特殊胜利的胜率统计。
  if room.settings then room.settings.enableFreeAssign = true end
  for _, p in ipairs(winners) do
    room:setPlayerProperty(p, "role", SPECIAL_ROLE)
  end
  return originalGameOver(room, SPECIAL_ROLE)
end

local function installForRoom(room)
  if room:getTag(HOOK_TAG) then return end
  local original = room.gameOver
  if type(original) ~= "function" then return end
  -- 把当前 room 的真实 gameOver 保存下来，避免重复包装和其它房间受到影响。
  room.gameOver = function(self, normal_winner)
    return resolveBeforeGameOver(self, normal_winner, original)
  end
  room:setTag(HOOK_TAG, true)
end

local function addInstallEffect(event, require_target)
  if not event then return end
  skill:addEffect(event, {
    anim_type = "special",
    can_trigger = function(self, _, target, player, _)
      if not player or not U.isAnna(player) or not player:hasSkill("xy__mipu") then
        return false
      end
      if require_target and player ~= target then return false end
      return player.room and not player.room:getTag(HOOK_TAG)
    end,
    on_cost = Util.TrueFunc,
    on_use = function(self, _, target, player, data)
      installForRoom(player.room)
    end,
  })
end

-- 先尝试在发放起始手牌后安装；若模式没有此时机，则在第一轮
-- GameStart 补装。TurnStart 再作容错，且因为标签防重绝不重复包装。
addInstallEffect(fk.AfterDrawInitialCards, true)
addInstallEffect(fk.GameStart, false)
addInstallEffect(fk.TurnStart, false)

return skill

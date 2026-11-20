-- 宇志（沮授·幻）
-- 一轮开始时，你选择任意项条件：1.对一名角色造成伤害；2.使用牌指定自己为目标；3.弃牌阶段弃置过牌；
-- 4.使用牌被其他角色响应；5.不以使用、打出或弃牌阶段弃置失去过牌。
-- 你达成一项条件后，你的所有技能本轮失效直到你进入濒死状态。你使用或打出牌时，你摸X张牌。（X为你选择的条件数量）

local yuzhi = fk.CreateSkill {
  name = "xy__yuzhi",
}

Fk:loadTranslationTable{
  ["xy__yuzhi"] = "宇志",
  [":xy__yuzhi"] = "一轮开始时，你选择任意项条件：1.对一名角色造成伤害；2.使用牌指定自己为目标；3.弃牌阶段弃置过牌；" ..
    "4.使用牌被其他角色响应；5.不以使用、打出或弃牌阶段弃置失去过牌。" ..
    "你达成一项条件后，你的所有技能本轮失效直到你进入濒死状态。你使用或打出牌时，你摸X张牌。（X为你选择的条件数量）",

  ["xy__yuzhi_1"] = "1.对一名角色造成伤害",
  ["xy__yuzhi_2"] = "2.使用牌指定自己为目标",
  ["xy__yuzhi_3"] = "3.弃牌阶段弃置过牌",
  ["xy__yuzhi_4"] = "4.使用牌被其他角色响应",
  ["xy__yuzhi_5"] = "5.不以使用、打出或弃牌阶段弃置失去过牌",
  ["#xy__yuzhi-choose"] = "宇志：选择任意项条件（达成任意一项后，你的所有技能本轮失效；使用或打出牌时摸等同于条件数的牌）",
  ["@xy__yuzhi_count-round"] = "宇志",
  ["@@xy__yuzhi_invalid-round"] = "宇志 技能失效",
  ["#xy__yuzhi-reached"] = "%from 达成了“宇志”条件：%arg，所有技能本轮失效",
}

local CONDS = "xy__yuzhi_conds-round"
local COUNT = "@xy__yuzhi_count-round"
local INVALID = "@@xy__yuzhi_invalid-round"

local function hasCond(player, n)
  return table.contains(player:getTableMark(CONDS), "xy__yuzhi_" .. n)
end

local function reach(player, n)
  local room = player.room
  if player:getMark(INVALID) ~= 0 or not hasCond(player, n) then return end
  room:setPlayerMark(player, INVALID, 1)
  room:sendLog{ type = "#xy__yuzhi-reached", from = player.id, arg = "xy__yuzhi_" .. n, toast = true }
end

local function isTarget(data, player)
  for _, t in ipairs(data.tos or {}) do
    if t == player then return true end
  end
  return false
end

-- 一轮开始时：选择条件
yuzhi:addEffect(fk.RoundStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yuzhi.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all = { "xy__yuzhi_1", "xy__yuzhi_2", "xy__yuzhi_3", "xy__yuzhi_4", "xy__yuzhi_5" }
    local chosen = room:askToChoices(player, {
      choices = all,
      min_num = 0,
      max_num = #all,
      skill_name = yuzhi.name,
      prompt = "#xy__yuzhi-choose",
      cancelable = true,
    }) or {}
    room:setPlayerMark(player, CONDS, #chosen > 0 and chosen or 0)
    room:setPlayerMark(player, COUNT, #chosen)
  end,
})

-- 使用或打出牌时：摸X张牌
local function drawEffect(event)
  yuzhi:addEffect(event, {
    anim_type = "drawcard",
    is_delay_effect = true,
    can_trigger = function(self, ev, target, player, data)
      return target == player and player:hasSkill(yuzhi.name) and player:getMark(INVALID) == 0 and
        player:getMark(COUNT) > 0
    end,
    on_cost = Util.TrueFunc,
    on_use = function(self, ev, target, player, data)
      player:drawCards(player:getMark(COUNT), yuzhi.name)
    end,
  })
end
drawEffect(fk.CardUsing)
drawEffect(fk.CardResponding)

-- ===== 条件检测 =====
-- 1. 对一名角色造成伤害
yuzhi:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return target == player and hasCond(player, 1)
  end,
  on_refresh = function(self, event, target, player, data) reach(player, 1) end,
})

-- 2. 使用牌指定自己为目标；4. 使用牌被其他角色响应
yuzhi:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    if target == player then
      return hasCond(player, 2) and isTarget(data, player)
    end
    local resp = data.responseToEvent
    return hasCond(player, 4) and resp and resp.from == player
  end,
  on_refresh = function(self, event, target, player, data)
    reach(player, target == player and 2 or 4)
  end,
})

-- 4. 使用牌被其他角色响应（打出响应）
yuzhi:addEffect(fk.CardResponding, {
  can_refresh = function(self, event, target, player, data)
    local resp = data.responseToEvent
    return target ~= player and hasCond(player, 4) and resp and resp.from == player
  end,
  on_refresh = function(self, event, target, player, data) reach(player, 4) end,
})

-- 3. 弃牌阶段弃置过牌；5. 不以使用、打出或弃牌阶段弃置失去过牌
yuzhi:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return (hasCond(player, 3) or hasCond(player, 5)) and player:getMark(INVALID) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local inDiscardPhase = room.current == player and player.phase == Player.Discard
    for _, move in ipairs(data) do
      if move.from == player then
        local lost = table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end)
        if lost then
          local discardPhaseDiscard = move.moveReason == fk.ReasonDiscard and inDiscardPhase
          if discardPhaseDiscard then
            reach(player, 3)
          elseif move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResponse then
            reach(player, 5)
          end
        end
      end
    end
  end,
})

-- 进入濒死状态：技能恢复有效
yuzhi:addEffect(fk.EnterDying, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(INVALID) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, INVALID, 0)
  end,
})

-- 所有技能本轮失效（"宇志"自身的检测与恢复部分除外，但其摸牌效果也会停止）
yuzhi:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    if from:getMark(INVALID) == 0 then return false end
    local skel = skill.getSkeleton and skill:getSkeleton()
    if skel and skel.name == yuzhi.name then return false end
    return skill:isPlayerSkill(from)
  end,
})

return yuzhi

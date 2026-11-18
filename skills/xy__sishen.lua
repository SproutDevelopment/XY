-- 【死神】聊天室整則訊息必須與存活武將名字完全相同才會判定。
-- 原生 C++ chat 不會進入 Lua；需要附帶的伺服器橋接補丁，
-- 沒有補丁時保留主動技的手動選名備援。
local D = dofile("./packages/XY/deathgod_utils.lua")
local skill = fk.CreateSkill{ name = "xy__sishen" }

skill:addEffect(fk.GameStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player and D.isOwner(player) and player.room and
      not player.room:getTag("xy__deathgod_chat_hook")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    D.installChatListener(player.room)
  end,
})

-- 在出牌階段點擊【死神】後，使用拓展包 QML 自訂文字輸入框。
-- 只有輸入的整則文字與某存活武將顯示名字完全相同，才會處決。
-- 若 FreeKill 版本不支援自訂對話框，保留原生選名備援，避免技能失效。
local INPUT_QML = "packages/XY/qml/DeathgodNameInput.qml"

local function askForWrittenName(room, player, skillName)
  if type(room.askToCustomDialog) == "function" then
    local ok, answer = pcall(room.askToCustomDialog, room, player, {
      qml_path = INPUT_QML,
      extra_data = {skill = skillName},
    })
    if ok then
      -- 0.5.12+ 返回 Lua 字串，不需要 JSON 解碼。
      -- nil 或空字串是取消，不能再次彈出選名備援。
      if type(answer) == "string" then return answer end
      if type(answer) == "table" and type(answer.text) == "string" then
        return answer.text
      end
      return ""
    end
    -- 舊核心不能建立自訂對話框時，才退回已知相容的選擇 UI。
  end
  if type(room.askToChoice) ~= "function" then return "" end
  local choices = D.availableNames(room)
  if #choices == 0 then return "" end
  local reply = room:askToChoice(player, {
    choices = choices,
    skill_name = skillName,
    prompt = "#xy__sishen-choose",
    cancelable = true,
  })
  return type(reply) == "string" and reply or ""
end

skill:addEffect("active", {
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player and D.isOwner(player) and player.phase == Player.Play
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local text = askForWrittenName(room, player, self.name)
    if text ~= "" then D.resolve(room, player, text) end
  end,
})
return skill

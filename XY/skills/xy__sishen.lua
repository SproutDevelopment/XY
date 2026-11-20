-- 筆記（夜神月）
-- 游戏任何时候，你可以选择并猜测一名其他角色被取替武将的名称。若你正确，则其立即死亡。
--
-- 实现：一个按钮。
--  · 出牌阶段可以直接按；
--  · 你被询问使用或打出牌（包括所有人被询问【无懈可击】时）也可以按。
-- 按下后选择一名其他角色，输入你猜的武将名字；若与其武将（主将或副将）名字完全相同，其立即死亡。
-- 技能借用一张“占位牌”让按钮可以点击，占位牌不会被真正使用。
local D = dofile("./packages/XY/deathgod_utils.lua")
local skill = fk.CreateSkill{ name = "xy__sishen" }

Fk:loadTranslationTable{
  ["xy__sishen"] = "筆記",
  [":xy__sishen"] = "游戏任何时候，你可以选择并猜测一名其他角色被取替武将的名称。若你正确，则其立即死亡。",
  ["#xy__sishen"] = "筆記：选择一名其他角色并猜测其武将名称，猜对则其立即死亡",
  ["#xy__sishen-target"] = "筆記：选择要猜测的角色",
  ["#xy__sishen-choose"] = "筆記：猜测 %dest 的武将名称",
  ["#xy__sishen-kill"] = "%from 发动“筆記”，写下%arg，令%to立即死亡。",
  ["#xy__sishen-miss"] = "%from 发动“筆記”猜测 %to 的武将名称，但猜错了",
}

-- 文字输入框（本体的 askToCustomDialog 需要 component = { url = ..., model = { url = ... } }）
local INPUT_COMPONENT = {
  url = "packages/XY/qml/DeathgodNameInput.qml",
  model = { url = "packages/XY/qml/DeathgodNameModel.qml" },
}

local function normalizeAnswer(answer)
  if type(answer) == "table" and type(answer.text) == "string" then answer = answer.text end
  if type(answer) ~= "string" then return "" end
  -- 回复可能被 JSON 编码成 "\"名字\""，尝试解码
  if answer:sub(1, 1) == '"' and answer:sub(-1) == '"' then
    local ok, dec = pcall(function() return json.decode(answer) end)
    if ok and type(dec) == "string" then answer = dec end
  end
  return answer
end

-- 输入猜测的名字（优先使用文字输入框；失败时退回从所有武将名字中选择）
local function askForWrittenName(room, player, to)
  if type(room.askToCustomDialog) == "function" then
    local ok, answer = pcall(room.askToCustomDialog, room, player, {
      skill_name = skill.name,
      component = INPUT_COMPONENT,
    })
    if ok then return normalizeAnswer(answer) end
    fk.qWarning("[xy__sishen] custom dialog failed: " .. tostring(answer))
  end
  local set, names = {}, {}
  for name, g in pairs(Fk.generals) do
    if not g.total_hidden then
      local label = D.visibleName(name)
      if label and not set[label] then
        set[label] = true
        names[#names + 1] = label
      end
    end
  end
  table.sort(names)
  table.insert(names, 1, "Cancel")
  local reply = room:askToChoice(player, {
    choices = names,
    skill_name = skill.name,
    prompt = "#xy__sishen-choose::" .. to.id,
  })
  if reply == "Cancel" then return "" end
  return type(reply) == "string" and reply or ""
end

local function doGuess(room, player)
  local others = room:getOtherPlayers(player, false)
  if #others == 0 then return end
  local tos = room:askToChoosePlayers(player, {
    targets = others,
    min_num = 1,
    max_num = 1,
    skill_name = skill.name,
    prompt = "#xy__sishen-target",
    cancelable = true,
  })
  local to = tos and tos[1]
  if not to then return end
  local text = askForWrittenName(room, player, to)
  if text == "" or to.dead then return end
  if D.targetNameMatches(to, text) then
    room:sendLog{ type = "#xy__sishen-kill", from = player.id, to = { to.id }, arg = text }
    room:killPlayer({ who = to })
  else
    room:sendLog{ type = "#xy__sishen-miss", from = player.id, to = { to.id } }
  end
end

-- 找一个能放进当前询问的占位牌名（只为了让按钮可以点击）
local function placeholderName()
  local pattern = Fk.currentResponsePattern
  if pattern == nil then return "ex_nihilo" end
  local exp = Exppattern:Parse(pattern)
  for _, name in ipairs(Fk:getAllCardNames("btde")) do
    if exp:matchExp(name) then return name end
  end
  return nil
end

skill:addEffect("viewas", {
  anim_type = "offensive",
  pattern = ".",
  prompt = "#xy__sishen",
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local name = placeholderName()
    if not name then return nil end
    local c = Fk:cloneCard(name)
    c.skillName = skill.name
    return c
  end,
  before_use = function(self, player, use)
    doGuess(player.room, player)
    return skill.name   -- 取消占位牌
  end,
  enabled_at_play = function(self, player)
    return D.isOwner(player)
  end,
  enabled_at_response = function(self, player, response)
    return D.isOwner(player)
  end,
  enabled_at_nullification = function(self, player, data)
    return D.isOwner(player)
  end,
})

return skill

-- 取逸（沮授）
-- 一名角色回合结束时，若其没有使用过一种类型的牌，则你可以获得其该类型的所有牌。
-- 若你以此法获得的手牌种类不小于你的体力值，你下回合无法对其发动此技能并失去一点体力。
-- （"退幻"后：目标角色可以选择是否让你发动此技能）

local quyi = fk.CreateSkill {
  name = "xy__quyi",
}

Fk:loadTranslationTable{
  ["xy__quyi"] = "取逸",
  [":xy__quyi"] = "一名角色回合结束时，若其没有使用过一种类型的牌，则你可以获得其该类型的所有牌。" ..
    "若你以此法获得的手牌种类不小于你的体力值，你下回合无法对其发动此技能并失去一点体力。",

  ["xy__type_basic"] = "基本牌",
  ["xy__type_trick"] = "锦囊牌",
  ["xy__type_equip"] = "装备牌",
  ["#xy__quyi-choice"] = "取逸：%dest 本回合没有使用过%arg，你可以获得其这些类型的所有牌",
  ["#xy__jushou-allow"] = "%src 想对你发动“%arg”，是否允许？",
  ["#xy__quyi-ban"] = "%from 以“取逸”获得的手牌种类不小于体力值，下回合无法对 %to 发动“取逸”",
}

XY_Jushou = XY_Jushou or {}
local REVERTED = "xy__jushou_reverted"

--- "退幻"后：目标角色可以选择是否让你发动该技能
function XY_Jushou.allowed(player, target, skillName)
  if player:getMark(REVERTED) == 0 or target == player or target.dead then return true end
  return player.room:askToSkillInvoke(target, {
    skill_name = skillName,
    prompt = "#xy__jushou-allow:" .. player.id .. "::" .. skillName,
  })
end

local TYPES = {
  { key = "xy__type_basic", type = Card.TypeBasic },
  { key = "xy__type_trick", type = Card.TypeTrick },
  { key = "xy__type_equip", type = Card.TypeEquip },
}
local BAN_NEXT = "xy__quyi_ban_next"   -- 下回合禁止的目标
local BAN_NOW = "xy__quyi_ban_now"     -- 本回合禁止的目标

local function unusedTypes(room, target)
  local used = {}
  room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
    if e.data.from == target then
      used[e.data.card.type] = true
    end
    return false
  end, Player.HistoryTurn)
  local ret = {}
  for _, t in ipairs(TYPES) do
    if not used[t.type] and table.find(target:getCardIds("he"), function(id)
      return Fk:getCardById(id).type == t.type
    end) then
      table.insert(ret, t)
    end
  end
  return ret
end

quyi:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(quyi.name) or target.dead or target == player then return false end
    if table.contains(player:getTableMark(BAN_NOW), target.id) then return false end
    return #unusedTypes(player.room, target) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local avail = unusedTypes(room, target)
    local names = table.concat(table.map(avail, function(t) return Fk:translate(t.key) end), "、")
    if not room:askToSkillInvoke(player, {
      skill_name = quyi.name,
      prompt = "#xy__quyi-choice::" .. target.id .. ":" .. names,
    }) then return false end
    if not XY_Jushou.allowed(player, target, quyi.name) then return false end
    event:setCostData(self, { tos = { target } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    -- 获得其本回合没有使用过的每种类型的所有牌
    local types = {}
    for _, t in ipairs(unusedTypes(room, target)) do types[t.type] = true end
    local ids = table.filter(target:getCardIds("he"), function(id)
      return types[Fk:getCardById(id).type]
    end)
    if #ids == 0 then return end
    room:obtainCard(player, ids, true, fk.ReasonPrey, player, quyi.name)

    -- 以此法获得的手牌种类（基本牌、锦囊牌、装备牌的种类数）
    local kindSet = {}
    for _, id in ipairs(ids) do
      if table.contains(player:getCardIds("h"), id) then
        kindSet[Fk:getCardById(id).type] = true
      end
    end
    local kinds = 0
    for _ in pairs(kindSet) do kinds = kinds + 1 end
    if kinds >= player.hp and not player.dead then
      room:addTableMark(player, BAN_NEXT, target.id)
      room:sendLog{ type = "#xy__quyi-ban", from = player.id, to = { target.id } }
      room:loseHp(player, 1, quyi.name)
    end
  end,
})

-- 每个回合开始时：上回合记录的禁止目标在本回合生效
quyi:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark(BAN_NEXT) ~= 0 or player:getMark(BAN_NOW) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local nextList = player:getTableMark(BAN_NEXT)
    room:setPlayerMark(player, BAN_NOW, #nextList > 0 and nextList or 0)
    room:setPlayerMark(player, BAN_NEXT, 0)
  end,
})

return quyi

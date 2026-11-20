-- 萬安（沮授）
-- 一名角色回合开始时，若你于上一个回合没有对其造成过伤害，你可以选择X种类型的牌令其无法使用或打出直到其下回合开始，
-- 令其跳过弃牌阶段，然后你减少1点体力上限。（X为你已失去的体力值+1）
-- （"退幻"后：目标角色可以选择是否让你发动此技能）

local wanan = fk.CreateSkill {
  name = "xy__wanan",
}

Fk:loadTranslationTable{
  ["xy__wanan"] = "万安",
  [":xy__wanan"] = "一名角色回合开始时，若你于上一个回合没有对其造成过伤害，你可以选择X种类型的牌令其无法使用或打出直到其下回合开始，" ..
    "令其跳过弃牌阶段，然后你减少1点体力上限。（X为你已失去的体力值+1）",

  ["#xy__wanan-invoke"] = "万安：你可以令 %dest %arg种类型的牌无法使用或打出，并令其跳过弃牌阶段，然后你减1点体力上限",
  ["#xy__wanan-types"] = "万安：选择%arg种类型",
  ["@xy__wanan_types"] = "万安禁",
  ["basic_char"] = "基",
  ["trick_char"] = "锦",
  ["equip_char"] = "装",
}

local DMG_TURN = "xy__wanan_dmg-turn"   -- 本回合你造成过伤害的角色
local DMG_LAST = "xy__wanan_dmg_last"   -- 上一个回合你造成过伤害的角色
local BANNED = "@xy__wanan_types"       -- 在目标身上：被禁止的类型

local TYPE_KEYS = { "xy__type_basic", "xy__type_trick", "xy__type_equip" }
local TYPE_STR = { xy__type_basic = "basic", xy__type_trick = "trick", xy__type_equip = "equip" }

local function getX(player)
  return math.min(3, math.max(1, player.maxHp - player.hp + 1))
end

-- 记录你造成伤害的角色
wanan:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.to and player:hasSkill(wanan.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    if not table.contains(player:getTableMark(DMG_TURN), data.to.id) then
      player.room:addTableMark(player, DMG_TURN, data.to.id)
    end
  end,
})

-- 回合结束：本回合的记录成为"上一个回合"的记录
wanan:addEffect(fk.TurnEnd, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(wanan.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local list = player:getTableMark(DMG_TURN)
    player.room:setPlayerMark(player, DMG_LAST, #list > 0 and table.simpleClone(list) or 0)
  end,
})

-- 其下回合开始：解除禁止
wanan:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(BANNED) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, BANNED, 0)
  end,
})

wanan:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(wanan.name) and not target.dead and
      not table.contains(player:getTableMark(DMG_LAST), target.id)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if not room:askToSkillInvoke(player, {
      skill_name = wanan.name,
      prompt = "#xy__wanan-invoke::" .. target.id .. ":" .. getX(player),
    }) then return false end
    if not XY_Jushou.allowed(player, target, wanan.name) then return false end
    event:setCostData(self, { tos = { target } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = getX(player)
    local chosen = room:askToChoices(player, {
      choices = TYPE_KEYS,
      min_num = x,
      max_num = x,
      skill_name = wanan.name,
      prompt = "#xy__wanan-types:::" .. x,
      cancelable = false,
    })
    local types = table.map(chosen, function(k) return TYPE_STR[k] end)
    room:setPlayerMark(target, BANNED, types)
    target:skip(Player.Discard)
    if not player.dead then
      room:changeMaxHp(player, -1)
    end
  end,
})

-- 无法使用或打出被禁止类型的牌
wanan:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local types = player:getTableMark(BANNED)
    return card and #types > 0 and table.contains(types, card:getTypeString())
  end,
  prohibit_response = function(self, player, card)
    local types = player:getTableMark(BANNED)
    return card and #types > 0 and table.contains(types, card:getTypeString())
  end,
})

return wanan

-- 優柔（孫尚香）
-- 锁定技，当你的勾玉颜色变为绿色/红色时，你的势力变为"吴"/"蜀"，然后你摸两张牌。你的登场势力为"吴"。
--
-- 勾玉颜色取决于体力值占体力上限的比例：
--   体力值 > 体力上限的2/3：绿色；体力值 > 体力上限的1/3：黄色；否则：红色。
-- 体力值或体力上限变化时都会检查。

local yourou = fk.CreateSkill {
  name = "xy__yourou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xy__yourou"] = "优柔",
  [":xy__yourou"] = "锁定技，当你的勾玉颜色变为绿色/红色时，你的势力变为“吴”/“蜀”，然后你摸两张牌。你的登场势力为“吴”。",
}

local function magatamaColor(hp, maxHp)
  if maxHp <= 0 or hp <= 0 then return "red" end
  if hp * 3 > maxHp * 2 then return "green" end
  if hp * 3 > maxHp then return "yellow" end
  return "red"
end

local function changed(player, beforeHp, beforeMax)
  local before = magatamaColor(beforeHp, beforeMax)
  local after = magatamaColor(player.hp, player.maxHp)
  return before ~= after and (after == "green" or after == "red")
end

local function apply(player)
  local room = player.room
  local kingdom = magatamaColor(player.hp, player.maxHp) == "green" and "wu" or "shu"
  if player.kingdom ~= kingdom then
    room:changeKingdom(player, kingdom, true)
  end
  player:drawCards(2, yourou.name)
end

-- 体力值变化
yourou:addEffect(fk.HpChanged, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(yourou.name) or player.dead then return false end
    return changed(player, player.hp - (data.num or 0), player.maxHp)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    apply(player)
  end,
})

-- 体力上限变化
yourou:addEffect(fk.MaxHpChanged, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(yourou.name) or player.dead then return false end
    return changed(player, player.hp, player.maxHp - (data.num or 0))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    apply(player)
  end,
})

return yourou

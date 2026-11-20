-- 後宮（董白）
-- 觉醒技，当你体力上限不小于八时，你体力上限调为三。你获得所有"妻子"的技能，你失去"邀雄"和"护妻"。

local hougong = fk.CreateSkill {
  name = "xy__hougong",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["xy__hougong"] = "后宫",
  [":xy__hougong"] = "觉醒技，当你体力上限不小于八时，你体力上限调为三。你获得所有“妻子”的技能，你失去“邀雄”和“护妻”。",
}

hougong:addEffect(fk.MaxHpChanged, {
  anim_type = "big",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hougong.name)
      and player:usedSkillTimes(hougong.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player.maxHp >= 8
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.maxHp ~= 3 then
      room:changeMaxHp(player, 3 - player.maxHp)
    end
    if player.dead then return end

    -- 妻子的技能：永久获得；其余“邀雄”临时技能立即失去
    local wifeSkills = {}
    for _, name in ipairs(player:getTableMark("@&xy__dongbai_wives")) do
      local g = Fk.generals[name]
      if g then table.insertTableIfNeed(wifeSkills, g:getSkillNameList(true)) end
    end
    local temp = table.filter(player:getTableMark("xy__yaoxiong_skills"), function(s)
      return not table.contains(wifeSkills, s)
    end)
    room:setPlayerMark(player, "xy__yaoxiong_skills", 0)

    local list = {}
    -- 失去“邀雄”后，其余由“邀雄”获得的（非妻子）技能也一并失去
    for _, s in ipairs(temp) do table.insert(list, "-" .. s) end
    for _, s in ipairs(wifeSkills) do
      if not player:hasSkill(s, true, true) then table.insert(list, s) end
    end
    table.insert(list, "-xy__yaoxiong")
    table.insert(list, "-xy__huqi")
    room:handleAddLoseSkills(player, table.concat(list, "|"), nil, true, false)
  end,
})

return hougong

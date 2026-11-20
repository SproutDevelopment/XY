-- 樂結（輝夜姬）
-- 持恒技，一轮结束或一名角色进入濒死状态时，你选择一项：
-- 1.弃置一名角色所有牌。2.对一名角色造成一点雷属性伤害。3.获得本回合进入弃牌堆的牌。
-- 4.防止你下次受到的伤害。5.令一名角色技能失效直到你下次发动此技能。6.摸三张牌。
-- 7.令一名角色下次受到的伤害翻倍。8.强攻：翻面并令一名角色恢复至1点体力。
-- 强攻：依次执行以上所有选项，然后（翻面并令一名角色恢复至1点体力），最后删除一个选项。

local lejie = fk.CreateSkill {
  name = "xy__lejie",
  tags = { Skill.Permanent },
}

Fk:loadTranslationTable{
  ["xy__lejie"] = "乐结",
  [":xy__lejie"] = "持恒技，一轮结束或一名角色进入濒死状态时，你选择一项：<br>" ..
    "1.弃置一名角色所有牌。2.对一名角色造成一点雷属性伤害。3.获得本回合进入弃牌堆的牌。<br>" ..
    "4.防止你下次受到的伤害。5.令一名角色技能失效直到你下次发动此技能。6.摸三张牌。<br>" ..
    "7.令一名角色下次受到的伤害翻倍。8.强攻：翻面并令一名角色恢复至1点体力。",

  ["xy__lejie_1"] = "1.弃置一名角色所有牌",
  ["xy__lejie_2"] = "2.对一名角色造成1点雷电伤害",
  ["xy__lejie_3"] = "3.获得本回合进入弃牌堆的牌",
  ["xy__lejie_4"] = "4.防止你下次受到的伤害",
  ["xy__lejie_5"] = "5.令一名角色技能失效",
  ["xy__lejie_6"] = "6.摸三张牌",
  ["xy__lejie_7"] = "7.令一名角色下次受到的伤害翻倍",
  ["xy__lejie_8"] = "8.强攻：翻面并令一名角色恢复至1点体力",
  ["#xy__lejie-choice"] = "乐结：请选择一项",
  ["#xy__lejie-target"] = "乐结：选择一名角色",
  ["#xy__lejie-delete"] = "乐结（强攻）：删除一个选项",
  ["#xy__lejie-doing"] = "%from 的“乐结”执行：%arg",
  ["#xy__lejie-t1"] = "乐结【1.弃置一名角色所有牌】：选择一名角色",
  ["#xy__lejie-t2"] = "乐结【2.造成1点雷电伤害】：选择一名角色",
  ["#xy__lejie-t5"] = "乐结【5.令一名角色技能失效】：选择一名角色",
  ["#xy__lejie-t7"] = "乐结【7.下次受到的伤害翻倍】：选择一名角色",
  ["#xy__lejie-t8"] = "乐结【8.强攻：令一名角色恢复至1点体力】：选择一名角色",
  ["@xy__lejie_removed"] = "乐结已删",

  ["@xy__lejie_prevent"] = "防伤",
  ["@@xy__lejie_invalid"] = "乐结 技能失效",
  ["@xy__lejie_double"] = "伤害翻倍",
}

local INVALID = "@@xy__lejie_invalid"
local INVALID_BY = "xy__lejie_invalid_by"
local PREVENT = "@xy__lejie_prevent"
local DOUBLE = "@xy__lejie_double"
local DISCARDED = "xy__lejie_discarded"   -- 房间标签：本回合进入弃牌堆的牌

local function chooseOne(player, targets, prompt)
  local room = player.room
  if #targets == 0 then return nil end
  return room:askToChoosePlayers(player, {
    targets = targets,
    min_num = 1,
    max_num = 1,
    prompt = prompt or "#xy__lejie-target",
    skill_name = lejie.name,
    cancelable = false,
  })[1]
end

local REMOVED = "xy__lejie_removed"   -- 已被"强攻"删除的选项

-- 执行第 i 项（1~7）
local function doOption(player, i)
  local room = player.room
  if player.dead then return end
  -- 日志：正在执行第几项
  room:sendLog{ type = "#xy__lejie-doing", from = player.id, arg = "xy__lejie_" .. i }
  if i == 1 then
    local to = chooseOne(player, table.filter(room.alive_players, function(p) return not p:isNude() end), "#xy__lejie-t1")
    if to then room:throwCard(to:getCardIds("he"), lejie.name, to, player) end
  elseif i == 2 then
    local to = chooseOne(player, room.alive_players, "#xy__lejie-t2")
    if to then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = lejie.name,
      }
    end
  elseif i == 3 then
    local ids = table.filter(room:getTag(DISCARDED) or {}, function(id)
      return room:getCardArea(id) == Card.DiscardPile
    end)
    if #ids > 0 then
      room:obtainCard(player, ids, true, fk.ReasonJustMove, player, lejie.name)
    end
  elseif i == 4 then
    room:addPlayerMark(player, PREVENT, 1)
  elseif i == 5 then
    local to = chooseOne(player, room.alive_players, "#xy__lejie-t5")
    if to then
      room:setPlayerMark(to, INVALID, 1)
      room:setPlayerMark(to, INVALID_BY, player.id)
    end
  elseif i == 6 then
    player:drawCards(3, lejie.name)
  elseif i == 7 then
    local to = chooseOne(player, room.alive_players, "#xy__lejie-t7")
    if to then room:addPlayerMark(to, DOUBLE, 1) end
  end
end

-- 尚未删除的其余选项（1~7）
local function remainingOthers(player)
  local removed = player:getTableMark(REMOVED)
  local list = {}
  for i = 1, 7 do
    local o = "xy__lejie_" .. i
    if not table.contains(removed, o) then table.insert(list, o) end
  end
  return list
end

local function doLejie(player)
  local room = player.room
  -- 上次"技能失效"的效果到此结束
  for _, p in ipairs(room.players) do
    if p:getMark(INVALID_BY) == player.id then
      room:setPlayerMark(p, INVALID, 0)
      room:setPlayerMark(p, INVALID_BY, 0)
    end
  end

  local others = remainingOthers(player)
  local choices = table.simpleClone(others)
  -- 当选项仅剩强攻和另一项时，无法选择强攻
  if #others >= 2 then
    table.insert(choices, "xy__lejie_8")
  end
  if #choices == 0 then return end
  local choice = room:askToChoice(player, {
    choices = choices,
    skill_name = lejie.name,
    prompt = "#xy__lejie-choice",
  })
  local n = tonumber(choice:match("_(%d)$"))

  if n <= 7 then
    doOption(player, n)
    return
  end

  -- 8. 强攻：先执行强攻效果（翻面并令一名角色恢复至1点体力）
  room:sendLog{ type = "#xy__lejie-doing", from = player.id, arg = "xy__lejie_8" }
  player:turnOver()
  local to = chooseOne(player, room.alive_players, "#xy__lejie-t8")
  if to and to.hp < 1 then
    room:recover{
      who = to,
      num = 1 - to.hp,
      recoverBy = player,
      skillName = lejie.name,
    }
  end
  -- 再依次执行其余选项
  for _, o in ipairs(others) do
    if player.dead then break end
    doOption(player, tonumber(o:match("_(%d)$")))
  end
  -- 然后须选择删除一个其余选项
  if player.dead then return end
  local remaining = remainingOthers(player)
  if #remaining > 0 then
    local del = room:askToChoice(player, {
      choices = remaining,
      skill_name = lejie.name,
      prompt = "#xy__lejie-delete",
    })
    room:addTableMark(player, REMOVED, del)
    room:setPlayerMark(player, "@xy__lejie_removed", #player:getTableMark(REMOVED))
  end
end

-- 一轮结束时
lejie:addEffect(fk.RoundEnd, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(lejie.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    doLejie(player)
  end,
})

-- 该角色是否本来就处于濒死结算中（濒死时再受到伤害不算"进入濒死状态"）
local function alreadyDying(room, who)
  local cur = room.logic:getCurrentEvent():findParent(GameEvent.Dying, true)
  local e = cur and cur.parent
  while e do
    if e.event == GameEvent.Dying and e.data and e.data.who == who then
      return true
    end
    e = e.parent
  end
  return false
end

-- 一名角色进入濒死状态时
lejie:addEffect(fk.EnterDying, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(lejie.name) and not alreadyDying(player.room, target)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    doLejie(player)
  end,
})

-- 4. 防止你下次受到的伤害 / 7. 下次受到的伤害翻倍
lejie:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and (player:getMark(PREVENT) > 0 or player:getMark(DOUBLE) > 0)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark(DOUBLE) > 0 then
      -- 每次"翻倍"叠加：1次 x2，2次 x4，3次 x8……
      local n = player:getMark(DOUBLE)
      room:setPlayerMark(player, DOUBLE, 0)
      data:changeDamage(math.floor(data.damage * (2 ^ n - 1)))
    end
    if player:getMark(PREVENT) > 0 then
      room:removePlayerMark(player, PREVENT, 1)
      if data.preventDamage then
        data:preventDamage()
      else
        return true
      end
    end
  end,
})

-- 5. 技能失效
lejie:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return from:getMark(INVALID) ~= 0 and skill:isPlayerSkill(from)
  end,
})

-- 3. 记录本回合进入弃牌堆的牌
lejie:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(lejie.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local list = room:getTag(DISCARDED) or {}
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(list, info.cardId)
        end
      end
    end
    room:setTag(DISCARDED, list)
  end,
})

lejie:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(lejie.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setTag(DISCARDED, {})
  end,
})

return lejie

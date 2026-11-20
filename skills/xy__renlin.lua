-- 仁鄰（曹節·仁慈敦厚）
-- 一名角色的出牌阶段开始时，你可以与其展示手牌。其将你与其手牌中牌名相同的牌扣置直到本阶段结束，
-- 然后获得你手牌中这些牌名的牌。该角色回合结束时，其须交给你其以此法获得的对应牌名与数量的牌。
-- 否则其每少交给你一张牌，其失去1点体力。
--
-- 实现：
-- 出牌阶段开始时，双方展示手牌；其手牌中与你手牌牌名相同的牌扣置于其武将牌上直到本阶段结束，
-- 然后你将你手牌中这些牌名的牌交给其；本阶段结束时，其取回被扣置的牌；
-- 其回合结束时，须按获得的牌名与数量交给你牌，每少交一张失去1点体力。

local renlin = fk.CreateSkill {
  name = "xy__renlin",
}

Fk:loadTranslationTable{
  ["xy__renlin"] = "仁邻",
  [":xy__renlin"] = "一名角色的出牌阶段开始时，你可以与其展示手牌。其将你与其手牌中牌名相同的牌扣置直到本阶段结束，" ..
    "然后获得你手牌中这些牌名的牌。该角色回合结束时，其须交给你其以此法获得的对应牌名与数量的牌。" ..
    "否则其每少交给你一张牌，其失去1点体力。",

  ["xy__renlin_pile"] = "仁邻",
  ["#xy__renlin-invoke"] = "仁邻：是否与 %dest 展示手牌？",
  ["#xy__renlin-give"] = "仁邻：请交给 %src %arg2张【%arg】",
  ["@xy__renlin_debt"] = "仁邻欠",
}

local PILE = "xy__renlin_pile"
local FROM = "xy__renlin_from"     -- 在目标身上：发动"仁邻"的角色id
local DEBT = "xy__renlin_debt"     -- 在目标身上：需要归还的牌名列表（每张一项）

local function trueNames(ids)
  local set = {}
  for _, id in ipairs(ids) do
    set[Fk:getCardById(id).trueName] = true
  end
  return set
end

-- 出牌阶段开始时
renlin:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(renlin.name) and target ~= player and not target.dead and
      target.phase == Player.Play and target:getMark(FROM) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = renlin.name,
      prompt = "#xy__renlin-invoke::" .. target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player:isKongcheng() then room:showCards(player:getCardIds("h"), player) end
    if not target:isKongcheng() then room:showCards(target:getCardIds("h"), target) end

    local mineNames = trueNames(player:getCardIds("h"))
    local theirNames = trueNames(target:getCardIds("h"))
    local common = {}
    for name in pairs(mineNames) do
      if theirNames[name] then common[name] = true end
    end
    if next(common) == nil then return end

    local mine = table.filter(player:getCardIds("h"), function(id)
      return common[Fk:getCardById(id).trueName]
    end)
    local theirs = table.filter(target:getCardIds("h"), function(id)
      return common[Fk:getCardById(id).trueName]
    end)

    room:setPlayerMark(target, FROM, player.id)
    room:setPlayerMark(target, DEBT, table.map(mine, function(id)
      return Fk:getCardById(id).trueName
    end))
    room:setPlayerMark(target, "@xy__renlin_debt", #mine)

    -- 其牌名相同的牌扣置直到本阶段结束
    if #theirs > 0 then target:addToPile(PILE, theirs, false, renlin.name) end
    -- 然后你将这些牌名的牌交给其
    if #mine > 0 and not target.dead then
      room:obtainCard(target, mine, false, fk.ReasonGive, player, renlin.name)
    end
  end,
})

-- 出牌阶段结束：其取回被扣置的牌
renlin:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Play and target:getMark(FROM) == player.id and
      #target:getPile(PILE) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(target, target:getPile(PILE), false, fk.ReasonJustMove, target, renlin.name)
  end,
})

-- 该角色回合结束时：按牌名与数量归还，每少一张失去1点体力
renlin:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target:getMark(FROM) == player.id and not target.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local debt = target:getTableMark(DEBT)
    room:setPlayerMark(target, FROM, 0)
    room:setPlayerMark(target, DEBT, 0)
    room:setPlayerMark(target, "@xy__renlin_debt", 0)

    local counts, order = {}, {}
    for _, name in ipairs(debt) do
      if not counts[name] then table.insert(order, name) end
      counts[name] = (counts[name] or 0) + 1
    end

    local short = 0
    for _, name in ipairs(order) do
      local need = counts[name]
      local avail = table.filter(target:getCardIds("he"), function(id)
        return Fk:getCardById(id).trueName == name
      end)
      local k = math.min(need, #avail)
      if k > 0 and not player.dead then
        local cards = room:askToCards(target, {
          min_num = k,
          max_num = k,
          include_equip = true,
          pattern = name,
          skill_name = renlin.name,
          prompt = "#xy__renlin-give:" .. player.id .. "::" .. name .. ":" .. k,
          cancelable = false,
        })
        if #cards > 0 then
          room:obtainCard(player, cards, false, fk.ReasonGive, target, renlin.name)
        end
        k = #cards
      end
      short = short + (need - k)
    end
    if short > 0 and not target.dead then
      room:loseHp(target, short, renlin.name)
    end
  end,
})

-- 该角色死亡：清除记录
renlin:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player, data)
    return target:getMark(FROM) == player.id
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, FROM, 0)
    room:setPlayerMark(target, DEBT, 0)
  end,
})

return renlin

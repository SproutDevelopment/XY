-- 拳法（猗窩座）
-- 出牌阶段，你可以弃置等量"斗"发动对应效果：2个：空式，2个：乱式，3个：灭式，5个：终式。
-- 空式：出牌阶段限一次，你对一名不在你攻击范围内的角色造成一点伤害。
-- 乱式：你对一名攻击范围内的角色使用一张【杀】不计入次数的【兵临城下】。
-- 灭式：你施法：视为对一名角色使用一张伤害为X的【杀】。
-- 终式：本回合所有其他角色视为处于你的攻击范围内，且你获得"斗"时视为对所有其他角色使用一张不计入次数的【杀】。
--       （此【杀】结算中你不能获得"斗"）
--
-- 实现说明：
-- 【兵临城下】：亮出牌堆顶四张牌，依次对目标使用其中的【杀】（不计入次数），其余的牌放回牌堆顶。
-- 施法：选择X（1~3），X个回合后（从本回合起算第X个回合结束时）执行效果。

local quanfa = fk.CreateSkill {
  name = "xy__quanfa",
}

Fk:loadTranslationTable{
  ["xy__quanfa"] = "拳法",
  [":xy__quanfa"] = "出牌阶段，你可以弃置等量“斗”发动对应效果：2个：空式，2个：乱式，3个：灭式，5个：终式。<br>" ..
    "<b>空式</b>：出牌阶段限一次，你对一名不在你攻击范围内的角色造成一点伤害。<br>" ..
    "<b>乱式</b>：你对一名攻击范围内的角色使用一张【杀】不计入次数的【兵临城下】。<br>" ..
    "<b>灭式</b>：你施法：视为对一名角色使用一张伤害为X的【杀】。<br>" ..
    "<b>终式</b>：本回合所有其他角色视为处于你的攻击范围内，且你获得「斗」时视为对所有其他角色使用一张不计入次数的【杀】。" ..
    "（此【杀】结算中你不能获得「斗」）",

  ["#xy__quanfa"] = "拳法：弃置“斗”发动一种拳式",
  ["xy__quanfa_kong"] = "空式（2斗）：对攻击范围外的一名角色造成1点伤害",
  ["xy__quanfa_luan"] = "乱式（2斗）：对攻击范围内一名角色使用【兵临城下】",
  ["xy__quanfa_mie"] = "灭式（3斗）：施法，视为使用伤害为X的【杀】",
  ["xy__quanfa_zhong"] = "终式（5斗）：本回合所有角色在攻击范围内，获得“斗”时视为使用【杀】",
  ["#xy__quanfa-choice"] = "拳法：选择一种拳式",
  ["#xy__quanfa-kong"] = "空式：对一名不在你攻击范围内的角色造成1点伤害",
  ["#xy__quanfa-luan"] = "乱式：选择攻击范围内的一名角色",
  ["#xy__quanfa-mie_x"] = "灭式（施法）：选择X，X个回合后视为使用伤害为X的【杀】",
  ["#xy__quanfa-mie_target"] = "灭式：视为对一名角色使用一张伤害为%arg的【杀】",
  ["#xy__quanfa-mie_log"] = "%from 的“灭式”施法完成",
  ["@@xy__quanfa_zhong-turn"] = "终式",
  ["@xy__quanfa_mie"] = "灭式",
}

local DOU = "@xy__dou"
local COST = { xy__quanfa_kong = 2, xy__quanfa_luan = 2, xy__quanfa_mie = 3, xy__quanfa_zhong = 5 }
local ORDER = { "xy__quanfa_kong", "xy__quanfa_luan", "xy__quanfa_mie", "xy__quanfa_zhong" }
local KONG_USED = "xy__quanfa_kong-phase"
local ZHONG = "@@xy__quanfa_zhong-turn"
local MIE = "xy__quanfa_mie_spells"   -- 施法中的灭式：{ {turns = 剩余回合, x = X}, ... }

local function kongTargets(player)
  return table.filter(Fk:currentRoom().alive_players, function(p)
    return p ~= player and not player:inMyAttackRange(p)
  end)
end

local function luanTargets(player)
  return table.filter(Fk:currentRoom().alive_players, function(p)
    return p ~= player and player:inMyAttackRange(p)
  end)
end

local function availableForms(player)
  local dou = player:getMark(DOU)
  return table.filter(ORDER, function(form)
    if dou < COST[form] then return false end
    if form == "xy__quanfa_kong" then
      return player:getMark(KONG_USED) == 0 and #kongTargets(player) > 0
    elseif form == "xy__quanfa_luan" then
      return #luanTargets(player) > 0
    end
    return true
  end)
end

local function updateMieMark(room, player)
  local spells = player:getTableMark(MIE)
  if #spells == 0 then
    room:setPlayerMark(player, "@xy__quanfa_mie", 0)
  else
    local parts = {}
    for _, s in ipairs(spells) do
      table.insert(parts, "X" .. s.x .. "/" .. s.turns)
    end
    room:setPlayerMark(player, "@xy__quanfa_mie", table.concat(parts, " "))
  end
end

-- 乱式：【兵临城下】
local function bingLinChengXia(player, to)
  local room = player.room
  local ids = room:getNCards(4)
  room:moveCardTo(ids, Card.Processing, nil, fk.ReasonJustMove, quanfa.name, nil, true, player)
  for _, id in ipairs(ids) do
    if player.dead or to.dead then break end
    local card = Fk:getCardById(id)
    if card.trueName == "slash" and room:getCardArea(id) == Card.Processing and
      player:canUseTo(card, to, { bypass_distances = true, bypass_times = true }) then
      room:useCard{
        from = player,
        tos = { to },
        card = card,
        extraUse = true,   -- 不计入次数
      }
    end
  end
  -- 其余的牌放回牌堆顶
  local rest = table.filter(ids, function(id) return room:getCardArea(id) == Card.Processing end)
  if #rest > 0 then
    room:moveCardTo(table.reverse(rest), Card.DrawPile, nil, fk.ReasonPut, quanfa.name, nil, true)
  end
end

quanfa:addEffect("active", {
  anim_type = "offensive",
  prompt = "#xy__quanfa",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return #availableForms(player) > 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local forms = availableForms(player)
    if #forms == 0 then return end
    local form = room:askToChoice(player, {
      choices = forms,
      skill_name = quanfa.name,
      prompt = "#xy__quanfa-choice",
    })
    room:removePlayerMark(player, DOU, COST[form])

    if form == "xy__quanfa_kong" then
      room:setPlayerMark(player, KONG_USED, 1)
      local to = room:askToChoosePlayers(player, {
        targets = kongTargets(player),
        min_num = 1,
        max_num = 1,
        prompt = "#xy__quanfa-kong",
        skill_name = quanfa.name,
        cancelable = false,
      })[1]
      if to then
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = quanfa.name,
        }
      end

    elseif form == "xy__quanfa_luan" then
      local to = room:askToChoosePlayers(player, {
        targets = luanTargets(player),
        min_num = 1,
        max_num = 1,
        prompt = "#xy__quanfa-luan",
        skill_name = quanfa.name,
        cancelable = false,
      })[1]
      if to then bingLinChengXia(player, to) end

    elseif form == "xy__quanfa_mie" then
      local x = tonumber(room:askToChoice(player, {
        choices = { "1", "2", "3" },
        skill_name = quanfa.name,
        prompt = "#xy__quanfa-mie_x",
      }))
      local spells = player:getTableMark(MIE)
      table.insert(spells, { turns = x, x = x })
      room:setPlayerMark(player, MIE, spells)
      updateMieMark(room, player)

    else
      room:setPlayerMark(player, ZHONG, 1)
    end
  end,
})

-- 灭式：施法计时，每个回合结束时减一，到0时执行
quanfa:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return #player:getTableMark(MIE) > 0 and not player.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local spells = player:getTableMark(MIE)
    local ready, waiting = {}, {}
    for _, s in ipairs(spells) do
      s.turns = s.turns - 1
      if s.turns <= 0 then
        table.insert(ready, s)
      else
        table.insert(waiting, s)
      end
    end
    room:setPlayerMark(player, MIE, #waiting > 0 and waiting or 0)
    updateMieMark(room, player)

    for _, s in ipairs(ready) do
      if player.dead then break end
      room:sendLog{ type = "#xy__quanfa-mie_log", from = player.id, toast = true }
      local card = Fk:cloneCard("slash")
      card.skillName = quanfa.name
      local targets = table.filter(room.alive_players, function(p)
        return p ~= player and player:canUseTo(card, p, { bypass_distances = true, bypass_times = true })
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#xy__quanfa-mie_target:::" .. s.x,
          skill_name = quanfa.name,
          cancelable = false,
        })[1]
        if to then
          room:useCard{
            from = player,
            tos = { to },
            card = card,
            extraUse = true,
            additionalDamage = s.x - 1,   -- 伤害为X
          }
        end
      end
    end
  end,
})

-- 终式：本回合所有其他角色视为处于你的攻击范围内
quanfa:addEffect("atkrange", {
  within_func = function(self, from, to)
    return from:getMark(ZHONG) ~= 0 and from ~= to
  end,
})

return quanfa

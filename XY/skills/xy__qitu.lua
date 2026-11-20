-- 歧途（朝比奈真冬）
-- 出牌阶段限一次，你可以展示三张手牌。若你本回合没有展示过这些牌，此技能视为没有发动过，
-- 然后你本回合使用这些牌时摸一张牌。否则，你本回合使用牌时失去一点体力并对一名角色造成一点伤害。

local qitu = fk.CreateSkill {
  name = "xy__qitu",
}

Fk:loadTranslationTable{
  ["xy__qitu"] = "歧途",
  [":xy__qitu"] = "出牌阶段限一次，你可以展示三张手牌。若你本回合没有展示过这些牌，此技能视为没有发动过，" ..
    "然后你本回合使用这些牌时摸一张牌。否则，你本回合使用牌时失去一点体力并对一名角色造成一点伤害。",

  ["#xy__qitu"] = "歧途：展示三张手牌",
  ["@@xy__qitu_punish-turn"] = "歧途 惩罚",
  ["@xy__qitu_draw-turn"] = "歧途摸牌",
  ["@@xy__qitu_shown-turn"] = "已展示",
  ["#xy__qitu-fresh"] = "%from 的“歧途”：这些牌本回合未展示过，此技能视为未发动，本回合使用这些牌时摸一张牌",
  ["#xy__qitu-punish"] = "%from 的“歧途”：这些牌本回合已展示过，本回合使用牌时失去1点体力并造成1点伤害",
  ["#xy__qitu-damage"] = "歧途：对一名角色造成1点伤害",
}

-- 本回合展示过的牌、本回合使用时摸牌的牌
local SHOWN = "xy__qitu_shown-turn"
local DRAW = "xy__qitu_draw-turn"
local PUNISH = "@@xy__qitu_punish-turn"
local SHOWN_LABEL = "@@xy__qitu_shown-turn"   -- 牌上的"已展示"标记

local function cardIds(card)
  if card:isVirtual() then
    return table.simpleClone(card.subcards)
  end
  return { card.id }
end

qitu:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#xy__qitu",
  card_num = 3,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(qitu.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 3 and table.contains(player:getCardIds("h"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local cards = effect.cards
    -- 在展示之前判断：这些牌本回合是否展示过
    local shownBefore = player:getTableMark(SHOWN)
    local fresh = not table.find(cards, function(id)
      return table.contains(shownBefore, id)
    end)
    -- 先记录效果，再展示
    if fresh then
      for _, id in ipairs(cards) do
        room:addTableMark(player, DRAW, id)
      end
      room:setPlayerMark(player, "@xy__qitu_draw-turn", #player:getTableMark(DRAW))
    else
      room:setPlayerMark(player, PUNISH, 1)
    end
    for _, id in ipairs(cards) do
      if not table.contains(player:getTableMark(SHOWN), id) then
        room:addTableMark(player, SHOWN, id)
      end
      room:setCardMark(Fk:getCardById(id), SHOWN_LABEL, 1)
    end
    room:showCards(cards, player)
    room:sendLog{
      type = fresh and "#xy__qitu-fresh" or "#xy__qitu-punish",
      from = player.id,
    }
    if fresh then
      -- 此技能视为没有发动过
      player:setSkillUseHistory(qitu.name, 0, Player.HistoryPhase)
      player:setSkillUseHistory(qitu.name, 0, Player.HistoryTurn)
    end
  end,
})

-- 记录本回合你展示过的牌（任何方式的展示都算）
qitu:addEffect(fk.CardShown, {
  can_refresh = function(self, event, target, player, data)
    local who = target or data.from
    if type(who) == "number" then who = player.room:getPlayerById(who) end
    return who == player and player:hasSkill(qitu.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(data.cardIds or {}) do
      if not table.contains(player:getTableMark(SHOWN), id) then
        room:addTableMark(player, SHOWN, id)
      end
      -- 在牌上标记"已展示"（本回合结束后清除）
      room:setCardMark(Fk:getCardById(id), SHOWN_LABEL, 1)
    end
  end,
})

-- 本回合使用牌时：摸牌 / 惩罚
-- 注意：is_delay_effect 让这个效果不计入"歧途"的发动次数，
-- 否则每次摸牌都会被当作发动了一次，导致出牌阶段无法再展示。
qitu:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player then return false end
    if player:getMark(PUNISH) ~= 0 then return true end
    local draw = player:getTableMark(DRAW)
    return table.find(cardIds(data.card), function(id)
      return table.contains(draw, id)
    end) ~= nil
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local draw = player:getTableMark(DRAW)
    if table.find(cardIds(data.card), function(id) return table.contains(draw, id) end) then
      player:drawCards(1, qitu.name)
    end
    if player:getMark(PUNISH) ~= 0 and not player.dead then
      room:loseHp(player, 1, qitu.name)
      if not player.dead then
        local to = room:askToChoosePlayers(player, {
          targets = room.alive_players,
          min_num = 1,
          max_num = 1,
          prompt = "#xy__qitu-damage",
          skill_name = qitu.name,
          cancelable = false,
        })[1]
        if to then
          room:damage{
            from = player,
            to = to,
            damage = 1,
            skillName = qitu.name,
          }
        end
      end
    end
  end,
})

return qitu

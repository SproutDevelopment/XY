-- 竊璽（曹節·魔帝）
-- 其他角色的出牌阶段开始时，其须令你可以交给其一张牌，若你交给其装备牌之外的牌，
-- 其失去一点体力然后你弃置其一半手牌（向上调整）。否则，你标记该牌为「魔气」并令其使用之。

local qiexi = fk.CreateSkill {
  name = "xy__qiexi",
}

Fk:loadTranslationTable{
  ["xy__qiexi"] = "窃玺",
  [":xy__qiexi"] = "其他角色的出牌阶段开始时，其须令你可以交给其一张牌，若你交给其装备牌之外的牌，" ..
    "其失去一点体力然后你弃置其一半手牌（向上调整）。否则，你标记该牌为「魔气」并令其使用之。",

  ["@@xy__moqi"] = "魔气",
  ["#xy__qiexi-give"] = "窃玺：你可以交给 %dest 一张牌",
}

qiexi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qiexi.name) and target ~= player and not target.dead and
      target.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = qiexi.name,
      prompt = "#xy__qiexi-give::" .. target.id,
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, { tos = { target }, cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = event:getCostData(self).cards[1]
    local card = Fk:getCardById(id)
    room:obtainCard(target, id, true, fk.ReasonGive, player, qiexi.name)
    if target.dead then return end

    if card.type ~= Card.TypeEquip then
      room:loseHp(target, 1, qiexi.name)
      if target.dead or player.dead or target:isKongcheng() then return end
      local n = math.ceil(target:getHandcardNum() / 2)
      local cards = room:askToChooseCards(player, {
        target = target,
        min = n,
        max = n,
        flag = "h",
        skill_name = qiexi.name,
      })
      if #cards > 0 then
        room:throwCard(cards, qiexi.name, target, player)
      end
    else
      room:setCardMark(card, "@@xy__moqi", 1)
      if table.contains(target:getCardIds("h"), id) and target:canUseTo(card, target) then
        room:useCard{
          from = target,
          tos = { target },
          card = card,
        }
      end
    end
  end,
})

return qiexi

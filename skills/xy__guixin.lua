-- 閨心（孫尚香）
-- 蜀势力技，出牌阶段限一次，你可以选择一名角色并弃置两张手牌，你与其各回复1点体力，然后其交给你其所有牌。

local guixin = fk.CreateSkill {
  name = "xy__guixin",
}

Fk:loadTranslationTable{
  ["xy__guixin"] = "闺心",
  [":xy__guixin"] = "蜀势力技，出牌阶段限一次，你可以选择一名角色并弃置两张手牌，你与其各回复1点体力，然后其交给你其所有牌。",
  ["#xy__guixin"] = "闺心：弃置两张手牌并选择一名角色（可以选择自己）",
}

guixin:addEffect("active", {
  anim_type = "support",
  prompt = "#xy__guixin",
  card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return player.kingdom == "shu" and player:usedSkillTimes(guixin.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2 and table.contains(player:getCardIds("h"), to_select) and
      not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local to = effect.tos[1]
    room:throwCard(effect.cards, guixin.name, player, player)
    for _, p in ipairs({ player, to }) do
      if not p.dead and p:isWounded() then
        room:recover{
          who = p,
          num = 1,
          recoverBy = player,
          skillName = guixin.name,
        }
      end
    end
    if to == player then
      -- 选择自己："交给你所有牌"，装备区的牌也收回手牌
      if not player.dead and #player:getCardIds("e") > 0 then
        room:obtainCard(player, player:getCardIds("e"), true, fk.ReasonJustMove, player, guixin.name)
      end
    elseif not to.dead and not player.dead and not to:isNude() then
      room:obtainCard(player, to:getCardIds("he"), false, fk.ReasonGive, to, guixin.name)
    end
  end,
})

return guixin

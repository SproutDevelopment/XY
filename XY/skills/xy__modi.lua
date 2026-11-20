-- 魔帝（曹節·魔帝）
-- 主公技，一名"魔"势力的角色的回合结束时，你展示其至多体力值张手牌，然后标记这些牌为「魔气」。

local modi = fk.CreateSkill {
  name = "xy__modi",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable{
  ["xy__modi"] = "魔帝",
  [":xy__modi"] = "主公技，一名“魔”势力的角色的回合结束时，你展示其至多体力值张手牌，然后标记这些牌为「魔气」。",
  ["#xy__modi-invoke"] = "魔帝：你可以展示 %dest 至多%arg张手牌，并标记为「魔气」",
}

modi:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(modi.name) and target.kingdom == "evil" and not target.dead and
      not target:isKongcheng() and target.hp > 0
  end,
  on_cost = function(self, event, target, player, data)
    local n = math.min(target.hp, target:getHandcardNum())
    return player.room:askToSkillInvoke(player, {
      skill_name = modi.name,
      prompt = "#xy__modi-invoke::" .. target.id .. ":" .. n,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.min(target.hp, target:getHandcardNum())
    local cards
    if target == player then
      cards = room:askToCards(player, {
        min_num = 1,
        max_num = n,
        include_equip = false,
        skill_name = modi.name,
        cancelable = false,
      })
    else
      cards = room:askToChooseCards(player, {
        target = target,
        min = 1,
        max = n,
        flag = "h",
        skill_name = modi.name,
      })
    end
    if #cards == 0 then return end
    room:showCards(cards, target)
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id), "@@xy__moqi", 1)
    end
  end,
})

return modi

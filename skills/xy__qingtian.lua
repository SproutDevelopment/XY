-- 晴天（瑪娜·唯心）
-- 你使用伤害牌时，你可以进行判定。若结果为黑色，此牌不能被响应；结果为红色，此牌造成的伤害+1。

local qingtian = fk.CreateSkill {
  name = "xy__qingtian",
}

Fk:loadTranslationTable{
  ["xy__qingtian"] = "晴天",
  [":xy__qingtian"] = "你使用伤害牌时，你可以进行判定。若结果为黑色，此牌不能被响应；结果为红色，此牌造成的伤害+1。",
}

qingtian:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingtian.name) and data.card.is_damage_card
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = qingtian.name,
      pattern = ".",
    }
    room:judge(judge)
    if not judge.card then return end
    if judge.card.color == Card.Black then
      data.disresponsiveList = table.simpleClone(room.players)
    elseif judge.card.color == Card.Red then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
})

return qingtian

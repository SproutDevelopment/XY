-- 棱鏡（瑪娜·唯心）
-- 你受到一点伤害时，你摸两张牌。

local lengjing = fk.CreateSkill {
  name = "xy__lengjing",
}

Fk:loadTranslationTable{
  ["xy__lengjing"] = "棱镜",
  [":xy__lengjing"] = "你受到一点伤害时，你摸两张牌。",
}

lengjing:addEffect(fk.DamageInflicted, {
  anim_type = "masochism",
  -- 优先级低于“义身”等改变伤害值的技能，按最终伤害值摸牌（例如伤害翻倍后为2点，摸4张）
  priority = 0.1,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lengjing.name) and not player.dead and data.damage > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(2 * data.damage, lengjing.name)
  end,
})

return lengjing

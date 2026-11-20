-- 義身（瑪娜）
-- 锁定技，你回合外受到的伤害翻倍。

local yishen = fk.CreateSkill {
  name = "xy__yishen",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xy__yishen"] = "义身",
  [":xy__yishen"] = "锁定技，你回合外受到的伤害翻倍。",
}

yishen:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yishen.name) and player.room.current ~= player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data:changeDamage(data.damage)
  end,
})

return yishen

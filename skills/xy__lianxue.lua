-- 戀雪（猗窩座）
-- 锁定技，你对女性角色造成的伤害减半。（向上整除）

local lianxue = fk.CreateSkill {
  name = "xy__lianxue",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xy__lianxue"] = "恋雪",
  [":xy__lianxue"] = "锁定技，你对女性角色造成的伤害减半。（向上整除）",
}

lianxue:addEffect(fk.DamageCaused, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lianxue.name) and data.to and data.to:isFemale() and
      data.damage > 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local half = math.ceil(data.damage / 2)
    data:changeDamage(half - data.damage)
  end,
})

return lianxue

-- 終凡（瑪娜）
-- 锁定技，你无法响应其他角色使用的牌。

local zhongfan = fk.CreateSkill {
  name = "xy__zhongfan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xy__zhongfan"] = "终凡",
  [":xy__zhongfan"] = "锁定技，你无法响应其他角色使用的牌。",
}

zhongfan:addEffect(fk.CardUsing, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(zhongfan.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.insertIfNeed(data.disresponsiveList, player)
    data.unoffsetableList = data.unoffsetableList or {}
    table.insertIfNeed(data.unoffsetableList, player)
  end,
})

return zhongfan

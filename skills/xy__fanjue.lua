-- 凡覺（沮授·幻）
-- 你进入濒死状态或一轮结束时，你退幻：将体力值和手牌上限调整到游戏开始时，
-- 然后你本局游戏发动"取逸"或"万安"时，目标角色可以选择是否让你发动该技能，
-- 且一轮结束时，若你一轮没有发动过武将上的技能，你失去一点体力。
--
-- 退幻：变回"沮授"。（卡面写"体力值和手牌上限"，此处按"体力上限与体力值"恢复，与征寰一致。）

local fanjue = fk.CreateSkill {
  name = "xy__fanjue",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xy__fanjue"] = "凡觉",
  [":xy__fanjue"] = "你进入濒死状态或一轮结束时，你退幻：将体力值和手牌上限调整到游戏开始时，" ..
    "然后你本局游戏发动“取逸”或“万安”时，目标角色可以选择是否让你发动该技能，" ..
    "且一轮结束时，若你一轮没有发动过武将上的技能，你失去一点体力。",
  ["$xy__fanjue1"] = "落定天元，征战星空，取无边之疆！",
}

local function leave(player)
  XY_Jushou.leave(player)
end

fanjue:addEffect(fk.EnterDying, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fanjue.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    leave(player)
  end,
})

fanjue:addEffect(fk.RoundEnd, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fanjue.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    leave(player)
  end,
})

return fanjue

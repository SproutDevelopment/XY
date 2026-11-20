-- 特權（锁定技）
-- 1) 你/其他角色"公审"受伤时判定的X数值为2/1
-- 2) 当你杀死一名角色时，"公审"对该次死亡不生效（不会失去"公审"）
-- 两项效果都由 gongshen.lua 检查本技能来实现，本文件只负责定义技能本体。

local tequan = fk.CreateSkill {
  name = "xy__tequan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xy__tequan"] = "特权",
  [":xy__tequan"] = "锁定技，你/其他角色“公审”受伤时判定的X数值为2/1；当你杀死一名角色时，“公审”失效。",
}

-- 占位效果：从不触发，仅保证技能对象能被正常创建
tequan:addEffect(fk.GameStart, {
  can_trigger = Util.FalseFunc,
})

return tequan

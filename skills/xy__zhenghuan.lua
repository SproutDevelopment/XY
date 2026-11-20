-- 征寰（沮授）
-- 觉醒技，第三轮开始时或你体力上限为0时，你入幻：将体力上限与体力值恢复至游戏开始时的状态。
--
-- 入幻：变身为"沮授（幻）"（宇志、宙鸣、凡觉）。
-- 本文件也负责：记录游戏开始时的体力，以及"退幻"后每轮结束时的失去体力。

local zhenghuan = fk.CreateSkill {
  name = "xy__zhenghuan",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["xy__zhenghuan"] = "征寰",
  [":xy__zhenghuan"] = "觉醒技，第三轮开始时或你体力上限为0时，你入幻：将体力上限与体力值恢复至游戏开始时的状态。",
  ["#xy__jushou-ruhuan"] = "%from 入幻",
  ["#xy__jushou-tuihuan"] = "%from 退幻",
  ["#xy__jushou-penalty"] = "%from 本轮没有发动过武将牌上的技能，失去1点体力",
}

XY_Jushou = XY_Jushou or {}
local START = "xy__jushou_start"        -- {maxHp, hp}
local REVERTED = "xy__jushou_reverted"

local function startValues(player)
  local s = player:getTableMark(START)
  if #s == 2 then return s[1], s[2] end
  local g = Fk.generals["xy__jushou"]
  return g and g.maxHp or player.maxHp, g and g.hp or player.hp
end

--- 将体力上限与体力值恢复至游戏开始时的状态
function XY_Jushou.restore(player)
  local room = player.room
  local maxHp, hp = startValues(player)
  room:setPlayerProperty(player, "maxHp", maxHp)
  room:setPlayerProperty(player, "hp", math.min(hp, maxHp))
  -- 手牌上限也恢复至游戏开始时（清除"宙鸣"的手牌上限-1）
  room:setPlayerMark(player, "@xy__zhouming_minus", 0)
end

--- 入幻
function XY_Jushou.enter(player)
  local room = player.room
  room:sendLog{ type = "#xy__jushou-ruhuan", from = player.id, toast = true }
  room:changeHero(player, "xy__jushou_huan", false, false, true, false, false)
  XY_Jushou.restore(player)
end

--- 退幻
function XY_Jushou.leave(player)
  local room = player.room
  room:sendLog{ type = "#xy__jushou-tuihuan", from = player.id, toast = true }
  room:changeHero(player, "xy__jushou", false, false, true, false, false)
  XY_Jushou.restore(player)
  room:setPlayerMark(player, REVERTED, 1)
end

-- 记录游戏开始时的体力上限与体力值
zhenghuan:addEffect(fk.GameStart, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(zhenghuan.name, true) and #player:getTableMark(START) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, START, { player.maxHp, player.hp })
  end,
})

local function canWake(player)
  return player:hasSkill(zhenghuan.name) and
    player:usedSkillTimes(zhenghuan.name, Player.HistoryGame) == 0
end

-- 第三轮开始时
zhenghuan:addEffect(fk.RoundStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return canWake(player) and (player.room:getBanner("RoundCount") or 0) >= 3
  end,
  can_wake = Util.TrueFunc,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    XY_Jushou.enter(player)
  end,
})

-- 体力上限将变为0时
zhenghuan:addEffect(fk.BeforeMaxHpChanged, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and canWake(player) and player.maxHp + data.num <= 0
  end,
  can_wake = Util.TrueFunc,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.prevented = true
    XY_Jushou.enter(player)
  end,
})

-- "退幻"后：一轮结束时，若你本轮没有发动过武将牌上的技能，你失去一点体力
zhenghuan:addEffect(fk.RoundEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead or player:getMark(REVERTED) == 0 then return false end
    for _, s in ipairs({ "xy__quyi", "xy__wanan", "xy__zhenghuan" }) do
      if player:usedSkillTimes(s, Player.HistoryRound) > 0 then return false end
    end
    return true
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:sendLog{ type = "#xy__jushou-penalty", from = player.id }
    player.room:loseHp(player, 1, zhenghuan.name)
  end,
})

return zhenghuan

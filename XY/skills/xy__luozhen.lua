-- 羅針（猗窩座）
-- 锁定技，当一名其他角色使用攻击类牌或受到伤害时，你获得一个"斗"。
--
-- "斗"记录为标记 @xy__dou。"拳法·终式"生效时，获得"斗"会视为对所有其他角色使用【杀】。

local luozhen = fk.CreateSkill {
  name = "xy__luozhen",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xy__luozhen"] = "罗针",
  [":xy__luozhen"] = "锁定技，当一名其他角色使用攻击类牌或受到伤害时，你获得一个“斗”。",
  ["@xy__dou"] = "斗",
}

XY_Akaza = XY_Akaza or {}

local ZHONG = "@@xy__quanfa_zhong-turn"        -- 终式生效中
local RESOLVING = "xy__quanfa_zhong_resolving" -- 终式的【杀】结算中

--- 获得"斗"；终式生效时，每获得一个"斗"视为对所有其他角色使用一张不计入次数的【杀】
function XY_Akaza.gainDou(player, n, skillName)
  local room = player.room
  if player.dead or n <= 0 then return end
  -- 终式的【杀】结算中不能获得"斗"
  if player:getMark(RESOLVING) ~= 0 then return end
  room:addPlayerMark(player, "@xy__dou", n)
  if player:getMark(ZHONG) == 0 then return end
  for _ = 1, n do
    if player.dead then break end
    local targets = table.filter(room:getOtherPlayers(player), function(p)
      return not p.dead
    end)
    if #targets == 0 then break end
    room:setPlayerMark(player, RESOLVING, 1)
    room:useVirtualCard("slash", nil, player, targets, "xy__quanfa", true)
    room:setPlayerMark(player, RESOLVING, 0)
  end
end

-- 其他角色使用攻击类牌（伤害类牌）
luozhen:addEffect(fk.CardUsing, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(luozhen.name) and data.card.is_damage_card and
      player:getMark(RESOLVING) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    XY_Akaza.gainDou(player, 1, luozhen.name)
  end,
})

-- 其他角色受到伤害时
luozhen:addEffect(fk.DamageInflicted, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(luozhen.name) and player:getMark(RESOLVING) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    XY_Akaza.gainDou(player, 1, luozhen.name)
  end,
})

return luozhen

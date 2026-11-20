-- 宙鳴（沮授·幻）
-- 回合结束时，若你的手牌上限不为0，你可以获得一个额外回合，然后你的手牌上限-1直到你杀死一名角色。

local zhouming = fk.CreateSkill {
  name = "xy__zhouming",
}

Fk:loadTranslationTable{
  ["xy__zhouming"] = "宙鸣",
  [":xy__zhouming"] = "回合结束时，若你的手牌上限不为0，你可以获得一个额外回合，然后你的手牌上限-1直到你杀死一名角色。",
  ["#xy__zhouming-invoke"] = "宙鸣：你可以获得一个额外回合，然后手牌上限-1（直到你杀死一名角色）",
  ["@xy__zhouming_minus"] = "手牌上限-",
}

local MINUS = "@xy__zhouming_minus"

zhouming:addEffect(fk.TurnEnd, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhouming.name) and player:getMaxCards() > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhouming.name,
      prompt = "#xy__zhouming-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraTurn(true, zhouming.name)
    player.room:addPlayerMark(player, MINUS, 1)
  end,
})

-- 杀死一名角色：手牌上限恢复
zhouming:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player, data)
    return data.killer == player and player:getMark(MINUS) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, MINUS, 0)
  end,
})

zhouming:addEffect("maxcards", {
  correct_func = function(self, player)
    return -player:getMark(MINUS)
  end,
})

return zhouming

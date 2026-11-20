-- 梟驕（孫尚香）
-- 吴势力技，当你失去一张装备区里的牌时，你可以摸两张牌，然后你选择是否失去一点体力
-- 让所有角色需要发动弃置牌数量为X的"制衡"。（X为其体力值，不足则改为其弃置所有牌）

local xiaojiao = fk.CreateSkill {
  name = "xy__xiaojiao",
}

Fk:loadTranslationTable{
  ["xy__xiaojiao"] = "枭骄",
  [":xy__xiaojiao"] = "吴势力技，当你失去一张装备区里的牌时，你可以摸两张牌，然后你选择是否失去一点体力" ..
    "让所有角色需要发动弃置牌数量为X的“制衡”。（X为其体力值，不足则改为其弃置所有牌）",

  ["#xy__xiaojiao-zhiheng"] = "枭骄：是否失去1点体力，令所有角色发动弃置牌数等于其体力值的“制衡”？",
  ["#xy__xiaojiao-discard"] = "枭骄：“制衡”，请弃置%arg张牌，然后摸等量的牌",
}

-- 本次移动中，你失去的装备区里的牌数
local function lostEquips(player, data)
  local n = 0
  for _, move in ipairs(data) do
    if move.from == player or move.from == player.id then
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.PlayerEquip then
          n = n + 1
        end
      end
    end
  end
  return n
end

xiaojiao:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xiaojiao.name) and player.kingdom == "wu" and lostEquips(player, data) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = xiaojiao.name })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, xiaojiao.name)
    if player.dead then return end
    if not room:askToSkillInvoke(player, {
      skill_name = xiaojiao.name,
      prompt = "#xy__xiaojiao-zhiheng",
    }) then return end

    room:loseHp(player, 1, xiaojiao.name)
    -- 所有角色依次"制衡"
    for _, p in ipairs(room:getAlivePlayers()) do
      if not p.dead then
        local x = math.max(p.hp, 0)
        local all = p:getCardIds("he")
        if #all > 0 and #all < x then
          -- 牌不足：弃置所有牌，不"制衡"（不摸牌）
          room:throwCard(all, xiaojiao.name, p, p)
        elseif x > 0 and #all >= x then
          local cards = room:askToDiscard(p, {
            min_num = x,
            max_num = x,
            include_equip = true,
            skill_name = xiaojiao.name,
            cancelable = false,
            prompt = "#xy__xiaojiao-discard:::" .. x,
          })
          if #cards > 0 and not p.dead then
            p:drawCards(#cards, xiaojiao.name)
          end
        end
      end
    end
  end,
})

return xiaojiao

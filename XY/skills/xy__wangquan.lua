-- 王權（瑪娜·唯心）
-- 出牌阶段，你可以将【桃】或装备牌置于你武将牌上并称之为"王权"。
-- 一名角色使用或打出牌时，你可以弃置一张"王权"令该牌失效。

local wangquan = fk.CreateSkill {
  name = "xy__wangquan",
}

Fk:loadTranslationTable{
  ["xy__wangquan"] = "王权",
  [":xy__wangquan"] = "出牌阶段，你可以将【桃】或装备牌置于你武将牌上并称之为“王权”。" ..
    "一名角色使用或打出牌时，你可以弃置一张“王权”令该牌失效。",
  ["xy__wangquan_pile"] = "王权",
  ["#xy__wangquan"] = "王权：将一张【桃】或装备牌置于武将牌上",
  ["#xy__wangquan-log"] = "%from 发动“王权”，令 %to 的%arg失效",
  ["#xy__wangquan-nullify"] = "王权：你可以弃置一张“王权”，令 %dest 使用/打出的%arg失效",
}

local PILE = "xy__wangquan_pile"

-- 出牌阶段：将【桃】或装备牌置为"王权"
wangquan:addEffect("active", {
  anim_type = "special",
  prompt = "#xy__wangquan",
  card_num = 1,
  target_num = 0,
  can_use = Util.TrueFunc,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    local c = Fk:getCardById(to_select)
    return c.trueName == "peach" or c.type == Card.TypeEquip
  end,
  on_use = function(self, room, effect)
    effect.from:addToPile(PILE, effect.cards, true, wangquan.name)
  end,
})

local function askNullify(player, target, data)
  local room = player.room
  local cards = room:askToCards(player, {
    min_num = 1,
    max_num = 1,
    include_equip = false,
    skill_name = wangquan.name,
    pattern = ".|.|.|" .. PILE,
    expand_pile = PILE,
    prompt = "#xy__wangquan-nullify::" .. target.id .. ":" .. data.card:toLogString(),
    cancelable = true,
  })
  return cards
end

-- 一名角色使用牌时
wangquan:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(wangquan.name) and #player:getPile(PILE) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local cards = askNullify(player, target, data)
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(event:getCostData(self).cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile,
      wangquan.name, PILE, true, player)
    -- 令该牌失效：取消其所有目标（包括被响应的牌），此牌不再生效
    data.toCard = nil
    data.tos = {}
    data.subTos = {}
    data.nullifiedTargets = table.simpleClone(room.players)
    room:sendLog{ type = "#xy__wangquan-log", from = player.id, to = { target.id }, arg = data.card:toLogString() }
  end,
})

-- 一名角色打出牌时：
-- 本体无法直接令“打出”的牌失效，因此按“视为未打出”的结果处理：
-- 若是响应伤害锦囊（【南蛮入侵】【万箭齐发】【决斗】等）而打出，则打出者受到该锦囊的伤害，且该锦囊对其的结算结束。
local function respondedTrick(data)
  local e = data.responseToEvent
  if e and e.card and e.card.type == Card.TypeTrick and e.card.is_damage_card then
    return e
  end
end

wangquan:addEffect(fk.CardResponding, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(wangquan.name) and #player:getPile(PILE) > 0 and respondedTrick(data) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local cards = askNullify(player, target, data)
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(event:getCostData(self).cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile,
      wangquan.name, PILE, true, player)
    room:sendLog{ type = "#xy__wangquan-log", from = player.id, to = { target.id }, arg = data.card:toLogString() }
    local effect = respondedTrick(data)
    local victim = data.from or target
    local source = effect.from
    if effect.card.trueName == "duel" and victim == effect.from then
      source = effect.to
    end
    if victim and not victim.dead then
      room:damage{
        from = source,
        to = victim,
        card = effect.card,
        damage = 1 + (effect.additionalDamage or 0),
        damageType = fk.NormalDamage,
        skillName = effect.card.skill and effect.card.skill.name or wangquan.name,
      }
    end
    -- 结束该锦囊对其的结算（例如【决斗】不再继续）
    local ce = room.logic:getCurrentEvent():findParent(GameEvent.CardEffect, true)
    if ce then ce:shutdown() end
  end,
})

return wangquan

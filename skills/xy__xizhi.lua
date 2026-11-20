-- 希志
-- 当一张造成过伤害或你弃置的牌于回合外进入弃牌堆时，你可以获得之。
-- 若你本轮没有以此法使用过此牌名的牌，则你可以立即使用之。（无距离限制）

local xizhi = fk.CreateSkill {
  name = "xy__xizhi",
}

Fk:loadTranslationTable{
  ["xy__xizhi"] = "希志",
  [":xy__xizhi"] = "当一张造成过伤害或你弃置的牌于回合外进入弃牌堆时，你可以获得之。" ..
    "若你本轮没有以此法使用过此牌名的牌，则你可以立即使用之。（无距离限制）",

  ["#xy__xizhi-get"] = "希志：是否获得 %arg？",
  ["#xy__xizhi-use"] = "希志：你可以立即使用 %arg（无距离限制）",
}

-- 造成过伤害、且之后还没进入过弃牌堆的牌（实体牌id）
local DAMAGED_TAG = "xy__xizhi_damaged"
-- 本轮以此法使用过的牌名
local USED = "xy__xizhi_used-round"

local function cardIds(card)
  if card:isVirtual() then
    return table.simpleClone(card.subcards)
  end
  return { card.id }
end

-- 记录造成过伤害的牌
xizhi:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return data.card ~= nil and player:hasSkill(xizhi.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local list = room:getTag(DAMAGED_TAG) or {}
    for _, id in ipairs(cardIds(data.card)) do
      table.insertIfNeed(list, id)
    end
    room:setTag(DAMAGED_TAG, list)
  end,
})

-- 本次正在进入弃牌堆的、造成过伤害的牌
local ENTERING_TAG = "xy__xizhi_entering"

-- 移动牌前：造成过伤害的牌一旦进入弃牌堆，其"造成过伤害"记录即被消耗（重置），
-- 本次移动仍可触发"希志"
xizhi:addEffect(fk.BeforeCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(xizhi.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    -- 多名角色拥有"希志"时，同一次移动只处理一次
    if room:getTag("xy__xizhi_last_move") == data then return end
    room:setTag("xy__xizhi_last_move", data)
    local damaged = room:getTag(DAMAGED_TAG) or {}
    local entering = {}
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(damaged, info.cardId) then
            table.removeOne(damaged, info.cardId)
            table.insert(entering, info.cardId)
          end
        end
      end
    end
    room:setTag(DAMAGED_TAG, damaged)
    room:setTag(ENTERING_TAG, entering)
  end,
})

local function isProposer(move, player)
  return move.proposer == player or move.proposer == player.id
end

-- 找出本次进入弃牌堆、符合条件的牌
local function findCards(player, data)
  local room = player.room
  local damaged = room:getTag(ENTERING_TAG) or {}
  local ids = {}
  for _, move in ipairs(data) do
    if move.toArea == Card.DiscardPile then
      -- 你弃置的牌（技能、弃牌阶段、【过河拆桥】等都属于"弃置"）
      local isDiscard = move.moveReason == fk.ReasonDiscard
      local byYou = isProposer(move, player) or
        (move.proposer == nil and (move.from == player or move.from == player.id))
      local discardedByYou = isDiscard and byYou
      for _, info in ipairs(move.moveInfo) do
        local id = info.cardId
        if (discardedByYou or table.contains(damaged, id)) and
          room:getCardArea(id) == Card.DiscardPile then
          table.insertIfNeed(ids, id)
        end
      end
    end
  end
  return ids
end

xizhi:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(xizhi.name) then return false end
    -- 于你的回合外
    if player.room.current == player then return false end
    return #findCards(player, data) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(findCards(player, data)) do
      if player.dead then break end
      if room:getCardArea(id) == Card.DiscardPile then
        local card = Fk:getCardById(id)
        if room:askToSkillInvoke(player, {
          skill_name = xizhi.name,
          prompt = "#xy__xizhi-get:::" .. card:toLogString(),
        }) then
          room:obtainCard(player, id, true, fk.ReasonJustMove, player, xizhi.name)
          -- 本轮没有以此法使用过此牌名的牌：可以立即使用（无距离限制）
          if not player.dead and table.contains(player:getCardIds("h"), id) and
            not table.contains(player:getTableMark(USED), card.trueName) then
            local use = room:askToUseRealCard(player, {
              pattern = ".|.|.|.|.|.|" .. id, -- 按牌的id精确匹配
              skill_name = xizhi.name,
              prompt = "#xy__xizhi-use:::" .. card:toLogString(),
              extra_data = {
                bypass_distances = true,
              },
              cancelable = true,
            })
            -- 牌已离开手牌即视为已使用
            if use or not table.contains(player:getCardIds("h"), id) then
              -- 火杀、雷杀等都按"杀"计算
              room:addTableMark(player, USED, card.trueName)
            end
          end
        end
      end
    end
  end,
})

return xizhi

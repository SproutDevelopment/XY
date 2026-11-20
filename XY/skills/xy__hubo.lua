-- 互博（鄧芝）
-- 转换技，①当你需要使用或打出牌时，你可以将一张牌交给一名角色，改为观看其手牌并可使用或打出其中一张需要的牌；
-- ②当其他角色需要响应使用的牌时，若此牌结算过程中你未发动过此技能，你可以获得其一张牌，
-- 其改为观看你手牌并可使用或打出其中一张需要的牌。以此法使用的牌无法被响应。
--
-- 实现：
-- ①（阳）出牌阶段主动使用：作为主动技能；需要使用/打出牌时（如被要求出【闪】）：在询问时发动。
-- ②（阴）其他角色被要求使用牌响应某张牌时发动。
-- 每次发动后自动切换阴阳。

local hubo = fk.CreateSkill {
  name = "xy__hubo",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["xy__hubo"] = "互博",
  [":xy__hubo"] = "转换技，①当你需要使用或打出牌时，你可以将一张牌交给一名角色，改为观看其手牌并可使用或打出其中一张需要的牌；" ..
    "②当其他角色需要响应使用的牌时，若此牌结算过程中你未发动过此技能，你可以获得其一张牌，" ..
    "其改为观看你手牌并可使用或打出其中一张需要的牌。以此法使用的牌无法被响应。",
  [":xy__hubo_yang"] = "转换技，<font color=\"#E0DB2F\">①当你需要使用或打出牌时，你可以将一张牌交给一名角色，改为观看其手牌并可使用或打出其中一张需要的牌；</font>" ..
    "②当其他角色需要响应使用的牌时，若此牌结算过程中你未发动过此技能，你可以获得其一张牌，" ..
    "其改为观看你手牌并可使用或打出其中一张需要的牌。以此法使用的牌无法被响应。",
  [":xy__hubo_yin"] = "转换技，①当你需要使用或打出牌时，你可以将一张牌交给一名角色，改为观看其手牌并可使用或打出其中一张需要的牌；" ..
    "<font color=\"#E0DB2F\">②当其他角色需要响应使用的牌时，若此牌结算过程中你未发动过此技能，你可以获得其一张牌，" ..
    "其改为观看你手牌并可使用或打出其中一张需要的牌。</font>以此法使用的牌无法被响应。",

  ["#xy__hubo-active-to"] = "互博①：选择要交给牌的角色，然后观看其手牌并可使用其中一张",
  ["#xy__hubo-active"] = "互博①：将一张牌交给一名角色，然后观看其手牌并可使用其中一张",
  ["#xy__hubo-give"] = "互博①：你可以将一张牌交给一名角色，改为观看其手牌并使用或打出其中一张需要的牌",
  ["#xy__hubo-pick"] = "互博：选择一张需要的牌",
  ["#xy__hubo-use"] = "互博①：你可以使用 %dest 手牌中的一张牌（不可被响应）",
  ["#xy__hubo-yin"] = "互博②：你可以获得 %dest 一张牌，令其改为观看你的手牌并使用其中一张需要的牌",
  ["xy__hubo_hand"] = "手牌",
  ["#xy__hubo-none"] = "互博：其中没有你需要的牌",
  ["#xy__hubo-nullify"] = "互博①：选择一张牌交给一名角色，然后观看其手牌并可使用其中的【无懈可击】",
  ["#xy__hubo-nullify-to"] = "互博①：选择要交给牌的角色",
}

-- 生成"使用/打出"的结果（以此法使用的牌无法被响应）
local function makeResult(room, event, user, card, data)
  local result = { from = user, card = card }
  if event == fk.AskForCardUse then
    local tos = {}
    local extra = data.extraData or {}
    for _, pid in ipairs(extra.must_targets or {}) do
      local p = room:getPlayerById(pid)
      if p then table.insert(tos, p) end
    end
    result.tos = tos
    result.disresponsiveList = table.simpleClone(room.players)
  end
  return result
end

-- 从某角色的手牌中选择一张符合要求的牌
local function pickNeeded(room, chooser, owner, pattern, prompt)
  local hand = owner:getCardIds("h")
  if #hand == 0 then return nil end
  local exp = Exppattern:Parse(pattern)
  if not table.find(hand, function(id) return exp:match(Fk:getCardById(id)) end) then
    -- 没有需要的牌，仍可以观看
    room:viewCards(chooser, {
      cards = hand,
      skill_name = hubo.name,
      prompt = "#xy__hubo-none",
    })
    return nil
  end
  local ids = room:askToChooseCards(chooser, {
    target = owner,
    min = 1,
    max = 1,
    flag = { card_data = { { "xy__hubo_hand", hand } } },
    pattern = pattern,
    skill_name = hubo.name,
    prompt = prompt,
    cancelable = true,
  })
  local id = ids and ids[1]
  if id and exp:match(Fk:getCardById(id)) then
    return Fk:getCardById(id)
  end
  return nil
end

local function isYang(player)
  return player:getSwitchSkillState(hubo.name) == fk.SwitchYang
end


-- ========== ①（阳）需要使用/打出牌时 ==========
local function yangCanTrigger(self, event, target, player, data)
  return target == player and player:hasSkill(hubo.name) and isYang(player) and
    not player:isNude() and #player.room:getOtherPlayers(player) > 0
end

local function yangCost(self, event, target, player, data)
  local room = player.room
  local tos, cards = room:askToChooseCardsAndPlayers(player, {
    targets = room:getOtherPlayers(player),
    min_num = 1,
    max_num = 1,
    min_card_num = 1,
    max_card_num = 1,
    pattern = ".",
    skill_name = hubo.name,
    prompt = "#xy__hubo-give",
    cancelable = true,
  })
  if tos and #tos > 0 and cards and #cards > 0 then
    event:setCostData(self, { tos = tos, cards = cards })
    return true
  end
end

local function yangUse(self, event, target, player, data)
  local room = player.room
  local cost = event:getCostData(self)
  local to = cost.tos[1]
  room:obtainCard(to, cost.cards, false, fk.ReasonGive, player, hubo.name)
  if player.dead or to.dead then return end
  local card = pickNeeded(room, player, to, data.pattern, "#xy__hubo-pick")
  if card then
    data.result = makeResult(room, event, player, card, data)
    return true
  end
end

hubo:addEffect(fk.AskForCardUse, {
  anim_type = "control",
  can_trigger = yangCanTrigger,
  on_cost = yangCost,
  on_use = yangUse,
})

hubo:addEffect(fk.AskForCardResponse, {
  anim_type = "control",
  can_trigger = yangCanTrigger,
  on_cost = yangCost,
  on_use = yangUse,
})

-- ①（阳）互博按钮（一个按钮，两种用法）：
--  · 出牌阶段：将一张牌交给一名角色，然后观看其手牌并可使用其中一张（无法被响应）。
--  · 被询问【无懈可击】时（所有人同时被询问，不经过“需要使用牌”的时机）：
--    将一张牌交给一名角色，然后观看其手牌并使用其中的【无懈可击】（无法被响应）。
-- 出牌阶段时按钮先转化为占位的【无中生有】，在 before_use 中改为真正的流程并取消占位牌。

hubo:addEffect("viewas", {
  anim_type = "control",
  pattern = "nullification,ex_nihilo",
  prompt = function(self, player)
    if Fk.currentResponsePattern == nil then return "#xy__hubo-active" end
    return "#xy__hubo-nullify"
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local name = Fk.currentResponsePattern == nil and "ex_nihilo" or "nullification"
    local c = Fk:cloneCard(name)
    c.skillName = hubo.name
    c:addSubcard(cards[1])
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    local give = use.card.subcards[1]
    local others = room:getOtherPlayers(player)
    if not give or #others == 0 then return hubo.name end
    local isPlay = use.card.name ~= "nullification"
    local tos = room:askToChoosePlayers(player, {
      targets = others,
      min_num = 1,
      max_num = 1,
      skill_name = hubo.name,
      prompt = isPlay and "#xy__hubo-active-to" or "#xy__hubo-nullify-to",
      cancelable = false,
    })
    local to = tos[1]
    room:obtainCard(to, give, false, fk.ReasonGive, player, hubo.name)

    if isPlay then
      -- 出牌阶段：取消占位牌，改为使用其手牌中的一张（发动本技能时阴阳已自动切换）
      if player.dead or to.dead or to:isKongcheng() then return hubo.name end
      local hand = to:getCardIds("h")
      local realUse = room:askToUseRealCard(player, {
        pattern = hand,
        skill_name = hubo.name,
        prompt = "#xy__hubo-use::" .. to.id,
        extra_data = { expand_pile = hand },
        cancelable = true,
        skip = true,
      })
      if realUse then
        realUse.disresponsiveList = table.simpleClone(room.players)
        room:useCard(realUse)
      end
      return hubo.name
    end

    if player.dead or to.dead then return hubo.name end
    local card = pickNeeded(room, player, to, "nullification", "#xy__hubo-pick")
    if not card then return hubo.name end
    use.card = card
    use.disresponsiveList = table.simpleClone(room.players)
  end,
  enabled_at_play = function(self, player)
    return isYang(player) and not player:isNude()
  end,
  enabled_at_response = function(self, player, response)
    return not response and isYang(player) and not player:isNude()
      and Fk.currentResponsePattern ~= nil
      and Exppattern:Parse(Fk.currentResponsePattern):matchExp("nullification")
  end,
  enabled_at_nullification = function(self, player, data)
    return isYang(player) and not player:isNude() and #Fk:currentRoom().alive_players > 1
  end,
})

-- ========== ②（阴）其他角色需要响应使用的牌时 ==========
local USED = "xy__hubo_used_events"

local function currentUseEventId(room)
  local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
  return e and e.id
end

hubo:addEffect(fk.AskForCardUse, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player or target.dead or not player:hasSkill(hubo.name) or isYang(player) then
      return false
    end
    if not data.eventData then return false end   -- 只在响应某张牌时
    local eid = currentUseEventId(player.room)
    return eid ~= nil and not table.contains(player:getTableMark(USED), eid)
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = hubo.name,
      prompt = "#xy__hubo-yin::" .. target.id,
    }) then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local eid = currentUseEventId(room)
    if eid then room:addTableMark(player, USED, eid) end
    -- 获得其一张牌
    if not target:isNude() then
      local id = room:askToChooseCard(player, {
        target = target,
        flag = "he",
        skill_name = hubo.name,
      })
      room:obtainCard(player, id, false, fk.ReasonPrey, player, hubo.name)
    end
    if player.dead or target.dead then return end
    -- 其改为观看你的手牌并使用其中一张需要的牌
    local card = pickNeeded(room, target, player, data.pattern, "#xy__hubo-pick")
    if card then
      data.result = makeResult(room, event, target, card, data)
      return true
    end
  end,
})

return hubo

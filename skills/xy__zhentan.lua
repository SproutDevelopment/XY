-- 【偵探】被一張牌唯一指定時，僅從本局真正存在的實體牌名中聲明。
-- 使用牌的戰報在 PreCardUse 就已經發送；在 TargetConfirmed 才遮掩會太遲。
-- 因此在 PreCardUse *先於移入處理區* 標記當前實體牌為未知牌，
-- 並替換該次使用的戰報，結算完畢才解除標記。
-- 不修改卡牌本體，避免影響牌的類型、花色、結算與其他技能。
-- 本版另外在 BeforeCardsMove 將該次處理區移牌設為暗置；只改虛名本身
-- 不會令 QML 的 known=false，實際圖片效果仍依賴客戶端資料追蹤行為。
local U = dofile("./packages/XY/anna_utils.lua")
local Vis = dofile("./packages/XY/zhentan_visibility.lua")
local Intercept = dofile("./packages/XY/zhentan_intercept.lua")
local skill = fk.CreateSkill{ name = "xy__zhentan" }

-- Only real physical cards that actually occupy an in-game area count.
-- In particular Card.Void (未加入本局的衍生牌) and Card.Unknown are not choices.
local IN_GAME_AREAS = {
  [Card.DrawPile] = true,
  [Card.DiscardPile] = true,
  [Card.Processing] = true,
  [Card.PlayerHand] = true,
  [Card.PlayerEquip] = true,
  [Card.PlayerJudge] = true,
  [Card.PlayerSpecial] = true,
}

local function allNames(room)
  local choices, seen = {}, {}
  local function addId(id)
    if type(id) ~= "number" or id == 0 then return end
    local card = Fk:getCardById(id, true) -- original physical name, not a filter skill
    local name = card and card.name
    if type(name) == "string" and name ~= "" and not seen[name] then
      seen[name] = true
      choices[#choices + 1] = name
    end
  end
  local function addIds(ids)
    if type(ids) ~= "table" then return end
    for _, id in pairs(ids) do addId(id) end
  end
  -- Check the current ROOM area for each engine ID: getAllCardIds by itself
  -- includes enabled/derived cards that may not be present in this game.
  if type(room.getCardArea) == "function" then
    local function inGame(id)
      local ok, area = pcall(room.getCardArea, room, id)
      if ok and IN_GAME_AREAS[area] then addId(id) end
    end
    if type(Fk.getAllCardIds) == "function" then
      for _, id in ipairs(Fk:getAllCardIds() or {}) do inGame(id) end
    end
    -- A mode can print physical cards during play; these IDs may be negative.
    for id in pairs(Fk.printed_cards or {}) do inGame(id) end
  end

  -- Explicit zones also work on core builds without getCardArea, including
  -- draw/discard, cards currently being used, dead players, and private piles.
  addIds(room.draw_pile)
  addIds(room.discard_pile)
  addIds(room.processing_area)
  addIds(room.processing)
  local players = room.players or (room.getAllPlayers and room:getAllPlayers()) or {}
  for _, p in ipairs(players) do
    if type(p.getCardIds) == "function" then
      local ok, ids = pcall(p.getCardIds, p, "hej")
      if ok then addIds(ids) end
    end
    -- FreeKill stores h/e/j directly in player_cards and every named private
    -- pile in special_cards. These tables cover any player area, including
    -- "future" and other extension-defined hidden piles.
    if type(p.player_cards) == "table" then
      for _, ids in pairs(p.player_cards) do addIds(ids) end
    end
    if type(p.special_cards) == "table" then
      for _, ids in pairs(p.special_cards) do addIds(ids) end
    end
    -- Compatibility for older extensions using non-standard pile members.
    if type(p.piles) == "table" then
      for _, ids in pairs(p.piles) do addIds(ids) end
    end
    if type(p.special_piles) == "table" then
      for _, ids in pairs(p.special_piles) do addIds(ids) end
    end
    if type(p.getPileNames) == "function" and type(p.getPile) == "function" then
      local ok, names = pcall(p.getPileNames, p)
      if ok and type(names) == "table" then
        for _, pileName in pairs(names) do
          local okPile, ids = pcall(p.getPile, p, pileName)
          if okPile then addIds(ids) end
        end
      end
    end
  end
  -- Deliberately NO Fk.all_card_names/all_card_types fallback and NO forced
  -- insertion of the incoming virtual card: neither proves physical presence.
  table.sort(choices)
  return choices
end

local function cardIds(card)
  if not card or not Card or type(Card.getIdList) ~= "function" then return {} end
  -- Important: FreeKill getIdList is STATIC, not card:getIdList().
  return Card:getIdList(card) or {}
end

local function changeDisplayedVirtualName(room, ids, name)
  if type(room.sendCardVirtName) == "function"
    and type(ids) == "table" and #ids > 0 then
    room:sendCardVirtName(ids, name)
  end
end

-- Keep this mask for the entire use-card event instead of immediately
-- revealing the card after the defender has guessed its name. Native movement
-- visibility is the only card-back mechanism used (no client patch).
local function maskCardUse(room, data)
  if type(data.extra_data) ~= "table" then data.extra_data = {} end
  if data.extra_data.xy__zhentan_hidden_use then return end
  local ids = cardIds(data.card)
  data.extra_data.xy__zhentan_hidden_use = {
    ids = ids,
    original_name = data.card.name,
  }
  Vis.register(room, ids)
  changeDisplayedVirtualName(room, ids, "xy__hidden_card")
end

local function idOf(x)
  if type(x) == "table" then return x.id end
  return x
end

-- The engine plays card-specific sound and sends the card-use battle log
-- before moving the physical card. A scoped interceptor masks those channels
-- and is always cleaned at CardUseFinished, even when the log is missing.
local function onlyTarget(data, player)
  if not data or not player or not data.card then return false end
  if data.to ~= player and data.to ~= player.id then return false end
  local targets
  if type(data.getAllTargets) == "function" then
    targets = data:getAllTargets()
  elseif data.use and type(data.use.tos) == "table" then
    targets = data.use.tos
  end
  return type(targets) == "table" and #targets == 1
    and idOf(targets[1]) == player.id
end

-- This event occurs before the original use-card battle log.
skill:addEffect(fk.PreCardUse, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and U.isAngel(player)
      and U.getStack(player) > 0 and not player.dead
      and type(data) == "table" and data.card ~= nil
      and type(data.tos) == "table" and #data.tos == 1
      and idOf(data.tos[1]) == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    -- This event runs before card processing, logs and target confirmation.
    maskCardUse(player.room, data)
    Intercept.begin(player.room, data, player)
  end,
})

-- Solution B: use the engine's own face-down card move information.
-- The QML CardItem.known flag is a client representation of card visibility;
-- merely changing virtName NEVER turns the card face down. A BeforeCardsMove
-- effect can instead set moveVisible=false for a marked card entering the
-- processing area, which may allow the native client to render its card back.
-- Mixed batches are separated by visibility, preserving the card order.
-- Do not alter card.name/card.skill/target.
skill:addEffect(fk.BeforeCardsMove, {
  global = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player and player.room and Vis.hasMarkedMove(player.room, data)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    Vis.hideMarkedMoves(player.room, data)
  end,
})

-- The mask has to survive TargetConfirmed, including if a failed guess
-- consumes the last transformation layer and the Angel changes form.
-- A global cleanup is used because the defender might no longer own this
-- skill when CardUseFinished runs.  It only acts on this one marked use.
skill:addEffect(fk.CardUseFinished, {
  global = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data and type(data.extra_data) == "table"
      and type(data.extra_data.xy__zhentan_hidden_use) == "table"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local state = data.extra_data.xy__zhentan_hidden_use
    data.extra_data.xy__zhentan_hidden_use = nil
    Vis.unregister(player.room, state.ids)
    Intercept.finish(player.room, data)
    changeDisplayedVirtualName(player.room, state.ids, state.original_name)
  end,
})

skill:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead
      and player:hasSkill(self) and U.isAngel(player)
      and U.getStack(player) > 0
      and onlyTarget(data, player)
      and not data:isNullified()
  end,
  on_cost = Util.TrueFunc, -- locked; choosing a card name is compulsory
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = data.card
    local info = card:getSuitCompletedString(false)
    local names = allNames(room)
    if #names == 0 then
      -- In a very unusual zero-physical-card game there is nothing legitimate
      -- to declare. Never expose all registered cards as a fallback.
      U.consumeStack(room, player, 1)
      room:sendLog({type = "#xy__zhentan-no-choices", from = player.id})
      return
    end
    local choice = room:askToChoice(player, {
      choices = names,
      skill_name = self.name,
      cancelable = false,
      prompt = "#xy__zhentan-choice:::" .. info,
    })
    if choice == card.name then
      data:setNullified()
      player:drawCards(2, self.name)
      -- No guessed name in public history: a correct guess would reveal the
      -- actual card despite the earlier masked #UseCardToTargets entry.
      room:sendLog({type = "#xy__zhentan-right", from = player.id})
    else
      U.consumeStack(room, player, 1)
      room:sendLog({type = "#xy__zhentan-wrong", from = player.id})
    end
  end,
})

return skill

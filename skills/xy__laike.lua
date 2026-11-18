-- 【來客】Select the recipient AND all cards to deposit in the same prompt.
-- All deposited Future cards are publicly visible to every player;
-- the recipient still decides which physical cards to cancel.
local U = dofile("./packages/XY/anna_utils.lua")
local Future = dofile("./packages/XY/xy_future.lua")
local skill = fk.CreateSkill{ name = "xy__laike" }

skill:addEffect("active", {
  anim_type = "control",
  card_num = 0,
  target_num = 0, -- recipient and cards are chosen in the subsequent unified UI
  can_use = function(self, player)
    if player == nil or not U.isAngel(player) or player.phase ~= Player.Play then
      return false
    end
    -- No usedSkillTimes() check: this skill may be used any number of times
    -- during the same Play phase, provided there are cards to place.
    -- Client-side skill availability must not depend on player.room existing.
    return #player:getCardIds("he") > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local hand_and_equips = player:getCardIds("he")
    if #hand_and_equips == 0 then return end

    local candidates = {}
    for _, p in ipairs(room.alive_players) do
      if p ~= player and not p.dead then
        candidates[#candidates + 1] = p
      end
    end
    if #candidates == 0 then return end

    -- The stock FreeKill API draws the target selector and hand/equip card
    -- selector in a SINGLE request. No separate target and discard prompts.
    local chosen, ids, confirmed = room:askToChooseCardsAndPlayers(player, {
      targets = candidates,
      min_num = 1, max_num = 1,
      min_card_num = 1, max_card_num = #hand_and_equips,
      pattern = ".",
      will_throw = false, -- do not discard the cards being placed!
      cancelable = true,
      skill_name = self.name,
      prompt = "#xy__laike-combined",
    })
    if not confirmed or type(chosen) ~= "table" or #chosen ~= 1
      or type(ids) ~= "table" or #ids == 0 then return end

    local target = chosen[1]
    if target == player or target.dead then return end
    local valid_target = false
    for _, p in ipairs(candidates) do
      if p == target then valid_target = true; break end
    end
    if not valid_target then return end

    -- Validate against CURRENT card ownership, rather than trusting a stale
    -- client reply; duplicate physical IDs must never be placed twice.
    local owned, seen = {}, {}
    for _, id in ipairs(player:getCardIds("he")) do owned[id] = true end
    for _, id in ipairs(ids) do
      if not owned[id] or seen[id] then return end
      seen[id] = true
    end
    Future.place(player, target, ids)
  end,
})

-- Explicitly bypass the engine's skill-use count limit for THIS active skill.
-- This does not bypass the number-of-uses limit for Slash or other cards.
skill:addEffect("targetmod", {
  bypass_times = function(self, player, used_skill, scope, card, to)
    local kind = type(used_skill)
    return player ~= nil and U.isAngel(player)
      and player.phase == Player.Play
      and (kind == "table" or kind == "userdata")
      and used_skill.name == "xy__laike"
  end,
})

return skill

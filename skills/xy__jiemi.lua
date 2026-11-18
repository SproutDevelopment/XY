-- 【解密】弃一张牌变身；每次叠加一层；声明使用牌后立即扣一层。
local U = dofile("./packages/XY/anna_utils.lua")
local skill = fk.CreateSkill{ name = "xy__jiemi" }

skill:addEffect("active", {
  anim_type = "special",
  -- No direct card or target selection: clicking the skill can submit at once.
  -- The player chooses a card to discard (or cancels) in the cost prompt instead.
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player ~= nil and U.isAnna(player) and player.phase == Player.Play and
      #player:getCardIds("he") > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local ids = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      cancelable = true,
      skill_name = self.name,
      prompt = "#xy__jiemi-discard",
    })
    -- A cancelled discard request must not transform, spend cards or add layers.
    if not ids or #ids == 0 then return end
    room:addPlayerMark(player, U.STACK, 1)
    if player.general == U.BASE then
      -- Preserve current HP, max HP and kingdom; don't heal on transformation.
      room:changeHero(player, U.ANGEL, false, false, true, false, false)
    elseif player.deputyGeneral == U.BASE then
      room:changeHero(player, U.ANGEL, false, true, true, false, false)
    end
  end,
})

-- A placed "未来" survives transformation, so its automatic resolution
-- belongs to this shared base+Angel skill rather than Angel-only 【来客】.
local Future = dofile("./packages/XY/xy_future.lua")
skill:addEffect(fk.TurnStart, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target ~= nil and not target.dead
      and U.isAnna(player) and player:hasSkill(self)
      and Future.count(target, player) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    Future.resolve(player.room, player, target)
  end,
})

-- FreeKill's AfterCardUseDeclared occurs immediately after a card is
-- declared (before targets and effects), unlike CardUseFinished.
skill:addEffect(fk.AfterCardUseDeclared, {
  anim_type = "special",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and U.isAnna(player)
      and player:hasSkill(self)
      and (tonumber(player:getMark(U.STACK)) or 0) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    U.consumeStack(player.room, player, 1)
  end,
})

return skill

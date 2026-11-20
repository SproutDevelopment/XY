-- 煉成：準備階段獲得棄牌堆中的一張【殺】；結束階段獲得一張【閃】。
local skill = fk.CreateSkill{
  name = "alch__liancheng",
}

-- Only physical cards that are currently in the discard pile can be obtained.
local function findDiscardCards(room, trueName)
  local result = {}
  for _, id in ipairs(room.discard_pile or {}) do
    local card = Fk:getCardById(id)
    if card and card.trueName == trueName then
      table.insert(result, id)
    end
  end
  return result
end

skill:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) then
      return false
    end
    local trueName
    if player.phase == Player.Start then
      trueName = "slash"
    elseif player.phase == Player.Finish then
      trueName = "jink"
    else
      return false
    end
    return #findDiscardCards(player.room, trueName) > 0
  end,
  -- Wording is mandatory, so do not prompt to invoke the skill.
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local trueName = player.phase == Player.Start and "slash" or "jink"
    local ids = findDiscardCards(room, trueName)
    if #ids == 0 then return end

    local chosen = ids[1]
    if #ids > 1 then
      room:fillAG(player, ids)
      chosen = room:askToAG(player, {
        card_ids = ids,
        skill_name = self.name,
        cancelable = false,
      })
      room:closeAG(player)
    end
    if chosen and chosen ~= -1 then
      room:obtainCard(player, chosen, true, fk.ReasonPrey, player, self.name)
    end
  end,
})

return skill

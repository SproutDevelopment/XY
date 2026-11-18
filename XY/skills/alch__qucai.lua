-- 取材：棄牌階段開始時，將手牌數調整至3張。
local skill = fk.CreateSkill{
  name = "alch__qucai",
  tags = {Skill.Compulsory},
}

skill:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player
      and player:hasSkill(self)
      and player.phase == Player.Discard
      and player:getHandcardNum() ~= 3
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local difference = 3 - player:getHandcardNum()
    if difference > 0 then
      player:drawCards(difference, self.name)
    elseif difference < 0 then
      player.room:askToDiscard(player, {
        min_num = -difference,
        max_num = -difference,
        include_equip = false,
        cancelable = false,
        skill_name = self.name,
      })
    end
  end,
})

return skill

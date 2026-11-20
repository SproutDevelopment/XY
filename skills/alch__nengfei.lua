-- 【能飞】展示为“中国红”，实质按红色判定。
-- 触发点：成为一张牌的目标后；setNullified 仅使此牌对自身无效。
local skill = fk.CreateSkill{ name = "alch__nengfei" }

skill:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
      and data.to == player and data.card ~= nil
      and not data:isNullified()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room.askForSkillInvoke then
      return room:askForSkillInvoke(player, self.name, nil, "#alch__nengfei-invoke")
    elseif room.askToSkillInvoke then
      return room:askToSkillInvoke(player, {
        skill_name = self.name,
        prompt = "#alch__nengfei-invoke",
      })
    end
    -- 如果游戏版本没有任何询问 API，不能擅自代替玩家发动可选技。
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = { who = player, reason = self.name }
    room:judge(judge)
    if judge.card and judge.card.color == Card.Red then
      data:setNullified()
    end
  end,
})

return skill

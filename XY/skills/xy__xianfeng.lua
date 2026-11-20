-- 仙風
-- 一名角色回合结束时，你可以选择一名角色区域内一张牌弃置之，
-- 若该牌和上次你发动此技能的颜色一样，此技能失效至你的回合开始。

local xianfeng = fk.CreateSkill {
  name = "xy__xianfeng",
}

Fk:loadTranslationTable{
  ["xy__xianfeng"] = "仙风",
  [":xy__xianfeng"] = "一名角色回合结束时，你可以选择一名角色区域内一张牌弃置之，" ..
    "若该牌和上次你发动此技能的颜色一样，此技能失效至你的回合开始。",

  ["@@xy__xianfeng_invalid"] = "仙风失效",
  ["@xy__xianfeng_color"] = "仙风",
  ["#xy__xianfeng-choose"] = "仙风：你可以弃置一名角色区域内的一张牌",
}

local LAST_COLOR = "xy__xianfeng_last"
local INVALID = "@@xy__xianfeng_invalid"

xianfeng:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xianfeng.name) and table.find(player.room.alive_players, function(p)
      return #p:getCardIds("hej") > 0
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return #p:getCardIds("hej") > 0
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#xy__xianfeng-choose",
      skill_name = xianfeng.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "hej",
      skill_name = xianfeng.name,
    })
    local color = Fk:getCardById(id).color
    room:throwCard(id, xianfeng.name, to, player)

    -- 与上次发动时弃置的牌颜色相同：失效至你的回合开始
    local last = player:getMark(LAST_COLOR)
    if last ~= 0 and last == color then
      room:setPlayerMark(player, INVALID, 1)
    end
    room:setPlayerMark(player, LAST_COLOR, color)
    room:setPlayerMark(player, "@xy__xianfeng_color", color == Card.Red and "red" or
      (color == Card.Black and "black" or "nocolor"))
  end,
})

-- 你的回合开始：恢复有效
xianfeng:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(INVALID) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, INVALID, 0)
  end,
})

xianfeng:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    if from:getMark(INVALID) == 0 or skill == self then return false end
    local skel = skill.getSkeleton and skill:getSkeleton()
    return skel ~= nil and skel.name == xianfeng.name
  end,
})

return xianfeng

-- 弱柳（坂柳有棲）
-- 持恒技，你的攻击范围始终为0。回合开始时，你可以令一名角色将手牌摸至体力值。

local ruoliu = fk.CreateSkill {
  name = "xy__ruoliu",
  tags = { Skill.Permanent },
}

Fk:loadTranslationTable{
  ["xy__ruoliu"] = "弱柳",
  [":xy__ruoliu"] = "持恒技，你的攻击范围始终为0。回合开始时，你可以令一名角色将手牌摸至体力值。",
  ["#xy__ruoliu-choose"] = "弱柳：你可以令一名角色将手牌摸至体力值",
}

-- 攻击范围始终为0
ruoliu:addEffect("atkrange", {
  final_func = function(self, from)
    if from:hasSkill(ruoliu.name) then
      return 0
    end
  end,
})

-- 回合开始时：令一名角色将手牌摸至体力值
ruoliu:addEffect(fk.TurnStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ruoliu.name) and
      table.find(player.room.alive_players, function(p) return p:getHandcardNum() < p.hp end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return p:getHandcardNum() < p.hp end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#xy__ruoliu-choose",
      skill_name = ruoliu.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    local n = to.hp - to:getHandcardNum()
    if n > 0 then
      to:drawCards(n, ruoliu.name)
    end
  end,
})

return ruoliu

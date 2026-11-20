-- 妮助
-- 一名角色展示手牌后，你可以对其造成一点伤害或弃置其展示的牌。

local nizhu = fk.CreateSkill {
  name = "xy__nizhu",
}

Fk:loadTranslationTable{
  ["xy__nizhu"] = "妮助",
  [":xy__nizhu"] = "一名角色展示手牌后，你可以对其造成一点伤害或弃置其展示的牌。",

  ["xy__nizhu_damage"] = "对其造成1点伤害",
  ["xy__nizhu_discard"] = "弃置其展示的牌",
  ["#xy__nizhu-choice"] = "妮助：%dest 展示了手牌，你可以对其造成1点伤害或弃置其展示的牌",

  ["$xy__nizhu1"] = "苹果猫，你这次加强满意了吗？",
}

-- 取出仍在该角色手牌中的被展示牌
local function shownHandCards(target, data)
  return table.filter(data.cardIds or {}, function(id)
    return table.contains(target:getCardIds("h"), id)
  end)
end

-- 展示牌的角色（兼容事件没有目标的情况）
local function shower(room, target, data)
  local who = target or data.from
  if type(who) == "number" then who = room:getPlayerById(who) end
  return who
end

nizhu:addEffect(fk.CardShown, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    local who = shower(player.room, target, data)
    return player:hasSkill(nizhu.name) and who and not who.dead and
      #shownHandCards(who, data) > 0
  end,
  on_cost = function(self, event, target, player, data)
    target = shower(player.room, target, data)
    local choice = player.room:askToChoice(player, {
      choices = { "xy__nizhu_damage", "xy__nizhu_discard", "Cancel" },
      skill_name = nizhu.name,
      prompt = "#xy__nizhu-choice::" .. target.id,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { tos = { target }, choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    if choice == "xy__nizhu_damage" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = nizhu.name,
      }
    else
      local ids = shownHandCards(target, data)
      if #ids > 0 then
        room:throwCard(ids, nizhu.name, target, player)
      end
    end
  end,
})

return nizhu

-- 文鳥
-- 当你成为伤害牌的目标时，你可以令此牌不可被你响应，然后你视为对伤害来源使用一张无距离限制的【杀】。

local wenniao = fk.CreateSkill {
  name = "xy__wenniao",
}

Fk:loadTranslationTable{
  ["xy__wenniao"] = "文鸟",
  [":xy__wenniao"] = "当你成为伤害牌的目标时，你可以令此牌不可被你响应，然后你视为对伤害来源使用一张无距离限制的【杀】。",

  ["#xy__wenniao-invoke"] = "文鸟：你可以令%arg不可被你响应，然后视为对 %dest 使用一张【杀】",
}

wenniao:addEffect(fk.TargetConfirming, {
  anim_type = "counter",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wenniao.name) and data.card.is_damage_card
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = wenniao.name,
      prompt = "#xy__wenniao-invoke::" .. data.from.id .. ":" .. data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    -- 此牌不可被你响应
    data.disresponsive = true
    if data.use then
      data.use.disresponsiveList = data.use.disresponsiveList or {}
      table.insertIfNeed(data.use.disresponsiveList, player)
    end

    -- 视为对伤害来源使用一张无距离限制的【杀】
    local from = data.from
    if player.dead or not from or from.dead or from == player then return end
    room:useVirtualCard("slash", nil, player, from, wenniao.name, true)
  end,
})

return wenniao

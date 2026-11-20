-- 確目（朝比奈真冬）
-- 出牌阶段，你可以弃置两张颜色相同的手牌，选择一名角色。若如此做，你令该角色选择一项：
-- 1.弃置一张牌并令你摸两张牌；2.将其武将牌翻面。

local quemu = fk.CreateSkill {
  name = "xy__quemu",
}

Fk:loadTranslationTable{
  ["xy__quemu"] = "确目",
  [":xy__quemu"] = "出牌阶段，你可以弃置两张颜色相同的手牌，选择一名角色。若如此做，你令该角色选择一项：" ..
    "1.弃置一张牌并令你摸两张牌；2.将其武将牌翻面。",

  ["#xy__quemu"] = "确目：弃置两张颜色相同的手牌并选择一名角色",
  ["xy__quemu_discard"] = "弃置一张牌，令其摸两张牌",
  ["xy__quemu_turnover"] = "将武将牌翻面",
  ["#xy__quemu-choice"] = "确目：请选择一项",
}

quemu:addEffect("active", {
  anim_type = "control",
  prompt = "#xy__quemu",
  card_num = 2,
  target_num = 1,
  can_use = Util.TrueFunc,
  card_filter = function(self, player, to_select, selected)
    if #selected >= 2 or not table.contains(player:getCardIds("h"), to_select) then return false end
    if player:prohibitDiscard(Fk:getCardById(to_select)) then return false end
    if #selected == 0 then return true end
    return Fk:getCardById(to_select).color == Fk:getCardById(selected[1]).color
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local to = effect.tos[1]
    room:throwCard(effect.cards, quemu.name, player, player)
    if to.dead then return end

    local choices = { "xy__quemu_turnover" }
    if not to:isNude() then
      table.insert(choices, 1, "xy__quemu_discard")
    end
    local choice = room:askToChoice(to, {
      choices = choices,
      skill_name = quemu.name,
      prompt = "#xy__quemu-choice",
    })
    if choice == "xy__quemu_discard" then
      room:askToDiscard(to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = quemu.name,
        cancelable = false,
      })
      if not player.dead then
        player:drawCards(2, quemu.name)
      end
    else
      to:turnOver()
    end
  end,
})

return quemu

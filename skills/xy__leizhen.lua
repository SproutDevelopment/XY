-- 雷珍（瑪娜·唯心）
-- 每轮限一次，你可以将一张牌当任意基本或锦囊牌使用或打出。

local leizhen = fk.CreateSkill {
  name = "xy__leizhen",
}

Fk:loadTranslationTable{
  ["xy__leizhen"] = "雷珍",
  [":xy__leizhen"] = "每轮限一次，你可以将一张牌当任意基本或锦囊牌使用或打出。",
  ["#xy__leizhen"] = "雷珍：将一张牌当任意基本牌或锦囊牌使用或打出（每轮限一次）",
}

local function usable(player)
  return player:usedSkillTimes(leizhen.name, Player.HistoryRound) == 0
end

leizhen:addEffect("viewas", {
  pattern = ".",
  prompt = "#xy__leizhen",
  interaction = function(self, player)
    local all = Fk:getAllCardNames("btd")
    local names = player:getViewAsCardNames(leizhen.name, all)
    if #names > 0 then
      return UI.CardNameBox { choices = names, all_choices = all }
    end
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction or not self.interaction.data then return nil end
    local c = Fk:cloneCard(self.interaction.data)
    c.skillName = leizhen.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return usable(player)
  end,
  enabled_at_response = function(self, player, response)
    return usable(player)
  end,
})

return leizhen

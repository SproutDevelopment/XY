-- 愛心（瑪娜·唯心）
-- 你可以将♥牌当【桃】使用。

local aixin = fk.CreateSkill {
  name = "xy__aixin",
}

Fk:loadTranslationTable{
  ["xy__aixin"] = "爱心",
  [":xy__aixin"] = "你可以将<font color='red'>♥</font>牌当【桃】使用。",
  ["#xy__aixin"] = "爱心：你可以将一张♥牌当【桃】使用",
}

aixin:addEffect("viewas", {
  anim_type = "support",
  pattern = "peach",
  prompt = "#xy__aixin",
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Heart
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("peach")
    c.skillName = aixin.name
    c:addSubcard(cards[1])
    return c
  end,
})

return aixin

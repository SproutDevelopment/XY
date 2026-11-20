-- 流循（唐咨）
-- 魏势力技，吴势力技，你进入濒死状态时，若你势力为"魏"/"吴"，你将势力修改为"吴"/"晋"，
-- 然后从弃牌堆选择并获得一张牌。

local liuxun = fk.CreateSkill {
  name = "xy__liuxun",
}

Fk:loadTranslationTable{
  ["xy__liuxun"] = "流循",
  [":xy__liuxun"] = "魏势力技，吴势力技，你进入濒死状态时，若你势力为“魏”/“吴”，你将势力修改为“吴”/“晋”，" ..
    "然后从弃牌堆选择并获得一张牌。",
  ["xy__discard_pile"] = "弃牌堆",
  ["jin"] = "晋",
}

local NEXT = { wei = "wu", wu = "jin" }

liuxun:addEffect(fk.EnterDying, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liuxun.name) and NEXT[player.kingdom] ~= nil
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeKingdom(player, NEXT[player.kingdom], true)
    local ids = table.simpleClone(room.discard_pile)
    if #ids == 0 then return end
    local id = room:askToChooseCard(player, {
      target = player,
      flag = { card_data = { { "xy__discard_pile", ids } } },
      skill_name = liuxun.name,
    })
    if id and room:getCardArea(id) == Card.DiscardPile then
      room:obtainCard(player, id, true, fk.ReasonJustMove, player, liuxun.name)
    end
  end,
})

return liuxun

-- 星舞
-- 一名角色的弃牌阶段开始时，你可以摸一张牌并将一张牌置于武将牌上，称为"星舞"，
-- 然后你可移去三张"星舞"牌，弃置一名其他角色装备区里的所有牌，然后对其造成2点伤害。

local xingwu = fk.CreateSkill {
  name = "xy__xingwu",
}

Fk:loadTranslationTable{
  ["xy__xingwu"] = "星舞",
  [":xy__xingwu"] = "一名角色的弃牌阶段开始时，你可以摸一张牌并将一张牌置于武将牌上，称为“星舞”，" ..
    "然后你可移去三张“星舞”牌，弃置一名其他角色装备区里的所有牌，然后对其造成2点伤害。",

  ["#xy__xingwu-invoke"] = "星舞：你可以摸一张牌并将一张牌置为“星舞”",
  ["#xy__xingwu-target"] = "星舞：你可以移去三张“星舞”，弃置一名其他角色装备区所有牌并对其造成2点伤害",
  ["#xy__xingwu-remove"] = "星舞：选择三张“星舞”牌移去",
}

local PILE = "xy__xingwu_pile"

xingwu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xingwu.name) and target.phase == Player.Discard
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = xingwu.name,
      prompt = "#xy__xingwu-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    -- 摸一张牌并将一张牌置为"星舞"（与 娉婷 共用）
    XY_Erqiao.drawAndPut(player, xingwu.name)
    if player.dead or #player:getPile(PILE) < 3 then return end

    -- 然后你可以移去三张"星舞"
    local others = room:getOtherPlayers(player)
    if #others == 0 then return end
    local tos = room:askToChoosePlayers(player, {
      targets = others,
      min_num = 1,
      max_num = 1,
      prompt = "#xy__xingwu-target",
      skill_name = xingwu.name,
      cancelable = true,
    })
    if #tos == 0 then return end
    local to = tos[1]

    local cards = room:askToCards(player, {
      min_num = 3,
      max_num = 3,
      include_equip = false,
      skill_name = xingwu.name,
      pattern = ".|.|.|" .. PILE,
      expand_pile = PILE,
      prompt = "#xy__xingwu-remove",
      cancelable = false,
    })
    if #cards < 3 then
      cards = table.slice(player:getPile(PILE), 1, 4)
    end
    room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, xingwu.name, PILE, true, player)

    -- 弃置其装备区里的所有牌
    if not to.dead and #to:getCardIds("e") > 0 then
      room:throwCard(to:getCardIds("e"), xingwu.name, to, player)
    end
    -- 然后对其造成2点伤害
    if not to.dead then
      room:damage{
        from = player,
        to = to,
        damage = 2,
        skillName = xingwu.name,
      }
    end
  end,
})

return xingwu

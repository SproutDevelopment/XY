-- 扶風（坂柳有棲）
-- 出牌阶段，你可以选择一名其他角色的手牌并得知该牌的花色点数和类型，然后声明一个牌名且展示该手牌。
-- 若你声明的牌名为该牌的牌名，你获得之并令其失去1点体力，然后你可以摸一张牌。否则，此技能本阶段失效。
-- （你以此法获得的牌无距离次数限制且不计入手牌上限）

local fufeng = fk.CreateSkill {
  name = "xy__fufeng",
}

Fk:loadTranslationTable{
  ["xy__fufeng"] = "扶风",
  [":xy__fufeng"] = "出牌阶段，你可以选择一名其他角色的手牌并得知该牌的花色点数和类型，然后声明一个牌名且展示该手牌。" ..
    "若你声明的牌名为该牌的牌名，你获得之并令其失去1点体力，然后你可以摸一张牌。否则，此技能本阶段失效。" ..
    "（你以此法获得的牌无距离次数限制且不计入手牌上限）",

  ["#xy__fufeng"] = "扶风：选择一名其他角色，选择其一张手牌",
  ["#xy__fufeng-declare"] = "扶风：该牌为 %arg，类型为 %arg2，请声明一个牌名",
  ["#xy__fufeng-draw"] = "扶风：猜中了！你可以摸一张牌",
  ["#xy__fufeng-log_right"] = "%from 声明了 %arg，猜中了",
  ["#xy__fufeng-log_wrong"] = "%from 声明了 %arg，猜错了，“扶风”本阶段失效",
  ["@@xy__fufeng-inhand"] = "扶风",
  ["@@xy__fufeng_fail-phase"] = "扶风失效",
}

local CARD_MARK = "@@xy__fufeng-inhand"
local FAIL = "@@xy__fufeng_fail-phase"

fufeng:addEffect("active", {
  anim_type = "control",
  prompt = "#xy__fufeng",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark(FAIL) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local to = effect.tos[1]
    if to:isKongcheng() then return end
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "h",
      skill_name = fufeng.name,
    })
    local card = Fk:getCardById(id)

    -- 得知花色点数和类型（只在你的询问框里显示），然后声明一个牌名
    local info = Fk:translate(card:getSuitString(true)) .. card:getNumberStr()
    -- 可声明的牌名：本局游戏中现存的所有牌（牌堆、弃牌堆、处理区、所有角色的区域）
    local names = {}
    local function addIds(ids)
      for _, cid in ipairs(ids or {}) do
        table.insertIfNeed(names, Fk:getCardById(cid).trueName)
      end
    end
    addIds(room.draw_pile)
    addIds(room.discard_pile)
    addIds(room.processing_area)
    for _, p in ipairs(room.players) do
      addIds(p:getCardIds("hej"))
      for _, pile in pairs(p.special_cards or {}) do
        addIds(pile)
      end
    end
    local declared = room:askToChoice(player, {
      choices = names,
      skill_name = fufeng.name,
      prompt = "#xy__fufeng-declare:::" .. info .. ":" .. Fk:translate(card:getTypeString()),
    })

    -- 展示该手牌
    if table.contains(to:getCardIds("h"), id) then
      room:showCards({ id }, to)
    end

    if declared == card.trueName then
      room:sendLog{ type = "#xy__fufeng-log_right", from = player.id, arg = declared, toast = true }
      if table.contains(to:getCardIds("h"), id) then
        room:obtainCard(player, id, true, fk.ReasonPrey, player, fufeng.name)
        if table.contains(player:getCardIds("h"), id) then
          room:setCardMark(Fk:getCardById(id), CARD_MARK, 1)
        end
      end
      if not to.dead then
        room:loseHp(to, 1, fufeng.name)
      end
      if not player.dead and room:askToSkillInvoke(player, {
        skill_name = fufeng.name,
        prompt = "#xy__fufeng-draw",
      }) then
        player:drawCards(1, fufeng.name)
      end
    else
      room:sendLog{ type = "#xy__fufeng-log_wrong", from = player.id, arg = declared, toast = true }
      room:setPlayerMark(player, FAIL, 1)
    end
  end,
})

-- 以此法获得的牌：无距离次数限制
fufeng:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card:getMark(CARD_MARK) > 0
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and card:getMark(CARD_MARK) > 0
  end,
})

-- 以此法获得的牌：不计入手牌上限
fufeng:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark(CARD_MARK) > 0
  end,
})

return fufeng

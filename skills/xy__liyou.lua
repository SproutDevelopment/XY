-- 利友（野俊&香織，"真情"成功后获得）
-- 持恒技，一名角色获得牌时，你展示并获得之，然后用任意张牌替换其获得的牌。

local liyou = fk.CreateSkill {
  name = "xy__liyou",
  tags = { Skill.Permanent },
}

Fk:loadTranslationTable{
  ["xy__liyou"] = "利友",
  [":xy__liyou"] = "持恒技，一名角色获得牌时，你展示并获得之，然后用任意张牌替换其获得的牌。",
  ["#xy__liyou-give"] = "利友：交给 %dest 至少一张手牌，替换其获得的牌",
}

-- 找出其他角色本次获得、仍在其手牌中的牌：{ [角色] = {牌id...} }
local function collect(player, data)
  local room = player.room
  local result, order, reasons = {}, {}, {}
  for _, move in ipairs(data) do
    local to = move.to
    if type(to) == "number" then to = room:getPlayerById(to) end
    if move.toArea == Card.PlayerHand and to and to ~= player and not to.dead and
      move.skillName ~= liyou.name then
      for _, info in ipairs(move.moveInfo) do
        local id = info.cardId
        if table.contains(to:getCardIds("h"), id) then
          if not result[to] then
            result[to] = {}
            table.insert(order, to)
            reasons[to] = move.moveReason
          end
          table.insertIfNeed(result[to], id)
        end
      end
    end
  end
  return result, order, reasons
end

liyou:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(liyou.name) then return false end
    local _, order = collect(player, data)
    return #order > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local result, order, reasons = collect(player, data)
    for _, p in ipairs(order) do
      if player.dead then break end
      local ids = table.filter(result[p], function(id)
        return table.contains(p:getCardIds("h"), id)
      end)
      if #ids > 0 then
        room:showCards(ids, p)
        room:obtainCard(player, ids, true, fk.ReasonPrey, player, liyou.name)
        -- 用任意张牌替换
        if not p.dead and not player:isKongcheng() then
          local cards = room:askToCards(player, {
            min_num = 1,
            max_num = #player:getCardIds("h"),
            include_equip = false,
            skill_name = liyou.name,
            prompt = "#xy__liyou-give::" .. p.id,
            cancelable = false,
          })
          if #cards > 0 then
            -- 替换的牌按其原本获得牌的方式计算：
            -- 例如其从牌堆摸牌时，换给其的牌也视为其从牌堆摸的牌
            if reasons[p] == fk.ReasonDraw then
              -- 置于牌堆顶，再由其摸这些牌：真正视为其从牌堆摸的牌
              room:moveCards({
                ids = cards,
                from = player,
                toArea = Card.DrawPile,
                moveReason = fk.ReasonPut,
                skillName = liyou.name,
                proposer = player,
                moveVisible = false,
                drawPilePosition = 1,
              })
              if not p.dead then
                p:drawCards(#cards, liyou.name)
              end
            else
              room:moveCardTo(cards, Card.PlayerHand, p, reasons[p] or fk.ReasonGive, liyou.name, nil, false, player)
            end
          end
        end
      end
    end
  end,
})

return liyou

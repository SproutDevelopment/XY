-- 公審（国安法官版）
-- 当一名角色受到伤害时/濒死结算结束时没有脱离濒死状态，你进行一次判定。

local gongshen2 = fk.CreateSkill {
  name = "xy__gongshen2",
}

Fk:loadTranslationTable{
  ["xy__gongshen2"] = "公审",
  [":xy__gongshen2"] = "当一名角色受到伤害时/濒死结算结束时没有脱离濒死状态，你进行一次判定。若该牌花色为：<br>" ..
    "♦：受伤的角色摸两张牌/获得所有其之外的角色两张手牌，然后其立即使用手牌中所有的【桃】和【酒】" ..
    "（若其之外的角色少于两张手牌则先将手牌摸至两张）；<br>" ..
    "♣：受伤的角色弃置伤害来源两张牌/所有牌；<br>" ..
    "♥：受伤的角色回复一点体力/回复体力至1点并摸两张牌；<br>" ..
    "♠：伤害来源翻面/受到等同于令死亡的角色进入濒死状态的伤害。",

  ["#xy__gongshen2-prey"] = "公审：获得 %dest 的两张手牌",
  ["#xy__gongshen2-discard"] = "公审：弃置 %dest 的 %arg 张牌",
}

-- 共享接口：國安 也会调用这里的函数来发动"公审"
XY_GongshenV2 = XY_GongshenV2 or {}

--- 进行一次"公审"判定并结算
---@param player ServerPlayer @ 进行判定的角色
---@param mode string @ "damage"（受伤）或 "dying"（濒死）
---@param victim ServerPlayer @ 受伤/濒死的角色
---@param source ServerPlayer? @ 伤害来源（可为空）
---@param amount integer? @ 令其进入濒死的伤害值（♠ 濒死效果用）
function XY_GongshenV2.resolve(player, mode, victim, source, amount)
  local room = player.room
  local skillName = gongshen2.name

  local judge = {
    who = player,
    reason = skillName,
    pattern = ".",
  }
  room:judge(judge)
  local card = judge.card
  if not card then return end

  -- 记录本回合"公审"判定结果的颜色，供 國安 回合结束时检查
  if card.color == Card.Red or card.color == Card.Black then
    room:addTableMark(player, "xy__gongshen2_colors-turn", card.color)
  else
    room:addTableMark(player, "xy__gongshen2_colors-turn", Card.NoColor)
  end

  local suit = card.suit
  local srcAlive = source and not source.dead

  if mode == "damage" then
    if suit == Card.Diamond then
      if not victim.dead then
        victim:drawCards(2, skillName)
      end
    elseif suit == Card.Club then
      if srcAlive and not victim.dead and not source:isNude() then
        local n = math.min(2, #source:getCardIds("he"))
        local cards = room:askToChooseCards(victim, {
          target = source,
          min = n,
          max = n,
          flag = "he",
          skill_name = skillName,
          prompt = "#xy__gongshen2-discard::" .. source.id .. ":" .. n,
        })
        room:throwCard(cards, skillName, source, victim)
      end
    elseif suit == Card.Heart then
      if not victim.dead and victim:isWounded() then
        room:recover{
          who = victim,
          num = 1,
          recoverBy = player,
          skillName = skillName,
        }
      end
    elseif suit == Card.Spade then
      if srcAlive then
        source:turnOver()
      end
    end

  else -- mode == "dying"
    if suit == Card.Diamond then
      if victim.dead then return end
      for _, p in ipairs(room:getOtherPlayers(victim)) do
        if victim.dead then break end
        if not p.dead then
          local num = p:getHandcardNum()
          if num < 2 then
            p:drawCards(2 - num, skillName)
          end
          if p:getHandcardNum() > 0 then
            local n = math.min(2, p:getHandcardNum())
            local cards = room:askToChooseCards(victim, {
              target = p,
              min = n,
              max = n,
              flag = "h",
              skill_name = skillName,
              prompt = "#xy__gongshen2-prey::" .. p.id,
            })
            room:obtainCard(victim, cards, false, fk.ReasonPrey, victim, skillName)
          end
        end
      end
      -- 立即使用手牌中所有的【桃】和【酒】
      local toUse = table.filter(victim:getCardIds("h"), function(id)
        local c = Fk:getCardById(id)
        return c.trueName == "peach" or c.trueName == "analeptic"
      end)
      for _, id in ipairs(toUse) do
        if victim.dead then break end
        if table.contains(victim:getCardIds("h"), id) then
          room:useCard{
            from = victim,
            tos = { victim },
            card = Fk:getCardById(id),
          }
        end
      end

    elseif suit == Card.Club then
      if srcAlive and not victim.dead and not source:isNude() then
        room:throwCard(source:getCardIds("he"), skillName, source, victim)
      end

    elseif suit == Card.Heart then
      if not victim.dead and victim.hp < 1 then
        room:recover{
          who = victim,
          num = 1 - victim.hp,
          recoverBy = player,
          skillName = skillName,
        }
      end
      if not victim.dead then
        victim:drawCards(2, skillName)
      end

    elseif suit == Card.Spade then
      -- 没有实际伤害（如國安出牌阶段声明的公审）时伤害值为0，不造成伤害
      if srcAlive and amount and amount > 0 then
        room:damage{
          from = source, -- 伤害来源与最初那次伤害的来源相同
          to = source,
          damage = amount,
          skillName = skillName,
        }
      end
    end
  end
end

-- ========== 受到伤害时（强制） ==========
gongshen2:addEffect(fk.DamageInflicted, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gongshen2.name) and not target.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    XY_GongshenV2.resolve(player, "damage", target, data.from, data.damage)
  end,
})

-- ========== 濒死结算结束时没有脱离濒死状态（强制） ==========
gongshen2:addEffect(fk.AskForPeachesDone, {
  anim_type = "big",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gongshen2.name) and target.hp <= 0 and not target.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local damage = data.damage
    XY_GongshenV2.resolve(player, "dying", target,
      damage and damage.from or nil, damage and damage.damage or 1)
  end,
})

return gongshen2

-- 公审
-- 当一名角色受到伤害时或死亡结算前，你进行一次不可被改判的判定。

local gongshen = fk.CreateSkill {
  name = "xy__gongshen",
}

Fk:loadTranslationTable{
  ["xy__gongshen"] = "公审",
  [":xy__gongshen"] = "当一名角色受到伤害时或死亡结算前，你进行一次不可被改判的判定。<br>" ..
    "受伤：♦：受伤的角色摸X张牌；♣：伤害来源被受伤的角色弃置X张牌；♥：受伤的角色回复X点体力；♠：伤害来源翻面。<br>" ..
    "死亡结算前：♦：伤害来源弃置所有区域内的牌；♣：你将现有状态改为濒死状态，并获得所有其他角色的两张手牌" ..
    "（若不足则其将手牌摸至两张）；♥：死亡结算前的角色回复体力至1点并摸2张牌；" ..
    "♠：伤害来源受到等同于令死亡的角色进入濒死状态的伤害。",

  ["#xy__gongshen-discard"] = "公审：弃置 %dest 的 %arg 张牌",
  ["#xy__gongshen-prey"] = "公审：获得 %dest 的两张手牌",

  ["$xy__gongshen1"] = "法律面前人人平等。",
}

-- 特权：你受伤时 X=2，其他角色受伤时 X=1；没有特权时 X 默认为 1
local function getX(player, target)
  if player:hasSkill("xy__tequan") then
    return target == player and 2 or 1
  end
  return 1
end

local function canGongshen(player)
  return player:hasSkill(gongshen.name)
end

-- 进行判定，返回判定牌的花色
local function doJudge(player)
  local judge = {
    who = player,
    reason = gongshen.name,
    pattern = ".",
  }
  player.room:judge(judge)
  return judge.card and judge.card.suit or Card.NoSuit
end

-- ========== 受到伤害时 ==========
gongshen:addEffect(fk.DamageInflicted, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return canGongshen(player) and not target.dead
  end,
  on_cost = Util.TrueFunc, -- 强制发动
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = getX(player, target)
    local from = data.from
    local suit = doJudge(player)

    if suit == Card.Diamond then
      if not target.dead then
        target:drawCards(x, gongshen.name)
      end
    elseif suit == Card.Club then
      if from and not from.dead and not target.dead and not from:isNude() then
        local n = math.min(x, #from:getCardIds("he"))
        local cards = room:askToChooseCards(target, {
          target = from,
          min = n,
          max = n,
          flag = "he",
          skill_name = gongshen.name,
          prompt = "#xy__gongshen-discard::" .. from.id .. ":" .. n,
        })
        room:throwCard(cards, gongshen.name, from, target)
      end
    elseif suit == Card.Heart then
      if not target.dead and target:isWounded() then
        room:recover{
          who = target,
          num = x,
          recoverBy = player,
          skillName = gongshen.name,
        }
      end
    elseif suit == Card.Spade then
      if from and not from.dead then
        from:turnOver()
      end
    end
  end,
})

-- ========== 死亡结算前（求桃结束后体力仍不大于0，即将死亡） ==========
gongshen:addEffect(fk.AskForPeachesDone, {
  anim_type = "big",
  can_trigger = function(self, event, target, player, data)
    if not (canGongshen(player) and target.hp <= 0 and not target.dead) then return false end
    -- 特权：你杀死一名角色时，"公审"对该次死亡不生效
    local from = data.damage and data.damage.from or nil
    if from == player and player:hasSkill("xy__tequan") then return false end
    return true
  end,
  on_cost = Util.TrueFunc, -- 强制发动
  on_use = function(self, event, target, player, data)
    local room = player.room
    local damage = data.damage
    local from = damage and damage.from or nil
    local suit = doJudge(player)

    if suit == Card.Diamond then
      -- 伤害来源弃置所有区域内的牌
      if from and not from.dead then
        from:throwAllCards("hej", gongshen.name)
      end
    elseif suit == Card.Club then
      -- 获得所有其他角色的两张手牌（不足则先摸至两张）
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if player.dead then break end
        if not p.dead then
          local num = p:getHandcardNum()
          if num < 2 then
            p:drawCards(2 - num, gongshen.name)
          end
          if p:getHandcardNum() > 0 then
            local n = math.min(2, p:getHandcardNum())
            local cards = room:askToChooseCards(player, {
              target = p,
              min = n,
              max = n,
              flag = "h",
              skill_name = gongshen.name,
              prompt = "#xy__gongshen-prey::" .. p.id,
            })
            room:obtainCard(player, cards, false, fk.ReasonPrey, player, gongshen.name)
          end
        end
      end
      -- 你进入濒死状态（体力降至0）
      if not player.dead and player.hp > 0 then
        room:loseHp(player, player.hp, gongshen.name)
      end
    elseif suit == Card.Heart then
      -- 死亡结算前的角色回复体力至1点并摸2张牌
      if not target.dead and target.hp < 1 then
        room:recover{
          who = target,
          num = 1 - target.hp,
          recoverBy = player,
          skillName = gongshen.name,
        }
      end
      if not target.dead then
        target:drawCards(2, gongshen.name)
      end
    elseif suit == Card.Spade then
      -- 伤害来源受到等同于令死亡角色进入濒死的伤害
      if from and not from.dead and damage and damage.damage > 0 then
        room:damage{
          from = from, -- 伤害来源与最初那次伤害的来源相同
          to = from,
          damage = damage.damage,
          skillName = gongshen.name,
        }
      end
    end
  end,
})

-- ========== 不可被改判 ==========
-- 在改判时机以最高优先级抢先结算并返回 true，中断后续所有改判技能
gongshen:addEffect(fk.AskForRetrial, {
  global = true,
  mute = true,
  priority = 100,
  can_trigger = function(self, event, target, player, data)
    return data.reason == gongshen.name and data.who == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    return true
  end,
})

return gongshen

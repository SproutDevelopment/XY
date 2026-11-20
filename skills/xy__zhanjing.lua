-- 斬頸（猗窩座）
-- 当你受到致命伤害时，你防止之并进行一次判定，若结果为红心，你将体力值回复至上限并删除上述描述。
-- 之后你每个回合开始时，失去一点体力令你可使用【杀】的次数永久+1，然后你下次以此法失去的体力值+1。

local zhanjing = fk.CreateSkill {
  name = "xy__zhanjing",
}

Fk:loadTranslationTable{
  ["xy__zhanjing"] = "斩颈",
  [":xy__zhanjing"] = "当你受到致命伤害时，你防止之并进行一次判定，若结果为红心，你将体力值回复至上限并删除上述描述。" ..
    "之后你每个回合开始时，失去一点体力令你可使用【杀】的次数永久+1，然后你下次以此法失去的体力值+1。",

  ["@@xy__zhanjing_deleted"] = "斩颈已删",
  ["@xy__zhanjing_slash"] = "杀次数+",
  ["@xy__zhanjing_lose"] = "斩颈失去",
}

local DELETED = "@@xy__zhanjing_deleted"
local SLASH_PLUS = "@xy__zhanjing_slash"
local LOSE = "@xy__zhanjing_lose"   -- 下次失去的体力值

-- 受到致命伤害时：防止并判定
zhanjing:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhanjing.name) and player:getMark(DELETED) == 0 and
      data.damage >= player.hp + player.shield
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    local judge = {
      who = player,
      reason = zhanjing.name,
      pattern = ".|.|heart",
    }
    room:judge(judge)
    if judge.card and judge.card.suit == Card.Heart and not player.dead then
      if player.hp < player.maxHp then
        room:recover{
          who = player,
          num = player.maxHp - player.hp,
          recoverBy = player,
          skillName = zhanjing.name,
        }
      end
      -- 删除上述描述
      room:setPlayerMark(player, DELETED, 1)
      room:setPlayerMark(player, LOSE, 1)
    end
  end,
})

-- 之后你每个回合开始时
zhanjing:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhanjing.name) and player:getMark(DELETED) ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.max(player:getMark(LOSE), 1)
    room:loseHp(player, n, zhanjing.name)
    room:addPlayerMark(player, SLASH_PLUS, 1)
    room:setPlayerMark(player, LOSE, n + 1)
  end,
})

-- 可使用【杀】的次数永久+X
zhanjing:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope, card, to)
    local isSlash = (card and card.trueName == "slash") or
      (skill and (skill.trueName == "slash_skill" or skill.name == "slash_skill"))
    if isSlash and scope == Player.HistoryPhase then
      return player:getMark(SLASH_PLUS)
    end
  end,
})

return zhanjing

-- 魔刃
-- 你使用【杀】或【决斗】指定一名目标时，你可以弃置一张牌并进行判定直到判定结果为黑色。
-- 该牌造成伤害时，你可以令此牌伤害+X。（X为判定的次数）

local moren = fk.CreateSkill {
  name = "xy__moren",
}

Fk:loadTranslationTable{
  ["xy__moren"] = "魔刃",
  [":xy__moren"] = "你使用【杀】或【决斗】指定一名目标时，你可以弃置一张牌并进行判定直到判定结果为黑色。" ..
    "该牌造成伤害时，你可以令此牌伤害+X。（X为判定的次数）",

  ["#xy__moren-discard"] = "魔刃：你可以弃置一张牌，然后进行判定直到结果为黑色（对 %dest）",
  ["#xy__moren-damage"] = "魔刃：你可以令此牌对 %dest 造成的伤害+%arg",
  ["#xy__moren-count"] = "%from 的“魔刃”共判定了 %arg 次",
}

-- 防止牌堆中没有黑色牌时无限循环
local MAX_JUDGE = 60
-- 记录：{ {card = 牌, user = 使用者id, to = 目标id, x = 次数}, ... }
local TAG = "xy__moren_records"

local function getRecords(room)
  return room:getTag(TAG) or {}
end

-- ========== 指定目标时：弃一张牌，判定直到黑色 ==========
moren:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(moren.name) and
      (data.card.trueName == "slash" or data.card.trueName == "duel") and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = moren.name,
      cancelable = true,
      prompt = "#xy__moren-discard::" .. data.to.id,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, moren.name, player, player)

    local x = 0
    repeat
      x = x + 1
      local judge = {
        who = player,
        reason = moren.name,
        pattern = ".|.|spade,club",
      }
      room:judge(judge)
      local black = judge.card and judge.card.color == Card.Black
    until black or player.dead or x >= MAX_JUDGE

    room:sendLog{
      type = "#xy__moren-count",
      from = player.id,
      arg = tostring(x),
    }

    -- 记录在房间里（按这张牌和目标分别记录）
    local records = getRecords(room)
    table.insert(records, { card = data.card, user = player.id, to = data.to.id, x = x })
    room:setTag(TAG, records)
  end,
})

-- 查找此伤害对应的 X：
-- 对目标造成伤害取该目标的 X；【决斗】对使用者造成伤害取伤害来源（即该目标）的 X
local function findX(room, player, data)
  if not data.card then return 0 end
  local total = 0
  for _, r in ipairs(getRecords(room)) do
    if r.card == data.card and r.user == player.id then
      if r.to == data.to.id then
        total = total + r.x
      elseif data.to == player and data.from and r.to == data.from.id then
        total = total + r.x
      end
    end
  end
  return total
end

-- ========== 该牌造成伤害时：可以令伤害+X ==========
moren:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(moren.name) and findX(player.room, player, data) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local x = findX(player.room, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = moren.name,
      prompt = "#xy__moren-damage::" .. data.to.id .. ":" .. x,
    }) then
      event:setCostData(self, { x = x })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local x = event:getCostData(self).x
    if data.changeDamage then
      data:changeDamage(x)
    else
      data.damage = data.damage + x
    end
  end,
})

-- ========== 该牌结算完毕：清除记录 ==========
moren:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.find(getRecords(player.room), function(r)
      return r.card == data.card
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local records = table.filter(getRecords(room), function(r)
      return r.card ~= data.card
    end)
    room:setTag(TAG, records)
  end,
})

return moren

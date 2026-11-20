-- 曹祖（曹節·仁慈敦厚）
-- 你受到一点伤害时，你可以获得造成伤害牌并摸X张牌。（X为本回合对你造成伤害的伤害牌字数之和）

local caozu = fk.CreateSkill {
  name = "xy__caozu",
}

Fk:loadTranslationTable{
  ["xy__caozu"] = "曹祖",
  [":xy__caozu"] = "你受到一点伤害时，你可以获得造成伤害牌并摸X张牌。（X为本回合对你造成伤害的伤害牌字数之和）",
  ["#xy__caozu-invoke"] = "曹祖：你可以获得%arg并摸%arg2张牌",
}

-- 本轮之前已对你造成伤害的伤害牌名（本轮内累加）
local NAMES = "xy__caozu_names-round"

local function nameLength(name)
  local text = Fk:translate(name)
  return utf8.len(text) or #text
end

local function cardIds(card)
  if card:isVirtual() then
    return table.simpleClone(card.subcards)
  end
  return { card.id }
end

-- 计算 X：本轮此前的伤害牌字数 + 本次伤害牌字数
local function getX(player, card)
  local x = nameLength(card.name)
  for _, name in ipairs(player:getTableMark(NAMES)) do
    x = x + nameLength(name)
  end
  return x
end

caozu:addEffect(fk.DamageInflicted, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(caozu.name) and data.card ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = caozu.name,
      prompt = "#xy__caozu-invoke:::" .. data.card:toLogString() .. ":" .. getX(player, data.card),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = getX(player, data.card)
    -- 获得造成伤害的牌（仍在处理区时）
    local ids = table.filter(cardIds(data.card), function(id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #ids > 0 then
      room:obtainCard(player, ids, true, fk.ReasonJustMove, player, caozu.name)
    end
    -- 摸X张牌
    if not player.dead and x > 0 then
      player:drawCards(x, caozu.name)
    end
  end,
})

-- 伤害结算后记录这张伤害牌
caozu:addEffect(fk.Damaged, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card ~= nil and player:hasSkill(caozu.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMark(player, NAMES, data.card.name)
  end,
})

return caozu

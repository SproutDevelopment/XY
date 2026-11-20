-- 荊薔
-- 其他角色/你成为【杀】的目标或受到伤害时，你可以弃置其/摸一张牌，
-- 然后可以对其/其他角色使用该牌。若该【杀】造成了伤害，则你展示其所有手牌。
--
-- "该【杀】" = 触发本技能的那张原本的【杀】：
-- 若该【杀】对因其发动本技能的角色造成了伤害，则在该【杀】结算完毕后展示该角色的所有手牌。

local jingqiang = fk.CreateSkill {
  name = "xy__jingqiang",
}

Fk:loadTranslationTable{
  ["xy__jingqiang"] = "荆蔷",
  [":xy__jingqiang"] = "其他角色/你成为【杀】的目标或受到伤害时，你可以弃置其/摸一张牌，" ..
    "然后可以对其/其他角色使用该牌。若该【杀】造成了伤害，则你展示其所有手牌。",

  ["#xy__jingqiang-other"] = "荆蔷：你可以弃置 %dest 一张牌，然后可以对其使用该牌",
  ["#xy__jingqiang-self"] = "荆蔷：你可以摸一张牌，然后可以对其他角色使用该牌",
  ["#xy__jingqiang-use_other"] = "荆蔷：你可以对 %dest 使用 %arg",
  ["#xy__jingqiang-use_self"] = "荆蔷：你可以对其他角色使用 %arg",
}

local function doJingqiang(player, target)
  local room = player.room
  local id

  if target ~= player then
    -- 其他角色：弃置其一张牌
    if target.dead or target:isNude() then return end
    id = room:askToChooseCard(player, {
      target = target,
      flag = "he",
      skill_name = jingqiang.name,
    })
    room:throwCard(id, jingqiang.name, target, player)
    if room:getCardArea(id) ~= Card.DiscardPile or target.dead or player.dead then return end
  else
    -- 你自己：摸一张牌
    local ids = player:drawCards(1, jingqiang.name)
    id = ids and ids[1]
    if not id or player.dead or not table.contains(player:getCardIds("h"), id) then return end
  end

  local card = Fk:getCardById(id)
  local targets = target ~= player and { target.id }
    or table.map(room:getOtherPlayers(player), Util.IdMapper)

  -- 正常受距离与次数限制
  room:askToUseRealCard(player, {
    pattern = ".|.|.|.|.|.|" .. id, -- 按牌的id精确匹配
    skill_name = jingqiang.name,
    prompt = target ~= player
      and ("#xy__jingqiang-use_other::" .. target.id .. ":" .. card:toLogString())
      or ("#xy__jingqiang-use_self:::" .. card:toLogString()),
    extra_data = {
      -- FreeKill 默认不计次数，这里改为正常受次数限制
      bypass_times = false,
      extraUse = false,
      expand_pile = target ~= player and { id } or nil,
      exclusive_targets = targets,
    },
    cancelable = true,
  })
end

-- 该【杀】是否对某角色造成过伤害
local function dealtDamageTo(use, p)
  if not use.damageDealt then return false end
  return (use.damageDealt[p.id] or use.damageDealt[p] or 0) > 0
end

local function markKey(player)
  return "xy__jingqiang_" .. player.id
end

-- ========== 成为【杀】的目标时 ==========
jingqiang:addEffect(fk.TargetConfirming, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(jingqiang.name) or target.dead then return false end
    if data.card.trueName ~= "slash" then return false end
    return target == player or not target:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = jingqiang.name,
      prompt = target == player and "#xy__jingqiang-self" or ("#xy__jingqiang-other::" .. target.id),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    -- 在原本的【杀】的使用数据上记录：结算后检查是否对该角色造成了伤害
    -- 指定目标时仍处于该【杀】的使用流程中，直接取其使用数据
    -- 注意：FreeKill 在每个目标的结算后会用 data.extra_data 覆盖【杀】的 extra_data，
    -- 所以必须记录在 data.extra_data 上（并同步到【杀】的使用数据）。
    local use = data.use
    data.extra_data = data.extra_data or (use and use.extra_data) or {}
    local list = data.extra_data[markKey(player)] or {}
    table.insertIfNeed(list, target.id)
    data.extra_data[markKey(player)] = list
    if use then use.extra_data = data.extra_data end
    doJingqiang(player, target)
  end,
})

-- ========== 原本的【杀】结算完毕：若造成了伤害，展示其所有手牌 ==========
jingqiang:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead or data.card.trueName ~= "slash" then return false end
    local list = data.extra_data and data.extra_data[markKey(player)]
    if not list then return false end
    local room = player.room
    return table.find(list, function(pid)
      local p = room:getPlayerById(pid)
      return p and not p.dead and not p:isNude() and dealtDamageTo(data, p)
    end) ~= nil
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, pid in ipairs(data.extra_data[markKey(player)]) do
      local p = room:getPlayerById(pid)
      if p and not p.dead and not p:isNude() and dealtDamageTo(data, p) then
        -- 展示其所有牌（手牌和装备区；手牌被展示会触发"妮助"）
        room:showCards(p:getCardIds("he"), p)
      end
    end
  end,
})

-- ========== 受到伤害时 ==========
jingqiang:addEffect(fk.DamageInflicted, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(jingqiang.name) or target.dead then return false end
    return target == player or not target:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = jingqiang.name,
      prompt = target == player and "#xy__jingqiang-self" or ("#xy__jingqiang-other::" .. target.id),
    })
  end,
  on_use = function(self, event, target, player, data)
    doJingqiang(player, target)
  end,
})

return jingqiang

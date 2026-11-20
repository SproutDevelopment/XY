-- 卻決
-- 限定技，回合开始时，你可以选择一名角色，令所有角色的技能失效，令你和其以外的角色无法使用或打出或弃置牌，
-- 然后你和其弃置区域内所有牌。你将其体力上限调至你的体力上限，然后令你和其将体力调至体力上限。
-- 你/其回合结束时，其/你立即获得一个额外回合。以上效果持续到你或其死亡。

local quejue = fk.CreateSkill {
  name = "xy__quejue",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["xy__quejue"] = "却决",
  [":xy__quejue"] = "限定技，回合开始时，你可以选择一名角色，令所有角色的技能失效，令你和其以外的角色无法使用或打出或弃置牌，" ..
    "然后你和其弃置区域内所有牌。你将其体力上限调至你的体力上限，然后令你和其将体力调至体力上限。" ..
    "你/其回合结束时，其/你立即获得一个额外回合。以上效果持续到你或其死亡。",

  ["@@xy__quejue"] = "却决",
  ["#xy__quejue-choose"] = "却决：你可以选择一名角色，发动“却决”",
}

-- 标记：xy__quejue_partner = 对方的id（双方都有）；xy__quejue_owner = 1（发动者）
local PARTNER = "xy__quejue_partner"
local OWNER = "xy__quejue_owner"

local function inPair(p)
  return p:getMark(PARTNER) ~= 0
end

-- 是否有"却决"效果正在持续
local function active()
  local room = Fk:currentRoom()
  return table.find(room.alive_players, inPair) ~= nil
end

-- 是否被限制（你和其以外的角色）
local function restricted(player)
  return active() and not inPair(player)
end

-- ========== 回合开始时 ==========
quejue:addEffect(fk.TurnStart, {
  anim_type = "big",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(quejue.name) and
      player:usedSkillTimes(quejue.name, Player.HistoryGame) == 0 and
      #player.room:getOtherPlayers(player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player),
      min_num = 1,
      max_num = 1,
      prompt = "#xy__quejue-choose",
      skill_name = quejue.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]

    -- 开始持续效果（技能失效、其他角色不能用/打出/弃置牌）
    room:setPlayerMark(player, PARTNER, to.id)
    room:setPlayerMark(to, PARTNER, player.id)
    room:setPlayerMark(player, OWNER, 1)
    room:setPlayerMark(player, "@@xy__quejue", 1)
    room:setPlayerMark(to, "@@xy__quejue", 1)

    -- 你和其弃置区域内所有牌
    for _, p in ipairs({ player, to }) do
      if not p.dead and #p:getCardIds("hej") > 0 then
        p:throwAllCards("hej", quejue.name)
      end
    end

    -- 将其体力上限调至你的体力上限
    if not to.dead and to.maxHp ~= player.maxHp then
      room:changeMaxHp(to, player.maxHp - to.maxHp)
    end

    -- 你和其将体力调至体力上限
    for _, p in ipairs({ player, to }) do
      if not p.dead and p.hp ~= p.maxHp then
        room:changeHp(p, p.maxHp - p.hp, nil, quejue.name)
      end
    end
  end,
})

-- ========== 你/其回合结束时，其/你立即获得一个额外回合 ==========
quejue:addEffect(fk.TurnEnd, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if player:getMark(OWNER) == 0 or not inPair(player) then return false end
    local partner = player.room:getPlayerById(player:getMark(PARTNER))
    if not partner or partner.dead or player.dead then return false end
    return target == player or target == partner
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local partner = room:getPlayerById(player:getMark(PARTNER))
    local nextOne = target == player and partner or player
    -- 在本回合结束后立即进行（避免回合无限嵌套）
    nextOne:gainAnExtraTurn(true, quejue.name)
  end,
})

-- ========== 你或其死亡：效果结束 ==========
quejue:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player, data)
    if player:getMark(OWNER) == 0 then return false end
    return target == player or target.id == player:getMark(PARTNER)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local partner = room:getPlayerById(player:getMark(PARTNER))
    for _, p in ipairs({ player, partner }) do
      if p then
        room:setPlayerMark(p, PARTNER, 0)
        room:setPlayerMark(p, "@@xy__quejue", 0)
      end
    end
    room:setPlayerMark(player, OWNER, 0)
  end,
})

-- ========== 所有角色的技能失效（包括天堂久良罗自己；仅"却决"自身除外，以便持续效果生效） ==========
quejue:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    if not active() then return false end
    local skel = skill.getSkeleton and skill:getSkeleton()
    if skel and skel.name == quejue.name then return false end
    return skill:isPlayerSkill(from)
  end,
})

-- ========== 你和其以外的角色无法使用、打出或弃置牌 ==========
quejue:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return restricted(player)
  end,
  prohibit_response = function(self, player, card)
    return restricted(player)
  end,
  prohibit_discard = function(self, player, card)
    return restricted(player)
  end,
})

return quejue

-- 娉婷
-- 锁定技，每轮开始时或一名角色受到伤害后，你摸一张牌然后将一张牌作为"星舞"牌置于武将牌上；
-- 若你有"星舞"牌，你视为拥有"天香"和"流离"。

local pingting = fk.CreateSkill {
  name = "xy__pingting",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xy__pingting"] = "娉婷",
  [":xy__pingting"] = "锁定技，每轮开始时或一名角色受到伤害后，你摸一张牌然后将一张牌作为“星舞”牌置于武将牌上；" ..
    "若你有“星舞”牌，你视为拥有“天香”和“流离”。",

  ["xy__xingwu_pile"] = "星舞",
  ["#xy__pingting-put"] = "娉婷：将一张牌作为“星舞”牌置于武将牌上",
}

local PILE = "xy__xingwu_pile"
local EXTRA_SKILLS = { "tianxiang", "liuli" }

-- 摸一张牌，然后将一张牌置为"星舞"（星舞 也会调用这个函数）
XY_Erqiao = XY_Erqiao or {}
function XY_Erqiao.drawAndPut(player, skillName)
  local room = player.room
  player:drawCards(1, skillName)
  if player.dead or player:isNude() then return end
  local cards = room:askToCards(player, {
    min_num = 1,
    max_num = 1,
    include_equip = true,
    skill_name = skillName,
    prompt = "#xy__pingting-put",
    cancelable = false,
  })
  if #cards > 0 then
    player:addToPile(PILE, cards, true, skillName)
  end
end

-- 是否应当拥有 天香/流离
local function shouldHave(player)
  return player:hasSkill(pingting.name, true) and #player:getPile(PILE) > 0
end

-- 缺少的 天香/流离（已拥有的不重复获得）
local function missing(player)
  return table.filter(EXTRA_SKILLS, function(s)
    return Fk.skills[s] ~= nil and not player:hasSkill(s, true, true)
  end)
end

-- 当前拥有的 天香/流离（无论来源）
local function owned(player)
  return table.filter(EXTRA_SKILLS, function(s)
    return player:hasSkill(s, true, true)
  end)
end

-- 有"星舞"：获得缺少的 天香/流离；没有"星舞"：失去 天香/流离（无论来源）
local function sync(player)
  local room = player.room
  if shouldHave(player) then
    local toAdd = missing(player)
    if #toAdd > 0 then
      room:handleAddLoseSkills(player, table.concat(toAdd, "|"), nil, false, false)
    end
  else
    local toLose = owned(player)
    if #toLose > 0 then
      room:handleAddLoseSkills(player, "-" .. table.concat(toLose, "|-"), nil, false, false)
    end
  end
end

local function needSync(player)
  if not player:hasSkill(pingting.name, true) then return false end
  if shouldHave(player) then
    return #missing(player) > 0
  else
    return #owned(player) > 0
  end
end

-- ========== 每轮开始时 ==========
pingting:addEffect(fk.RoundStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(pingting.name)
  end,
  on_use = function(self, event, target, player, data)
    XY_Erqiao.drawAndPut(player, pingting.name)
  end,
})

-- ========== 一名角色受到伤害后 ==========
pingting:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(pingting.name)
  end,
  on_use = function(self, event, target, player, data)
    XY_Erqiao.drawAndPut(player, pingting.name)
  end,
})

-- ========== "星舞"牌变化时：同步 天香/流离 ==========
pingting:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return needSync(player)
  end,
  on_refresh = function(self, event, target, player, data)
    sync(player)
  end,
})

-- 获得其他技能时也检查（没有"星舞"时不能拥有 天香/流离）
pingting:addEffect(fk.EventAcquireSkill, {
  can_refresh = function(self, event, target, player, data)
    return target == player and needSync(player)
  end,
  on_refresh = function(self, event, target, player, data)
    sync(player)
  end,
})

-- 失去"娉婷"时也要失去 天香/流离
pingting:addEffect(fk.EventLoseSkill, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.skill and data.skill.name == pingting.name and #owned(player) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local toLose = owned(player)
    player.room:handleAddLoseSkills(player, "-" .. table.concat(toLose, "|-"), nil, false, false)
  end,
})

return pingting

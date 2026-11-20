-- 眾心（一心）
-- 每轮开始时，你展示拥有可以获得技能的技能的5张武将牌，然后你可以选择是否失去所有以此法获得的技能
-- 并获得该武将牌所有可以获得技能或必须该技能才可获取技能的技能。
--
-- 实现：
-- "可以获得技能的技能"：技能骨架声明了相关技能（related_skills），例如魂姿→英姿/英魂、化身等。
-- 从武将牌堆随机展示5张符合条件的武将牌，你选择其中一张并确认后：
--   失去之前以此法获得的所有技能，获得该武将牌上所有能获得技能的技能；
--   若该武将只在武将层面声明了相关技能（旧写法，无法分辨是哪个技能），则获得其所有技能。

local zhongxin = fk.CreateSkill {
  name = "xy__zhongxin",
}

Fk:loadTranslationTable{
  ["xy__zhongxin"] = "众心",
  [":xy__zhongxin"] = "每轮开始时，你展示拥有可以获得技能的技能的5张武将牌，然后你可以选择是否失去所有以此法获得的技能" ..
    "并获得该武将牌所有可以获得技能或必须该技能才可获取技能的技能。",

  ["#xy__zhongxin-choose"] = "众心：选择一张武将牌更换技能；选择“不更换”则取消",
  ["#xy__zhongxin-confirm"] = "众心：是否失去以此法获得的技能，并获得 %arg 的技能：%arg2？",
  ["$xy__zhongxin1"] = "「英秀」「幼羚」「家宝」「念慈」「思贤」「有容」「向华」「修端」「允行」「Chris Wong」「Mr Green」「Miss Wong」",
  ["$xy__zhongxin2"] = "大家嘅力量，我「一心」收到啦！！",
}

local GAINED = "xy__zhongxin_skills"

-- 选将规则：可以选择一张，也可以一张都不选直接确定（即取消，不更换技能）
if not Fk.choose_general_rule["xy__zhongxin_pick"] then
  Fk:addChooseGeneralRule{
    name = "xy__zhongxin_pick",
    card_filter = function(to_select, selected, data, extra_data)
      return #selected < 1
    end,
    feasible = function(selected, data, extra_data)
      return #selected <= 1
    end,
    prompt = function(data, extra_data)
      return Fk:translate("#xy__zhongxin-choose")
    end,
    default_choice = function(data, extra_data)
      return {}
    end,
  }
end

-- 一个“相关技能”是否为真正可获得的技能（排除模式技能、附加按钮技能“xxx&”、隐藏效果“#xxx”）
local function realSkill(name)
  if type(name) ~= "string" or name:startsWith("#") or name:endsWith("&") then return false end
  local sk = Fk.skills[name]
  if not sk then return false end
  if sk.visible == false then return false end
  local skel = Fk.skill_skels[name]
  if skel and skel.mode_skill then return false end
  return true
end

local function desc(name)
  return Fk:translate(":" .. name)
end

-- 描述中被引号括起来的词（标记名、技能名等）：“X” 「X」 "X"
local function quotedTerms(text)
  local ret = {}
  for _, pat in ipairs({ "“(.-)”", "「(.-)」", '"(.-)"' }) do
    for w in text:gmatch(pat) do
      if #w > 0 and #w <= 18 then table.insertIfNeed(ret, w) end
    end
  end
  return ret
end

-- 两个技能是否相互依赖：一方描述提到另一方的技能名，或两者描述共用同一个引号词（如同名标记）
local function linked(a, b)
  local da, db = desc(a), desc(b)
  local na, nb = Fk:translate(a), Fk:translate(b)
  if da:find(nb, 1, true) or db:find(na, 1, true) then return true end
  local ta = quotedTerms(da)
  for _, w in ipairs(quotedTerms(db)) do
    if table.contains(ta, w) then return true end
  end
  return false
end

-- 该武将牌上"可以获得技能的技能"，以及它们依赖的同将技能（提供所需标记/作为获得条件的技能）
local function acquireSkills(general)
  local own = general:getSkillNameList()
  local ret = {}
  for _, name in ipairs(own) do
    local skel = Fk.skill_skels[name]
    if skel and skel.related_skills and table.find(skel.related_skills, realSkill) then
      table.insertIfNeed(ret, name)
    end
  end
  if #ret == 0 then
    -- 旧写法：只在武将上声明了相关技能，找出描述里提到这些相关技能的技能
    local rel = {}
    for _, s in ipairs(general.related_skills or {}) do
      local n = type(s) == "table" and s.name or s
      if realSkill(n) and not table.contains(own, n) then table.insertIfNeed(rel, n) end
    end
    for _, n in ipairs(general.related_other_skills or {}) do
      if realSkill(n) and not table.contains(own, n) then table.insertIfNeed(rel, n) end
    end
    for _, name in ipairs(own) do
      local d = desc(name)
      if table.find(rel, function(r) return d:find(Fk:translate(r), 1, true) ~= nil end) then
        table.insertIfNeed(ret, name)
      end
    end
  end
  if #ret == 0 then return ret end
  -- 加入依赖的同将技能（反复检查，直到不再增加）
  local changed = true
  while changed do
    changed = false
    for _, name in ipairs(own) do
      if not table.contains(ret, name) and realSkill(name) and
        table.find(ret, function(r) return linked(r, name) end) then
        table.insert(ret, name)
        changed = true
      end
    end
  end
  return ret
end

zhongxin:addEffect(fk.RoundStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhongxin.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local candidates = table.filter(room.general_pile, function(name)
      local g = Fk.generals[name]
      return g ~= nil and #acquireSkills(g) > 0
    end)
    if #candidates == 0 then return end
    local shown = table.random(candidates, math.min(5, #candidates))

    -- 展示5张武将牌并选择一张
    local list = table.simpleClone(shown)
    table.insert(list, "xy__zhongxin_cancel")   -- “不更换”卡：选它等于取消
    local chosen = room:askToChooseGeneral(player, {
      generals = list,
      n = 1,
      no_convert = true,
      rule = "xy__zhongxin_pick",
      extra_data = { skillName = zhongxin.name },
    })
    if type(chosen) == "table" then chosen = chosen[1] end
    if not chosen or chosen == "xy__zhongxin_cancel" or not Fk.generals[chosen] then return end

    local skills = acquireSkills(Fk.generals[chosen])
    local skillText = table.concat(table.map(skills, function(s) return Fk:translate(s) end), "、")

    -- 失去所有以此法获得的技能
    local old = player:getTableMark(GAINED)
    if #old > 0 then
      room:handleAddLoseSkills(player, "-" .. table.concat(old, "|-"), nil, true, false)
    end
    -- 获得该武将牌的技能（已拥有的不重复获得，也不记录）
    local toGain = table.filter(skills, function(s)
      return not player:hasSkill(s, true, true)
    end)
    room:setPlayerMark(player, GAINED, #toGain > 0 and toGain or 0)
    if #toGain > 0 then
      room:handleAddLoseSkills(player, table.concat(toGain, "|"), nil, true, false)
    end
  end,
})

return zhongxin

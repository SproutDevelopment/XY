-- 邀雄（董白）
-- 回合开始时，你随机获得一张武将牌，获得其所有技能。你本回合每技能限一次，你可以无视技能发动条件发动该技能，
-- 如技能描述里有无法被定义的目标，你可以自行指定之。如你获得的武将牌为女，你加一点体力上限，放置其于你的武将牌上，
-- 称为"妻子"。回合结束时，你失去所有"邀雄"获得的技能。
--
-- 说明：“无视技能发动条件发动”实现为出牌阶段的“邀雄”按钮，详见下方。
-- “使用次数”：每有一次额外次数（来自“护妻”），回合开始时多获得一张武将牌。

local yaoxiong = fk.CreateSkill {
  name = "xy__yaoxiong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xy__yaoxiong"] = "邀雄",
  [":xy__yaoxiong"] = "回合开始时，你随机获得一张武将牌，获得其所有技能。你本回合每技能限一次，你可以无视技能发动条件发动该技能，" ..
    "如技能描述里有无法被定义的目标，你可以自行指定之。如你获得的武将牌为女，你加一点体力上限，放置其于你的武将牌上，" ..
    "称为“妻子”。回合结束时，你失去所有“邀雄”获得的技能。",
  ["@&xy__dongbai_wives"] = "妻子",
  ["#xy__yaoxiong-log"] = "%from 发动“邀雄”，获得了武将牌 %arg",
  ["#xy__yaoxiong-active"] = "邀雄：先选择一个技能，无视发动条件发动（通过邀雄每个技能每回合限一次）；若技能涉及另一名角色，再选择该角色",
  ["#xy__yaoxiong-use"] = "邀雄：发动 %arg",
  ["#xy__yaoxiong-pick"] = "邀雄：选择要发动的技能（无视发动条件）",
  ["#xy__yaoxiong-person"] = "邀雄：选择 %arg 中涉及的另一名角色",
  ["#xy__yaoxiong-fire"] = "%from 通过“邀雄”发动了 %arg",
  ["#xy__yaoxiong-fail"] = "%arg 无法在此时发动，已跳过",
}

XY_Dongbai = XY_Dongbai or {}
XY_Dongbai.WIVES = "@&xy__dongbai_wives"
XY_Dongbai.TEMP = "xy__yaoxiong_skills"     -- 本回合由邀雄获得、回合结束时失去的技能
XY_Dongbai.EXTRA = "@xy__huqi_extra"        -- 护妻：下回合邀雄额外次数

yaoxiong:addEffect(fk.TurnStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yaoxiong.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local times = 1 + player:getMark(XY_Dongbai.EXTRA)
    room:setPlayerMark(player, XY_Dongbai.EXTRA, 0)
    for _ = 1, times do
      if player.dead then return end
      local got = room:findGenerals(function(name)
        return Fk.generals[name] ~= nil
      end, 1)
      if #got == 0 then return end
      local name = got[1]
      local general = Fk.generals[name]
      room:sendLog{ type = "#xy__yaoxiong-log", from = player.id, arg = name, toast = true }

      local skills = table.filter(general:getSkillNameList(true), function(s)
        return not player:hasSkill(s, true, true)
      end)
      if #skills > 0 then
        local temp = player:getTableMark(XY_Dongbai.TEMP)
        table.insertTableIfNeed(temp, skills)
        room:setPlayerMark(player, XY_Dongbai.TEMP, temp)
        room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
      end

      if general.gender == General.Female then
        room:changeMaxHp(player, 1)
        room:addTableMark(player, XY_Dongbai.WIVES, name)   -- 妻子留在武将牌上
      else
        room:returnToGeneralPile({ name })
      end
    end
  end,
})

yaoxiong:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and #player:getTableMark(XY_Dongbai.TEMP) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "xy__yaoxiong_used", 0)
    local temp = player:getTableMark(XY_Dongbai.TEMP)
    room:setPlayerMark(player, XY_Dongbai.TEMP, 0)
    room:handleAddLoseSkills(player, "-" .. table.concat(temp, "|-"), nil, true, false)
  end,
})

-- 出牌阶段：选择一个“邀雄”获得的技能（触发技、主动技、转化技均可），无视发动条件发动之。
-- 通过此按钮，每个技能每回合限一次；此次数与技能平时的使用次数分开计算（例如【制衡】可以平时用一次，再通过邀雄用一次）。
-- 先选择技能；若该触发技的时机涉及另一名角色（如伤害来源/伤害目标），则必须再选择一名角色。
XY_Dongbai.USED = "xy__yaoxiong_used"

-- 返回技能的主要效果及其类型："trigger" / "active" / "viewas"
local function mainEffect(name)
  local skel = Fk.skill_skels[name]
  if not skel then return nil end
  local trig
  for _, eff in ipairs(skel.effects) do
    if eff:isInstanceOf(ActiveSkill) then return eff, "active" end
    if eff:isInstanceOf(ViewAsSkill) then return eff, "viewas" end
    if not trig and eff:isInstanceOf(TriggerSkill) and not eff.is_delay_effect and eff.event then
      trig = eff
    end
  end
  if trig then return trig, "trigger" end
end

-- 触发技的时机是否涉及“另一名角色”，以及你在其中的身份
-- 返回 "victim"（你是受害/被指定方，选择的角色为来源）、"source"（你是来源，选择的角色为目标）、
-- "other"（技能读取了来源/目标等角色数据，但身份不明）或 nil（不涉及他人）
local VICTIM = { "Damaged", "DamageInflicted", "DetermineDamageInflicted", "TargetConfirming", "TargetConfirmed",
  "HpLost", "PreHpLost" }
local SOURCE = { "Damage", "DamageCaused", "DetermineDamageCaused", "DamageFinished", "TargetSpecifying",
  "TargetSpecified", "CardUsing", "CardUseFinished", "CardResponding", "CardEffectCancelledOut",
  "PindianResultConfirmed", "PindianFinished" }
local PERSON_KEYS = { from = true, to = true, tos = true, proposer = true, killer = true, damage = false,
  responseToEvent = true, toCard = false }

local function eventIn(ev, list)
  for _, n in ipairs(list) do
    if fk[n] and ev == fk[n] then return true end
  end
  return false
end

local function personRole(eff, player)
  local ev = eff.event
  if eventIn(ev, VICTIM) then return "victim" end
  if eventIn(ev, SOURCE) then return "source" end
  -- 试探：看技能的发动条件会不会读取“来源/目标”等角色数据
  local touched = false
  local spec = setmetatable({}, { __index = function(_, k)
    if PERSON_KEYS[k] then touched = true end
    if k == "who" then return player end
    return nil
  end })
  pcall(function()
    local data = TriggerData:new(spec)
    local e = ev:new(player.room, player, data)
    eff:triggerable(e, player, player, data)
  end)
  if touched then return "other" end
  return nil
end

-- 生成假的时机数据（尽量使用对应的数据类型，使技能里的方法调用可用）
local function makeFakeData(eff, player, from, to)
  local spec = {
    who = player, target = player,
    from = from, to = to, tos = { to },
    proposer = from, killer = from,
    num = 1, damage = 1, damageType = fk.NormalDamage,
    card = Fk:cloneCard("slash"), phase = Player.Play,
    extra_data = {},
  }
  local ev = eff.event
  local cls
  if eventIn(ev, { "Damage", "Damaged", "DamageCaused", "DamageInflicted", "DetermineDamageCaused",
    "DetermineDamageInflicted", "DamageFinished", "PreDamage" }) then
    cls = rawget(_G, "DamageData")
  elseif eventIn(ev, { "HpLost", "PreHpLost" }) then
    cls = rawget(_G, "HpLostData")
  elseif eventIn(ev, { "CardUsing", "CardUseFinished", "PreCardUse", "AfterCardUseDeclared",
    "AfterCardTargetDeclared" }) then
    cls = rawget(_G, "UseCardData")
  end
  if cls then
    local ok, d = pcall(function() return cls:new(spec) end)
    if ok and d then return d end
  end
  return spec
end

local function choicesFor(player)
  local used = player:getTableMark(XY_Dongbai.USED)
  return table.filter(player:getTableMark(XY_Dongbai.TEMP), function(name)
    return not table.contains(used, name) and player:hasSkill(name, true) and mainEffect(name) ~= nil
  end)
end

-- 记录/还原使用次数，使邀雄的发动不占用技能平时的次数
local function snapshot(player, keys)
  local ret = {}
  for _, k in ipairs(keys) do
    ret[k] = player.skillUsedHistory[k] and player.skillUsedHistory[k][Player.HistoryGame] or 0
  end
  return ret
end
local function restore(player, before)
  for k, n in pairs(before) do
    local now = player.skillUsedHistory[k] and player.skillUsedHistory[k][Player.HistoryGame] or 0
    if now > n then player:addSkillUseHistory(k, n - now) end
  end
end

yaoxiong:addEffect("active", {
  anim_type = "special",
  prompt = "#xy__yaoxiong-active",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return #choicesFor(player) > 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    -- 第一步：选择技能
    local choices = choicesFor(player)
    if #choices == 0 then return end
    local all = table.simpleClone(choices)
    table.insert(all, "Cancel")
    local name = room:askToChoice(player, {
      choices = all,
      skill_name = yaoxiong.name,
      prompt = "#xy__yaoxiong-pick",
    })
    if not name or name == "Cancel" then return end
    local eff, kind = mainEffect(name)
    if not eff then return end

    -- 第二步：若该技能涉及未被定义的另一名角色，必须选择一名角色
    local other, role = player, nil
    if kind == "trigger" then
      role = personRole(eff, player)
      if role then
        local tos = room:askToChoosePlayers(player, {
          targets = room:getOtherPlayers(player, false),
          min_num = 1,
          max_num = 1,
          skill_name = yaoxiong.name,
          prompt = "#xy__yaoxiong-person:::" .. name,
          cancelable = false,
        })
        other = tos[1] or player
      end
    end

    room:addTableMark(player, XY_Dongbai.USED, name)
    room:sendLog{ type = "#xy__yaoxiong-fire", from = player.id, arg = name }
    local before = snapshot(player, { name, eff.name, "#" .. name .. "_main_skill" })

    local ok, cancelled = true, false
    if kind == "trigger" then
      local from, to = other, other
      if role == "victim" then from, to = other, player
      elseif role == "source" then from, to = player, other end
      local fakeData = makeFakeData(eff, player, from, to)
      local err
      ok, err = pcall(function()
        local ev = eff.event:new(room, player, fakeData)
        eff:trigger(ev, player, player, fakeData)
      end)
      if not ok then fk.qWarning("[xy__yaoxiong] " .. name .. ": " .. tostring(err)) end
    elseif kind == "active" then
      -- 主动技：直接弹出该技能的操作（不检查其使用次数/条件）
      ok = pcall(function()
        cancelled = not room:askToUseActiveSkill(player, {
          skill_name = eff.name,
          prompt = "#xy__yaoxiong-use:::" .. name,
          cancelable = true,
        })
      end)
    else
      -- 转化技：选择转化用的牌和目标，然后使用转化出的牌
      ok = pcall(function()
        local success, ret = room:askToUseActiveSkill(player, {
          skill_name = eff.name,
          prompt = "#xy__yaoxiong-use:::" .. name,
          cancelable = true,
          skip = true,
        })
        cancelled = not success
        if success and ret then
          local c = eff:viewAs(player, ret.cards or {})
          if c then
            room:useCard{
              from = player,
              tos = ret.targets or {},
              card = c,
              extraUse = true,
            }
          end
        end
      end)
    end

    restore(player, before)
    if ok and cancelled then
      -- 取消了：不算作通过邀雄使用过
      room:removeTableMark(player, XY_Dongbai.USED, name)
      return
    end
    if not ok then
      room:sendLog{ type = "#xy__yaoxiong-fail", from = player.id, arg = name, toast = true }
    end
  end,
})

return yaoxiong

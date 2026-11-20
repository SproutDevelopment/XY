-- 彩才
-- 你进入濒死状态时，你可以令一名角色所有技能本回合失效。
-- 一名角色的技能失效或失去时，你可以获得其中任意项。
-- 你进入濒死状态时，你可以删除"时划"中一个时机并恢复1点体力。
-- （若你获得重复技能则你改为取代之）

local caicai = fk.CreateSkill {
  name = "xy__caicai",
}

Fk:loadTranslationTable{
  ["xy__caicai"] = "彩才",
  [":xy__caicai"] = "你进入濒死状态时，你可以令一名角色所有技能本回合失效。" ..
    "一名角色的技能失效或失去时，你可以获得其中任意项。" ..
    "你进入濒死状态时，你可以删除“时划”中一个时机并恢复1点体力。" ..
    "（若你获得重复技能则你改为取代之）",

  ["@@xy__caicai_invalid-turn"] = "彩才 技能失效",
  ["#xy__caicai-invalid"] = "彩才：你可以令一名角色所有技能本回合失效",
  ["#xy__caicai-gain"] = "彩才：你可以获得 %dest 的任意个技能",
  ["#xy__caicai-gain_lost"] = "彩才：你可以获得 %dest 失去的技能",
  ["#xy__caicai-shihua"] = "彩才：你可以删除“时划”中一个时机并回复1点体力",
}

-- 获取一名角色的（可见）技能名
local function skillNames(p)
  if p.getSkillNameList then
    return table.filter(p:getSkillNameList(), function(name)
      return not name:startsWith("#")
    end)
  end
  local names = {}
  for _, s in ipairs(p.player_skills) do
    if not s.name:startsWith("#") then
      table.insertIfNeed(names, s.name)
    end
  end
  return names
end

-- 获得技能；若你已拥有该技能，改为"取代之"：令原角色失去该技能
local function gainSkills(player, from, names)
  local room = player.room
  local toGain, toTake = {}, {}
  for _, name in ipairs(names) do
    if player:hasSkill(name, true, true) then
      table.insert(toTake, name)
    else
      table.insert(toGain, name)
    end
  end
  if #toGain > 0 then
    room:handleAddLoseSkills(player, table.concat(toGain, "|"), nil, true, false)
  end
  if #toTake > 0 and from and from ~= player and not from.dead then
    room:handleAddLoseSkills(from, "-" .. table.concat(toTake, "|-"), nil, true, false)
  end
end

local function askGain(player, from, names, prompt)
  local room = player.room
  if #names == 0 or player.dead then return end
  local chosen = room:askToChoices(player, {
    choices = names,
    min_num = 0,
    max_num = #names,
    skill_name = caicai.name,
    prompt = prompt,
    cancelable = true,
  })
  if chosen and #chosen > 0 then
    gainSkills(player, from, chosen)
  end
end

-- ========== 失效技能检测 ==========
-- 记录其他角色当前处于失效状态的技能，格式为 "角色id:技能名"
local SNAPSHOT = "xy__caicai_invalid_snapshot"

local function currentInvalid(player)
  local list = {}
  for _, p in ipairs(player.room.alive_players) do
    if p ~= player then
      for _, name in ipairs(skillNames(p)) do
        -- 拥有该技能，但它现在不生效
        if not p:hasSkill(name) then
          table.insert(list, p.id .. ":" .. name)
        end
      end
    end
  end
  return list
end

local function sameSet(a, b)
  if #a ~= #b then return false end
  for _, v in ipairs(a) do
    if not table.contains(b, v) then return false end
  end
  return true
end

-- 更新记录，并返回新失效的技能：{ [角色id] = {技能名, ...} }
local function refreshSnapshot(player)
  local room = player.room
  local old = player:getTableMark(SNAPSHOT)
  local now = currentInvalid(player)
  room:setPlayerMark(player, SNAPSHOT, #now > 0 and now or 0)
  local newOnes = {}
  for _, entry in ipairs(now) do
    if not table.contains(old, entry) then
      local pid, name = entry:match("^(%d+):(.+)$")
      pid = tonumber(pid)
      if pid then
        newOnes[pid] = newOnes[pid] or {}
        table.insert(newOnes[pid], name)
      end
    end
  end
  return newOnes
end

-- 任意技能发动结算后：检查是否有新的失效技能，若有则可以获得其中任意项
caicai:addEffect(fk.AfterSkillEffect, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(caicai.name) then return false end
    -- 失效状态有任何变化（新失效或恢复）都需要更新记录
    return not sameSet(player:getTableMark(SNAPSHOT), currentInvalid(player))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local newOnes = refreshSnapshot(player)
    for _, p in ipairs(room:getAlivePlayers()) do
      local names = newOnes[p.id]
      if names and #names > 0 and not player.dead then
        askGain(player, p, names, "#xy__caicai-gain::" .. p.id)
      end
    end
  end,
})

-- ========== 进入濒死：令一名角色所有技能本回合失效（然后可以获得其中任意项） ==========
caicai:addEffect(fk.EnterDying, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(caicai.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#xy__caicai-invalid",
      skill_name = caicai.name,
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
    room:setPlayerMark(to, "@@xy__caicai_invalid-turn", 1)
    -- 先更新失效记录，避免之后的检测再询问一次同样的技能
    refreshSnapshot(player)
    -- 技能失效时，你可以获得其中任意项
    askGain(player, to, skillNames(to), "#xy__caicai-gain::" .. to.id)
  end,
})

-- 技能失效效果
caicai:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return from:getMark("@@xy__caicai_invalid-turn") > 0 and skill:isPlayerSkill(from)
  end,
})

-- ========== 一名角色失去技能时：你可以获得之 ==========
caicai:addEffect(fk.EventLoseSkill, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    -- 包括你自己失去技能（可以重新获得）
    if not player:hasSkill(caicai.name, true) then return false end
    local skill = data.skill
    if not skill then return false end
    local name = skill.name
    return name and not name:startsWith("#") and not name:endsWith("&")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    askGain(player, target, { data.skill.name }, "#xy__caicai-gain_lost::" .. target.id)
  end,
})

-- ========== 进入濒死：删除"时划"中一个时机并回复1点体力 ==========
caicai:addEffect(fk.EnterDying, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(caicai.name) then return false end
    return #player:getTableMark("xy__shihua_removed") < 3
  end,
  on_cost = function(self, event, target, player, data)
    local all = { "xy__shihua_round_start", "xy__shihua_round_end", "xy__shihua_skip" }
    local choices = table.filter(all, function(t)
      return not table.contains(player:getTableMark("xy__shihua_removed"), t)
    end)
    table.insert(choices, "Cancel")
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = caicai.name,
      prompt = "#xy__caicai-shihua",
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    room:addTableMark(player, "xy__shihua_removed", choice)
    room:setPlayerMark(player, "@xy__shihua_removed", #player:getTableMark("xy__shihua_removed"))
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = caicai.name,
      }
    end
  end,
})

return caicai

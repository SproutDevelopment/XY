-- 時劃
-- 你可以在以下时机获得一个额外回合：1.每轮开始时，2.每轮结束时，3.你的阶段或回合被跳过时。
-- （"彩才"可以删除其中的时机，被删除的时机记录在 xy__shihua_removed 中）

local shihua = fk.CreateSkill {
  name = "xy__shihua",
}

Fk:loadTranslationTable{
  ["xy__shihua"] = "时划",
  [":xy__shihua"] = "你可以在以下时机获得一个额外回合：1.每轮开始时，2.每轮结束时，3.你的阶段或回合被跳过时。",

  ["xy__shihua_round_start"] = "每轮开始时",
  ["xy__shihua_round_end"] = "每轮结束时",
  ["xy__shihua_skip"] = "阶段或回合被跳过时",
  ["@xy__shihua_removed"] = "时划已删",

  ["#xy__shihua-invoke"] = "时划：你可以获得一个额外回合",

  ["$xy__shihua1"] = "私、かぐやとの思い出を胸に、前に進むよ！",
}

-- 该时机是否已被"彩才"删除
local function removed(player, timing)
  return table.contains(player:getTableMark("xy__shihua_removed"), timing)
end

local function askInvoke(player)
  return player.room:askToSkillInvoke(player, {
    skill_name = shihua.name,
    prompt = "#xy__shihua-invoke",
  })
end

-- 1. 每轮开始时
shihua:addEffect(fk.RoundStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shihua.name) and not removed(player, "xy__shihua_round_start")
  end,
  on_cost = function(self, event, target, player, data)
    return askInvoke(player)
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraTurn(false, shihua.name)
  end,
})

-- 2. 每轮结束时
shihua:addEffect(fk.RoundEnd, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shihua.name) and not removed(player, "xy__shihua_round_end")
  end,
  on_cost = function(self, event, target, player, data)
    return askInvoke(player)
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraTurn(false, shihua.name)
  end,
})

-- 3a. 你的阶段被跳过时
shihua:addEffect(fk.EventPhaseSkipped, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shihua.name) and
      not removed(player, "xy__shihua_skip")
  end,
  on_cost = function(self, event, target, player, data)
    return askInvoke(player)
  end,
  on_use = function(self, event, target, player, data)
    -- 在当前回合结束后进行
    player:gainAnExtraTurn(true, shihua.name)
  end,
})

-- 3b. 你的回合被跳过时（武将牌背面朝上导致跳过回合）
-- 新月杀没有专门的"回合被跳过"时机：背面朝上的角色会在回合开始前翻回正面并跳过该回合，
-- 所以这里在回合开始前检查是否背面朝上。
shihua:addEffect(fk.BeforeTurnStart, {
  anim_type = "special",
  priority = 0.1,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shihua.name) and
      not player.faceup and not removed(player, "xy__shihua_skip")
  end,
  on_cost = function(self, event, target, player, data)
    return askInvoke(player)
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraTurn(true, shihua.name)
  end,
})

return shihua

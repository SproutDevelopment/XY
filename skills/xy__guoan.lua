-- 國安
-- 出牌阶段各限一次或你造成伤害时，你可以将伤害来源改为一名其他角色，
-- 且可以发动你声明伤害来源或受伤角色的一次受伤或濒死的"公审"；
-- 一名角色的回合结束时，若本回合"公审"的判定结果均为红/黑，你可以令一名角色恢复/失去一点体力。
--
-- 实现方式（暂定理解）：
-- 1) 出牌阶段：受伤版、濒死版"公审"各限一次。你声明一名受伤角色和一名伤害来源，然后结算对应版本的"公审"。
-- 2) 你造成伤害时：你可以将伤害来源改为一名其他角色，然后可以以本次伤害的来源和受伤角色发动一次受伤或濒死的"公审"。
-- 3) 任意角色回合结束时：若本回合有"公审"判定且结果全红/全黑，你可以令一名角色回复/失去1点体力。

local guoan = fk.CreateSkill {
  name = "xy__guoan",
}

Fk:loadTranslationTable{
  ["xy__guoan"] = "国安",
  [":xy__guoan"] = "出牌阶段各限一次或你造成伤害时，你可以将伤害来源改为一名其他角色，" ..
    "且可以发动你声明伤害来源或受伤角色的一次受伤或濒死的“公审”；" ..
    "一名角色的回合结束时，若本回合“公审”的判定结果均为红/黑，你可以令一名角色恢复/失去一点体力。",

  ["$xy__guoan1"] = "□□□□，□□□□！",

  ["xy__guoan_damage"] = "受伤的公审",
  ["xy__guoan_dying"] = "濒死的公审",
  ["xy__guoan_none"] = "不发动",

  ["#xy__guoan-active"] = "国安：声明一名角色与伤害来源，发动一次“公审”",
  ["#xy__guoan-mode"] = "国安：选择要发动的“公审”",
  ["#xy__guoan-victim"] = "国安：声明受伤（濒死）的角色",
  ["#xy__guoan-source"] = "国安：声明伤害来源",
  ["#xy__guoan-change"] = "国安：你可以将伤害来源改为一名其他角色",
  ["#xy__guoan-recover"] = "国安：本回合“公审”判定均为红色，你可以令一名角色回复1点体力",
  ["#xy__guoan-lose"] = "国安：本回合“公审”判定均为黑色，你可以令一名角色失去1点体力",
}

local function availableModes(player)
  local modes = {}
  if player:getMark("xy__guoan_damage-phase") == 0 then
    table.insert(modes, "xy__guoan_damage")
  end
  if player:getMark("xy__guoan_dying-phase") == 0 then
    table.insert(modes, "xy__guoan_dying")
  end
  return modes
end

-- ========== 1) 出牌阶段：受伤/濒死"公审"各限一次 ==========
guoan:addEffect("active", {
  anim_type = "control",
  prompt = "#xy__guoan-active",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return #availableModes(player) > 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local modes = availableModes(player)
    local choice = room:askToChoice(player, {
      choices = modes,
      skill_name = guoan.name,
      prompt = "#xy__guoan-mode",
    })
    room:setPlayerMark(player, choice .. "-phase", 1)

    local victim = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#xy__guoan-victim",
      skill_name = guoan.name,
      cancelable = false,
    })[1]
    local source = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#xy__guoan-source",
      skill_name = guoan.name,
      cancelable = false,
    })[1]

    local mode = choice == "xy__guoan_damage" and "damage" or "dying"
    XY_GongshenV2.resolve(player, mode, victim, source, 0)
  end,
})

-- ========== 2) 你造成伤害时 ==========
guoan:addEffect(fk.DamageCaused, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guoan.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = guoan.name })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local tos = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player),
      min_num = 1,
      max_num = 1,
      prompt = "#xy__guoan-change",
      skill_name = guoan.name,
      cancelable = true,
    })
    if #tos > 0 then
      data.from = tos[1]
    end

    local choice = room:askToChoice(player, {
      choices = { "xy__guoan_damage", "xy__guoan_dying", "xy__guoan_none" },
      skill_name = guoan.name,
      prompt = "#xy__guoan-mode",
    })
    if choice ~= "xy__guoan_none" then
      -- 你声明受伤角色和伤害来源
      local victim = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 1,
        prompt = "#xy__guoan-victim",
        skill_name = guoan.name,
        cancelable = false,
      })[1]
      local source = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 1,
        prompt = "#xy__guoan-source",
        skill_name = guoan.name,
        cancelable = false,
      })[1]
      if victim then
        local mode = choice == "xy__guoan_damage" and "damage" or "dying"
        XY_GongshenV2.resolve(player, mode, victim, source, data.damage)
      end
    end
  end,
})

-- ========== 3) 一名角色的回合结束时 ==========
guoan:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(guoan.name) then return false end
    local colors = player:getTableMark("xy__gongshen2_colors-turn")
    if #colors == 0 then return false end
    return table.every(colors, function(c) return c == Card.Red end) or
      table.every(colors, function(c) return c == Card.Black end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local colors = player:getTableMark("xy__gongshen2_colors-turn")
    local isRed = colors[1] == Card.Red
    local targets = isRed and table.filter(room.alive_players, function(p)
      return p:isWounded()
    end) or room.alive_players
    if #targets == 0 then return false end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = isRed and "#xy__guoan-recover" or "#xy__guoan-lose",
      skill_name = guoan.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos, red = isRed })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    local to = cost.tos[1]
    if cost.red then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = guoan.name,
      }
    else
      room:loseHp(to, 1, guoan.name)
    end
  end,
})

return guoan

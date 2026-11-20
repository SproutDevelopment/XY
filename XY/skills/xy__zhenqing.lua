-- 真情（野俊&香織）
-- 使命技，回合开始或受到一点伤害时，你令一名其他角色选择一项：
-- 1.交给你其所有手牌；2.失去1点体力且令其体力上限调整至其体力值；3.你展示其所有手牌。
-- （其无法选择本轮被一名角色选择过的选项）
-- 成功：回合结束时，若你本局游戏曾以此法展示一名角色的所有手牌，你令自己展示所有手牌，
-- 然后其他角色选择展示自己手牌或交给你一张牌，你获得"利友"。
-- 失败：你第七回合结束时，你的使命未完成，你死亡。

local zhenqing = fk.CreateSkill {
  name = "xy__zhenqing",
  tags = { Skill.Quest },
}

Fk:loadTranslationTable{
  ["xy__zhenqing"] = "真情",
  [":xy__zhenqing"] = "使命技，回合开始或受到一点伤害时，你令一名其他角色选择一项：1.交给你其所有手牌；" ..
    "2.失去1点体力且令其体力上限调整至其体力值；3.你展示其所有手牌。（其无法选择本轮被一名角色选择过的选项）<br>" ..
    "成功：回合结束时，若你本局游戏曾以此法展示一名角色的所有手牌，你令自己展示所有手牌，" ..
    "然后其他角色选择展示自己手牌或交给你一张牌，你获得“利友”。<br>" ..
    "失败：你第七回合结束时，你的使命未完成，你死亡。",

  ["xy__zhenqing_give"] = "交给其所有手牌",
  ["xy__zhenqing_hp"] = "失去1点体力，体力上限调整至体力值",
  ["xy__zhenqing_show"] = "其展示你的所有手牌",
  ["xy__zhenqing_showself"] = "展示自己的手牌",
  ["xy__zhenqing_givecard"] = "交给其一张牌",
  ["#xy__zhenqing-choose"] = "真情：令一名其他角色选择一项",
  ["#xy__zhenqing-choice"] = "真情：%src 令你选择一项",
  ["#xy__zhenqing-success"] = "真情：%src 的使命成功，请选择一项",
  ["#xy__zhenqing-give"] = "真情：交给 %src 一张牌",
  ["@xy__zhenqing_turns"] = "真情回合",
  ["@@xy__zhenqing_shown"] = "真情可成功",
  ["#xy__zhenqing-ready"] = "%from 的“真情”已展示一名角色的所有手牌，回合结束时使命成功",
  ["#xy__zhenqing-succeed"] = "%from 的“真情”使命成功，获得“利友”",
}

local OPTIONS = { "xy__zhenqing_give", "xy__zhenqing_hp", "xy__zhenqing_show" }
local CHOSEN = "xy__zhenqing_chosen-round"   -- 本轮被选择过的选项
local SHOWN = "xy__zhenqing_shown"           -- 曾以此法展示过一名角色的所有手牌
local DONE = "xy__zhenqing_done"             -- 使命已完成或失败
local TURNS = "@xy__zhenqing_turns"          -- 你已开始的回合数

local function active(player)
  return player:hasSkill(zhenqing.name) and player:getMark(DONE) == 0
end

local function doZhenqing(player)
  local room = player.room
  local others = room:getOtherPlayers(player)
  if #others == 0 then return end
  local function available(p)
    return table.filter(OPTIONS, function(o)
      if table.contains(player:getTableMark(CHOSEN), o) then return false end
      -- 交给你所有手牌 / 展示所有手牌：至少要有1张手牌
      if (o == "xy__zhenqing_give" or o == "xy__zhenqing_show") and p:isKongcheng() then return false end
      return true
    end)
  end
  local targets = table.filter(others, function(p) return #available(p) > 0 end)
  if #targets == 0 then return end

  local to = room:askToChoosePlayers(player, {
    targets = targets,
    min_num = 1,
    max_num = 1,
    prompt = "#xy__zhenqing-choose",
    skill_name = zhenqing.name,
    cancelable = false,
  })[1]
  if not to then return end
  local choices = available(to)
  if #choices == 0 then return end

  local choice = room:askToChoice(to, {
    choices = choices,
    skill_name = zhenqing.name,
    prompt = "#xy__zhenqing-choice:" .. player.id,
  })
  room:addTableMark(player, CHOSEN, choice)

  if choice == "xy__zhenqing_give" then
    if not to:isKongcheng() then
      room:obtainCard(player, to:getCardIds("h"), false, fk.ReasonGive, to, zhenqing.name)
    end
  elseif choice == "xy__zhenqing_hp" then
    room:loseHp(to, 1, zhenqing.name)
    if not to.dead and to.hp > 0 and to.maxHp > to.hp then
      room:changeMaxHp(to, to.hp - to.maxHp)
    end
  else
    if not to:isKongcheng() then
      -- 先记录，再展示
      room:setPlayerMark(player, SHOWN, 1)
      room:setPlayerMark(player, "@@xy__zhenqing_shown", 1)
      room:sendLog{ type = "#xy__zhenqing-ready", from = player.id }
      room:showCards(to:getCardIds("h"), to)
    end
  end
end

local function finishQuest(room, player, failed)
  room:setPlayerMark(player, DONE, 1)
  room:setPlayerMark(player, TURNS, 0)
  room:setPlayerMark(player, "@@xy__zhenqing_shown", 0)
  if room.updateQuestSkillState then
    pcall(room.updateQuestSkillState, room, player, zhenqing.name, failed)
  end
end

-- 回合开始时
zhenqing:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and active(player)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    doZhenqing(player)
  end,
})

-- 受到一点伤害时（每点伤害各一次）
zhenqing:addEffect(fk.DamageInflicted, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and active(player)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    for _ = 1, math.max(data.damage, 1) do
      if player.dead or not active(player) then break end
      doZhenqing(player)
    end
  end,
})

-- 记录你的回合数
zhenqing:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhenqing.name, true) and player:getMark(DONE) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, TURNS, 1)
  end,
})

-- 回合结束时：成功 / 失败
zhenqing:addEffect(fk.TurnEnd, {
  anim_type = "big",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not active(player) then return false end
    return player:getMark(SHOWN) ~= 0 or player:getMark(TURNS) >= 7
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark(SHOWN) ~= 0 then
      -- 成功：先获得"利友"
      room:sendLog{ type = "#xy__zhenqing-succeed", from = player.id }
      finishQuest(room, player, false)
      room:handleAddLoseSkills(player, "xy__liyou", nil, true, false)
      if not player:isKongcheng() then
        room:showCards(player:getCardIds("h"), player)
      end
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if player.dead then break end
        if not p.dead then
          local choices = {}
          if not p:isKongcheng() then
            table.insert(choices, "xy__zhenqing_showself")
          end
          if not p:isNude() then
            table.insert(choices, "xy__zhenqing_givecard")
          end
          if #choices > 0 then
          local choice = room:askToChoice(p, {
            choices = choices,
            skill_name = zhenqing.name,
            prompt = "#xy__zhenqing-success:" .. player.id,
          })
          if choice == "xy__zhenqing_givecard" then
            local cards = room:askToCards(p, {
              min_num = 1,
              max_num = 1,
              include_equip = true,
              skill_name = zhenqing.name,
              prompt = "#xy__zhenqing-give:" .. player.id,
              cancelable = false,
            })
            if #cards > 0 then
              room:obtainCard(player, cards, false, fk.ReasonGive, p, zhenqing.name)
            end
          elseif not p:isKongcheng() then
            room:showCards(p:getCardIds("h"), p)
          end
          end
        end
      end
    else
      -- 失败：第七回合结束时
      finishQuest(room, player, true)
      room:killPlayer({ who = player })
    end
  end,
})

return zhenqing

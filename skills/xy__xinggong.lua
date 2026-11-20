-- 星宮（瑪娜·唯心）
-- 你获得此技能时，你获得十二枚"星宫"。出牌阶段，你可以弃置一枚"星宫"并令一名角色任意项技能失效直到你下回合开始。

local xinggong = fk.CreateSkill {
  name = "xy__xinggong",
}

Fk:loadTranslationTable{
  ["xy__xinggong"] = "星宫",
  [":xy__xinggong"] = "你获得此技能时，你获得十二枚“星宫”。出牌阶段，你可以弃置一枚“星宫”并令一名角色任意项技能失效直到你下回合开始。",
  ["@xy__xinggong"] = "星宫",
  ["#xy__xinggong"] = "星宫：弃置一枚“星宫”，令一名角色任意项技能失效直到你下回合开始",
  ["#xy__xinggong-skills"] = "星宫：选择令 %dest 失效的技能",
  ["@xy__xinggong_inv"] = "星宫失效",
}

local STARS = "@xy__xinggong"
local INV = "@xy__xinggong_inv"       -- 在目标身上：失效的技能名
local BY = "xy__xinggong_by"          -- 在目标身上：施加者id

-- 获得此技能时：获得十二枚"星宫"
xinggong:addAcquireEffect(function(self, player, is_start)
  player.room:setPlayerMark(player, STARS, 12)
end)

local function skillNames(p)
  local names = {}
  for _, s in ipairs(p.player_skills) do
    if not s.name:startsWith("#") and s:isPlayerSkill(p) and s.visible ~= false then
      table.insertIfNeed(names, s.name)
    end
  end
  return names
end

xinggong:addEffect("active", {
  anim_type = "control",
  prompt = "#xy__xinggong",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark(STARS) > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and #skillNames(to_select) > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local to = effect.tos[1]
    room:removePlayerMark(player, STARS, 1)
    local names = skillNames(to)
    if #names == 0 then return end
    local chosen = room:askToChoices(player, {
      choices = names,
      min_num = 1,
      max_num = #names,
      skill_name = xinggong.name,
      prompt = "#xy__xinggong-skills::" .. to.id,
      cancelable = false,
    })
    local list = to:getTableMark(INV)
    for _, s in ipairs(chosen) do table.insertIfNeed(list, s) end
    room:setPlayerMark(to, INV, list)
    room:setPlayerMark(to, BY, player.id)
  end,
})

-- 你的下回合开始：失效结束
xinggong:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.players) do
      if p:getMark(BY) == player.id then
        room:setPlayerMark(p, INV, 0)
        room:setPlayerMark(p, BY, 0)
      end
    end
  end,
})

xinggong:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    local list = from:getTableMark(INV)
    if #list == 0 then return false end
    local skel = skill.getSkeleton and skill:getSkeleton()
    local name = skel and skel.name or skill.name
    return table.contains(list, name)
  end,
})

return xinggong

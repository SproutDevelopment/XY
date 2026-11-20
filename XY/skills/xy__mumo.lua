-- 穆魔（曹節·魔帝）
-- 每回合限X次，一名角色使用一张非装备牌时，你选择一项：1.为该牌增加和减少任意名目标（无须合法）；
-- 2.令你或其摸两张牌；3.标记该角色的一张非「魔气」牌为「魔气」。（X为其区域内「魔气」的数量）

local mumo = fk.CreateSkill {
  name = "xy__mumo",
}

Fk:loadTranslationTable{
  ["xy__mumo"] = "穆魔",
  [":xy__mumo"] = "每回合限X次，一名角色使用一张非装备牌时，你选择一项：1.为该牌增加和减少任意名目标（无须合法）；" ..
    "2.令你或其摸两张牌；3.标记该角色的一张非「魔气」牌为「魔气」。（X为其区域内「魔气」的数量）",

  ["xy__mumo_targets"] = "增加和减少目标",
  ["xy__mumo_draw"] = "令你或其摸两张牌",
  ["xy__mumo_mark"] = "标记一张牌为「魔气」",
  ["xy__mumo_me"] = "你摸两张牌",
  ["xy__mumo_user"] = "其摸两张牌",
  ["#xy__mumo-choice"] = "穆魔：%dest 使用了%arg，请选择一项",
  ["#xy__mumo-remove"] = "穆魔：选择要减少的目标（可不选）",
  ["#xy__mumo-add"] = "穆魔：选择要增加的目标（可不选）",
  ["#xy__mumo-who"] = "穆魔：令谁摸两张牌？",
  ["@xy__mumo_used-turn"] = "穆魔",
}

local MOQI = "@@xy__moqi"
local USED = "@xy__mumo_used-turn"

local function isMoqi(id)
  return Fk:getCardById(id):getMark(MOQI) ~= 0
end

local function moqiCount(p)
  return #table.filter(p:getCardIds("hej"), isMoqi)
end

-- 当前目标列表（兼容不同版本的数据格式）
local function getTargets(room, data)
  local list = {}
  for _, t in ipairs(data.tos or {}) do
    local p = t
    if type(t) == "number" then p = room:getPlayerById(t)
    elseif type(t) == "table" and type(t[1]) == "number" then p = room:getPlayerById(t[1]) end
    if p then table.insertIfNeed(list, p) end
  end
  return list
end

local function removeTarget(data, p)
  if data.removeTarget then
    data:removeTarget(p)
    return
  end
  for i = #data.tos, 1, -1 do
    local t = data.tos[i]
    if t == p or t == p.id or (type(t) == "table" and t[1] == p.id) then
      table.remove(data.tos, i)
    end
  end
end

local function addTarget(data, p)
  if data.addTarget then
    data:addTarget(p)
  else
    table.insert(data.tos, p)
  end
end

mumo:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mumo.name) and data.card.type ~= Card.TypeEquip and
      not target.dead and player:getMark(USED) < moqiCount(target)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, USED, 1)

    local choices = { "xy__mumo_targets", "xy__mumo_draw" }
    local nonMoqi = table.filter(target:getCardIds("hej"), function(id) return not isMoqi(id) end)
    if #nonMoqi > 0 then
      table.insert(choices, "xy__mumo_mark")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = mumo.name,
      prompt = "#xy__mumo-choice::" .. target.id .. ":" .. data.card:toLogString(),
    })

    if choice == "xy__mumo_targets" then
      local current = getTargets(room, data)
      if #current > 0 then
        local removes = room:askToChoosePlayers(player, {
          targets = current,
          min_num = 0,
          max_num = #current,
          prompt = "#xy__mumo-remove",
          skill_name = mumo.name,
          cancelable = true,
        })
        for _, p in ipairs(removes) do
          removeTarget(data, p)
        end
      end
      current = getTargets(room, data)
      local candidates = table.filter(room.alive_players, function(p)
        return not table.contains(current, p)
      end)
      if #candidates > 0 then
        local adds = room:askToChoosePlayers(player, {
          targets = candidates,
          min_num = 0,
          max_num = #candidates,
          prompt = "#xy__mumo-add",
          skill_name = mumo.name,
          cancelable = true,
        })
        for _, p in ipairs(adds) do
          addTarget(data, p)
        end
      end
      if room.sortByAction and data.tos and type(data.tos[1]) ~= "table" then
        room:sortByAction(data.tos)
      end

    elseif choice == "xy__mumo_draw" then
      local who = room:askToChoice(player, {
        choices = { "xy__mumo_me", "xy__mumo_user" },
        skill_name = mumo.name,
        prompt = "#xy__mumo-who",
      })
      local p = who == "xy__mumo_me" and player or target
      if not p.dead then
        p:drawCards(2, mumo.name)
      end

    else
      local id = room:askToChooseCard(player, {
        target = target,
        flag = "hej",
        skill_name = mumo.name,
      })
      -- 选到已是「魔气」的牌时，改为随机标记一张非「魔气」牌
      if isMoqi(id) then
        local rest = table.filter(target:getCardIds("hej"), function(c) return not isMoqi(c) end)
        id = #rest > 0 and table.random(rest) or nil
      end
      if id then
        room:setCardMark(Fk:getCardById(id), MOQI, 1)
      end
    end
  end,
})

return mumo

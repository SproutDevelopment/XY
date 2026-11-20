-- 創命
-- 限定技，出牌阶段，你可以复活一名角色至体力上限，然后你可以随机展示8张武将牌
-- 并选择是否替换之并调整至该武将的体力和体力上限。

local chuangming = fk.CreateSkill {
  name = "xy__chuangming",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["xy__chuangming"] = "创命",
  [":xy__chuangming"] = "限定技，出牌阶段，你可以复活一名角色至体力上限，然后你可以随机展示8张武将牌" ..
    "并选择是否替换之并调整至该武将的体力和体力上限。",

  ["#xy__chuangming"] = "创命：复活一名已死亡的角色",
  ["#xy__chuangming-revive"] = "创命：选择要复活的角色",
  ["#xy__chuangming-show"] = "创命：是否随机展示8张武将牌，并可以替换 %dest 的武将？",
  ["#xy__chuangming-choose"] = "创命：选择一张武将牌",
  ["#xy__chuangming-replace"] = "创命：是否将 %dest 的武将替换为 %arg？",
}

local function deadPlayers(room)
  return table.filter(room.players, function(p) return p.dead end)
end

chuangming:addEffect("active", {
  anim_type = "big",
  prompt = "#xy__chuangming",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(chuangming.name, Player.HistoryGame) == 0 and
      #deadPlayers(Fk:currentRoom()) > 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local dead = deadPlayers(room)
    if #dead == 0 then return end

    -- 选择要复活的角色（以武将名显示）
    local choices = {}
    for _, p in ipairs(dead) do
      table.insert(choices, p.general)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = chuangming.name,
      prompt = "#xy__chuangming-revive",
    })
    local to
    for i, p in ipairs(dead) do
      if choices[i] == choice then
        to = p
        break
      end
    end
    if not to then return end

    -- 复活至体力上限
    room:revivePlayer(to, true)
    room:setPlayerProperty(to, "hp", to.maxHp)

    if player.dead or to.dead then return end

    -- 然后你可以随机展示8张武将牌并选择是否替换之
    if not room:askToSkillInvoke(player, {
      skill_name = chuangming.name,
      prompt = "#xy__chuangming-show::" .. to.id,
    }) then return end

    local generals = room:getNGenerals(8)
    if #generals == 0 then return end
    local chosen = room:askToChooseGeneral(player, {
      generals = generals,
      n = 1,
      no_convert = true,
    })
    if type(chosen) == "table" then chosen = chosen[1] end

    local replace = chosen and room:askToSkillInvoke(player, {
      skill_name = chuangming.name,
      prompt = "#xy__chuangming-replace::" .. to.id .. ":" .. chosen,
    })

    if replace then
      table.removeOne(generals, chosen)
      local g = Fk.generals[chosen]
      room:changeHero(to, chosen, false, false, true, false, false)
      -- 调整至该武将的体力和体力上限
      room:setPlayerProperty(to, "maxHp", g.maxHp)
      room:setPlayerProperty(to, "hp", g.hp)
    end
    room:returnToGeneralPile(generals)
  end,
})

return chuangming

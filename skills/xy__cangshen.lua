-- Yagami Light / Cangshen: permanent active privacy and unknown-general art.
-- Core general IDs are NEVER mutated. Only other players' CLIENTS receive
-- anjiang/hiddenone; they continue to see their OWN true general.
local D = dofile('./packages/XY/deathgod_utils.lua')
local Art = dofile('./packages/XY/cangshen_unknown_general.lua')
local skill = fk.CreateSkill{ name = 'xy__cangshen', tags = {Skill.Permanent} }

-- 重新把各角色的武将属性发给其他人：让客户端重新读取名字，
-- 此时“藏身”已生效，名字会被替换为“？？？”（否则开局时已显示的名字不会更新）
local function resendNames(room)
  if Art.isRunning and Art.isRunning(room) then return end
  if type(room.notifyProperty) ~= "function" then return end
  for _, viewer in ipairs(room.players or {}) do
    for _, subject in ipairs(room.players or {}) do
      if subject ~= viewer then
        for _, prop in ipairs({ "general", "deputyGeneral" }) do
          local v = subject[prop]
          if type(v) == "string" and v ~= "" then
            pcall(room.notifyProperty, room, viewer, subject, prop)
          end
        end
      end
    end
  end
end

local function refresh(room, changed)
  if not room then return end
  D.refreshHiddenDescriptions(room)
  Art.sync(room, changed)
  resendNames(room)
end

-- Owner's GameStart and TurnStart are enough to establish and periodically
-- refresh the permanent effect (including after reconnects).
local function addOwnerRefresh(event)
  if not event then return end
  skill:addEffect(event, {
    anim_type = 'special',
    can_trigger = function(self, _, target, player, data)
      return player and player.room and D.hasCangshen(player)
    end,
    on_cost = Util.TrueFunc,
    on_use = function(self, _, target, player, data)
      refresh(player.room, true)
    end,
  })
end
addOwnerRefresh(fk.GameStart)
addOwnerRefresh(fk.TurnStart)

-- Death/revival effects must remain registered as global triggers: the last
-- bearer is already dead when Deathed runs and no longer has this skill.
local function addGlobalRefresh(event, changedSubject)
  if not event then return end
  skill:addEffect(event, {
    global = true,
    mute = true,
    can_trigger = function(self, _, target, player, data)
      return target == player and player and player.room ~= nil
    end,
    on_cost = Util.TrueFunc,
    on_use = function(self, _, target, player, data)
      refresh(player.room, changedSubject and player or true)
    end,
  })
end
addGlobalRefresh(fk.Deathed, false)
addGlobalRefresh(fk.AfterPlayerRevived, false)
addGlobalRefresh(fk.AfterPropertyChange, true)

return skill

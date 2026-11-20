-- 【密题】每出牌阶段限0次起步，每猜对一名角色身分永久+1，最多8次。
-- 只在安娜自己的回合开始时，以新月杀自带选项框逐个猜测所有符合条件的角色（包括自己）。
local U = dofile("./packages/XY/anna_utils.lua")
local Guesses = dofile("./packages/XY/role_guess.lua")
local skill = fk.CreateSkill{ name = "xy__miti" }

skill:addEffect(fk.TurnStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player ~= nil and target == player and not player.dead
      and U.isAnna(player) and player:hasSkill("xy__miti")
      and player:getMark("xy__miti_guessed-turn") == 0
      and #Guesses.targets(player.room, player) > 0
      and #Guesses.availableRoles(player.room) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "xy__miti_guessed-turn", 1)
    -- This log confirms the trigger ran, useful if a client still hides dialogs.
    room:sendLog({type = "#xy__miti-enter", from = player.id})
    local correct = Guesses.askAll(room, player, self.name)
    if correct > 0 then
      local gained = U.grantPhaseLimit(room, player, correct)
      room:sendLog({type = "#xy__miti-study", from = player.id,
        arg = tostring(correct), arg2 = tostring(gained)})
    end
  end,
})

skill:addEffect("active", {
  anim_type = "control",
  can_use = function(self, player)
    return player ~= nil and U.isAnna(player) and player.phase == Player.Play
      and U.getPhaseRemaining(player) > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if player.phase ~= Player.Play or U.getPhaseRemaining(player) <= 0 then return end

    local selected = room:askToChoosePlayers(player, {
      targets = room.alive_players, min_num = 1, max_num = 1,
      cancelable = false, skill_name = self.name,
      prompt = "#xy__miti-target",
    })
    local other = selected and selected[1]
    if not other then return end

    -- Use up ONE allowance for the CURRENT play phase only. The '-phase'
    -- suffix ensures FreeKill resets this counter after the phase ends.
    room:addPlayerMark(player, U.PHASE_USED, 1)

    local guess = U.askThreeNumbers(room, player, self.name, "#xy__miti-number")
    local ids = other:getCardIds("he")
    local actual = U.typeCounts(ids)
    if U.allCorrect(guess, actual) then
      if other ~= player and #ids > 0 then
        room:obtainCard(player, ids, false, fk.ReasonPrey, player, self.name)
      end
      room:sendLog({
        type = "#xy__miti-perfect", from = player.id,
        to = {other.id}, arg = self.name,
      })
    else
      local zhNames = {
        [Card.TypeBasic] = "基本牌",
        [Card.TypeTrick] = "锦囊牌",
        [Card.TypeEquip] = "装备牌",
      }
      local clues = {}
      for _, t in ipairs({Card.TypeBasic, Card.TypeTrick, Card.TypeEquip}) do
        local comparison = actual[t] > guess[t] and "大于" or
          (actual[t] < guess[t] and "小于" or "等于")
        clues[#clues+1] = zhNames[t] .. comparison .. "你声明的数量"
      end
      -- 真实聊天频道，发送者是被猜测的角色，而非安娜或旁白战报。
      other:chat("【密题】" .. table.concat(clues, "；") .. "。")
    end
  end,
})

return skill

-- 闕寒（輝夜姬）
-- 你受到一点伤害后，若你未因此进入濒死状态，你与伤害来源各选择是否令你摸一张牌，
-- 与你选择不同的角色执行一次濒死结算。

local quehan = fk.CreateSkill {
  name = "xy__quehan",
}

Fk:loadTranslationTable{
  ["xy__quehan"] = "阙寒",
  [":xy__quehan"] = "你受到一点伤害后，若你未因此进入濒死状态，你与伤害来源各选择是否令你摸一张牌，" ..
    "与你选择不同的角色执行一次濒死结算。",

  ["xy__quehan_yes"] = "令其摸一张牌",
  ["xy__quehan_no"] = "不令其摸牌",
  ["#xy__quehan-self"] = "阙寒：是否令你摸一张牌？",
  ["#xy__quehan-source"] = "阙寒：是否令 %src 摸一张牌？（与其选择不同则你执行一次濒死结算）",
}

quehan:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(quehan.name) and not player.dead and player.hp > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _ = 1, math.max(data.damage, 1) do
      if player.dead or player.hp <= 0 then break end
      local mine = room:askToChoice(player, {
        choices = { "xy__quehan_yes", "xy__quehan_no" },
        skill_name = quehan.name,
        prompt = "#xy__quehan-self",
      })
      local src = data.from
      local theirs
      if src and not src.dead and src ~= player then
        theirs = room:askToChoice(src, {
          choices = { "xy__quehan_yes", "xy__quehan_no" },
          skill_name = quehan.name,
          prompt = "#xy__quehan-source:" .. player.id,
        })
      end
      -- 两人都选择后再摸牌：每有一人选择"摸牌"，你摸一张
      local n = (mine == "xy__quehan_yes" and 1 or 0) + (theirs == "xy__quehan_yes" and 1 or 0)
      if n > 0 and not player.dead then
        player:drawCards(n, quehan.name)
      end
      -- 与你选择不同的角色执行一次濒死结算
      if theirs and theirs ~= mine and not src.dead then
        room:enterDying({ who = src, damage = data })
      end
    end
  end,
})

return quehan

-- 護妻（董白）
-- 你回合外体力减少时，你可以减少一点体力上限并防止之，然后你下回合"邀雄"的使用次数+1。

local huqi = fk.CreateSkill {
  name = "xy__huqi",
}

Fk:loadTranslationTable{
  ["xy__huqi"] = "护妻",
  [":xy__huqi"] = "你回合外体力减少时，你可以减少一点体力上限并防止之，然后你下回合“邀雄”的使用次数+1。",
  ["#xy__huqi-invoke"] = "护妻：你可以减1点体力上限，防止此次失去%arg点体力，下回合“邀雄”次数+1",
  ["@xy__huqi_extra"] = "邀雄+",
}

huqi:addEffect(fk.BeforeHpChanged, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huqi.name) and data.num < 0
      and player.room.current ~= player
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = huqi.name,
      prompt = "#xy__huqi-invoke:::" .. tostring(-data.num),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.prevented = true
    room:changeMaxHp(player, -1)
    if not player.dead then
      room:addPlayerMark(player, "@xy__huqi_extra", 1)
    end
  end,
})

return huqi

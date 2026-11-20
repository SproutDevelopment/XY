-- 唯心（瑪娜）
-- 锁定技，你死亡时，你增加1点体力上限，然后将复活至体力上限，并从"晴天""棱镜""爱心""雷珍""王权""星宫"中
-- 获得一个未被获得的技能。若你已经拥有所有技能，你失去此技能。
--
-- 实现：在死亡流程最开始（fk.BeforeGameOverJudge，尚未弃牌、失去技能、判定胜负）发动：
-- 复活并中止本次死亡事件。因此无论是濒死后死亡还是被直接杀死（"即死"），都会触发。

local weixin = fk.CreateSkill {
  name = "xy__weixin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xy__weixin"] = "唯心",
  [":xy__weixin"] = "锁定技，你死亡时，你增加1点体力上限，然后将复活至体力上限，并从“<a href=\'xy__qingtian_href\'>晴天</a>”“<a href=\'xy__lengjing_href\'>棱镜</a>”“<a href=\'xy__aixin_href\'>爱心</a>”“<a href=\'xy__leizhen_href\'>雷珍</a>”“<a href=\'xy__wangquan_href\'>王权</a>”“<a href=\'xy__xinggong_href\'>星宫</a>”" ..
    "中获得一个未被获得的技能。若你已经拥有所有技能，你失去此技能。",
  ["$xy__weixin1"] = "发生了很多事呢~",
  ["#xy__weixin-choose"] = "唯心：选择获得一个技能",
  ["#xy__weixin-revive"] = "%from 发动“唯心”，复活了！",
}

local POOL = { "xy__qingtian", "xy__lengjing", "xy__aixin", "xy__leizhen", "xy__wangquan", "xy__xinggong" }
local GAINED = "xy__weixin_gained"

weixin:addEffect(fk.BeforeGameOverJudge, {
  anim_type = "big",
  priority = 10,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.dead and player:hasSkill(weixin.name, false, true)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local missing = table.filter(POOL, function(s)
      return not table.contains(player:getTableMark(GAINED), s) and not player:hasSkill(s, true, true)
    end)
    if #missing == 0 then
      -- 已经拥有所有技能：失去此技能，然后正常死亡
      room:handleAddLoseSkills(player, "-" .. weixin.name, nil, true, false)
      return
    end
    -- 复活
    room:revivePlayer(player, false, weixin.name)
    room:sendLog{ type = "#xy__weixin-revive", from = player.id, toast = true }
    room:changeMaxHp(player, 1)
    if player.hp ~= player.maxHp then
      room:setPlayerProperty(player, "hp", player.maxHp)
    end
    local choice = room:askToChoice(player, {
      choices = missing,
      skill_name = weixin.name,
      prompt = "#xy__weixin-choose",
    })
    room:addTableMark(player, GAINED, choice)
    room:handleAddLoseSkills(player, choice, nil, true, false)
    -- 若已经拥有所有技能，立即失去此技能
    if table.every(POOL, function(s) return player:hasSkill(s, true, true) end) then
      room:handleAddLoseSkills(player, "-" .. weixin.name, nil, true, false)
    end
    -- 中止本次死亡（不弃牌、不失去技能、不判定胜负、不执行奖惩）
    local death = room.logic:getCurrentEvent():findParent(GameEvent.Death, true)
    if death then death:shutdown() end
  end,
})

return weixin

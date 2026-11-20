-- 【黄皮】显示文案保留“中国红”和“黄皮肤”的原设定。
-- 实际效果只检查角色场上可见的红色牌（装备区 e + 判定区 j），
-- 不检查手牌，也不检查角色肤色。
local skill = fk.CreateSkill{ name = "alch__huangpi" }

-- 指定角色的装备区或判定区里是否至少有一张红牌？
local function hasRedCardOnField(p)
  if not p or p.dead then return false end

  for _, id in ipairs(p:getCardIds("ej")) do
    local card = Fk:getCardById(id)
    if card and card.color == Card.Red then
      return true
    end
  end

  return false
end

-- 计算当前场上拥有红色装备牌/判定区牌的存活角色数量。
local function countRedCardOwners(room)
  local count = 0
  for _, p in ipairs(room.alive_players) do
    if hasRedCardOnField(p) then
      count = count + 1
    end
  end
  return count
end

skill:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",

  can_trigger = function(self, event, target, player, data)
    -- 仅当前回合结束的角色本人场上有红牌时才询问发动。
    return target ~= nil and not target.dead
      and player ~= nil and not player.dead
      and player:hasSkill(self)
      and hasRedCardOnField(target)
  end,

  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room.askForSkillInvoke then
      return room:askForSkillInvoke(player, self.name, nil, "#alch__huangpi-invoke")
    elseif room.askToSkillInvoke then
      return room:askToSkillInvoke(player, {
        skill_name = self.name,
        prompt = "#alch__huangpi-invoke",
      })
    end
    return false
  end,

  on_use = function(self, event, target, player, data)
    -- 在结算时重新计算：每名符合条件的存活角色只计一次。
    local amount = countRedCardOwners(player.room)
    if amount > 0 then
      player:drawCards(amount, self.name)
    end
  end,
})

return skill

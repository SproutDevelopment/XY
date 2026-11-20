-- 督造（唐咨）
-- 锁定技，你的登场势力为"魏"；当你使用一张牌或成为一张牌的目标时，你令此牌额外执行一次。
-- （对每个目标都生效；你对自己使用的牌执行4次）

local duzao = fk.CreateSkill {
  name = "xy__duzao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xy__duzao"] = "督造",
  [":xy__duzao"] = "锁定技，你的登场势力为“魏”；当你使用一张牌或成为一张牌的目标时，你令此牌额外执行一次。",
}

local function isTarget(data, player)
  for _, t in ipairs(data.tos or {}) do
    if t == player or t == player.id or (type(t) == "table" and t[1] == player.id) then
      return true
    end
  end
  return false
end

duzao:addEffect(fk.CardUsing, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(duzao.name) and (target == player or isTarget(data, player))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    -- 你使用的牌：执行次数翻倍；你是目标的牌：再翻倍（你对自己使用则共执行4次）
    local doubles = 0
    if target == player then doubles = doubles + 1 end
    if isTarget(data, player) then doubles = doubles + 1 end
    local times = ((data.additionalEffect or 0) + 1) * (2 ^ doubles)
    data.additionalEffect = math.floor(times) - 1
  end,
})

return duzao

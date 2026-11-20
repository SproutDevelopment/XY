-- 星月同輝自定义武将：帕拉塞尔苏斯、攬佬、安娜 (FreeKill 0.5.5+)
-- 拓展安装位置：packages/XY。
local extension = Package:new("starmoon")
extension.extensionName = "XY"

extension:loadSkillSkelsByPath("./packages/XY/skills")

-- ===== 武将按 XY 编号由小到大排列 =====
-- XY 000 瑪娜
local mana = General:new(extension, "xy__mana", "qun", 1, 1, General.Female)
mana:addSkills({"xy__weixin", "xy__zhongfan", "xy__yishen"})
mana:addRelatedSkills({"xy__qingtian", "xy__lengjing", "xy__aixin", "xy__leizhen", "xy__wangquan", "xy__xinggong"})

-- XY 001 帕拉塞爾蘇斯
local paracelsus = General:new(
  extension, "alch__paracelsus", "qun", 3, 3, General.Male
)
paracelsus:addSkills({"alch__liancheng", "alch__qucai"})

-- XY 018 董白
local dongbai = General:new(extension, "xy__dongbai", "qun", 3, 3, General.Female)
dongbai:addSkills({"xy__yaoxiong", "xy__huqi", "xy__hougong"})

-- XY 020
local faguan = General:new(extension, "xy__faguan", "qun", 4, 4, General.Male)
faguan:addSkills({"xy__tequan", "xy__gongshen"})

-- XY 130 沮授（含入幻形态）
local jushou = General:new(extension, "xy__jushou", "qun", 3, 5, General.Male)
jushou:addSkills({"xy__quyi", "xy__wanan", "xy__zhenghuan"})
jushou:addRelatedSkills({"xy__yuzhi", "xy__zhouming", "xy__fanjue"})

-- 入幻形态：只用于变身，不出现在选将中（与解密天使相同的处理方式）
local jushouHuan = General:new(extension, "xy__jushou_huan", "qun", 3, 5, General.Male)
jushouHuan.hidden = true
jushouHuan.total_hidden = true
jushouHuan:addSkills({"xy__yuzhi", "xy__zhouming", "xy__fanjue"})
for i = #extension.generals, 1, -1 do
  if extension.generals[i] == jushouHuan then
    table.remove(extension.generals, i)
  end
end

-- 一心“众心”选将界面中的“不更换”卡（仅作为取消选项，不出现在选将中）
local zhongxinCancel = General:new(extension, "xy__zhongxin_cancel", "qun", 1, 1, General.Female)
zhongxinCancel.hidden = true
zhongxinCancel.total_hidden = true
for i = #extension.generals, 1, -1 do
  if extension.generals[i] == zhongxinCancel then
    table.remove(extension.generals, i)
  end
end

-- XY 220
local guoanfaguan = General:new(extension, "xy__guoanfaguan", "qun", 4, 4, General.Male)
guoanfaguan:addSkills({"xy__guoan", "xy__gongshen2"})

-- XY 224
local yueer = General:new(extension, "xy__yueer", "qun", 3, 3, General.Female)
yueer:addSkills({"xy__nizhu", "xy__jingqiang"})

-- XY 236 攬佬
local lanlao = General:new(
  extension, "alch__lanlao", "qun", 3, 3, General.Female
)
lanlao:addSkills({"alch__nengfei", "alch__huangpi"})

-- XY 237
local qiwozuo = General:new(extension, "xy__qiwozuo", "qun", 4, 4, General.Male)
qiwozuo:addSkills({"xy__luozhen", "xy__quanfa", "xy__zhanjing", "xy__lianxue"})

-- XY 240
local jiujicaiye = General:new(extension, "xy__jiujicaiye", "qun", 3, 3, General.Female)
jiujicaiye:addSkills({"xy__shihua", "xy__chuangming", "xy__caicai"})

-- XY 242
local huiyeji = General:new(extension, "xy__huiyeji", "qun", 3, 3, General.Female)
huiyeji:addSkills({"xy__lejie", "xy__quehan"})

-- XY 257
local mocaojie = General:new(extension, "xy__mocaojie", "evil", 3, 3, General.Female)
mocaojie:addSkills({"xy__qiexi", "xy__mumo", "xy__modi"})

-- XY 259
local caojie = General:new(extension, "xy__caojie", "qun", 4, 4, General.Male)
caojie:addSkills({"xy__renlin", "xy__caozu"})

-- XY 269
local tangzi = General:new(extension, "xy__tangzi", "wei", 4, 4, General.Male)
tangzi:addSkills({"xy__duzao", "xy__liuxun"})

-- XY 293
local sunshangxiang = General:new(extension, "xy__sunshangxiang", "wu", 3, 3, General.Female)
sunshangxiang:addSkills({"xy__yourou", "xy__guixin", "xy__xiaojiao"})

-- XY 295
local yejunxiangzhi = General:new(extension, "xy__yejunxiangzhi", "qun", 3, 3, General.Female)
yejunxiangzhi:addSkills({"xy__zhenqing"})
yejunxiangzhi:addRelatedSkills({"xy__liyou"})

-- XY 296
local mafuyu = General:new(extension, "xy__chaobinaizhendong", "qun", 4, 4, General.Female)
mafuyu:addSkills({"xy__qitu", "xy__quemu"})

-- XY 304
local yixin = General:new(extension, "xy__yixin", "qun", 4, 4, General.Female)
yixin:addSkills({"xy__zhongxin"})

-- XY 306
local banliuyouqi = General:new(extension, "xy__banliuyouqi", "qun", 3, 3, General.Female)
banliuyouqi:addSkills({"xy__fufeng", "xy__ruoliu"})

-- XY 310 安娜（含解謎天使形态）
-- 解謎天使目前只有暫時性的變身模板，等待您提供正式武將資料與圖片。
local anna = General:new(
  extension, "xy__anna", "qun", 3, 3, General.Female
)
anna:addSkills({"xy__jiemi", "xy__mipu", "xy__miti"})

local angel = General:new(
  extension, "xy__decrypt_angel", "qun", 3, 3, General.Female
)
-- Transformation-only form: not an initial general-choice candidate.
-- Keep the general registered so room:changeHero can still transform Anna.
angel.hidden = true
angel.total_hidden = true
angel:addSkills({"xy__jiemi", "xy__mipu", "xy__miti", "xy__zhentan", "xy__laike"})

-- Secondary forms must be usable by changeHero, but must not be offered
-- as playable generals. General:new added this form to extension.generals;
-- remove it from that selection/package list. The engine registry is kept
-- separately by the install hook below, so transformation still resolves.
for i = #extension.generals, 1, -1 do
  if extension.generals[i] == angel then
    table.remove(extension.generals, i)
  end
end

-- XY 312
local erqiao = General:new(extension, "xy__daqiaoxiaoqiao", "wu", 3, 3, General.Female)
erqiao:addSkills({"xy__pingting", "xy__xingwu"})
erqiao:addRelatedSkills({"tianxiang", "liuli"})

-- XY 313
local kurara = General:new(extension, "xy__tiantangjiuliangluo", "qun", 5, 5, General.Female)
kurara:addSkills({"xy__moren", "xy__wenniao", "xy__quejue"})

-- XY 314
local shalina = General:new(extension, "xy__shalina", "qun", 3, 3, General.Female)
shalina:addSkills({"xy__xianfeng", "xy__xizhi"})

-- XY 317 夜神月
local deathgod = General:new(
  extension, "xy__deathgod", "qun", 4, 4, General.Male
)
deathgod:addSkills({"xy__cangshen", "xy__sishen"})

-- ===== 玥映千星（星月同輝下的第二个武将包） =====
local yueying = Package:new("yueying")
yueying.extensionName = "XY"

local dengzhi = General:new(yueying, "xy__dengzhi", "shu", 3, 3, General.Male)
dengzhi:addSkills({"xy__hubo"})

-- 固定登场势力：孫尚香只能为吳，曹節（魔帝）只能为魔
-- 选择势力的弹窗由服务器根据武将的"副势力"生成（选项为 主势力/副势力）。
-- 服务器端把副势力设为固定势力，弹窗就只剩这一个选项；
-- 客户端（你的画面）仍显示原本的副势力，例如孫尚香显示为蜀吳。
local function fixKingdomChoice(general, serverSub, clientSub)
  local mt = {}
  for k, v in pairs(getmetatable(general)) do mt[k] = v end
  local baseIndex = mt.__index
  mt.__index = function(t, k)
    if k == "subkingdom" then
      if rawget(_G, "RoomInstance") then return serverSub end
      return clientSub
    end
    if type(baseIndex) == "function" then return baseIndex(t, k) end
    return baseIndex and baseIndex[k]
  end
  rawset(general, "subkingdom", nil)
  setmetatable(general, mt)
end
fixKingdomChoice(sunshangxiang, "wu", "shu")
fixKingdomChoice(mocaojie, "evil", nil)

-- 选将界面的势力按钮也只提供固定势力（客户端与服务器都使用此函数）
local XY_FIXED_KINGDOMS = {
  xy__sunshangxiang = { "wu" },
  xy__mocaojie = { "evil" },
}
if not rawget(Fk, "_xy_fixed_kingdom_patch") then
  local oldGetKingdomsNeedToChoose = Fk.getKingdomsNeedToChoose
  Fk.getKingdomsNeedToChoose = function(self, general)
    local fixed = XY_FIXED_KINGDOMS[general]
    if fixed then return table.simpleClone(fixed) end
    return oldGetKingdomsNeedToChoose(self, general)
  end
  Fk._xy_fixed_kingdom_patch = true
end

local installBasePackage = extension.install
function extension:install(engine)
  -- Install the playable characters and all skeleton skills normally.
  installBasePackage(self, engine)
  -- Register the second form only in the runtime lookup used by changeHero.
  -- Do not add it back to the package's initial general list.
  if engine.generals[angel.name] == nil then
    engine:addGeneral(angel)
  end
  if engine.generals[jushouHuan.name] == nil then
    engine:addGeneral(jushouHuan)
  end
  if engine.generals[zhongxinCancel.name] == nil then
    engine:addGeneral(zhongxinCancel)
  end

  -- Some custom/free-select interfaces ask canUseGeneral directly. Reject
  -- this one ID even if a UI ignores the standard hidden flags.
  if not engine._xy_decrypt_angel_choose_guard and type(engine.canUseGeneral) == 'function' then
    local oldCanUseGeneral = engine.canUseGeneral
    engine.canUseGeneral = function(self, general_name, ...)
      if general_name == angel.name or general_name == jushouHuan.name
        or general_name == zhongxinCancel.name then return false end
      return oldCanUseGeneral(self, general_name, ...)
    end
    engine._xy_decrypt_angel_choose_guard = true
  end
end

Fk:loadTranslationTable{
  ["XY"] = "星月同輝",
  ["starmoon"] = "星月同輝",
  ["yueying"] = "玥映千星",
  ["alch"] = "星月同輝",

  ["alch__paracelsus"] = "帕拉塞爾蘇斯",
  ["#alch__paracelsus"] = "鍊金術士",
  ["alch__liancheng"] = "炼成",
  [":alch__liancheng"] = "准备阶段，你从弃牌堆中获得一张【杀】；结束阶段，你从弃牌堆中获得一张【闪】。",
  ["alch__qucai"] = "取材",
  [":alch__qucai"] = "锁定技，弃牌阶段开始时，你将手牌数调整至3。",

  ["alch__lanlao"] = "攬佬",
  ["#alch__lanlao"] = "中国人",
  ["alch__nengfei"] = "能飞",
  [":alch__nengfei"] = "你成为一张牌的目标时，你可以进行一次判定。若判定结果为中国红，此牌对你无效。",
  ["alch__huangpi"] = "黄皮",
  [":alch__huangpi"] = "一名场上拥有中国红牌的角色回合结束时，若该角色为黄皮肤，你可以摸场上拥有中国红牌的角色数量张牌。",
  ["#alch__nengfei-invoke"] = "能飞：是否进行判定？",
  ["#alch__huangpi-invoke"] = "黄皮：是否摸牌？",

  -- 新武將：夜神月
  ["xy__deathgod"] = "夜神月",
  ["#xy__deathgod"] = "不可直視之名",
  ["xy__cangshen"] = "藏身",
  ["xy__cangshen-hidden-desc"] = "受“藏身”影響，無法查看此技能描述。",
  [":xy__cangshen"] = "持恆技，遊戲開始時即生效。當你存活時，所有角色無法觀看其他角色的武將名字、技能名字、技能描述及武將皮膚。",

  -- 新增：解謎天使——安娜
  ["xy"] = "星月同輝",
  ["xy__anna"] = "安娜",
  ["#xy__anna"] = "解謎天使",
  ["xy__decrypt_angel"] = "解密天使",
  ["#xy__decrypt_angel"] = "解密中的安娜",

  -- 解密天使限定技能
  ["xy__hidden_card"] = "未知牌",
  ["#xy__zhentan-hidden-use"] = "%from 對 %to 使用了一張【未知牌】。",
  ["#xy__zhentan-no-choices"] = "%from 發動〖偵探〗，但本局沒有可聲明的實體牌名，失去一層變身層數。",
  ["xy__zhentan"] = "偵探",
  [":xy__zhentan"] = "你拥有“解密”，“谜谱”，“密题”。你成为一张牌的唯一目标时，使用该牌的角色需暗置之并需声明该牌的花色和点数，然后你选择是否声明一个牌名。若该牌名与你声明的牌名相同，该牌无效且你摸两张牌。否则，你减少1层变身层数。",
  ["#xy__zhentan-choice"] = "侦探：这张牌的花色点数是%arg，请声明其牌名",
  ["#xy__zhentan-right"] = "%from 發動〖偵探〗猜中了未知牌，令此牌對其無效並摸兩張牌。",
  ["#xy__zhentan-wrong"] = "%from 發動〖偵探〗猜測失敗，失去一層變身層數。",
  ["xy__laike"] = "來客",
  [":xy__laike"] = "出牌阶段，你可以扣置任意张牌于一名其他角色的武将牌上，称之为“未来”。一名角色回合开始时，其可以弃置任意张牌，来弃置自己等量张“未来”，然后你依次对其使用“未来”的牌。 （无距离限制）",
  ["xy__future"] = "未來",
  ["#xy__laike-combined"] = "來客：請選擇一名其他角色及至少一張牌，扣置為“未來”。（你於其回合開始時對其使用）",
  ["#xy__laike-offset"] = "來客：你共有%arg張“未來”（所有角色均可檢視牌面），可先棄置任意張自己的牌，再選擇要移除的相同數量“未來”",
  ["#xy__laike-select"] = "來客：請直接選擇要移除的%arg張“未來”（所有角色均可檢視牌面）",

  ["xy__jiemi"] = "解密",
  [":xy__jiemi"] = "变身技，出牌阶段，你可以弃置一张牌并将武将牌替换成【解密天使】。 （直到你使用一张牌）",
  ["#xy__jiemi-discard"] = "解密：选择弃置一张牌来变身／叠加层数，或点击取消放弃本次发动",
  ["@xy__jiemi_stack"] = "解密",

  ["xy__mipu"] = "谜谱",
  [":xy__mipu"] = "使命技，成功：游戏结束时，你可以声明牌堆里每类型牌的数量，若你正确，你胜利。",
  ["#xy__mipu-ask"] = "谜谱：是否猜测剩余摸牌堆基本牌、锦囊牌、装备牌的数量？",
  ["#xy__mipu-number"] = "谜谱：请声明%arg的数量（剩余摸牌堆）",
  ["xy__mipu_yes"] = "挑战谜谱",
  ["xy__mipu_no"] = "不发动",
  ["#xy__mipu-guess"] = "【谜谱】%from 的猜测（基本牌 / 锦囊牌 / 装备牌）：%arg。",
  ["#xy__mipu-answer"] = "【谜谱】正确答案（基本牌 / 锦囊牌 / 装备牌）：%arg。",
  ["#xy__mipu-success"] = "%from 谜谱成功，获得特殊胜利！",
  ["#xy__mipu-failure"] = "%from 谜谱未能解开，保留正常游戏结果。",
  ["xy__mipu_winner"] = "谜谱胜利",

  ["xy__miti"] = "密题",
  [":xy__miti"] = "成器（8），出牌阶段，你可以选择一名角色并声明其每种类型牌的数量，若你声明的数量正确，你获得其所有牌。否则，其须声明其每种类型的牌大于或小于或等于你声明的数量。回合开始时，声明所有名角色的身分或阵营。进学：你正确声明一名角色的身分或阵营。",
  ["@xy__miti_limit"] = "密题每阶段次数",
  ["#xy__miti-enter"] = "【密题】安娜回合开始，正在依次询问角色身份。",
  ["xy__miti_guess_lord"] = "主公",
  ["xy__miti_guess_loyalist"] = "忠臣",
  ["xy__miti_guess_rebel"] = "反贼",
  ["xy__miti_guess_renegade"] = "内奸",
  ["xy__miti_skip"] = "跳过此角色",
  ["#xy__miti-wrong"] = "【密题】%from未猜对%to的身份。",
  ["#xy__miti-target"] = "密题：选择一名要猜测牌型数量的角色",
  ["#xy__miti-number"] = "密题：请声明目标%arg的数量（手牌和装备区）",
  ["xy__basic"] = "基本牌",
  ["xy__trick"] = "锦囊牌",
  ["xy__equip"] = "装备牌",
  ["xy__more"] = "多于",
  ["xy__equal"] = "等于",
  ["xy__less"] = "少于",
  ["#xy__miti-study"] = "【密题】本次配对猜对%arg人身分，之后每个出牌阶段的使用次数上限增加%arg2次。",
  ["#xy__miti-reveal"] = "【密题】%from猜对了%to的身分：%arg；现在公开该角色的身分。",
  ["#xy__miti-perfect"] = "%from猜对了%to的所有牌型数量！",
  ["#xy__miti-clue"] = "【密题】%from对%to说：%arg的数量%arg2你声明的数量。",
}

Fk:loadTranslationTable{
  ["xy__faguan"] = "法官",
  ["#xy__faguan"] = "公正無私",
  ["xy__guoanfaguan"] = "國安法官",
  ["#xy__guoanfaguan"] = "國安天命",
  ["xy__yueer"] = "約兒",
  ["#xy__yueer"] = "荊棘公主",
  ["xy__jiujicaiye"] = "酒寄彩葉",
  ["#xy__jiujicaiye"] = "寫下故事的下一頁",
  ["xy__daqiaoxiaoqiao"] = "大喬&小喬",
  ["#xy__daqiaoxiaoqiao"] = "江東之花",
  ["xy__tiantangjiuliangluo"] = "天堂久良羅",
  ["#xy__tiantangjiuliangluo"] = "文鳥文",
  ["xy__shalina"] = "莎莉娜&仙子伊布",
  ["#xy__shalina"] = "不改志向",
}

Fk:loadTranslationTable{
  ["jin"] = "晉",
  ["xy__chaobinaizhendong"] = "朝比奈真冬",
  ["#xy__chaobinaizhendong"] = "人生歧路",
  ["xy__sunshangxiang"] = "孫尚香",
  ["#xy__sunshangxiang"] = "心無定所",
  ["xy__yejunxiangzhi"] = "野俊&香織",
  ["#xy__yejunxiangzhi"] = "愛的戰爭",
  ["xy__tangzi"] = "唐咨",
  ["#xy__tangzi"] = "狡黠的生存者",
  ["xy__caojie"] = "曹節",
  ["#xy__caojie"] = "仁慈敦厚",
  ["xy__mocaojie"] = "曹節",
  ["#xy__mocaojie"] = "魔帝",
  ["xy__qiwozuo"] = "猗窩座",
  ["#xy__qiwozuo"] = "上弦之叁",
  ["~xy__qiwozuo"] = "成为鬼吧！",
  ["xy__dengzhi"] = "鄧芝",
  ["#xy__dengzhi"] = "出使東吳",
  ["xy__banliuyouqi"] = "坂柳有棲",
  ["#xy__banliuyouqi"] = "弱柳扶風",
  ["$xy__ruoliu1"] = "弱柳扶風，卻為坂柳扶風之智",
  ["xy__yixin"] = "一心",
  ["#xy__yixin"] = "萬眾一心",
  ["xy__jushou"] = "沮授",
  ["#xy__jushou"] = "落定天元",
  ["xy__zhongxin_cancel"] = "不更換",
  ["#xy__zhongxin_cancel"] = "取消",
  ["xy__jushou_huan"] = "沮授",
  ["#xy__jushou_huan"] = "落定天元",
  ["$xy__zhenghuan1"] = "取其安逸，三年之中，事可坐定也。",
  ["xy__dongbai"] = "董白",
  ["#xy__dongbai"] = "亂世霸主",
  ["$xy__hougong1"] = "後宮佳麗三千，一起上！",
  ["xy__mana"] = "瑪娜",
  ["#xy__mana"] = "魔法少女",
  ["~xy__mana"] = "發生過很多事呢~",
  ["xy__huiyeji"] = "輝夜姬",
  ["#xy__huiyeji"] = "超時空",
}

-- Client-side privacy adapter. Masks other players' general names, skill
-- names and descriptions while 【藏身】 is active.
-- Internal general IDs and game rules remain untouched.
dofile("./packages/XY/cangshen_client.lua")

-- Client-side convenience: one click on 【解密】 submits its target-free
-- active use; normal one-card discard prompt still follows.
dofile("./packages/XY/one_click_jiemi.lua")

-- ===== 皮肤 =====
-- 图片放在 packages/XY/image/skins/ 里
local skinPack = Package:new("xy_skins", Package.SkinPack)
skinPack.extensionName = "XY"
skinPack:addSkinPackage {
  content = {
    {
      enabled_generals = { "xy__banliuyouqi" },
      skins = { "xy__banliuyouqi--uniform.jpg" },
    },
    {
      enabled_generals = { "xy__mana" },
      skins = { "xy__mana--skin.jpg" },
    },
    {
      enabled_generals = { "xy__yueer" },
      skins = { "xy__yueer--skin.jpg" },
    },
  },
}
Fk:loadTranslationTable{
  ["xy_skins"] = "星月同輝皮膚",
  ["xy__banliuyouqi--uniform.jpg"] = "制服",
  ["xy__mana--skin.jpg"] = "唯心",
  ["xy__yueer--skin.jpg"] = "母女",
}

-- ===== 修复：游戏本体缺少 Room:getPlayerSkinsData，导致对局中“更换皮肤”报错、无法换肤 =====
do
  local ok, RoomClass = pcall(require, "ltk.server.room")
  if ok and type(RoomClass) == "table" and RoomClass.getPlayerSkinsData == nil then
    RoomClass.getPlayerSkinsData = function(self, id, data)
      if type(data) == "table" then return data end
      if type(data) == "string" then
        local ret = {}
        for part in (data .. ","):gmatch("([^,]*),") do table.insert(ret, part) end
        return ret
      end
      return {}
    end
  end
end

-- ===== 技能描述中的超链接 =====
-- 所有本扩展技能的描述里，凡是用 “X” / 「X」 / 〖X〗 括起来、且 X 是某个技能名的，
-- 都改成可点击的链接，点击后显示该技能的说明（在武将详情页中可用）。
do
  local nameMap = {}
  local function addName(skillName, preferred)
    if type(skillName) ~= "string" or skillName:startsWith("#") or skillName:endsWith("&") then return end
    local t = Fk:translate(skillName)
    if t == skillName or t == "" then return end
    if preferred or not nameMap[t] then nameMap[t] = skillName end
  end
  for name, _ in pairs(Fk.skills) do addName(name, false) end
  for _, skel in ipairs(extension.skill_skels) do addName(skel.name, true) end

  local pairsList = { { "“", "”" }, { "「", "」" }, { "〖", "〗" } }
  for _, skel in ipairs(extension.skill_skels) do
    for _, key in ipairs({ ":" .. skel.name, ":" .. skel.name .. "_yang", ":" .. skel.name .. "_yin" }) do
      local d = Fk:translate(key)
      if d ~= key and not d:find("<a ", 1, true) then
        local nd = d
        for _, pr in ipairs(pairsList) do
          nd = nd:gsub(pr[1] .. "(.-)" .. pr[2], function(w)
            local sn = nameMap[w]
            if sn and sn ~= skel.name then
              local hk = sn .. "_href"
              Fk:loadTranslationTable{ [hk] = "<b>" .. w .. "</b>：" .. Fk:translate(":" .. sn) }
              return pr[1] .. "<a href='" .. hk .. "'>" .. w .. "</a>" .. pr[2]
            end
          end)
        end
        if nd ~= d then Fk:loadTranslationTable{ [key] = nd } end
      end
    end
  end
end

-- 瑪娜“唯心”描述中的超链接（描述里已写好链接，这里生成链接内容）
for _, k in ipairs({ "xy__qingtian", "xy__lengjing", "xy__aixin", "xy__leizhen", "xy__wangquan", "xy__xinggong" }) do
  Fk:loadTranslationTable{
    [k .. "_href"] = "<b>" .. Fk:translate(k) .. "</b>：" .. Fk:translate(":" .. k),
  }
end

return { extension, yueying, skinPack }

local Mcm = {}

local CATEGORY = "IsaacDanmaku"
local GENERAL = "陪伴"
local LAYOUT = "显示"

local function indexOf(values, current)
  for index, value in ipairs(values) do if value == current then return index end end
  return 1
end

local function addChoice(tab, label, key, values, labels, settings, changed)
  ModConfigMenu.AddSetting(CATEGORY, tab, {
    Type = ModConfigMenu.OptionType.NUMBER,
    CurrentSetting = function() return indexOf(values, settings[key]) end,
    Minimum = 1,
    Maximum = #values,
    ModifyBy = 1,
    Display = function() return label .. "：" .. labels[indexOf(values, settings[key])] end,
    OnChange = function(value)
      settings[key] = values[value]
      changed()
    end,
    Info = { "IsaacDanmaku 会自行保存此设置。" },
  })
end

function Mcm.register(settings, save, renderer)
  if ModConfigMenu == nil then return false end
  if ModConfigMenu.RemoveCategory ~= nil then ModConfigMenu.RemoveCategory(CATEGORY) end

  local function changed()
    renderer:setSettings(settings)
    save()
  end

  ModConfigMenu.AddTitle(CATEGORY, GENERAL, "IsaacDanmaku 局内弹幕")
  ModConfigMenu.AddSetting(CATEGORY, GENERAL, {
    Type = ModConfigMenu.OptionType.BOOLEAN,
    CurrentSetting = function() return settings.enabled end,
    Display = function() return "启用弹幕：" .. (settings.enabled and "是" or "否") end,
    OnChange = function(value)
      settings.enabled = value
      changed()
    end,
    Info = { "关闭后不再生成或显示 IsaacDanmaku 弹幕。" },
  })
  addChoice(GENERAL, "频率", "frequency",
    { "off", "low", "normal", "high" }, { "关闭", "低", "普通", "高" }, settings, changed)
  addChoice(GENERAL, "人格", "persona",
    { "strategist", "roaster", "supporter" }, { "冷静军师", "幽默损友", "温暖鼓励" }, settings, changed)
  addChoice(GENERAL, "剧透", "spoiler_level",
    { "none", "hint", "full" }, { "无剧透", "轻提示", "完整说明" }, settings, changed)

  ModConfigMenu.AddTitle(CATEGORY, LAYOUT, "弹幕布局")
  addChoice(LAYOUT, "区域", "position",
    { "top", "middle", "bottom" }, { "顶部", "中部", "底部" }, settings, changed)
  addChoice(LAYOUT, "速度", "speed",
    { "slow", "normal", "fast" }, { "慢", "普通", "快" }, settings, changed)
  addChoice(LAYOUT, "字号", "font_size",
    { "small", "medium", "large" }, { "小", "中", "大" }, settings, changed)

  ModConfigMenu.AddSetting(CATEGORY, LAYOUT, {
    Type = ModConfigMenu.OptionType.SCROLL,
    CurrentSetting = function() return math.floor((settings.opacity - 0.5) * 20 + 0.5) end,
    Display = function()
      local value = math.floor((settings.opacity - 0.5) * 20 + 0.5)
      return "透明度：$scroll" .. value .. " " .. math.floor(settings.opacity * 100 + 0.5) .. "%"
    end,
    OnChange = function(value)
      settings.opacity = 0.5 + math.max(0, math.min(10, value)) * 0.05
      changed()
    end,
    Info = { "可选 50% 至 100%。" },
  })
  ModConfigMenu.AddSetting(CATEGORY, LAYOUT, {
    Type = ModConfigMenu.OptionType.NUMBER,
    CurrentSetting = function() return settings.max_visible end,
    Minimum = 1,
    Maximum = 3,
    ModifyBy = 1,
    Display = function() return "同屏数量：" .. settings.max_visible end,
    OnChange = function(value)
      settings.max_visible = value
      changed()
    end,
    Info = { "同时显示 1 至 3 条弹幕。" },
  })
  return true
end

return Mcm

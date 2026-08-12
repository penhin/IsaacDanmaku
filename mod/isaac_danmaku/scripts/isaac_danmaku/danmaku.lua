local Constants = include("scripts.isaac_danmaku.constants")

local Danmaku = {}
Danmaku.__index = Danmaku

local function defaultPlatform(fontPath)
  local font = Font()
  local loaded = font:Load(fontPath)
  if not loaded then
    Isaac.DebugString("[IsaacDanmaku] failed to load bundled Chinese font")
  end
  return {
    width = function() return Isaac.GetScreenWidth() end,
    height = function() return Isaac.GetScreenHeight() end,
    textWidth = function(text) return font:GetStringWidthUTF8(text) end,
    random = function(maximum) return math.random(maximum) end,
    draw = function(text, x, y, scale, opacity)
      font:DrawStringScaledUTF8(text, x + 1, y + 1, scale, scale, KColor(0, 0, 0, opacity * 0.75), 0, false)
      font:DrawStringScaledUTF8(text, x, y, scale, scale, KColor(1, 1, 1, opacity), 0, false)
    end,
  }
end

function Danmaku.new(settings, platform, fontPath)
  local self = setmetatable({}, Danmaku)
  self.settings = settings
  self.platform = platform or defaultPlatform(fontPath)
  self.queue = {}
  self.active = {}
  self.frame = 0
  return self
end

function Danmaku:setSettings(settings)
  self.settings = settings
end

function Danmaku:clear()
  self.queue = {}
  self.active = {}
end

function Danmaku:push(message, force)
  if not self.settings.enabled and not force then return end
  if message.critical and #self.active >= self.settings.max_visible then
    local lowestActive = 1
    for index = 2, #self.active do
      if self.active[index].priority < self.active[lowestActive].priority then lowestActive = index end
    end
    if message.priority > self.active[lowestActive].priority then table.remove(self.active, lowestActive) end
  end
  if #self.queue >= 12 then
    local lowest = 1
    for index = 2, #self.queue do
      if self.queue[index].priority < self.queue[lowest].priority then lowest = index end
    end
    if not message.critical and message.priority <= self.queue[lowest].priority then return end
    table.remove(self.queue, lowest)
  end
  local inserted = false
  for index, queued in ipairs(self.queue) do
    if message.priority > queued.priority then
      table.insert(self.queue, index, message)
      inserted = true
      break
    end
  end
  if not inserted then table.insert(self.queue, message) end
end

function Danmaku:preview(message)
  self:clear()
  self:push(message, true)
end

local function centerY(position, height, spacing)
  if position == "middle" then return height / 2 end
  if position == "bottom" then return height - 24 - spacing end
  return 24 + spacing
end

function Danmaku:updateAndRender()
  self.frame = self.frame + 1
  if not self.settings.enabled then self:clear() return end

  local maxVisible = self.settings.max_visible
  local usedLanes = {}
  for _, message in ipairs(self.active) do usedLanes[message.lane] = true end
  while #self.active < maxVisible and #self.queue > 0 do
    local message = table.remove(self.queue, 1)
    message.started_frame = self.frame
    local available = {}
    for lane = 1, 3 do
      if not usedLanes[lane] then table.insert(available, lane) end
    end
    local random = self.platform.random or math.random
    message.lane = table.remove(available, random(#available))
    usedLanes[message.lane] = true
    message.width = self.platform.textWidth(message.text) * Constants.FONT_SCALE[self.settings.font_size]
    table.insert(self.active, message)
  end

  local screenWidth = self.platform.width()
  local screenHeight = self.platform.height()
  local scale = Constants.FONT_SCALE[self.settings.font_size]
  local duration = Constants.SPEED_FRAMES[self.settings.speed]
  local spacing = 34 * scale
  local y0 = centerY(self.settings.position, screenHeight, spacing)
  local survivors = {}
  for _, message in ipairs(self.active) do
    local progress = (self.frame - message.started_frame) / duration
    if progress <= 1 then
      local x = screenWidth - progress * (screenWidth + message.width + 16)
      local y = y0 + (message.lane - 2) * spacing
      self.platform.draw(message.text, x, y, scale, self.settings.opacity)
      table.insert(survivors, message)
    end
  end
  self.active = survivors
end

return Danmaku

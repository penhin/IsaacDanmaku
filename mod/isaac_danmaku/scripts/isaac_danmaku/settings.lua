local Constants = include("scripts.isaac_danmaku.constants")

local Settings = {}

Settings.DEFAULTS = {
  schema_version = Constants.SAVE_VERSION,
  enabled = true,
  frequency = "normal",
  persona = "strategist",
  spoiler_level = "none",
  position = "top",
  speed = "normal",
  font_size = "medium",
  opacity = 0.9,
  max_visible = 2,
}

local function contains(values, candidate)
  for _, value in ipairs(values) do
    if value == candidate then return true end
  end
  return false
end

function Settings.sanitize(candidate)
  candidate = type(candidate) == "table" and candidate or {}
  local result = {}
  for key, value in pairs(Settings.DEFAULTS) do result[key] = value end

  if type(candidate.enabled) == "boolean" then result.enabled = candidate.enabled end
  if contains(Constants.FREQUENCIES, candidate.frequency) then result.frequency = candidate.frequency end
  if contains(Constants.PERSONAS, candidate.persona) then result.persona = candidate.persona end
  if contains(Constants.SPOILERS, candidate.spoiler_level) then result.spoiler_level = candidate.spoiler_level end
  if contains(Constants.POSITIONS, candidate.position) then result.position = candidate.position end
  if contains(Constants.SPEEDS, candidate.speed) then result.speed = candidate.speed end
  if contains(Constants.FONT_SIZES, candidate.font_size) then result.font_size = candidate.font_size end
  if type(candidate.opacity) == "number" then
    result.opacity = math.max(0.5, math.min(1.0, candidate.opacity))
  end
  if type(candidate.max_visible) == "number" then
    result.max_visible = math.max(1, math.min(3, math.floor(candidate.max_visible)))
  end
  return result
end

function Settings.load(mod, codec)
  if not mod:HasData() then return Settings.sanitize(nil) end
  local ok, decoded = pcall(codec.decode, mod:LoadData())
  if not ok or type(decoded) ~= "table" or decoded.schema_version ~= Constants.SAVE_VERSION then
    Isaac.DebugString("[IsaacDanmaku] invalid settings; defaults restored")
    return Settings.sanitize(nil)
  end
  return Settings.sanitize(decoded)
end

function Settings.save(mod, codec, settings)
  mod:SaveData(codec.encode(Settings.sanitize(settings)))
end

return Settings

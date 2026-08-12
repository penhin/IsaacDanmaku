local Constants = include("scripts.isaac_danmaku.constants")

local CommentEngine = {}
CommentEngine.__index = CommentEngine

local function stableHash(value)
  local hash = 2166136261
  for index = 1, #value do
    hash = (hash * 16777619 + string.byte(value, index)) % 2147483647
  end
  return hash
end

function CommentEngine.new(rules)
  local self = setmetatable({}, CommentEngine)
  self.rules = rules
  self.counts = {}
  self.last_frames = {}
  self.last_message_frame = -math.huge
  self.recent = {}
  return self
end

function CommentEngine:reset()
  self.counts = {}
  self.last_frames = {}
  self.last_message_frame = -math.huge
  self.recent = {}
end

local function wasRecent(recent, text)
  for _, value in ipairs(recent) do if value == text then return true end end
  return false
end

function CommentEngine:generate(scenario, context, settings)
  if not settings.enabled or settings.frequency == "off" then return nil end
  local globalCooldown = Constants.GLOBAL_COOLDOWN_FRAMES[settings.frequency]
  if not scenario.critical and scenario.priority < 80
    and scenario.frame - self.last_message_frame < globalCooldown then
    return nil
  end
  local selected = nil
  for _, candidate in ipairs(self.rules) do
    if candidate.schema_version == Constants.SCHEMA_VERSION
      and candidate.scenario_id == scenario.id
      and Constants.SPOILER_RANK[candidate.spoiler_level] <= Constants.SPOILER_RANK[settings.spoiler_level]
      and (self.counts[candidate.id] or 0) < candidate.max_per_run then
      local lastFrame = self.last_frames[candidate.id] or -math.huge
      local cooldown = candidate.cooldown_frames * Constants.FREQUENCY_COOLDOWN[settings.frequency]
      if scenario.critical or scenario.frame - lastFrame >= cooldown then
        if selected == nil or candidate.priority > selected.priority then selected = candidate end
      end
    end
  end
  if selected == nil then return nil end

  local variants = selected.variants[settings.persona] or selected.variants.strategist
  local key = table.concat({ tostring(context.run_seed), tostring(scenario.sequence), selected.id }, ":")
  local start = (stableHash(key) % #variants) + 1
  local text = nil
  for offset = 0, #variants - 1 do
    local candidate = variants[((start + offset - 1) % #variants) + 1]
    if not wasRecent(self.recent, candidate) then text = candidate break end
  end
  text = text or variants[start]

  self.counts[selected.id] = (self.counts[selected.id] or 0) + 1
  self.last_frames[selected.id] = scenario.frame
  self.last_message_frame = scenario.frame
  table.insert(self.recent, text)
  if #self.recent > 8 then table.remove(self.recent, 1) end
  return {
    text = text,
    scenario_id = scenario.id,
    priority = math.max(scenario.priority, selected.priority),
    critical = scenario.critical,
  }
end

return CommentEngine

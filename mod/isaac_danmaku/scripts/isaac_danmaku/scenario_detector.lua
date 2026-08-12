local Constants = include("scripts.isaac_danmaku.constants")

local ScenarioDetector = {}
ScenarioDetector.__index = ScenarioDetector

local ROOM_SCENARIOS = {
  treasure = "F2", shop = "F3", devil = "F4", angel = "F5",
  sacrifice = "F6", secret = "F7", super_secret = "F7",
}

local PRIORITIES = {
  A1 = 30, A3 = 80, A9 = 45, C1 = 70, C8 = 100,
  F1 = 60, F2 = 50, F3 = 50, F4 = 65, F5 = 65, F6 = 50, F7 = 55,
  H1 = 90, H2 = 90, H6 = 100,
}

function ScenarioDetector.new()
  return setmetatable({}, ScenarioDetector)
end

local function classify(fact)
  local data = fact.data or {}
  if fact.kind == "run_started" then return data.is_continued and "H2" or "H1" end
  if fact.kind == "new_level" then return "F1" end
  if fact.kind == "room_entered" then
    if data.room_type == "boss" then return "A3" end
    if ROOM_SCENARIOS[data.room_type] then return ROOM_SCENARIOS[data.room_type] end
    if data.has_enemies then return "A1" end
  end
  if fact.kind == "room_cleared" then return "A9" end
  if fact.kind == "player_damaged" then return "C1" end
  if fact.kind == "player_died" then return "C8" end
  if fact.kind == "run_ended" and data.won then return "H6" end
  return nil
end

function ScenarioDetector:consume(context, fact)
  local scenarioId = classify(fact)
  context:apply(fact)
  if scenarioId == nil or not Constants.SCENARIOS[scenarioId] then return nil end
  local lifecycleIds = nil
  if scenarioId == "F1" then lifecycleIds = { "H3" } end
  if scenarioId == "C8" then lifecycleIds = { "H5" } end
  return {
    id = scenarioId,
    frame = fact.frame,
    sequence = context:nextSequence(),
    priority = PRIORITIES[scenarioId] or 0,
    critical = scenarioId == "C8" or scenarioId == "H6",
    facts = fact.data or {},
    lifecycle_ids = lifecycleIds,
  }
end

return ScenarioDetector

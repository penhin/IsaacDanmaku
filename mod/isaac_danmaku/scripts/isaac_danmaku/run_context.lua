local RunContext = {}
RunContext.__index = RunContext

function RunContext.new()
  local self = setmetatable({}, RunContext)
  self:reset()
  return self
end

function RunContext:reset()
  self.active = false
  self.run_seed = 0
  self.is_continued = false
  self.started_frame = 0
  self.stage = nil
  self.stage_type = nil
  self.room_index = nil
  self.room_type = nil
  self.room_started_frame = nil
  self.combat_started_frame = nil
  self.last_health = nil
  self.damage_count = 0
  self.room_damage_count = 0
  self.scenario_sequence = 0
end

function RunContext:apply(fact)
  local kind = fact.kind
  local data = fact.data or {}
  if kind == "run_started" then
    self:reset()
    self.active = true
    self.run_seed = data.run_seed or 0
    self.is_continued = data.is_continued == true
    self.started_frame = fact.frame
    self.last_health = data.hearts
  elseif kind == "new_level" then
    self.stage = data.stage
    self.stage_type = data.stage_type
    self.room_index = nil
    self.room_type = nil
    self.room_started_frame = nil
    self.combat_started_frame = nil
    self.room_damage_count = 0
  elseif kind == "room_entered" then
    self.room_index = data.room_index
    self.room_type = data.room_type
    self.room_started_frame = fact.frame
    self.combat_started_frame = data.has_enemies and fact.frame or nil
    self.room_damage_count = 0
  elseif kind == "player_damaged" then
    self.damage_count = self.damage_count + 1
    self.room_damage_count = self.room_damage_count + 1
  elseif kind == "health_snapshot" then
    self.last_health = data.hearts or self.last_health
  elseif kind == "room_cleared" then
    self.combat_started_frame = nil
  elseif kind == "player_died" or kind == "run_ended" then
    self.active = false
  end
end

function RunContext:nextSequence()
  self.scenario_sequence = self.scenario_sequence + 1
  return self.scenario_sequence
end

function RunContext:snapshot()
  return {
    run_seed = self.run_seed,
    is_continued = self.is_continued,
    stage = self.stage,
    stage_type = self.stage_type,
    room_index = self.room_index,
    room_type = self.room_type,
    hearts = self.last_health,
    damage_count = self.damage_count,
    room_damage_count = self.room_damage_count,
  }
end

return RunContext

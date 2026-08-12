local failures = 0
local checks = 0

function include(name)
  local path = "mod/isaac_danmaku/" .. string.gsub(name, "%.", "/") .. ".lua"
  return assert(loadfile(path))()
end

local luaFiles = {
  "mod/isaac_danmaku/main.lua",
  "mod/isaac_danmaku/scripts/isaac_danmaku/callbacks.lua",
  "mod/isaac_danmaku/scripts/isaac_danmaku/comment_engine.lua",
  "mod/isaac_danmaku/scripts/isaac_danmaku/constants.lua",
  "mod/isaac_danmaku/scripts/isaac_danmaku/danmaku.lua",
  "mod/isaac_danmaku/scripts/isaac_danmaku/dev_console.lua",
  "mod/isaac_danmaku/scripts/isaac_danmaku/mcm.lua",
  "mod/isaac_danmaku/scripts/isaac_danmaku/rules.lua",
  "mod/isaac_danmaku/scripts/isaac_danmaku/run_context.lua",
  "mod/isaac_danmaku/scripts/isaac_danmaku/scenario_detector.lua",
  "mod/isaac_danmaku/scripts/isaac_danmaku/settings.lua",
}

local function check(name, condition)
  checks = checks + 1
  if not condition then
    failures = failures + 1
    io.stderr:write("FAIL: " .. name .. "\n")
  end
end

for _, path in ipairs(luaFiles) do
  check("syntax " .. path, loadfile(path) ~= nil)
end

local Settings = include("scripts.isaac_danmaku.settings")
local RunContext = include("scripts.isaac_danmaku.run_context")
local ScenarioDetector = include("scripts.isaac_danmaku.scenario_detector")
local CommentEngine = include("scripts.isaac_danmaku.comment_engine")
local Rules = include("scripts.isaac_danmaku.rules")
local Danmaku = include("scripts.isaac_danmaku.danmaku")
local Mcm = include("scripts.isaac_danmaku.mcm")
local Callbacks = include("scripts.isaac_danmaku.callbacks")
local DevConsole = include("scripts.isaac_danmaku.dev_console")
local Constants = include("scripts.isaac_danmaku.constants")

local defaults = Settings.sanitize({ opacity = 4, max_visible = 99, persona = "invalid" })
check("settings clamp opacity", defaults.opacity == 1.0)
check("settings clamp lane count", defaults.max_visible == 3)
check("settings reject enum", defaults.persona == "strategist")
check("font scales stay compact and ordered", Constants.FONT_SCALE.small < Constants.FONT_SCALE.medium
  and Constants.FONT_SCALE.medium < Constants.FONT_SCALE.large
  and Constants.FONT_SCALE.medium <= 0.35)
check("normal danmaku remains readable", Constants.SPEED_FRAMES.normal >= 480)

local saved = "old"
local fakeMod = {
  HasData = function() return true end,
  LoadData = function() return saved end,
}
local fakeCodec = {
  decode = function(value)
    if value == "broken" then error("bad json") end
    return { schema_version = 0, enabled = false }
  end,
}
Isaac = { DebugString = function() end, ConsoleOutput = function() end }
check("old settings schema restores defaults", Settings.load(fakeMod, fakeCodec).enabled == true)
saved = "broken"
check("corrupt settings restores defaults", Settings.load(fakeMod, fakeCodec).enabled == true)

local menuSettings = Settings.sanitize(nil)
local menuEntries = {}
local menuSaves = 0
ModConfigMenu = {
  OptionType = { BOOLEAN = 1, NUMBER = 2, SCROLL = 3 },
  RemoveCategory = function() end,
  AddTitle = function() end,
  AddSetting = function(_, _, entry) table.insert(menuEntries, entry) end,
}
local menuRenderer = { setSettings = function() end }
check("MCM registers when global is available",
  Mcm.register(menuSettings, function() menuSaves = menuSaves + 1 end, menuRenderer) == true)
local opacityEntry = nil
for _, entry in ipairs(menuEntries) do
  if entry.Type == ModConfigMenu.OptionType.SCROLL then opacityEntry = entry end
end
opacityEntry.OnChange(0)
check("MCM opacity lower endpoint", menuSettings.opacity == 0.5)
opacityEntry.OnChange(10)
check("MCM opacity upper endpoint", menuSettings.opacity == 1.0 and menuSaves == 2)
ModConfigMenu = nil

local context = RunContext.new()
local detector = ScenarioDetector.new()
local started = detector:consume(context, {
  kind = "run_started", frame = 10,
  data = { run_seed = 123, is_continued = false, hearts = 6 },
})
check("new run becomes H1", started.id == "H1")
check("run context activates", context.active and context.run_seed == 123)

local continuedContext = RunContext.new()
local continued = detector:consume(continuedContext, {
  kind = "run_started", frame = 10,
  data = { run_seed = 456, is_continued = true, hearts = 4 },
})
check("continued run becomes H2", continued.id == "H2")

local boss = detector:consume(context, {
  kind = "room_entered", frame = 40,
  data = { room_index = 5, room_type = "boss", has_enemies = true },
})
check("boss room prefers A3", boss.id == "A3")

local secret = detector:consume(context, {
  kind = "room_entered", frame = 50,
  data = { room_index = 6, room_type = "super_secret", has_enemies = false },
})
check("super secret room maps to F7", secret.id == "F7")

local damaged = detector:consume(context, {
  kind = "player_damaged", frame = 60,
  data = { amount = 1, hearts_before = 6 },
})
check("damage becomes C1", damaged.id == "C1")
detector:consume(context, { kind = "health_snapshot", frame = 61, data = { hearts = 4 } })
check("damage updates context", context.last_health == 4 and context.damage_count == 1)

local floor = detector:consume(context, {
  kind = "new_level", frame = 70, data = { stage = 2, stage_type = 0 },
})
check("floor event carries H3 without duplicate comment", floor.id == "F1" and floor.lifecycle_ids[1] == "H3")

local died = detector:consume(context, { kind = "player_died", frame = 80, data = {} })
check("death event carries H5 without duplicate comment", died.id == "C8" and died.lifecycle_ids[1] == "H5")

local registered = {}
local callbackFacts = {}
local callbackContext = RunContext.new()
callbackContext.active = true
callbackContext.stage = 1
callbackContext.stage_type = 0
local callbackGame = {
  GetFrameCount = function() return 100 end,
  GetSeeds = function() return { GetStartSeed = function() return 789 end } end,
  GetLevel = function()
    return {
      GetStage = function() return 2 end,
      GetStageType = function() return 0 end,
      GetCurrentRoomIndex = function() return 7 end,
    }
  end,
  GetRoom = function()
    return {
      GetType = function() return 1 end,
      IsClear = function() return false end,
      GetAliveEnemiesCount = function() return 2 end,
    }
  end,
}
Game = function() return callbackGame end
local callbackPlayer = {
  GetHearts = function() return 4 end,
  GetSoulHearts = function() return 2 end,
  GetBoneHearts = function() return 0 end,
}
Isaac.GetPlayer = function() return callbackPlayer end
RoomType = {
  ROOM_BOSS = 5, ROOM_TREASURE = 4, ROOM_SHOP = 2, ROOM_DEVIL = 14,
  ROOM_ANGEL = 15, ROOM_SACRIFICE = 13, ROOM_SECRET = 7, ROOM_SUPERSECRET = 8,
}
EntityType = { ENTITY_PLAYER = 1 }
ModCallbacks = {
  MC_POST_GAME_STARTED = 1, MC_POST_NEW_LEVEL = 2, MC_POST_NEW_ROOM = 3,
  MC_ENTITY_TAKE_DMG = 4, MC_PRE_SPAWN_CLEAN_AWARD = 5, MC_POST_UPDATE = 6,
  MC_POST_GAME_END = 7, MC_PRE_GAME_EXIT = 8, MC_POST_RENDER = 9,
  MC_EXECUTE_CMD = 10,
}
local callbackMod = {
  AddCallback = function(_, id, fn) registered[id] = fn end,
  AddPriorityCallback = function(_, id, _, fn) registered[id] = fn end,
}
CallbackPriority = { EARLY = -100 }
Callbacks.register(callbackMod, callbackContext,
  function(fact) table.insert(callbackFacts, fact); callbackContext:apply(fact) end,
  { clear = function() end, updateAndRender = function() end }, function() end)
registered[ModCallbacks.MC_POST_NEW_ROOM]()
registered[ModCallbacks.MC_POST_NEW_LEVEL]()
check("level callbacks normalize native reverse order", #callbackFacts == 2
  and callbackFacts[1].kind == "new_level"
  and callbackFacts[2].kind == "room_entered"
  and callbackFacts[2].silent == true)

local reloadContext = RunContext.new()
local reloadFacts = {}
Callbacks.register(callbackMod, reloadContext,
  function(fact) table.insert(reloadFacts, fact); reloadContext:apply(fact) end,
  { clear = function() end, updateAndRender = function() end }, function() end)
check("hot reload silently rehydrates active run", reloadContext.active
  and reloadContext.run_seed == 789
  and reloadContext.stage == 2
  and reloadContext.room_index == 7
  and #reloadFacts == 3
  and reloadFacts[1].silent == true)

local previews = {}
local previewRenderer = {
  active = {}, queue = {},
  push = function(_, message) table.insert(previews, message) end,
  preview = function(_, message) previews = { message } end,
  clear = function() previews = {} end,
}
DevConsole.register(callbackMod, previewRenderer, Settings.sanitize(nil), Rules, callbackContext)
registered[ModCallbacks.MC_EXECUTE_CMD](nil, "idm", "test A3")
check("dev command previews one scene", #previews == 1 and previews[1].scenario_id == "A3")
registered[ModCallbacks.MC_EXECUTE_CMD](nil, "idm", "clear")
check("dev command clears previews", #previews == 0)
registered[ModCallbacks.MC_EXECUTE_CMD](nil, "idm", "A3")
check("short dev command previews one scene", #previews == 1 and previews[1].scenario_id == "A3")
registered[ModCallbacks.MC_EXECUTE_CMD](nil, "idm", "clear")
IsaacDanmakuDev("test A3")
check("built-in lua command fallback previews scene", #previews == 1 and previews[1].scenario_id == "A3")
I("clear")
I("A3")
check("short built-in lua alias previews scene", #previews == 1 and previews[1].scenario_id == "A3")

local settings = Settings.sanitize(nil)
local engineA = CommentEngine.new(Rules)
local engineB = CommentEngine.new(Rules)
local messageA = engineA:generate(started, context, settings)
local messageB = engineB:generate(started, context, settings)
check("stable text choice", messageA.text == messageB.text)
check("message carries scenario", messageA.scenario_id == "H1")
check("max per run silences duplicate start", engineA:generate(started, context, settings) == nil)

local pacingEngine = CommentEngine.new(Rules)
local firstRoom = { id = "A1", frame = 100, sequence = 10, priority = 30, critical = false }
local nextRoom = { id = "A9", frame = 200, sequence = 11, priority = 40, critical = false }
local laterRoom = { id = "A9", frame = 4700, sequence = 12, priority = 40, critical = false }
check("first ordinary message passes global pacing", pacingEngine:generate(firstRoom, context, settings) ~= nil)
check("global pacing silences nearby ordinary message", pacingEngine:generate(nextRoom, context, settings) == nil)
check("ordinary message resumes after global cooldown", pacingEngine:generate(laterRoom, context, settings) ~= nil)

local platform = {
  width = function() return 640 end,
  height = function() return 360 end,
  textWidth = function(text) return #text * 8 end,
  random = function(maximum) return maximum end,
  draw = function() end,
}
local renderer = Danmaku.new(settings, platform)
for index = 1, 20 do renderer:push({ text = "m" .. index, priority = index, critical = false }) end
check("renderer bounds queue", #renderer.queue == 12)
renderer:updateAndRender()
check("renderer fills configured lanes", #renderer.active == settings.max_visible)
renderer:push({ text = "critical", priority = 100, critical = true })
check("critical message preempts a lower priority lane", #renderer.active == settings.max_visible - 1)
renderer:updateAndRender()
local foundCritical = false
for _, message in ipairs(renderer.active) do
  if message.text == "critical" then foundCritical = true end
end
check("critical message takes the released lane", foundCritical)
renderer:clear()
check("renderer clear", #renderer.queue == 0 and #renderer.active == 0)
settings.enabled = false
renderer:preview({ text = "forced preview", priority = 1, critical = false })
check("renderer preview bypasses disabled setting and stale queue",
  #renderer.queue == 1 and renderer.queue[1].text == "forced preview")
settings.enabled = true

local laneSettings = Settings.sanitize({ max_visible = 3 })
local laneRenderer = Danmaku.new(laneSettings, platform)
for index = 1, 3 do laneRenderer:push({ text = "lane" .. index, priority = 1, critical = false }) end
laneRenderer:updateAndRender()
local occupied = {}
for _, message in ipairs(laneRenderer.active) do occupied[message.lane] = true end
check("renderer randomly assigns three unique nearby rows",
  occupied[1] and occupied[2] and occupied[3])

local covered = {}
for _, rule in ipairs(Rules) do covered[rule.scenario_id] = true end
for scenarioId in pairs(include("scripts.isaac_danmaku.constants").COMMENT_SCENARIOS) do
  check("rule coverage " .. scenarioId, covered[scenarioId] == true)
end

if io.open ~= nil then
  local glyphs = {}
  local fontFile = assert(io.open("mod/isaac_danmaku/resources/font/isaac_danmaku_zh.fnt.txt", "r"))
  for line in fontFile:lines() do
    local id = string.match(line, "^char id=(%d+)")
    if id ~= nil then glyphs[tonumber(id)] = true end
  end
  fontFile:close()
  for _, path in ipairs(luaFiles) do
    local sourceFile = assert(io.open(path, "r"))
    local source = sourceFile:read("*a")
    sourceFile:close()
    for _, codepoint in utf8.codes(source) do
      if codepoint >= 32 then check("font glyph U+" .. string.format("%04X", codepoint), glyphs[codepoint] == true) end
    end
  end
end

if failures > 0 then
  io.stderr:write(string.format("%d/%d checks failed\n", failures, checks))
  os.exit(1)
end
print(string.format("%d Lua checks passed", checks))

local IsaacDanmaku = RegisterMod("IsaacDanmaku", 1)
local json = require("json")

local function currentModPath()
  if debug ~= nil then
    local source = string.sub(debug.getinfo(currentModPath).source, 2)
    return string.gsub(source, "main.lua$", "")
  end

  -- Standard sandbox hides `debug`. A failed local require exposes the
  -- current mod search path; this is the same fallback used by established
  -- Repentance+ mods such as EID and Mod Config Menu.
  local _, requireError = pcall(require, "")
  local _, basePathStart = string.find(requireError, "no file '", 1, true)
  if basePathStart ~= nil then
    local _, modPathStart = string.find(requireError, "no file '", basePathStart + 1, true)
    if modPathStart ~= nil then
      local modPathEnd = string.find(requireError, ".lua'", modPathStart + 1, true)
      if modPathEnd ~= nil then
        local path = string.sub(requireError, modPathStart + 1, modPathEnd - 1)
        return string.gsub(path, "\\", "/")
      end
    end
  end
  return "../mods/isaac_danmaku/"
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

local settings = Settings.load(IsaacDanmaku, json)
local context = RunContext.new()
local detector = ScenarioDetector.new()
local engine = CommentEngine.new(Rules)
local renderer = Danmaku.new(settings, nil,
  currentModPath() .. "resources/font/isaac_danmaku_zh.fnt")

local function persistSettings()
  Settings.save(IsaacDanmaku, json, settings)
end

local function onFact(fact)
  if fact.kind == "run_started" then
    engine:reset()
    renderer:clear()
  end
  local scenario = detector:consume(context, fact)
  if scenario == nil or fact.silent then
    return
  end

  local message = engine:generate(scenario, context, settings)
  if message ~= nil then
    renderer:push(message)
  end
end

local mcmOk, mcmError = pcall(Mcm.register, settings, persistSettings, renderer)
if not mcmOk then
  Isaac.DebugString("[IsaacDanmaku] ModConfigMenu registration failed: " .. tostring(mcmError))
end
Callbacks.register(IsaacDanmaku, context, onFact, renderer, persistSettings)
DevConsole.register(IsaacDanmaku, renderer, settings, Rules, context)

Isaac.DebugString("[IsaacDanmaku] 0.1.1 loaded (Repentance+ single-player only)")

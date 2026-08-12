local DevConsole = {}

local COMMANDS = { isaacdanmaku = true, idm = true }

local function output(text)
  Isaac.ConsoleOutput("[IsaacDanmaku] " .. text .. "\n")
end

local function split(value)
  local parts = {}
  for part in string.gmatch(value or "", "%S+") do
    table.insert(parts, part)
  end
  return parts
end

local function findRule(rules, scenarioId)
  for _, rule in ipairs(rules) do
    if rule.scenario_id == scenarioId then return rule end
  end
  return nil
end

local function scenarioIds(rules)
  local ids = {}
  for _, rule in ipairs(rules) do table.insert(ids, rule.scenario_id) end
  table.sort(ids)
  return ids
end

function DevConsole.register(mod, renderer, settings, rules, context)
  local pending = {}

  local function showRule(scenarioId)
    local rule = findRule(rules, scenarioId)
    if rule == nil then
      output("unknown scenario: " .. scenarioId)
      return false
    end
    local variants = rule.variants[settings.persona] or rule.variants.strategist
    renderer:push({
      text = "[" .. scenarioId .. "] " .. variants[1],
      scenario_id = scenarioId,
      priority = rule.priority,
      critical = rule.priority >= 100,
    })
    output("queued scenario " .. scenarioId)
    return true
  end

  local function showHelp()
    output("commands:")
    output("  idm test <scene-id>  - preview one scene, e.g. idm test A3")
    output("  idm test all         - preview every M0 comment in order")
    output("  idm clear            - clear previews and danmaku")
    output("  idm status           - show context and renderer state")
    output("  idm list             - list available scene IDs")
  end

  local function execute(_, command, parameters)
    if not COMMANDS[string.lower(command or "")] then return end
    Isaac.DebugString("[IsaacDanmaku] console command: "
      .. tostring(command) .. " " .. tostring(parameters))
    local arguments = split(parameters)
    local action = string.lower(arguments[1] or "help")

    if action == "test" then
      local requested = string.upper(arguments[2] or "")
      if requested == "ALL" then
        pending = scenarioIds(rules)
        output("queued " .. tostring(#pending) .. " scenarios")
      elseif requested == "" then
        output("missing scene ID; try: idm test A3")
      else
        showRule(requested)
      end
    elseif action == "clear" then
      pending = {}
      renderer:clear()
      output("preview queue cleared")
    elseif action == "status" then
      output("active=" .. tostring(context.active)
        .. " stage=" .. tostring(context.stage)
        .. " room=" .. tostring(context.room_index)
        .. " active_messages=" .. tostring(#renderer.active)
        .. " queued_messages=" .. tostring(#renderer.queue)
        .. " pending_previews=" .. tostring(#pending))
    elseif action == "list" then
      output(table.concat(scenarioIds(rules), " "))
    else
      showHelp()
    end
    return "[IsaacDanmaku] command accepted"
  end

  -- Run before ordinary callbacks from other mods. A malformed command
  -- handler in another mod can otherwise swallow custom console commands.
  if mod.AddPriorityCallback ~= nil and CallbackPriority ~= nil then
    mod:AddPriorityCallback(ModCallbacks.MC_EXECUTE_CMD, CallbackPriority.EARLY, execute)
  else
    mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, execute)
  end

  -- Reliable fallback through the game's built-in `lua` command:
  --   lua IsaacDanmakuDev("test A3")
  _G.IsaacDanmakuDev = function(parameters)
    return execute(nil, "idm", parameters or "help")
  end

  mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if #pending == 0 then return end
    if #renderer.active == 0 and #renderer.queue == 0 then
      showRule(table.remove(pending, 1))
    end
  end)
end

return DevConsole

local Callbacks = {}

local function primaryHealth()
  local player = Isaac.GetPlayer(0)
  return player:GetHearts() + player:GetSoulHearts() + player:GetBoneHearts() * 2
end

local function roomName(roomType)
  if roomType == RoomType.ROOM_BOSS then return "boss" end
  if roomType == RoomType.ROOM_TREASURE then return "treasure" end
  if roomType == RoomType.ROOM_SHOP then return "shop" end
  if roomType == RoomType.ROOM_DEVIL then return "devil" end
  if roomType == RoomType.ROOM_ANGEL then return "angel" end
  if roomType == RoomType.ROOM_SACRIFICE then return "sacrifice" end
  if roomType == RoomType.ROOM_SECRET then return "secret" end
  if roomType == RoomType.ROOM_SUPERSECRET then return "super_secret" end
  return "normal"
end

function Callbacks.register(mod, context, onFact, renderer, persistSettings)
  local game = Game()
  local deathReported = false
  local healthRefreshPending = false
  local levelHandledEarly = false

  local function frame() return game:GetFrameCount() end

  local function emitNewLevel(silent)
    if not context.active then return end
    local level = game:GetLevel()
    onFact({
      kind = "new_level",
      frame = frame(),
      data = { stage = level:GetStage(), stage_type = level:GetStageType() },
      silent = silent == true,
    })
  end

  local function emitRoomEntered(silent)
    if not context.active then return end
    local room = game:GetRoom()
    local level = game:GetLevel()
    onFact({
      kind = "room_entered",
      frame = frame(),
      data = {
        room_index = level:GetCurrentRoomIndex(),
        room_type = roomName(room:GetType()),
        has_enemies = not room:IsClear() and room:GetAliveEnemiesCount() > 0,
      },
      silent = silent == true,
    })
  end

  mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, isContinued)
    deathReported = false
    onFact({
      kind = "run_started",
      frame = frame(),
      data = {
        is_continued = isContinued,
        run_seed = game:GetSeeds():GetStartSeed(),
        hearts = primaryHealth(),
      },
    })
    -- Vanilla fires the initial level callback before POST_GAME_STARTED.
    emitNewLevel(true)
    emitRoomEntered(true)
  end)

  mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
    if levelHandledEarly then
      levelHandledEarly = false
      return
    end
    emitNewLevel()
  end)

  mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    if context.active then
      local level = game:GetLevel()
      if context.stage ~= level:GetStage() or context.stage_type ~= level:GetStageType() then
        -- The game calls NEW_ROOM before NEW_LEVEL. Normalize the facts here,
        -- then ignore the later native level callback.
        levelHandledEarly = true
        emitNewLevel()
        emitRoomEntered(true)
        return
      end
    end
    emitRoomEntered()
  end)

  mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount)
    if not context.active then return end
    local player = entity:ToPlayer()
    if player == nil or GetPtrHash(player) ~= GetPtrHash(Isaac.GetPlayer(0)) then return end
    onFact({
      kind = "player_damaged",
      frame = frame(),
      data = { amount = amount, hearts_before = primaryHealth() },
    })
    healthRefreshPending = true
  end, EntityType.ENTITY_PLAYER)

  mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
    if not context.active or context.combat_started_frame == nil then return end
    onFact({
      kind = "room_cleared",
      frame = frame(),
      data = {
        combat_frames = frame() - context.combat_started_frame,
        damage_taken = context.room_damage_count,
      },
    })
  end)

  mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if context.active and healthRefreshPending then
      healthRefreshPending = false
      onFact({ kind = "health_snapshot", frame = frame(), data = { hearts = primaryHealth() }, silent = true })
    end
    if not context.active or deathReported then return end
    local player = Isaac.GetPlayer(0)
    if player:IsDead() then
      deathReported = true
      onFact({ kind = "player_died", frame = frame(), data = {} })
    end
  end)

  mod:AddCallback(ModCallbacks.MC_POST_GAME_END, function(_, isGameOver)
    if not isGameOver then
      onFact({ kind = "run_ended", frame = frame(), data = { won = true } })
    elseif not deathReported then
      deathReported = true
      onFact({ kind = "player_died", frame = frame(), data = {} })
    end
  end)

  mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
    persistSettings()
    context:reset()
    renderer:clear()
    deathReported = false
    healthRefreshPending = false
    levelHandledEarly = false
  end)

  mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    renderer:updateAndRender()
  end)

  -- `luamod isaac_danmaku` reloads files but does not replay the native
  -- game-start callbacks. Rehydrate the domain state silently when reloading
  -- during a run so subsequent room, damage, and floor facts remain usable.
  if game:GetFrameCount() > 0 and not context.active then
    onFact({
      kind = "run_started",
      frame = frame(),
      silent = true,
      data = {
        is_continued = true,
        run_seed = game:GetSeeds():GetStartSeed(),
        hearts = primaryHealth(),
      },
    })
    emitNewLevel(true)
    emitRoomEntered(true)
  end
end

return Callbacks

local Constants = {}

Constants.SCHEMA_VERSION = 2
Constants.SAVE_VERSION = 1

Constants.PERSONAS = { "strategist", "roaster", "supporter" }
Constants.SPOILERS = { "none", "hint", "full" }
Constants.FREQUENCIES = { "off", "low", "normal", "high" }
Constants.POSITIONS = { "top", "middle", "bottom" }
Constants.SPEEDS = { "slow", "normal", "fast" }
Constants.FONT_SIZES = { "small", "medium", "large" }

Constants.SPOILER_RANK = { none = 0, hint = 1, full = 2 }
Constants.FREQUENCY_COOLDOWN = { off = math.huge, low = 2.0, normal = 1.0, high = 0.55 }
Constants.GLOBAL_COOLDOWN_FRAMES = { off = math.huge, low = 9000, normal = 4500, high = 1800 }
Constants.SPEED_FRAMES = { slow = 210, normal = 150, fast = 105 }
Constants.FONT_SCALE = { small = 0.8, medium = 1.0, large = 1.2 }

Constants.SCENARIOS = {
  A1 = true, A3 = true, A9 = true,
  C1 = true, C8 = true,
  F1 = true, F2 = true, F3 = true, F4 = true, F5 = true, F6 = true, F7 = true,
  H1 = true, H2 = true, H3 = true, H5 = true, H6 = true,
}

Constants.COMMENT_SCENARIOS = {
  A1 = true, A3 = true, A9 = true,
  C1 = true, C8 = true,
  F1 = true, F2 = true, F3 = true, F4 = true, F5 = true, F6 = true, F7 = true,
  H1 = true, H2 = true, H6 = true,
}

return Constants

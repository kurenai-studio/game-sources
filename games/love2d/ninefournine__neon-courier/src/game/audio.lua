-- Original score/SFX, tolerant of absent devices and browser gesture policies.
-- Sources are allocated once; static effects use small bounded voice pools.
local audio = { disabled = false, unlocked = false, status = "not loaded" }
local sources, effects, poolIndex = {}, {}, {}
local effectGain = {}
local level = { music = 0, sfx = 0, chase = 0, engine = 0, skid = 0 }
local wasBoost = false
local lastDriftCheck = 0

local function clamp(value, lo, hi)
  return math.max(lo, math.min(hi, value))
end

local function approach(current, target, dt, rate)
  return current + (target - current) * (1 - math.exp(-rate * dt))
end

local function safe(method, source, ...)
  if not source then return nil end
  local ok, result = pcall(source[method], source, ...)
  if ok then return result end
  audio.disabled = true
  audio.status = "audio unavailable: " .. tostring(result)
  return nil
end

local function setting(settings, long, short, fallback)
  local value = settings and settings[long]
  if value == nil and settings then value = settings[short] end
  if type(value) ~= "number" or value ~= value then value = fallback end
  return clamp(value, 0, 1)
end

local function muted(settings)
  return settings and (settings.muted or settings.mute)
end

function audio.load(settings)
  audio.stop()
  sources, effects, poolIndex, effectGain = {}, {}, {}, {}
  audio.disabled, audio.unlocked = false, false
  if not love or not love.audio or not love.audio.newSource then
    audio.disabled, audio.status = true, "audio module unavailable"
    return false
  end
  local function source(name, extension, kind, looping)
    local ok, result = pcall(love.audio.newSource, "assets/audio/" .. name .. extension, kind)
    if not ok then
      audio.disabled, audio.status = true, "audio unavailable: " .. tostring(result)
      return nil
    end
    safe("setVolume", result, 0)
    if looping then safe("setLooping", result, true) end
    return result
  end
  -- Matching static buffers are started together in one update, then kept
  -- within 30ms. Memory: about 3.4MB decoded mono PCM, plus short SFX.
  sources.music = source("night_shift", ".ogg", "static", true)
  sources.chase = source("chase_layer", ".ogg", "static", true)
  sources.rain = source("rain", ".ogg", "static", true)
  sources.engine = source("engine", ".wav", "static", true)
  sources.skid = source("skid", ".ogg", "static", true)
  local names = { "pickup", "delivery", "upgrade", "failed", "impact", "emp",
    "explosion", "boost", "ui", "back" }
  for _, name in ipairs(names) do
    local first = source(name, ".wav", "static", false)
    effects[name] = { first }
    if first then
      for i = 2, (name == "impact" and 3 or 2) do
        local ok, copy = pcall(first.clone, first)
        if ok then effects[name][i] = copy end
      end
    end
    poolIndex[name] = 1
  end
  level = { music = 0, sfx = 0, chase = 0, engine = 0, skid = 0 }
  wasBoost, lastDriftCheck = false, 0
  if not audio.disabled then audio.status = "ready; waiting for start gesture" end
  return not audio.disabled
end

function audio.unlock()
  if audio.disabled or audio.unlocked then return not audio.disabled end
  -- Call directly from start/confirm handling, before returning to love.update;
  -- love.js resumes its WebAudio context on this user gesture.
  local started = 0
  for _, name in ipairs({ "music", "chase", "rain", "engine", "skid" }) do
    local source = sources[name]
    if source then
      -- love.js 11.5's OpenAL batch-play path can raise a JavaScript exception
      -- outside Lua pcall. Scalar Source:play uses the tested backend path.
      local result = safe("play", source)
      if audio.disabled or result == false then
        audio.disabled = true
        if result == false then audio.status = "audio playback unavailable" end
        return false
      end
      started = started + 1
    end
  end
  if started == 0 then return false end
  audio.unlocked, audio.status = true, "playing"
  return true
end

function audio.play(name)
  if audio.disabled or not audio.unlocked or level.sfx < .001 then return end
  local voices = effects[name]
  if not voices or #voices == 0 then return end
  local index = poolIndex[name] or 1
  local voice = voices[index]
  poolIndex[name] = index % #voices + 1
  safe("stop", voice)
  local gain = (name == "impact" and .65 or name == "ui" and .50 or 1)
  effectGain[voice] = gain
  safe("setVolume", voice, level.sfx * gain)
  safe("play", voice)
end

function audio.update(dt, state, settings, mode)
  if audio.disabled or not audio.unlocked then return end
  dt = clamp(type(dt) == "number" and dt or 0, 0, .1)
  local music = setting(settings, "musicVolume", "music", .65)
  local sfx = setting(settings, "sfxVolume", "sfx", .75)
  if muted(settings) then music, sfx = 0, 0 end
  level.music = approach(level.music, music, dt, 7)
  level.sfx = approach(level.sfx, sfx, dt, 10)
  for voice, gain in pairs(effectGain) do
    safe("setVolume", voice, level.sfx * gain)
  end
  local playing = state and (mode == "playing" or mode == "shift" or mode == "onboarding"
    or mode == "play" or mode == nil)
  local p = state and state.player
  local speed = p and math.sqrt((p.vx or 0)^2 + (p.vy or 0)^2) or 0
  local boost = p and (p.boostActive or p.boosting) or false
  local pursuit = 0
  if playing then
    for _, car in ipairs(state.cars or {}) do
      if car.kind == "police" then
        local dx, dy = (car.x or 0) - (p and p.x or 0), (car.y or 0) - (p and p.y or 0)
        if dx*dx + dy*dy < 250*250 then pursuit = pursuit + 1 end
      end
    end
  end
  local heat = state and state.heat or 0
  local chaseTarget = playing and clamp(heat * .10 + pursuit * .21, 0, .85) or 0
  level.chase = approach(level.chase, chaseTarget, dt, 1.7)
  level.engine = approach(level.engine, playing and clamp(speed / 160, .10, .80) or 0, dt, 6)
  -- Drift is mechanical slip relative to the car's heading, where available.
  local slip = 0
  if p and type(p.angle or p.heading) == "number" and speed > 35 then
    local angle = p.angle or p.heading
    slip = math.abs(-(p.vx or 0) * math.sin(angle) + (p.vy or 0) * math.cos(angle)) / speed
  end
  local skid = playing and clamp((slip - .25) * .7, 0, .30) or 0
  level.skid = approach(level.skid, skid, dt, 8)
  local scoreGain = (mode == "pause" or mode == "paused" or mode == "upgrade") and .65 or 1
  -- Combined base/chase peak remains below .84 at maximum layer gain. Effects
  -- remain intentionally short and quiet, with separate user controls.
  safe("setVolume", sources.music, level.music * .78 * scoreGain)
  safe("setVolume", sources.chase, level.music * level.chase * .58 * scoreGain)
  safe("setVolume", sources.rain, level.sfx * .24)
  safe("setVolume", sources.engine, level.sfx * level.engine * .24)
  safe("setPitch", sources.engine, clamp(.65 + speed / 120 + (boost and .35 or 0), .65, 2.7))
  safe("setVolume", sources.skid, level.sfx * level.skid)
  if boost and not wasBoost and playing then audio.play("boost") end
  wasBoost = boost and playing
  -- Scalar starts share this update. Web backends can schedule static voices
  -- on adjacent frames; correct a demonstrated >30ms drift once a second.
  lastDriftCheck = lastDriftCheck + dt
  if lastDriftCheck > 1 then
    lastDriftCheck = 0
    local baseTime = safe("tell", sources.music, "seconds")
    local layerTime = safe("tell", sources.chase, "seconds")
    if baseTime and layerTime and math.abs(baseTime - layerTime) > .03
      and math.abs(baseTime - layerTime) < 38 then
      safe("seek", sources.chase, baseTime, "seconds")
    end
  end
end

function audio.stop()
  for _, source in pairs(sources) do pcall(source.stop, source) end
  for _, voices in pairs(effects) do
    for _, source in ipairs(voices) do pcall(source.stop, source) end
  end
  audio.unlocked = false
end

return audio

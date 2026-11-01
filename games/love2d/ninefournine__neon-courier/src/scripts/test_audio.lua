-- Deterministic module checks; no real device or listening is implied.
-- Run from the repository root: lua scripts/test_audio.lua
local function check(value, message) assert(value, message) end

love = nil
local absent = dofile("game/audio.lua")
check(not absent.load({}) and absent.disabled and not absent.unlock(), "missing audio module")
absent.update(.1, {}, {}, "play")
absent.play("impact")
absent.stop()

love = { audio = { newSource = function() error("simulated unavailable device") end } }
local device = dofile("game/audio.lua")
check(not device.load({}) and device.disabled, "missing audio device")

local all = {}
local function newSource(path)
  local source = { path = path, position = 0, plays = 0, volume = 0, pitch = 1 }
  function source:setVolume(value)
    check(value >= 0 and value <= 1, "volume bounds")
    self.volume = value
  end
  function source:setLooping(value) self.looping = value end
  function source:play() self.plays = self.plays + 1; return true end
  function source:stop() self.stopped = true end
  function source:clone() return newSource(self.path) end
  function source:setPitch(value) self.pitch = value end
  function source:tell() return self.position end
  function source:seek(value) self.position = value end
  all[#all + 1] = source
  return source
end
-- The browser regression was a fatal batch API exception outside Lua's pcall.
-- Keep bulk playback unavailable while scalar sources remain usable.
love = { audio = { newSource = newSource,
  play = function() error("batch API deliberately unavailable") end } }
local audio = dofile("game/audio.lua")
check(audio.load({ music = .4, sfx = .5 }) and not audio.unlocked, "gesture gating")
check(audio.unlock(), "scalar startup survives unavailable batch API")
for i = 1, 5 do check(all[i].plays == 1, "each continuous source starts once") end
audio.unlock()
for i = 1, 5 do check(all[i].plays == 1, "idempotent unlock") end

local state = { player = { x = 0, y = 0, vx = 100, vy = 0, angle = 0 }, heat = 2,
  cars = { { kind = "police", x = 20, y = 0 } } }
for i = 1, 80 do audio.update(.1, state, { music = .4, sfx = .5 }, "play") end
check(math.abs(all[1].volume - .312) < .001, "music setting alias")
check(all[2].volume > .07 and all[2].volume < .11, "pursuit layer")
check(all[4].volume > 0 and all[4].pitch > 1, "engine speed response")
all[1].position, all[2].position = 7, 7.1
for i = 1, 12 do audio.update(.1, state, { music = .4, sfx = .5 }, "play") end
check(all[2].position == 7, "score layer alignment correction")
for i = 1, 4 do audio.play("impact") end
local activeVoices = 0
for _, source in ipairs(all) do
  if source.path:match("impact") and source.plays > 0 then activeVoices = activeVoices + 1 end
end
check(activeVoices == 3, "bounded impact voice pool")
for i = 1, 100 do audio.update(.1, state, { music = .4, sfx = .5, muted = true }, "play") end
for _, source in ipairs(all) do check(source.volume < .001, "mute includes active effects") end
audio.stop()
check(not audio.unlocked, "stop/reset")
print("PASS audio: missing module/device, gesture gate, scalar startup, idempotence, settings, chase/engine, alignment, bounded effects, mute, stop")

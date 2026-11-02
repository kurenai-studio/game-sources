-- Kindred Lights — procedural audio
-- All in-game music and sound effects are synthesized here at load time.
-- Key/harmony/tempo mirror the theme track: Db major <-> F minor, ~117 BPM.

local A = {}

local SR_HI = 44100
local SR_LO = 22050
local TWO_PI = math.pi * 2
local sin, exp, floor, random = math.sin, math.exp, math.floor, math.random

local function mtof(m) return 440 * 2 ^ ((m - 69) / 12) end

-- sine lookup table for speed
local TBL_N = 4096
local SIN = {}
for i = 0, TBL_N do SIN[i] = sin(i / TBL_N * TWO_PI) end
local function fsin(phase) -- phase in cycles
  local p = (phase - floor(phase)) * TBL_N
  local i = floor(p)
  local f = p - i
  return SIN[i] + (SIN[i + 1] - SIN[i]) * f
end

local function bell(freq, dur)
  local n = floor(dur * SR_HI)
  local sd = love.sound.newSoundData(n, SR_HI, 16, 1)
  local partials = { { 1, 1.0, 1.0 }, { 2.0, 0.42, 1.8 }, { 3.003, 0.18, 2.8 }, { 4.17, 0.10, 4.0 }, { 5.43, 0.05, 5.5 } }
  local atk = floor(0.006 * SR_HI)
  for i = 0, n - 1 do
    local t = i / SR_HI
    local v = 0
    for k = 1, #partials do
      local p = partials[k]
      v = v + fsin(freq * p[1] * t + 0.002 * fsin(5 * t)) * p[2] * exp(-t * p[3] * 1.6)
    end
    local env = (i < atk) and (i / atk) or 1
    local tail = (i > n - 2000) and ((n - i) / 2000) or 1
    sd:setSample(i, v * 0.42 * env * tail)
  end
  return sd
end

local function pad(freq, dur)
  local n = floor(dur * SR_LO)
  local sd = love.sound.newSoundData(n, SR_LO, 16, 1)
  local atk, rel = 1.3, 1.8
  local d1, d2 = 1.0035, 0.9968
  for i = 0, n - 1 do
    local t = i / SR_LO
    local v = 0
    for h = 1, 5 do
      local amp = 1 / (h * h * 0.8 + 0.2)
      v = v + (fsin(freq * h * d1 * t) + fsin(freq * h * d2 * t + 0.3)) * amp
    end
    v = v * (0.75 + 0.25 * fsin(0.23 * t))
    local env
    if t < atk then env = (t / atk) ^ 2
    elseif t > dur - rel then env = math.max(0, (dur - t) / rel) ^ 1.5
    else env = 1 end
    sd:setSample(i, v * 0.11 * env)
  end
  return sd
end

local function bass(freq, dur)
  local n = floor(dur * SR_LO)
  local sd = love.sound.newSoundData(n, SR_LO, 16, 1)
  for i = 0, n - 1 do
    local t = i / SR_LO
    local v = fsin(freq * t) + 0.3 * fsin(freq * 2 * t) + 0.1 * fsin(freq * 3 * t)
    local env = math.min(1, t / 0.02) * exp(-t * 1.4)
    local tail = (i > n - 800) and ((n - i) / 800) or 1
    sd:setSample(i, v * 0.32 * env * tail)
  end
  return sd
end

local function kick()
  local dur = 0.42
  local n = floor(dur * SR_LO)
  local sd = love.sound.newSoundData(n, SR_LO, 16, 1)
  local ph = 0
  for i = 0, n - 1 do
    local t = i / SR_LO
    local f = 45 + 85 * exp(-t * 28)
    ph = ph + f / SR_LO
    local env = math.min(1, t / 0.003) * exp(-t * 9)
    sd:setSample(i, fsin(ph) * env * 0.55)
  end
  return sd
end

local function noiseHit(dur, decay, hp, vol)
  local n = floor(dur * SR_HI)
  local sd = love.sound.newSoundData(n, SR_HI, 16, 1)
  local prev, lp = 0, 0
  for i = 0, n - 1 do
    local t = i / SR_HI
    local w = random() * 2 - 1
    -- crude high-pass: difference, then gentle low-pass to soften
    local h = w - prev * hp
    prev = w
    lp = lp + (h - lp) * 0.45
    local env = math.min(1, t / 0.004) * exp(-t * decay)
    sd:setSample(i, lp * env * vol)
  end
  return sd
end

-- chord tables (MIDI)
local Db, Eb, F, Gb, Ab, Bb, C = 61, 63, 65, 66, 68, 70, 72
A.chords = {
  { name = "Db", root = 49, tones = { 61, 65, 68 } },
  { name = "Db", root = 49, tones = { 61, 65, 68 } },
  { name = "Db", root = 49, tones = { 61, 65, 68 } },
  { name = "Fm", root = 53, tones = { 60, 65, 68 } },
}
-- melodic (bell) pool: F natural minor / Db major notes, two octaves
local SCALE = { 0, 1, 3, 5, 7, 8, 10 } -- relative to C: C Db Eb F G Ab Bb  (G rarely used)

A.bpm = 117.45
A.beat = 60 / A.bpm

function A.load(progress)
  A.src = {}
  local step, total = 0, 0
  local bellNotes = {}
  for m = 60, 96 do
    local pc = m % 12
    if pc == 0 or pc == 1 or pc == 3 or pc == 5 or pc == 8 or pc == 10 then bellNotes[#bellNotes + 1] = m end
  end
  local padNotes = { 48, 49, 53, 56, 60, 61, 65, 68, 72 }
  local bassNotes = { 37, 41, 44 }
  A.bells, A.pads, A.basses = {}, {}, {}
  for _, m in ipairs(bellNotes) do A.bells[m] = love.audio.newSource(bell(mtof(m), 2.4), "static") end
  for _, m in ipairs(padNotes) do A.pads[m] = love.audio.newSource(pad(mtof(m), 7.5), "static") end
  for _, m in ipairs(bassNotes) do A.basses[m] = love.audio.newSource(bass(mtof(m), 2.2), "static") end
  A.kick = love.audio.newSource(kick(), "static")
  A.shaker = love.audio.newSource(noiseHit(0.09, 55, 0.95, 0.22), "static")
  A.tick = love.audio.newSource(noiseHit(0.05, 90, 0.6, 0.30), "static")
  A.bellList = bellNotes
  A.voices = {}
  A.master = 1
  A.musicVol = 1
  A.musicTarget = 1
  A.layers = { pad = true, arp = 0, bass = false, rhythm = false, bells = false }
  A.t = 0
  A.lastStep = -1
  A.lastSing = 72
  A.pending = {}
end

-- play a copy of a static source (polyphony)
local function play(src, vol, pitch)
  if not src then return end
  local s = src:clone()
  s:setVolume(math.max(0, math.min(1, vol * A.master)))
  if pitch then s:setPitch(pitch) end
  s:play()
  local v = A.voices
  v[#v + 1] = s
  return s
end
A.play = play

local function nearestBell(m)
  local best, bd = A.bellList[1], 999
  for _, n in ipairs(A.bellList) do
    local d = math.abs(n - m)
    if d < bd then best, bd = n, d end
  end
  return best
end

function A.currentChord()
  local bar = floor(A.t / (A.beat * 4))
  return A.chords[(bar % 4) + 1], bar
end

-- time (in seconds) to the nearest beat, signed
function A.beatOffset()
  local b = A.t / A.beat
  local frac = b - floor(b + 0.5)
  return frac * A.beat
end

function A.beatPhase()
  local b = A.t / A.beat
  return b - floor(b)
end

-- player sings: returns the chosen MIDI note
function A.sing(vol)
  local ch = A.currentChord()
  -- gentle random walk across chord tones in octaves 5-6
  local cands = {}
  for _, tn in ipairs(ch.tones) do
    for o = 0, 2 do
      local m = tn + o * 12
      if m >= 65 and m <= 92 then cands[#cands + 1] = m end
    end
  end
  table.sort(cands, function(a, b) return math.abs(a - A.lastSing) < math.abs(b - A.lastSing) end)
  local pick = cands[math.random(2, math.min(4, #cands))] or cands[1]
  A.lastSing = pick
  play(A.bells[nearestBell(pick)], (vol or 0.55) * A.sfxVol)
  return pick
end

A.sfxVol = 1

-- schedule a note in the future (seconds from now)
function A.later(delay, m, vol)
  A.pending[#A.pending + 1] = { at = love.timer.getTime() + delay, m = m, vol = vol }
end

-- an answering voice: a chord tone above `base`, offset by idx
function A.answer(base, idx, delay, vol)
  local ch = A.currentChord()
  local tones = {}
  for o = 0, 2 do
    for _, tn in ipairs(ch.tones) do tones[#tones + 1] = tn + o * 12 end
  end
  table.sort(tones)
  local start = 1
  for i, tn in ipairs(tones) do if tn >= base then start = i break end end
  local m = tones[math.min(#tones, start + idx)] or base
  if m > 94 then m = m - 12 end
  A.later(delay, nearestBell(m), vol or 0.35)
end

function A.swell()
  local ch = A.currentChord()
  for i, tn in ipairs(ch.tones) do
    play(A.pads[tn] or A.pads[61], 0.55 * A.musicVol)
    A.later(0.1 * i, nearestBell(tn + 12), 0.3)
  end
end

function A.update(dt)
  A.t = A.t + dt
  -- music volume fade
  local k = math.min(1, dt * 1.2)
  A.musicVol = A.musicVol + (A.musicTarget - A.musicVol) * k
  local now = love.timer.getTime()
  for i = #A.pending, 1, -1 do
    local p = A.pending[i]
    if now >= p.at then
      play(A.bells[p.m], p.vol * A.sfxVol)
      table.remove(A.pending, i)
    end
  end
  -- sequencer: 8th notes
  local step = floor(A.t / (A.beat / 2))
  if step ~= A.lastStep then
    A.lastStep = step
    A.onStep(step)
  end
  -- garbage-collect finished voices
  local v = A.voices
  for i = #v, 1, -1 do
    if not v[i]:isPlaying() then table.remove(v, i) end
  end
end

-- arpeggio pattern: each companion unlocks one more step
local ARP_ORDER = { 1, 5, 3, 7, 2, 6, 4, 8 }
local ARP_DEG = { 1, 2, 3, 2, 4, 3, 2, 5 }

function A.onStep(step)
  local mv = A.musicVol
  if mv < 0.01 or A.muted then return end
  local s8 = step % 8         -- position within a bar (8 eighths)
  local bar = floor(step / 8)
  local ch = A.chords[(bar % 4) + 1]
  local L = A.layers
  if s8 == 0 and bar % 2 == 0 and L.pad then
    -- pad chord every 2 bars (long, overlapping)
    for _, tn in ipairs(ch.tones) do play(A.pads[tn - 12] or A.pads[tn], 0.36 * mv) end
  elseif s8 == 0 and bar % 2 == 1 and L.pad and ch.name == "Fm" then
    play(A.pads[60], 0.3 * mv)
  end
  if L.bass and (s8 == 0 or s8 == 5) then
    local r = ch.root - 12
    play(A.basses[r] or A.basses[37], (s8 == 0 and 0.55 or 0.3) * mv)
  end
  if L.arp > 0 then
    local unlocked = false
    for i = 1, math.min(8, L.arp) do if ARP_ORDER[i] == s8 + 1 then unlocked = true end end
    if unlocked then
      local tones = {}
      for o = 0, 1 do for _, tn in ipairs(ch.tones) do tones[#tones + 1] = tn + 12 * o end end
      table.sort(tones)
      local m = tones[ARP_DEG[s8 + 1]]
      play(A.bells[nearestBell(m)], 0.16 * mv)
    end
  end
  if L.rhythm then
    if s8 == 0 or s8 == 4 then play(A.kick, 0.55 * mv) end
    if s8 == 2 or s8 == 6 then play(A.tick, 0.30 * mv) end
    play(A.shaker, (s8 % 2 == 1 and 0.22 or 0.10) * mv)
  end
  if L.bells and s8 == 0 and bar % 2 == 0 then
    -- slow title bells
    local m = ch.tones[math.random(1, 3)] + 12
    play(A.bells[nearestBell(m)], 0.18 * mv)
  end
end

function A.stopAll()
  for _, s in ipairs(A.voices) do s:stop() end
  A.voices = {}
  A.pending = {}
end

return A

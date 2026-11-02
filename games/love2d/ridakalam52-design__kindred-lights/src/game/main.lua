-- Kindred Lights
-- A game by Rida Kalam for thatgamejam #02.
-- Code written with an AI coding assistant. MIT License.

local Audio = require "audio"
local Track = require "trackdata"

local W, H = 1280, 720
local lg = love.graphics
local sin, cos, abs, sqrt, floor, min, max, exp, pi = math.sin, math.cos, math.abs, math.sqrt, math.floor, math.min, math.max, math.exp, math.pi
local random = love.math.random

---------------------------------------------------------------------------
-- options / test harness
---------------------------------------------------------------------------
local OPT = { autoplay = false, shots = false, fast = 1, start = nil, maxframes = nil }
local frame = 0
local shotQueue = {}   -- {name, frame}
local shotsTaken = {}
local logf = function(...) print(...) io.stdout:flush() end

local function lerp(a, b, t) return a + (b - a) * t end
local function clamp(x, a, b) return x < a and a or (x > b and b or x) end
local function smooth(t) t = clamp(t, 0, 1) return t * t * (3 - 2 * t) end
local function lerpc(c1, c2, t) return { lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t), lerp(c1[3], c2[3], t) } end
local function dist(ax, ay, bx, by) local dx, dy = ax - bx, ay - by return sqrt(dx * dx + dy * dy) end

local function shot(name, delayFrames)
  if not OPT.shots or shotsTaken[name] then return end
  shotsTaken[name] = true
  shotQueue[#shotQueue + 1] = { name = name, at = frame + (delayFrames or 0) }
end

---------------------------------------------------------------------------
-- resources
---------------------------------------------------------------------------
local canvas, lightCanvas
local LIGHT_GAIN = 1
local glowTex, dotTex, vignette
local fonts = {}
local theme -- the theme track (played unmodified in the finale)
local skyMesh

local function makeGlow(size, power)
  local id = love.image.newImageData(size, size)
  local c = (size - 1) / 2
  id:mapPixel(function(x, y)
    local dx, dy = (x - c) / c, (y - c) / c
    local d = sqrt(dx * dx + dy * dy)
    local a = max(0, 1 - d)
    return 1, 1, 1, a ^ power
  end)
  local img = lg.newImage(id)
  img:setFilter("linear", "linear")
  return img
end

local function makeVignette()
  local w, h = 320, 180
  local id = love.image.newImageData(w, h)
  id:mapPixel(function(x, y)
    local dx, dy = (x / (w - 1) - 0.5) * 2, (y / (h - 1) - 0.5) * 2
    local d = sqrt(dx * dx * 0.8 + dy * dy)
    local a = smooth((d - 0.55) / 0.9) * 0.75
    return 0, 0, 0.02, a
  end)
  local img = lg.newImage(id)
  img:setFilter("linear", "linear")
  return img
end

---------------------------------------------------------------------------
-- world definition
---------------------------------------------------------------------------
local S = 1.3 -- horizontal world scale
local WORLD_END = floor(9000 * S)
local LX = floor(8450 * S) -- the Old Light

local CHAPTERS = {
  { x = 0, name = "I  \194\183  Hush", sub = "every light begins alone" },
  { x = 2250 * S, name = "II  \194\183  Swell", sub = "a voice, and then another" },
  { x = 5250 * S, name = "III  \194\183  Pulse", sub = "one heartbeat, shared" },
  { x = 7850 * S, name = "IV  \194\183  Glow", sub = "the Old Light is waiting" },
}

-- sky palette keyed by world x
local SKY = {
  { x = 0, top = { 0.02, 0.025, 0.08 }, bot = { 0.10, 0.08, 0.22 }, amb = 0.62, ground = { 0.075, 0.06, 0.14 }, rim = { 0.40, 0.36, 0.70 } },
  { x = 2250 * S, top = { 0.04, 0.045, 0.15 }, bot = { 0.26, 0.15, 0.40 }, amb = 0.62, ground = { 0.10, 0.07, 0.17 }, rim = { 0.60, 0.45, 0.90 } },
  { x = 5250 * S, top = { 0.10, 0.08, 0.27 }, bot = { 0.66, 0.31, 0.42 }, amb = 0.74, ground = { 0.16, 0.08, 0.17 }, rim = { 1.00, 0.62, 0.68 } },
  { x = 7850 * S, top = { 0.17, 0.17, 0.44 }, bot = { 1.00, 0.68, 0.45 }, amb = 0.88, ground = { 0.24, 0.12, 0.18 }, rim = { 1.00, 0.82, 0.58 } },
  { x = WORLD_END, top = { 0.20, 0.20, 0.48 }, bot = { 1.00, 0.74, 0.50 }, amb = 0.92, ground = { 0.26, 0.14, 0.19 }, rim = { 1.00, 0.86, 0.62 } },
}

local function skyAt(x)
  for i = 1, #SKY - 1 do
    local a, b = SKY[i], SKY[i + 1]
    if x <= b.x then
      local t = smooth((x - a.x) / (b.x - a.x))
      return {
        top = lerpc(a.top, b.top, t), bot = lerpc(a.bot, b.bot, t),
        amb = lerp(a.amb, b.amb, t), ground = lerpc(a.ground, b.ground, t), rim = lerpc(a.rim, b.rim, t),
      }
    end
  end
  local l = SKY[#SKY]
  return { top = l.top, bot = l.bot, amb = l.amb, ground = l.ground, rim = l.rim }
end

local function groundY(x)
  local y = 610 + 34 * sin(x * 0.0019 + 1.0) + 20 * sin(x * 0.0051 + 2.0) + 8 * sin(x * 0.013)
  -- the hill of the Old Light
  local d = (x - LX) / (700)
  local hill = 190 * exp(-d * d * 2.2)
  -- a gentle rise at the very start
  return y - hill
end

local MOUNTAINS = {
  { p = 0.12, base = 420, amp = 70, f = { 0.0021, 0.0057, 0.013 }, ph = { 0.3, 1.7, 2.9 }, mix = 0.60 },
  { p = 0.30, base = 470, amp = 60, f = { 0.0029, 0.0071, 0.017 }, ph = { 2.1, 0.4, 1.1 }, mix = 0.40 },
  { p = 0.58, base = 525, amp = 46, f = { 0.0037, 0.0091, 0.021 }, ph = { 1.2, 2.6, 0.2 }, mix = 0.22 },
}
local function mountainY(m, x)
  return m.base - m.amp * (sin(x * m.f[1] + m.ph[1]) * 0.6 + sin(x * m.f[2] + m.ph[2]) * 0.3 + sin(x * m.f[3] + m.ph[3]) * 0.1)
end

local PALETTE = {
  { 1.00, 0.76, 0.50 }, { 0.58, 0.82, 1.00 }, { 1.00, 0.60, 0.74 }, { 0.66, 1.00, 0.72 },
  { 0.82, 0.68, 1.00 }, { 1.00, 0.90, 0.58 }, { 0.58, 1.00, 0.94 },
}
local PLAYER_COL = { 1.0, 0.93, 0.78 }

local world -- built in newGame()

local function newRibbon(pts)
  local ctrl = {}
  for i = 1, #pts, 2 do ctrl[#ctrl + 1] = { pts[i] * S, pts[i + 1] } end
  local r = { pts = {} }
  local n = #ctrl
  for i = 1, n - 1 do
    local p0, p1, p2, p3 = ctrl[max(1, i - 1)], ctrl[i], ctrl[i + 1], ctrl[min(n, i + 2)]
    local segs = max(4, floor(dist(p1[1], p1[2], p2[1], p2[2]) / 14))
    for k = 0, segs - 1 do
      local t = k / segs
      local t2, t3 = t * t, t * t * t
      local function cr(a, b, c, d) return 0.5 * ((2 * b) + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (-a + 3 * b - 3 * c + d) * t3) end
      r.pts[#r.pts + 1] = { cr(p0[1], p1[1], p2[1], p3[1]), cr(p0[2], p1[2], p2[2], p3[2]) }
    end
  end
  r.pts[#r.pts + 1] = ctrl[n]
  return r
end

local function buildTree()
  -- branches of the Old Light (deterministic)
  local rng = love.math.newRandomGenerator(7)
  local segs = {}
  local function branch(x, y, ang, len, w, depth)
    local x2, y2 = x + cos(ang) * len, y + sin(ang) * len
    segs[#segs + 1] = { x, y, x2, y2, w, depth }
    if depth >= 6 then return end
    local n = depth < 2 and 2 or (rng:random() < 0.5 and 2 or 3)
    for i = 1, n do
      local a = ang + (i - (n + 1) / 2) * (0.55 + rng:random() * 0.2) + (rng:random() - 0.5) * 0.3
      branch(x2, y2, a, len * (0.68 + rng:random() * 0.12), w * 0.66, depth + 1)
    end
  end
  branch(0, 0, -pi / 2, 120, 9, 1)
  return segs
end

local function newGame()
  local wd = {}
  wd.player = { x = 200, y = 420, vx = 0, vy = 0, singCD = 0, glow = 1, moved = 0 }
  wd.followers = {}
  local spots = {
    { 1150, 380 },
    { 2700, 300 }, { 3250, 560 }, { 3800, 115 }, { 4300, 430, true }, { 4720, 190 },
    { 5800, 250 }, { 6480, 130 }, { 7150, 470, true },
  }
  wd.wanderers = {}
  for i, s in ipairs(spots) do
    wd.wanderers[i] = { x = s[1] * S, y = s[2], hx = s[1] * S, hy = s[2], drift = s[3], state = "sleep", t = random() * 10, col = PALETTE[((i - 1) % #PALETTE) + 1], idx = i, wake = 0 }
  end
  wd.gates = {
    { x = 1950 * S, kind = "lights", need = 1, open = 0, opening = false, blobs = {} },
    { x = 4950 * S, kind = "lights", need = 6, open = 0, opening = false, blobs = {} },
    { x = 7650 * S, kind = "bloom", need = 10, open = 0, opening = false, blobs = {} },
  }
  for _, g in ipairs(wd.gates) do
    for i = 1, 90 do
      g.blobs[i] = { dx = (random() - 0.5) * 230, y = random() * 700 - 20, r = 50 + random() * 80, ph = random() * 6.28, sp = 0.3 + random() * 0.6 }
    end
    g.motes = {}
    for i = 1, 26 do g.motes[i] = { dx = (random() - 0.5) * 200, y = random() * 650, ph = random() * 6.28 } end
  end
  wd.buds = {}
  local nb = 14
  for i = 1, nb do
    local x = lerp(5500, 7500, (i - 1) / (nb - 1)) * S + (random() - 0.5) * 60
    wd.buds[i] = { x = x, h = 36 + random() * 34, state = "bud", t = 0, perfect = false, ph = random() * 6.28, col = PALETTE[(i % #PALETTE) + 1] }
  end
  wd.bloomed = 0
  wd.ribbons = {
    newRibbon({ 2450, 560, 2750, 440, 3050, 330, 3400, 250, 3750, 190, 4050, 220, 4250, 300 }),
    newRibbon({ 4300, 560, 4550, 470, 4800, 420, 4900, 410 }),
    newRibbon({ 6000, 560, 6200, 380, 6400, 200, 6600, 150, 6850, 210, 7100, 330, 7300, 420 }),
  }
  wd.reeds = {}
  for x = 0, WORLD_END, 14 do
    if random() < 0.7 then wd.reeds[#wd.reeds + 1] = { x = x + random() * 10, h = 8 + random() * 22, ph = random() * 6.28 } end
  end
  wd.tree = buildTree()
  wd.treeLit = 0
  wd.cam = { x = 0, y = 0 }
  wd.rings = {}
  wd.sparks = {}
  wd.chapter = 0
  wd.card = nil
  wd.hint = { text = "", a = 0, target = "" }
  wd.time = 0
  wd.firstWake = false
  wd.sangOnce = false
  wd.gateHintT = 0
  wd.finale = nil
  return wd
end

---------------------------------------------------------------------------
-- state
---------------------------------------------------------------------------
local state = "loading"
local stateT = 0
local paused = false
local motes = {}
local stars = {}
local trailPS
local title = {}
local credits = {}
local fade = { a = 1, target = 0 } -- screen fade to black (or white in finale)

local function setState(s)
  state = s
  stateT = 0
end

local function toVirtual(x, y)
  local ww, wh = lg.getDimensions()
  local sc = min(ww / W, wh / H)
  local ox, oy = (ww - W * sc) / 2, (wh - H * sc) / 2
  return (x - ox) / sc, (y - oy) / sc
end

---------------------------------------------------------------------------
-- load
---------------------------------------------------------------------------
function love.load(args)
  for _, a in ipairs(args or {}) do
    if a == "--autoplay" then OPT.autoplay = true end
    if a == "--shots" then OPT.shots = true end
    if a == "--skipdraw" then OPT.skipdraw = true end
    if a == "--uitest" then OPT.uitest = true end
    local f = a:match("^%-%-fast=(%d+)$"); if f then OPT.fast = tonumber(f) end
    local s = a:match("^%-%-start=(%w+)$"); if s then OPT.start = s end
    local m = a:match("^%-%-maxframes=(%d+)$"); if m then OPT.maxframes = tonumber(m) end
  end
  lg.setDefaultFilter("linear", "linear")
  canvas = lg.newCanvas(W, H, { msaa = 0 })
  local fmts = lg.getCanvasFormats()
  if fmts and fmts.rgba16f then
    lightCanvas = lg.newCanvas(W, H, { format = "rgba16f" })
    LIGHT_GAIN = 1.0
  else
    lightCanvas = lg.newCanvas(W, H)
    LIGHT_GAIN = 0.6
  end
  glowTex = makeGlow(128, 2.2)
  dotTex = makeGlow(32, 1.2)
  vignette = makeVignette()
  fonts.title = lg.newFont("assets/CormorantGaramond_wght.ttf", 104)
  fonts.chapter = lg.newFont("assets/CormorantGaramond-Italic_wght.ttf", 66)
  fonts.line = lg.newFont("assets/CormorantGaramond-Italic_wght.ttf", 46)
  fonts.sub = lg.newFont("assets/CormorantGaramond-Italic_wght.ttf", 30)
  fonts.ui = lg.newFont("assets/Quicksand_wght.ttf", 22)
  fonts.small = lg.newFont("assets/Quicksand_wght.ttf", 17)
  fonts.credit = lg.newFont("assets/Quicksand_wght.ttf", 24)
  fonts.creditH = lg.newFont("assets/CormorantGaramond-Italic_wght.ttf", 40)

  skyMesh = lg.newMesh({ { 0, 0, 0, 0, 1, 1, 1, 1 }, { W, 0, 1, 0, 1, 1, 1, 1 }, { W, H, 1, 1, 1, 1, 1, 1 }, { 0, H, 0, 1, 1, 1, 1, 1 } }, "fan", "stream")

  for i = 1, 220 do
    stars[i] = { x = random() * W * 1.6, y = random() * H * 0.75, s = 0.4 + random() * 1.3, ph = random() * 6.28, sp = 0.5 + random() * 2 }
  end
  for i = 1, 70 do
    motes[i] = { x = random() * W, y = random() * H, z = 0.3 + random() * 0.9, ph = random() * 6.28 }
  end

  trailPS = lg.newParticleSystem(dotTex, 1200)
  trailPS:setParticleLifetime(0.6, 1.4)
  trailPS:setEmissionRate(0)
  trailPS:setSizes(0.55, 0.35, 0.08)
  trailPS:setSpeed(5, 25)
  trailPS:setSpread(pi * 2)
  trailPS:setLinearDamping(1.5)
  trailPS:setColors(1, 0.92, 0.7, 0.85, 1, 0.75, 0.5, 0.4, 1, 0.6, 0.6, 0)

  -- a quiet loading frame while the synthesizer prepares its voices
  lg.clear(0.02, 0.02, 0.06, 1)
  lg.setFont(fonts.sub)
  lg.setColor(1, 0.95, 0.88, 0.7)
  local lw, lh = lg.getDimensions()
  lg.printf("gathering light...", 0, lh / 2 - 20, lw, "center")
  lg.present()
  local t0 = love.timer.getTime()
  Audio.load()
  logf(string.format("[load] audio synthesized in %.2fs", love.timer.getTime() - t0))
  -- The theme track is shipped in jam builds only (it is not ours to relicense).
  -- Without it, the finale falls back to the in-game synth music.
  if love.filesystem.getInfo("assets/theme.wav") then
    theme = love.audio.newSource("assets/theme.wav", "stream")
    theme:setLooping(false)
    theme:setVolume(1.0)
  else
    logf("[load] assets/theme.wav not found; finale will use synthesized music")
  end

  title.lights = {}
  for i = 1, 26 do
    title.lights[i] = { x = random() * W, y = 300 + random() * 300, ph = random() * 6.28, col = PALETTE[(i % #PALETTE) + 1], sp = 8 + random() * 20 }
  end

  Audio.layers = { pad = true, arp = 0, bass = false, rhythm = false, bells = true }
  setState("title")
  fade.a, fade.target = 1, 0
  shot("01_title", 150)

  if OPT.start then
    world = newGame()
    setState("play")
    local p = world.player
    if OPT.start == "ch2" then p.x = 2300 * S end
    if OPT.start == "ch3" then p.x = 5300 * S end
    if OPT.start == "ch4" then p.x = 7900 * S end
    if OPT.start ~= "ch1" then
      for _, w in ipairs(world.wanderers) do
        if w.x < p.x then w.state = "follow"; w.x, w.y = p.x - 50, p.y; world.followers[#world.followers + 1] = w end
      end
      for _, g in ipairs(world.gates) do if g.x < p.x then g.open = 1; g.opening = true end end
      if OPT.start == "ch4" then for _, b in ipairs(world.buds) do b.state = "bloom"; b.t = 5 end; world.bloomed = #world.buds end
    end
    world.cam.x = clamp(p.x - W * 0.42, 0, WORLD_END - W)
  end
end

---------------------------------------------------------------------------
-- effects helpers
---------------------------------------------------------------------------
local function addRing(x, y, col, maxR, life, width)
  world.rings[#world.rings + 1] = { x = x, y = y, t = 0, col = col, maxR = maxR or 220, life = life or 1.2, w = width or 3 }
end

local function burst(x, y, col, n, speed, life)
  for i = 1, n do
    local a = random() * pi * 2
    local s = (0.3 + random() * 0.7) * (speed or 120)
    world.sparks[#world.sparks + 1] = { x = x, y = y, vx = cos(a) * s, vy = sin(a) * s - 20, t = 0, life = (life or 1.4) * (0.6 + random() * 0.6), col = col, size = 0.4 + random() * 0.8 }
  end
end

local function setHint(text) world.hint.target = text end

---------------------------------------------------------------------------
-- gameplay
---------------------------------------------------------------------------
local singQueued = false

local function groupRadius()
  return 150 + 42 * #world.followers
end

local function wakeWanderer(w)
  w.state = "waking"
  w.wake = 0
  addRing(w.x, w.y, w.col, 260, 1.6, 4)
  burst(w.x, w.y, w.col, 40, 160, 1.6)
  Audio.answer(Audio.lastSing, 2, 0.35, 0.5)
  Audio.answer(Audio.lastSing, 4, 0.65, 0.35)
  world.followers[#world.followers + 1] = w
  w.followIndex = #world.followers
  logf(string.format("[play] t=%.1f woke light %d (followers=%d)", world.time, w.idx, #world.followers))
  if not world.firstWake then
    world.firstWake = true
  end
  if #world.followers == 1 then shot("02_hush", 100) end
  if #world.followers == 4 then shot("03_swell", 70) end
end

local function bloomBud(b, perfect)
  b.state = "bloom"
  b.t = 0
  b.perfect = perfect
  world.bloomed = world.bloomed + 1
  local by = groundY(b.x) - b.h
  burst(b.x, by, b.col, perfect and 50 or 24, perfect and 170 or 110, 1.5)
  addRing(b.x, by, b.col, perfect and 200 or 130, 1.2, 3)
  Audio.answer(Audio.lastSing, 1, 0.12, 0.4)
  logf(string.format("[play] t=%.1f bloom %d/%d perfect=%s", world.time, world.bloomed, #world.buds, tostring(perfect)))
  if world.bloomed == 6 then shot("04_pulse", 40) end
end

local function startFinale()
  local wd = world
  setState("finale")
  wd.finale = { t = 0, trackT = -3.0, started = false, risers = {}, bursts = {}, pulse = 0, beatI = 1, flash = 1, ended = false, camY = 0 }
  Audio.musicTarget = 0
  Audio.sfxVol = 0.6
  addRing(LX, groundY(LX) - 240, { 1, 0.9, 0.6 }, 900, 3.0, 6)
  burst(LX, groundY(LX) - 240, { 1, 0.85, 0.6 }, 120, 320, 2.5)
  logf(string.format("[play] t=%.1f FINALE begins", wd.time))
  shot("05_lantern", 90)
end

local function sing()
  local p = world.player
  if p.singCD > 0 then return end
  p.singCD = 0.38
  world.sangOnce = true
  local inFinale = state == "finale"
  local note = 72
  if not inFinale then note = Audio.sing(0.55) end
  addRing(p.x, p.y, PLAYER_COL, 230, 1.15, 3)
  burst(p.x, p.y, PLAYER_COL, 10, 70, 0.9)
  p.glow = 1.8
  if inFinale then return end
  local onBeat = abs(Audio.beatOffset()) < 0.13
  local perfect = Audio.layers.rhythm and onBeat
  -- friends answer, each a step higher
  for i, f in ipairs(world.followers) do
    if f.state == "follow" then
      local delay = perfect and (0.06 * i) or (0.22 + 0.17 * (i - 1))
      Audio.answer(note, i, delay, max(0.12, 0.34 - i * 0.025))
      f.echoAt = world.time + delay
    end
  end
  -- wake sleepers within reach
  for _, w in ipairs(world.wanderers) do
    if w.state == "sleep" and dist(p.x, p.y, w.x, w.y) < 210 then wakeWanderer(w) end
  end
  -- bloom buds within reach
  for _, b in ipairs(world.buds) do
    if b.state == "bud" and dist(p.x, p.y, b.x, groundY(b.x) - b.h) < 200 then bloomBud(b, perfect) end
  end
  if perfect then
    for _, f in ipairs(world.followers) do burst(f.x, f.y, f.col, 6, 60, 0.8) end
  end
  -- the Old Light
  local ox, oy = LX, groundY(LX) - 240
  if dist(p.x, p.y, ox, oy) < 260 then startFinale() end
end

-- the autoplay bot (for headless testing)
local bot = { cd = 0, stuck = 0, lastX = 0 }
local function botControl(dt)
  local p = world.player
  local tx, ty, act = nil, nil, nil
  local limit = WORLD_END
  local gate
  for _, g in ipairs(world.gates) do if g.open < 1 and not g.opening then gate = g; limit = g.x; break end end
  local best, bd = nil, 1e9
  for _, w in ipairs(world.wanderers) do
    if w.state == "sleep" and w.x < limit then
      local d = abs(w.x - p.x) + abs(w.y - p.y) * 0.5
      if d < bd then best, bd = w, d end
    end
  end
  if best then tx, ty, act = best.x, best.y, "wake" end
  if not tx and gate and gate.kind == "bloom" then
    for _, b in ipairs(world.buds) do
      if b.state == "bud" and b.x < limit then
        local d = abs(b.x - p.x)
        if d < bd then best, bd = b, d end
      end
    end
    if best then tx, ty, act = best.x, groundY(best.x) - best.h - 40, "bloom" end
  end
  if not tx then
    if gate then tx, ty, act = gate.x - 100, 380, "gate"
    else tx, ty, act = LX, groundY(LX) - 240, "light" end
  end
  local dx, dy = tx - p.x, ty - p.y
  local d = sqrt(dx * dx + dy * dy)
  local ax, ay = 0, 0
  if d > 40 then ax, ay = dx / d, dy / d end
  bot.cd = bot.cd - dt
  if act == "wake" and d < 150 and bot.cd <= 0 then singQueued = true; bot.cd = 0.5 end
  if act == "bloom" and d < 140 and bot.cd <= 0 and abs(Audio.beatOffset()) < 0.05 then singQueued = true; bot.cd = 0.4 end
  if act == "light" and d < 200 and bot.cd <= 0 then singQueued = true; bot.cd = 1 end
  if act == "gate" and d < 80 then
    bot.stuck = bot.stuck + dt
    if bot.stuck > 8 then logf("[bot] STUCK at gate x=" .. gate.x .. " followers=" .. #world.followers .. " bloomed=" .. world.bloomed); bot.stuck = -1e9 end
  end
  return ax, ay
end

local function pointSegDist(px, py, ax, ay, bx, by)
  local vx, vy = bx - ax, by - ay
  local wx, wy = px - ax, py - ay
  local L = vx * vx + vy * vy
  local t = L > 0 and clamp((wx * vx + wy * vy) / L, 0, 1) or 0
  local cx, cy = ax + vx * t, ay + vy * t
  return dist(px, py, cx, cy), vx, vy, sqrt(L)
end

local function updateChapter()
  local p = world.player
  local ch = 1
  for i, c in ipairs(CHAPTERS) do if p.x >= c.x then ch = i end end
  if ch > world.chapter then
    world.chapter = ch
    world.card = { i = ch, t = 0 }
    logf(string.format("[play] t=%.1f chapter %d", world.time, ch))
    if ch >= 3 then Audio.layers.rhythm = true; Audio.layers.bass = true end
  end
end

local function updatePlay(dt)
  local wd = world
  wd.time = wd.time + dt
  local p = wd.player

  -- input
  local ax, ay = 0, 0
  if OPT.autoplay then
    ax, ay = botControl(dt)
  else
    if love.keyboard.isDown("left", "a") then ax = ax - 1 end
    if love.keyboard.isDown("right", "d") then ax = ax + 1 end
    if love.keyboard.isDown("up", "w") then ay = ay - 1 end
    if love.keyboard.isDown("down", "s") then ay = ay + 1 end
    if love.mouse.isDown(1) then
      local mx, my = toVirtual(love.mouse.getPosition())
      local wx, wy = mx + wd.cam.x, my + wd.cam.y
      local dx, dy = wx - p.x, wy - p.y
      local d = sqrt(dx * dx + dy * dy)
      if d > 12 then
        local k = clamp(d / 120, 0, 1)
        ax, ay = ax + dx / d * k, ay + dy / d * k
      end
    end
  end
  local l = sqrt(ax * ax + ay * ay)
  if l > 1 then ax, ay = ax / l, ay / l end

  local acc, maxs = 850, 230
  -- wind ribbons
  local inRibbon = false
  for _, r in ipairs(wd.ribbons) do
    for i = 1, #r.pts - 1 do
      local a, b = r.pts[i], r.pts[i + 1]
      local d, vx, vy, L = pointSegDist(p.x, p.y, a[1], a[2], b[1], b[2])
      if d < 48 and L > 0 then
        inRibbon = true
        p.vx = p.vx + vx / L * 620 * dt
        p.vy = p.vy + vy / L * 620 * dt
        break
      end
    end
  end
  if inRibbon then maxs = 520; p.ribbonT = (p.ribbonT or 0) + dt else p.ribbonT = 0 end

  p.vx = p.vx + ax * acc * dt
  p.vy = p.vy + ay * acc * dt
  local damp = exp(-dt * (l > 0 and 1.6 or 2.6))
  p.vx, p.vy = p.vx * damp, p.vy * damp
  local sp = sqrt(p.vx * p.vx + p.vy * p.vy)
  if sp > maxs then p.vx, p.vy = p.vx / sp * maxs, p.vy / sp * maxs end
  -- gentle idle bob
  local ox, oy = p.x, p.y
  p.x = p.x + p.vx * dt
  p.y = p.y + p.vy * dt + sin(wd.time * 1.7) * 6 * dt
  p.moved = p.moved + abs(p.x - ox) + abs(p.y - oy)

  -- bounds
  p.x = clamp(p.x, 60, WORLD_END - 80)
  local gy = groundY(p.x) - 26
  if p.y > gy then p.y = gy; p.vy = -abs(p.vy) * 0.3 end
  if p.y < 50 then p.y = 50; p.vy = abs(p.vy) * 0.3 end

  -- gates
  local blockedBy = nil
  for _, g in ipairs(wd.gates) do
    local have = g.kind == "lights" and #wd.followers or wd.bloomed
    if not g.opening and have >= g.need and abs(p.x - g.x) < 520 then
      g.opening = true
      Audio.swell()
      addRing(g.x, 360, { 0.8, 0.8, 1.0 }, 420, 2.4, 4)
      logf(string.format("[play] t=%.1f gate at %d opens", wd.time, g.x))
      if g.need == 6 then shot("03b_gate", 60) end
    end
    if g.opening then g.open = min(1, g.open + dt / 2.6) end
    if g.open < 0.55 and p.x > g.x - 130 and p.x < g.x + 60 then
      p.x = g.x - 130
      p.vx = -abs(p.vx) * 0.4 - 30
      blockedBy = g
    end
  end
  if blockedBy then wd.gateHintT = 4 end
  wd.gateHintT = wd.gateHintT - dt

  if singQueued then singQueued = false; sing() end
  p.singCD = p.singCD - dt
  p.glow = lerp(p.glow, 1, 1 - exp(-dt * 3))

  -- wanderers / followers
  local leaderX, leaderY = p.x, p.y
  local fi = 0
  for _, w in ipairs(wd.wanderers) do
    w.t = w.t + dt
    if w.state == "sleep" then
      if w.drift then
        w.x = w.hx + cos(w.t * 0.22) * 150
        w.y = w.hy + sin(w.t * 0.44) * 55
      else
        w.x = w.hx + sin(w.t * 0.4) * 6
        w.y = w.hy + sin(w.t * 0.7) * 5
      end
      -- sleeping lights softly call out, so you can find them
      w.callT = (w.callT or (2 + random() * 3)) - dt
      if w.callT <= 0 then
        w.callT = 4.5 + random() * 2
        local d = dist(p.x, p.y, w.x, w.y)
        if d < 1100 then
          addRing(w.x, w.y, w.col, 120, 1.8, 2)
          if d > 120 and not OPT.autoplay then
            local m = Audio.currentChord().tones[((w.idx - 1) % 3) + 1] + 24
            Audio.later(0, m, 0.14 * (1 - d / 1100))
          end
        end
      end
    end
  end
  for i, f in ipairs(wd.followers) do
    if f.state == "waking" then
      f.wake = f.wake + dt
      if f.wake > 0.9 then f.state = "follow" end
    end
    local tx, ty = leaderX, leaderY
    local dx, dy = f.x - tx, f.y - ty
    local d = sqrt(dx * dx + dy * dy)
    local sep = 34 + i * 1.5
    if d > sep then
      local desX, desY = tx + dx / d * sep, ty + dy / d * sep
      local k = 1 - exp(-dt * (f.state == "follow" and 6 or 1.5))
      f.x, f.y = lerp(f.x, desX, k), lerp(f.y, desY, k)
    end
    f.y = f.y + sin(wd.time * 2 + i) * 10 * dt
    local fgy = groundY(f.x) - 20
    if f.y > fgy then f.y = fgy end
    leaderX, leaderY = f.x, f.y
    if wd.time % 0.05 < dt then
      trailPS:setPosition(f.x, f.y)
      trailPS:setColors(f.col[1], f.col[2], f.col[3], 0.6, f.col[1], f.col[2], f.col[3], 0.25, f.col[1], f.col[2], f.col[3], 0)
      trailPS:emit(1)
    end
  end
  -- player trail
  trailPS:setPosition(p.x, p.y)
  trailPS:setColors(1, 0.93, 0.75, 0.35, 1, 0.75, 0.5, 0.15, 1, 0.6, 0.6, 0)
  if frame % 2 == 0 then trailPS:emit(1) end
  trailPS:update(dt)

  -- buds
  for _, b in ipairs(wd.buds) do b.t = b.t + dt end

  -- music layers follow your companions
  Audio.layers.bells = false
  Audio.layers.arp = #wd.followers
  if #wd.followers >= 3 then Audio.layers.bass = true end

  updateChapter()
  if wd.card then wd.card.t = wd.card.t + dt; if wd.card.t > 6 then wd.card = nil end end

  -- hints
  local hint = ""
  local nearSleeper = false
  for _, w in ipairs(wd.wanderers) do
    if w.state == "sleep" and dist(p.x, p.y, w.x, w.y) < 320 then nearSleeper = true end
  end
  if p.moved < 260 and wd.time > 1.5 then
    hint = "Hold the mouse button, or use WASD / arrow keys, to drift."
  elseif nearSleeper and #wd.followers == 0 then
    hint = "A sleeping light.  Press Space (or right-click) to sing."
  elseif wd.firstWake and #wd.followers == 1 and wd.chapter == 1 and wd.player.x < 1700 * S then
    hint = "It answered.  Lights that hear you will follow."
  elseif wd.gateHintT > 0 then
    local g = blockedBy
    if not g then for _, gg in ipairs(wd.gates) do if gg.open < 0.55 and abs(p.x - gg.x) < 400 then g = gg end end end
    if g and g.kind == "lights" then
      hint = string.format("This dark is too deep for so few lights.   %d / %d   \226\128\148  listen for the ones still sleeping", #wd.followers, g.need)
    elseif g then
      hint = string.format("The way is dark.  Wake the flowers.   %d / %d", wd.bloomed, g.need)
    end
  elseif wd.chapter == 2 and p.ribbonT > 0 and p.ribbonT < 3 then
    hint = "Ride the wind."
  elseif wd.chapter == 3 and wd.bloomed < 3 and p.x < 6200 * S then
    hint = "Sing over the sleeping buds.  On the beat, your friends sing with you."
  elseif wd.chapter == 4 and dist(p.x, p.y, LX, groundY(LX) - 240) < 700 then
    hint = "Sing to the Old Light."
  end
  setHint(hint)
end

local function updateEffects(dt)
  local wd = world
  for i = #wd.rings, 1, -1 do
    local r = wd.rings[i]
    r.t = r.t + dt
    if r.t > r.life then table.remove(wd.rings, i) end
  end
  for i = #wd.sparks, 1, -1 do
    local s = wd.sparks[i]
    s.t = s.t + dt
    s.vx, s.vy = s.vx * exp(-dt * 1.8), s.vy * exp(-dt * 1.8) - 8 * dt
    s.x, s.y = s.x + s.vx * dt, s.y + s.vy * dt
    if s.t > s.life then table.remove(wd.sparks, i) end
  end
  local h = wd.hint
  if h.text ~= h.target then
    h.a = h.a - dt * 2.5
    if h.a <= 0 then h.a = 0; h.text = h.target end
  elseif h.text ~= "" then
    h.a = min(1, h.a + dt * 1.5)
  end
  -- camera
  local p = wd.player
  if state == "finale" then
    wd.cam.x = lerp(wd.cam.x, clamp(LX - W / 2, 0, WORLD_END - W), 1 - exp(-dt * 0.8))
    wd.cam.y = lerp(wd.cam.y, 0, 1 - exp(-dt * 0.8))
    return
  end
  local tx = clamp(p.x - W * 0.42 + p.vx * 0.35, 0, WORLD_END - W)
  local ty = clamp((p.y - 380) * 0.22, -70, 30)
  local k = 1 - exp(-dt * 2.2)
  wd.cam.x = lerp(wd.cam.x, tx, k)
  wd.cam.y = lerp(wd.cam.y, ty, k)
end

---------------------------------------------------------------------------
-- finale
---------------------------------------------------------------------------
local FINALE_LINES = {
  { 1.0, 8.6, "Every light begins alone." },
  { 9.6, 20.6, "Somewhere, someone sings into the dark..." },
  { 21.8, 32.8, "...and someone answers." },
  { 33.4, 41.2, "Answer after answer, the night fills." },
  { 42.0, 54.2, "Together, the dark becomes a sky." },
  { 55.2, 60.5, "Thank you for answering." },
}

local function trackRMS(t)
  local i = floor(t / Track.rms_hop) + 1
  local a = Track.rms[clamp(i, 1, #Track.rms)] or 0
  local b = Track.rms[clamp(i + 1, 1, #Track.rms)] or a
  local f = (t / Track.rms_hop) - floor(t / Track.rms_hop)
  return lerp(a, b, f)
end

local function updateFinale(dt)
  local wd = world
  local F = wd.finale
  F.t = F.t + dt
  wd.time = wd.time + dt
  local p = wd.player

  if not F.started and F.t >= 3.0 then
    F.started = true
    F.trackT = 0
    if theme then
      Audio.stopAll()
      Audio.muted = true
      theme:stop()
      theme:play()
      logf("[finale] theme track started (unmodified)")
    else
      Audio.musicTarget = 1
      Audio.layers = { pad = true, arp = 8, bass = true, rhythm = false, bells = false }
      logf("[finale] no theme file; synthesized finale music")
    end
  end
  if F.started then
    if not theme then
      Audio.layers.rhythm = F.trackT > 21.3 and F.trackT < 54.9
      if F.trackT > 52 then Audio.musicTarget = 0 end
    end
    if theme and theme:isPlaying() and not OPT.autoplay then
      F.trackT = theme:tell("seconds")
    else
      F.trackT = F.trackT + dt
    end
  end
  local tt = F.trackT
  local rms = F.started and trackRMS(max(0, tt)) or 0.2
  F.rms = rms

  -- beats
  while F.beatI <= #Track.beats and tt >= Track.beats[F.beatI] do
    F.pulse = 1
    if tt > 21.3 and tt < 54.9 and F.beatI % 2 == 0 then
      F.bursts[#F.bursts + 1] = { x = 120 + random() * (W - 240), y = 80 + random() * 300, t = 0, col = PALETTE[random(1, #PALETTE)] }
    end
    F.beatI = F.beatI + 1
  end
  F.pulse = F.pulse * exp(-dt * 5)
  for i = #F.bursts, 1, -1 do
    local b = F.bursts[i]
    b.t = b.t + dt
    if b.t > 2.2 then table.remove(F.bursts, i) end
  end

  -- camera rises with the music
  local rise = smooth(tt / 50)
  F.camY = -1100 * rise
  wd.treeLit = min(1, wd.treeLit + dt / 2.5)

  -- player: free drift, in screen space
  if not F.px then
    F.px, F.py = p.x - wd.cam.x, p.y - wd.cam.y
  end
  local ax, ay = 0, 0
  if not OPT.autoplay then
    if love.keyboard.isDown("left", "a") then ax = ax - 1 end
    if love.keyboard.isDown("right", "d") then ax = ax + 1 end
    if love.keyboard.isDown("up", "w") then ay = ay - 1 end
    if love.keyboard.isDown("down", "s") then ay = ay + 1 end
    if love.mouse.isDown(1) then
      local mx, my = toVirtual(love.mouse.getPosition())
      local dx, dy = mx - F.px, my - F.py
      local d = sqrt(dx * dx + dy * dy)
      if d > 12 then local k = clamp(d / 120, 0, 1); ax, ay = ax + dx / d * k, ay + dy / d * k end
    end
  else
    ax = cos(F.t * 0.4) * 0.4
    ay = sin(F.t * 0.6) * 0.3
    if F.t % 2.3 < dt then singQueued = true end
  end
  -- drift toward centre-ish at the start
  local cx, cy = W * 0.5, H * 0.55
  p.vx = (p.vx + ax * 700 * dt + (cx - F.px) * 0.6 * dt) * exp(-dt * 2)
  p.vy = (p.vy + ay * 700 * dt + (cy - F.py) * 0.6 * dt) * exp(-dt * 2)
  F.px = clamp(F.px + p.vx * dt, 60, W - 60)
  F.py = clamp(F.py + p.vy * dt, 60, H - 60)
  p.x, p.y = F.px + wd.cam.x, F.py + wd.cam.y + F.camY
  if singQueued then singQueued = false; sing() end
  p.singCD = p.singCD - dt
  p.glow = lerp(p.glow, 1, 1 - exp(-dt * 3))

  -- followers orbit the player
  for i, f in ipairs(wd.followers) do
    local a = F.t * 0.8 + i / #wd.followers * pi * 2
    local r = 60 + 12 * sin(F.t * 1.3 + i) + F.pulse * 10
    local tx, ty = p.x + cos(a) * r, p.y + sin(a) * r * 0.8
    local k = 1 - exp(-dt * 3)
    f.x, f.y = lerp(f.x, tx, k), lerp(f.y, ty, k)
  end

  -- risers: lights waking all over the world
  local want = 0
  if tt > 9 then want = floor(clamp((tt - 9) / 30, 0, 1) * 260) end
  while #F.risers < want do
    F.risers[#F.risers + 1] = {
      x = random() * W, y = H + 20 + random() * 80, vy = -(18 + random() * 30), ph = random() * 6.28,
      col = PALETTE[random(1, #PALETTE)], s = 0.4 + random() * 0.7, ang = random() * pi * 2, rr = 0.75 + random() * 0.5,
    }
  end
  local gather = smooth((tt - 41.5) / 9)
  for i, r in ipairs(F.risers) do
    r.ph = r.ph + dt
    if gather > 0 then
      local a = r.ang + F.t * 0.12
      local R = 235 * r.rr
      local tx, ty = W / 2 + cos(a) * R * 1.4, H * 0.56 + sin(a) * R * 0.8
      local k = (1 - exp(-dt * 1.3)) * gather
      r.x, r.y = lerp(r.x, tx, k), lerp(r.y, ty, k)
    else
      r.y = r.y + r.vy * dt
      r.x = r.x + sin(r.ph * 0.7) * 12 * dt
      if r.y < 40 then r.vy = abs(r.vy) * 0.2 end
      if r.y < 120 then r.vy = r.vy * exp(-dt * 0.8) end
    end
  end

  for _, f in ipairs(wd.followers) do
    if wd.time % 0.06 < dt then trailPS:setPosition(f.x, f.y); trailPS:emit(1) end
  end
  trailPS:setPosition(p.x, p.y); trailPS:emit(1)
  trailPS:update(dt)

  if F.started and tt >= 54.9 then fade.target = 1; fade.white = true end
  if F.started and tt >= Track.duration + 0.8 and not F.ended then
    F.ended = true
    logf("[finale] complete -> credits")
    shot("07_credits", 200)
    setState("credits")
    credits.t = 0
    fade.a, fade.target, fade.white = 1, 0, true
    Audio.musicVol = 0
    Audio.muted = false
    Audio.musicTarget = 0.6
    Audio.sfxVol = 1
    Audio.layers = { pad = true, arp = 0, bass = false, rhythm = false, bells = true }
  end
  if F.started then
    if tt > 15 then shot("06a_finale", 0) end
    if tt > 30 then shot("06b_finale", 0) end
    if tt > 48 then shot("06c_finale", 0) end
  end
end

---------------------------------------------------------------------------
-- drawing helpers
---------------------------------------------------------------------------
local stripMesh = lg.newMesh(2 * 90, "strip", "stream")
local function drawStrip(fn, x0, x1, step, yBottom, cTop, cBot)
  local verts = {}
  local n = 0
  local x = x0
  while x <= x1 + step and n < 88 do
    local y = fn(x)
    verts[#verts + 1] = { x, y, 0, 0, cTop[1], cTop[2], cTop[3], cTop[4] or 1 }
    verts[#verts + 1] = { x, yBottom, 0, 0, cBot[1], cBot[2], cBot[3], cBot[4] or 1 }
    n = n + 1
    x = x + step
  end
  stripMesh:setVertices(verts)
  stripMesh:setDrawRange(1, #verts)
  lg.setColor(1, 1, 1, 1)
  lg.draw(stripMesh)
end

local function drawSky(top, bot, camX, camY, starA)
  skyMesh:setVertex(1, 0, 0, 0, 0, top[1], top[2], top[3], 1)
  skyMesh:setVertex(2, W, 0, 1, 0, top[1], top[2], top[3], 1)
  skyMesh:setVertex(3, W, H, 1, 1, bot[1], bot[2], bot[3], 1)
  skyMesh:setVertex(4, 0, H, 0, 1, bot[1], bot[2], bot[3], 1)
  lg.setColor(1, 1, 1, 1)
  lg.draw(skyMesh)
  -- stars
  local t = love.timer.getTime()
  lg.setBlendMode("add")
  for _, s in ipairs(stars) do
    local x = (s.x - camX * 0.04) % (W * 1.6)
    local y = s.y - (camY or 0) * 0.05
    if x < W and y > -10 and y < H then
      local a = (0.45 + 0.55 * sin(t * s.sp + s.ph)) * starA * (1 - y / H * 0.7)
      lg.setColor(1, 0.95, 0.9, a)
      lg.draw(dotTex, x, y, 0, s.s * 0.18, s.s * 0.18, 16, 16)
    end
  end
  lg.setBlendMode("alpha")
end

local function drawMountains(sky, camX, camY)
  for _, m in ipairs(MOUNTAINS) do
    local c = lerpc(sky.ground, sky.bot, m.mix)
    local cb = lerpc(sky.ground, sky.bot, m.mix * 0.6)
    local off = camX * m.p
    local oy = -(camY or 0) * m.p * 0.6
    drawStrip(function(x) return mountainY(m, x + off) + oy end, -20, W + 20, 16, H + 400, { c[1], c[2], c[3], 1 }, { cb[1], cb[2], cb[3], 1 })
  end
end

local function drawGround(sky, camX)
  local c = sky.ground
  local cb = { c[1] * 0.5, c[2] * 0.5, c[3] * 0.6, 1 }
  drawStrip(function(x) return groundY(x) end, camX - 20, camX + W + 40, 16, 900, { c[1], c[2], c[3], 1 }, cb)
  -- rim light on the dune crest
  local pts = {}
  for x = floor(camX / 16) * 16 - 16, camX + W + 32, 16 do pts[#pts + 1] = x; pts[#pts + 1] = groundY(x) end
  lg.setLineWidth(2)
  lg.setColor(sky.rim[1], sky.rim[2], sky.rim[3], 0.35)
  lg.line(pts)
  lg.setLineWidth(1)
end

local function drawReeds(sky, camX, t)
  lg.setLineWidth(1.5)
  for _, r in ipairs(world.reeds) do
    if r.x > camX - 30 and r.x < camX + W + 30 then
      local gy = groundY(r.x) + 2
      local sway = sin(t * 1.3 + r.ph + r.x * 0.004) * 5
      lg.setColor(sky.rim[1] * 0.6, sky.rim[2] * 0.55, sky.rim[3] * 0.6, 0.55)
      lg.line(r.x, gy, r.x + sway * 0.5, gy - r.h * 0.5, r.x + sway, gy - r.h)
    end
  end
  lg.setLineWidth(1)
end

local function drawRibbons(t, camX)
  lg.setBlendMode("add")
  for _, r in ipairs(world.ribbons) do
    local pts = r.pts
    local n = #pts
    if pts[n][1] > camX - 100 and pts[1][1] < camX + W + 100 then
      for strand = 1, 3 do
        local prevx, prevy
        lg.setLineWidth(2.5)
        for i = 1, n do
          local x, y = pts[i][1], pts[i][2]
          y = y + sin(x * 0.006 + t * 1.3 + strand * 2.1) * (8 + strand * 5)
          if prevx and x > camX - 50 and x < camX + W + 50 then
            local edge = min(i / 12, (n - i) / 12, 1)
            lg.setColor(0.65, 0.82, 1.0, (0.05 + 0.03 * strand) * edge)
            lg.line(prevx, prevy, x, y)
          end
          prevx, prevy = x, y
        end
      end
      -- travelling motes
      for k = 0, 24 do
        local u = ((t * 0.07 + k / 25) % 1)
        local fi = u * (n - 1) + 1
        local i = floor(fi)
        local f = fi - i
        local a, b = pts[i], pts[min(i + 1, n)]
        local x, y = lerp(a[1], b[1], f), lerp(a[2], b[2], f)
        y = y + sin(x * 0.006 + t * 1.3 + k) * 14
        local edge = min(u * 8, (1 - u) * 8, 1)
        lg.setColor(0.8, 0.9, 1, 0.55 * edge)
        lg.draw(dotTex, x, y, 0, 0.32, 0.32, 16, 16)
        lg.setColor(0.6, 0.75, 1, 0.08 * edge)
        lg.draw(glowTex, x, y, 0, 0.35, 0.35, 64, 64)
      end
    end
  end
  lg.setLineWidth(1)
  lg.setBlendMode("alpha")
end

local function drawGates(t, camX)
  for _, g in ipairs(world.gates) do
    if g.x > camX - 400 and g.x < camX + W + 400 and g.open < 1 then
      local o = smooth(g.open)
      local gyTop = 0
      for _, b in ipairs(g.blobs) do
        local spread = 1 + o * 3
        local x = g.x + b.dx * spread + sin(t * b.sp + b.ph) * 18
        local y = b.y + cos(t * b.sp * 0.8 + b.ph) * 14 - o * 200 * (b.dx > 0 and 1 or 0.6)
        lg.setColor(0.035, 0.025, 0.08, 0.55 * (1 - o))
        lg.draw(glowTex, x, y, 0, b.r / 50, b.r / 50, 64, 64)
      end
      -- cold shimmer
      lg.setBlendMode("add")
      for _, m in ipairs(g.motes) do
        local x = g.x + m.dx * (1 + o * 2) + sin(t * 0.7 + m.ph) * 20
        local y = m.y + sin(t * 0.5 + m.ph) * 25
        lg.setColor(0.55, 0.6, 1.0, (0.35 + 0.25 * sin(t * 2 + m.ph)) * (1 - o))
        lg.draw(dotTex, x, y, 0, 0.4, 0.4, 16, 16)
        lg.setColor(0.35, 0.3, 0.8, 0.05 * (1 - o))
        lg.draw(glowTex, x, y, 0, 0.9, 0.9, 64, 64)
      end
      lg.setBlendMode("alpha")
      -- need indicator: a row of small orbs
      local have = g.kind == "lights" and #world.followers or world.bloomed
      local n = g.need
      local y = 110 - o * 60
      for i = 1, n do
        local x = g.x + (i - (n + 1) / 2) * 26
        local lit = i <= have
        lg.setColor(1, 1, 1, (lit and 0.9 or 0.18) * (1 - o))
        lg.circle(lit and "fill" or "line", x, y, lit and 6 or 5)
        if lit then
          lg.setBlendMode("add")
          lg.setColor(1, 0.9, 0.7, 0.5 * (1 - o))
          lg.draw(glowTex, x, y, 0, 0.25, 0.25, 64, 64)
          lg.setBlendMode("alpha")
        end
      end
    end
  end
end

local function drawBuds(t, camX)
  local bp = Audio.beatPhase()
  local pulse = exp(-bp * 6)
  for _, b in ipairs(world.buds) do
    if b.x > camX - 100 and b.x < camX + W + 100 then
      local gy = groundY(b.x)
      local sway = sin(t * 1.1 + b.ph) * 4
      local tx, ty = b.x + sway, gy - b.h
      lg.setLineWidth(2)
      lg.setColor(0.35, 0.55, 0.45, 0.8)
      lg.line(b.x, gy + 2, b.x + sway * 0.5, gy - b.h * 0.5, tx, ty)
      lg.setLineWidth(1)
      if b.state == "bud" then
        local br = 0.5 + 0.2 * sin(t * 2 + b.ph)
        lg.setColor(b.col[1] * 0.5, b.col[2] * 0.5, b.col[3] * 0.5, 0.9)
        lg.ellipse("fill", tx, ty - 5, 5, 9)
        lg.setBlendMode("add")
        lg.setColor(b.col[1], b.col[2], b.col[3], 0.18 * br)
        lg.draw(glowTex, tx, ty - 5, 0, 0.3, 0.3, 64, 64)
        lg.setBlendMode("alpha")
      else
        local open = smooth(b.t / 0.8)
        local sc = (1 + pulse * 0.18) * open
        local np = b.perfect and 8 or 6
        for k = 1, np do
          local a = k / np * pi * 2 + t * 0.3
          local px, py = tx + cos(a) * 10 * sc, ty + sin(a) * 10 * sc
          lg.setColor(b.col[1], b.col[2], b.col[3], 0.85)
          lg.ellipse("fill", px, py, 7 * sc, 4 * sc, a)
        end
        lg.setColor(1, 0.97, 0.85, 1)
        lg.circle("fill", tx, ty, 4 * sc)
      end
    end
  end
end

local function drawTree(t, camX)
  if LX < camX - 500 or LX > camX + W + 500 then return end
  local gy = groundY(LX)
  local lit = world.treeLit
  local call = 0.5 + 0.5 * sin(t * 1.4)
  for _, s in ipairs(world.tree) do
    local w = s[5]
    local c = lerpc({ 0.55, 0.52, 0.7 }, { 1, 0.86, 0.6 }, lit)
    lg.setLineWidth(max(1, w))
    lg.setColor(c[1], c[2], c[3], 0.55 + 0.45 * lit)
    lg.line(LX + s[1], gy + s[2], LX + s[3], gy + s[4])
  end
  lg.setLineWidth(1)
  -- blossoms at branch tips
  lg.setBlendMode("add")
  for i, s in ipairs(world.tree) do
    if s[6] >= 5 then
      local a = (0.15 + 0.25 * call) * (1 - lit) + lit * 0.8
      local col = PALETTE[(i % #PALETTE) + 1]
      lg.setColor(col[1], col[2], col[3], a)
      lg.draw(dotTex, LX + s[3], gy + s[4], 0, 0.5 + lit * 0.4, 0.5 + lit * 0.4, 16, 16)
    end
  end
  -- the orb
  local oy = gy - 240
  lg.setColor(1, 0.92, 0.75, 0.25 + 0.2 * call + lit * 0.6)
  lg.draw(glowTex, LX, oy, 0, 1.2 + lit * 2, 1.2 + lit * 2, 64, 64)
  lg.setBlendMode("alpha")
  lg.setColor(1, 0.97, 0.9, 0.6 + 0.4 * lit)
  lg.circle("fill", LX, oy, 10 + lit * 6)
end

local function drawLight(x, y, col, r, a)
  lg.setColor(col[1] * a, col[2] * a, col[3] * a, 1)
  lg.draw(glowTex, x, y, 0, r / 64, r / 64, 64, 64)
end

local function drawSpark(x, y, col, size, a)
  -- outer halo, inner core
  lg.setBlendMode("add")
  lg.setColor(col[1], col[2], col[3], 0.35 * a)
  lg.draw(glowTex, x, y, 0, size * 0.9, size * 0.9, 64, 64)
  lg.setColor(col[1], col[2], col[3], 0.8 * a)
  lg.draw(glowTex, x, y, 0, size * 0.28, size * 0.28, 64, 64)
  lg.setBlendMode("alpha")
  lg.setColor(1, 1, 1, 0.95 * a)
  lg.circle("fill", x, y, 3.2 * size)
end

local function drawRingsAndSparks()
  lg.setBlendMode("add")
  for _, r in ipairs(world.rings) do
    local f = r.t / r.life
    local rad = r.maxR * (1 - (1 - f) ^ 3)
    lg.setLineWidth(r.w * 3 * (1 - f) + 1)
    lg.setColor(r.col[1], r.col[2], r.col[3], 0.12 * (1 - f) ^ 1.5)
    lg.circle("line", r.x, r.y, rad, 72)
    lg.setLineWidth(r.w * (1 - f) + 0.5)
    lg.setColor(r.col[1], r.col[2], r.col[3], 0.45 * (1 - f) ^ 2)
    lg.circle("line", r.x, r.y, rad, 72)
  end
  lg.setLineWidth(1)
  for _, s in ipairs(world.sparks) do
    local f = s.t / s.life
    lg.setColor(s.col[1], s.col[2], s.col[3], (1 - f) * 0.9)
    lg.draw(dotTex, s.x, s.y, 0, s.size * (1 - f * 0.5), s.size * (1 - f * 0.5), 16, 16)
  end
  lg.setBlendMode("alpha")
end

local function drawMotes(camX, camY, col, a)
  local t = love.timer.getTime()
  lg.setBlendMode("add")
  for _, m in ipairs(motes) do
    local x = (m.x - camX * m.z * 0.5 + sin(t * 0.3 + m.ph) * 20) % W
    local y = (m.y - (camY or 0) * m.z * 0.5 + sin(t * 0.21 + m.ph) * 30 - t * 6 * m.z) % H
    lg.setColor(col[1], col[2], col[3], a * (0.3 + 0.3 * sin(t + m.ph)) * m.z)
    lg.draw(dotTex, x, y, 0, 0.18 * m.z + 0.1, 0.18 * m.z + 0.1, 16, 16)
  end
  lg.setBlendMode("alpha")
end

local function drawCentered(text, font, y, a, col)
  lg.setFont(font)
  col = col or { 1, 0.97, 0.92 }
  lg.setColor(0, 0, 0, 0.25 * a)
  lg.printf(text, 2, y + 2, W, "center")
  lg.setColor(col[1], col[2], col[3], a)
  lg.printf(text, 0, y, W, "center")
end

---------------------------------------------------------------------------
-- draw states
---------------------------------------------------------------------------
local function drawPlay()
  local wd = world
  local p = wd.player
  local camX, camY = wd.cam.x, wd.cam.y
  local sky = skyAt(p.x)
  local t = love.timer.getTime()
  local finale = state == "finale"
  local F = wd.finale
  if finale then
    camY = camY + F.camY
    local k = smooth(F.t / 6)
    local night = { top = { 0.02, 0.03, 0.12 }, bot = { 0.95, 0.55, 0.42 } }
    sky = { top = lerpc(sky.top, night.top, k), bot = lerpc(sky.bot, night.bot, k), amb = 1, ground = sky.ground, rim = sky.rim }
  end

  -- 1. scene
  lg.setCanvas(canvas)
  lg.clear(0, 0, 0, 1)
  drawSky(sky.top, sky.bot, camX, camY, finale and 1 or clamp(1.1 - sky.amb, 0.2, 1))
  drawMountains(sky, camX, camY)
  lg.push()
  lg.translate(-floor(camX), -floor(camY))
  drawGround(sky, camX)
  drawReeds(sky, camX, t)
  drawRibbons(t, camX)
  drawBuds(t, camX)
  drawTree(t, camX)
  -- sleeping lights (dim) drawn in the scene
  for _, w in ipairs(wd.wanderers) do
    if w.state == "sleep" and w.x > camX - 100 and w.x < camX + W + 100 then
      local br = 0.35 + 0.15 * sin(w.t * 1.2)
      local near = dist(p.x, p.y, w.x, w.y) < 300 and (0.3 + 0.3 * sin(t * 6)) or 0
      local c = { w.col[1] * 0.6 + 0.2, w.col[2] * 0.6 + 0.2, w.col[3] * 0.6 + 0.2 }
      drawSpark(w.x, w.y, c, 0.55, br + near)
    end
  end
  lg.pop()

  -- 2. light map (multiplied over the scene)
  if not finale then
    lg.setCanvas(lightCanvas)
    local amb = sky.amb
    lg.clear(amb, amb * 0.97, amb * 1.02 > 1 and 1 or amb * 1.02, 1)
    lg.push()
    lg.translate(-floor(camX), -floor(camY))
    lg.setBlendMode("add")
    local R = groupRadius() * p.glow
    drawLight(p.x, p.y, { 1, 0.88, 0.70 }, R * 1.6, 1.3 * LIGHT_GAIN)
    drawLight(p.x, p.y, { 1, 0.92, 0.80 }, R * 0.7, 1.0 * LIGHT_GAIN)
    for _, f in ipairs(wd.followers) do drawLight(f.x, f.y, f.col, 130, 0.8 * LIGHT_GAIN) end
    for _, w in ipairs(wd.wanderers) do
      if w.state == "sleep" then drawLight(w.x, w.y, w.col, 70, 0.25) end
    end
    for _, b in ipairs(wd.buds) do
      if b.state == "bloom" and b.x > camX - 200 and b.x < camX + W + 200 then
        drawLight(b.x, groundY(b.x) - b.h, b.col, 150 * smooth(b.t / 0.8), 0.6)
      end
    end
    for _, r in ipairs(wd.rings) do
      local f = r.t / r.life
      drawLight(r.x, r.y, r.col, r.maxR * f + 20, 0.35 * (1 - f))
    end
    drawLight(LX, groundY(LX) - 240, { 1, 0.85, 0.6 }, 220, 0.5)
    lg.pop()
    lg.setBlendMode("alpha")
    lg.setCanvas(canvas)
    lg.setColor(1, 1, 1, 1)
    lg.setBlendMode("multiply", "premultiplied")
    lg.draw(lightCanvas)
    lg.setBlendMode("alpha")
  else
    lg.setCanvas(canvas)
  end

  -- 3. glows on top
  lg.push()
  lg.translate(-floor(camX), -floor(camY))
  drawGates(t, camX)
  lg.setBlendMode("add")
  lg.setColor(1, 1, 1, 1)
  lg.draw(trailPS)
  lg.setBlendMode("alpha")
  for i, f in ipairs(wd.followers) do
    local a = 1
    local s = 0.75
    if f.state == "waking" then s = 0.55 + f.wake * 0.3; a = 0.6 + f.wake * 0.5 end
    if f.echoAt and wd.time > f.echoAt and wd.time < f.echoAt + 0.4 then
      local e = 1 - (wd.time - f.echoAt) / 0.4
      s = s + 0.5 * e
      if not f.echoRing or f.echoRing ~= f.echoAt then f.echoRing = f.echoAt; addRing(f.x, f.y, f.col, 90, 0.8, 2) end
    end
    if finale then s = s * (1 + F.pulse * 0.4) end
    drawSpark(f.x, f.y, f.col, s, a)
  end
  if not finale then
    lg.setBlendMode("add")
    lg.setColor(1, 0.85, 0.65, 0.07)
    lg.draw(glowTex, p.x, p.y, 0, groupRadius() / 64, groupRadius() / 64, 64, 64)
    lg.setBlendMode("alpha")
  end
  drawSpark(p.x, p.y, PLAYER_COL, 0.95 * p.glow * (finale and (1 + F.pulse * 0.3) or 1), 1)
  drawRingsAndSparks()
  lg.pop()

  -- finale overlays (screen space)
  if finale then
    local tt = F.trackT
    lg.setBlendMode("add")
    -- constellation lines
    if tt > 21.3 then
      local la = clamp((tt - 21.3) / 4, 0, 1) * (0.10 + 0.25 * (F.rms or 0.5))
      lg.setLineWidth(1)
      local rs = F.risers
      for i = 1, #rs do
        local a = rs[i]
        for j = i + 1, min(#rs, i + 12) do
          local b = rs[j]
          local dx, dy = a.x - b.x, a.y - b.y
          local d2 = dx * dx + dy * dy
          if d2 < 130 * 130 then
            lg.setColor(1, 0.9, 0.8, la * (1 - d2 / (130 * 130)))
            lg.line(a.x, a.y, b.x, b.y)
          end
        end
      end
    end
    for _, r in ipairs(F.risers) do
      local tw = 0.6 + 0.4 * sin(r.ph * 3)
      local s = r.s * (1 + F.pulse * 0.5)
      lg.setColor(r.col[1], r.col[2], r.col[3], 0.35 * tw)
      lg.draw(glowTex, r.x, r.y, 0, s * 0.45, s * 0.45, 64, 64)
      lg.setColor(1, 1, 1, 0.9 * tw)
      lg.draw(dotTex, r.x, r.y, 0, s * 0.35, s * 0.35, 16, 16)
    end
    for _, b in ipairs(F.bursts) do
      local f = b.t / 2.2
      for k = 1, 14 do
        local a = k / 14 * pi * 2
        local rr = 90 * (1 - (1 - f) ^ 3)
        lg.setColor(b.col[1], b.col[2], b.col[3], 0.7 * (1 - f))
        lg.draw(dotTex, b.x + cos(a) * rr, b.y + sin(a) * rr + f * 20, 0, 0.5, 0.5, 16, 16)
      end
    end
    lg.setBlendMode("alpha")
    for _, L in ipairs(FINALE_LINES) do
      if tt >= L[1] and tt <= L[2] then
        local a = smooth((tt - L[1]) / 1.2) * smooth((L[2] - tt) / 1.2)
        drawCentered(L[3], fonts.line, H * 0.08, a)
      end
    end
  end

  drawMotes(camX, camY, sky.rim, finale and 0.6 or 0.8)

  -- vignette
  lg.setColor(1, 1, 1, 1)
  lg.draw(vignette, 0, 0, 0, W / 320, H / 180)

  -- UI
  if not finale then
    if wd.card then
      local c = CHAPTERS[wd.card.i]
      local tt = wd.card.t
      local a = smooth(tt / 1.4) * smooth((6 - tt) / 1.6)
      drawCentered(c.name, fonts.chapter, H * 0.2, a)
      drawCentered(c.sub, fonts.sub, H * 0.2 + 82, a * 0.8)
    end
    if wd.hint.a > 0 and wd.hint.text ~= "" then
      drawCentered(wd.hint.text, fonts.ui, H - 74, wd.hint.a * 0.9)
    end
    -- companions counter (top-left)
    local n = #wd.followers
    for i = 1, #wd.wanderers do
      local x, y = 34 + (i - 1) * 18, 32
      if i <= n then
        local c = wd.followers[i].col
        lg.setColor(c[1], c[2], c[3], 0.85)
        lg.circle("fill", x, y, 4.5)
      else
        lg.setColor(1, 1, 1, 0.12)
        lg.circle("line", x, y, 4)
      end
    end
  end
end

local function drawTitle()
  local t = stateT
  lg.setCanvas(canvas)
  lg.clear(0, 0, 0, 1)
  local sky = { top = { 0.02, 0.025, 0.08 }, bot = { 0.30, 0.15, 0.36 }, ground = { 0.05, 0.035, 0.09 }, rim = { 0.7, 0.5, 0.8 } }
  local camX = t * 14
  drawSky(sky.top, sky.bot, camX, 0, 1)
  drawMountains(sky, camX, 0)
  -- foreground dune
  local c = sky.ground
  drawStrip(function(x) return 640 + 26 * sin((x + camX) * 0.004) + 10 * sin((x + camX) * 0.011) end, -20, W + 20, 16, 900, { c[1], c[2], c[3], 1 }, { 0.02, 0.01, 0.04, 1 })
  -- drifting lights
  lg.setBlendMode("add")
  for i, l in ipairs(title.lights) do
    local x = (l.x + t * l.sp) % (W + 80) - 40
    local y = l.y + sin(t * 0.5 + l.ph) * 20
    lg.setColor(l.col[1], l.col[2], l.col[3], 0.22)
    lg.draw(glowTex, x, y, 0, 0.35, 0.35, 64, 64)
    lg.setColor(1, 1, 1, 0.7)
    lg.draw(dotTex, x, y, 0, 0.22, 0.22, 16, 16)
  end
  lg.setBlendMode("alpha")
  -- the hero light, pulsing gently
  local hx, hy = W / 2, 470 + sin(t * 1.1) * 8
  drawSpark(hx, hy, PLAYER_COL, 1.1 + 0.1 * sin(t * 2), 1)
  drawMotes(camX, 0, sky.rim, 0.8)
  lg.setColor(1, 1, 1, 1)
  lg.draw(vignette, 0, 0, 0, W / 320, H / 180)
  local a = smooth(t / 2)
  drawCentered("Kindred Lights", fonts.title, 150, a)
  drawCentered("Sing into the dark. Someone will answer.", fonts.sub, 278, a * 0.85)
  local blink = 0.55 + 0.45 * sin(t * 2.4)
  drawCentered("Press Space or click to begin", fonts.ui, 590, smooth((t - 1.5) / 1.5) * blink)
  drawCentered("C  credits      F11  fullscreen      Esc  quit", fonts.small, 664, smooth((t - 2) / 1.5) * 0.5)
end

local CREDITS = {
  { "h", "Kindred Lights" },
  { "", "" },
  { "t", "A game by Rida Kalam" },
  { "t", "made for thatgamejam #02" },
  { "", "" },
  { "h", "Music" },
  { "t", "Theme music by Jason Grace" },
  { "t", "(the jam's theme track, played unmodified in the finale)" },
  { "t", "All other music and sound is synthesized live in the game" },
  { "", "" },
  { "h", "Fonts" },
  { "t", "Cormorant Garamond and Quicksand (SIL Open Font License)" },
  { "", "" },
  { "h", "Made with" },
  { "t", "L\195\150VE 11.5" },
  { "", "" },
  { "h", "AI disclosure" },
  { "t", "This game contains AI-generated content." },
  { "t", "The code was written with an AI coding assistant." },
  { "t", "No AI-generated images or music are used;" },
  { "t", "all visuals are drawn in code and all game music is synthesized in code." },
  { "", "" },
  { "", "" },
  { "h", "Thank you for answering." },
}

local function drawCredits()
  local t = credits.t or 0
  lg.setCanvas(canvas)
  lg.clear(0, 0, 0, 1)
  local sky = { top = { 0.02, 0.03, 0.10 }, bot = { 0.22, 0.12, 0.30 }, ground = { 0.04, 0.03, 0.08 }, rim = { 0.9, 0.7, 0.6 } }
  drawSky(sky.top, sky.bot, t * 10, 0, 1)
  drawMountains(sky, t * 10, 0)
  lg.setBlendMode("add")
  for i, l in ipairs(title.lights) do
    local x = (l.x + t * l.sp) % (W + 80) - 40
    local y = (l.y - t * 12 + i * 13) % (H + 60) - 30
    lg.setColor(l.col[1], l.col[2], l.col[3], 0.2)
    lg.draw(glowTex, x, y, 0, 0.3, 0.3, 64, 64)
  end
  lg.setBlendMode("alpha")
  local y = H - t * 42 + 40
  local endY
  for _, c in ipairs(CREDITS) do
    if c[1] == "h" then
      if y > -60 and y < H + 10 then drawCentered(c[2], fonts.creditH, y, 1, { 1, 0.9, 0.75 }) end
      y = y + 56
    elseif c[1] == "t" then
      if y > -60 and y < H + 10 then drawCentered(c[2], fonts.credit, y, 0.9) end
      y = y + 36
    else
      y = y + 26
    end
    endY = y
  end
  credits.done = endY < H * 0.55
  if credits.done then credits.scrollStop = true end
  lg.setColor(1, 1, 1, 1)
  lg.draw(vignette, 0, 0, 0, W / 320, H / 180)
  if t > 3 then
    lg.setFont(fonts.small)
    lg.setColor(1, 1, 1, 0.35)
    lg.printf("Press any key to return", 0, 24, W - 30, "right")
  end
end

---------------------------------------------------------------------------
-- LÖVE callbacks
---------------------------------------------------------------------------
local function step(dt)
  frame = frame + 1
  stateT = stateT + dt
  Audio.update(dt)
  if state == "title" then
    Audio.layers.bells = true
  elseif state == "play" then
    if not paused then
      updatePlay(dt)
      updateEffects(dt)
    end
  elseif state == "finale" then
    updateFinale(dt)
    updateEffects(dt)
  elseif state == "credits" then
    if not credits.scrollStop then credits.t = (credits.t or 0) + dt end
    if OPT.autoplay and stateT > 15 then shot("08_credits_end", 0) end
    if OPT.autoplay and stateT > 22 then logf("[test] reached credits; quitting"); love.event.quit() end
  end
  -- fade
  local fs = (state == "finale" and fade.target == 1) and 0.35 or 1.2
  if fade.a < fade.target then fade.a = min(fade.target, fade.a + dt * fs)
  elseif fade.a > fade.target then fade.a = max(fade.target, fade.a - dt * 0.8) end
end

function love.update(dt)
  dt = min(dt, 1 / 20)
  if OPT.autoplay or OPT.shots then dt = 1 / 60 end
  for i = 1, OPT.fast do step(dt) end
  if OPT.autoplay and state == "title" and stateT > (OPT.shots and 3 or 0.5) then
    world = newGame(); setState("play"); fade.a, fade.target = 1, 0
    Audio.layers = { pad = true, arp = 0, bass = false, rhythm = false, bells = false }
  end
  if OPT.uitest then
    local seq = {
      [60] = { "keypressed", "space" }, [120] = { "keypressed", "escape" }, [150] = { "keypressed", "escape" },
      [180] = { "mousepressed", 640, 360, 2 }, [200] = { "keypressed", "space" }, [260] = { "keypressed", "escape" },
      [290] = { "keypressed", "q" }, [340] = { "keypressed", "c" }, [500] = { "keypressed", "x" },
      [560] = { "mousepressed", 100, 100, 1 }, [620] = { "keypressed", "escape" }, [700] = { "quit" },
    }
    local e = seq[frame]
    if e then logf("[uitest] frame " .. frame .. " state=" .. state .. " paused=" .. tostring(paused) .. " -> " .. e[1] .. " " .. tostring(e[2])); love.event.push(unpack(e)) end
  end
  if OPT.maxframes and frame > OPT.maxframes then logf("[test] maxframes reached in state " .. state); love.event.quit() end
end

local function shotSoon()
  for _, q in ipairs(shotQueue) do if q.at - frame <= 2 then return true end end
  return false
end

function love.draw()
  if OPT.shots and OPT.skipdraw and not shotSoon() then return end
  if state == "title" then drawTitle()
  elseif state == "play" or state == "finale" then drawPlay()
  elseif state == "credits" then drawCredits() end
  -- fade overlay
  if fade.a > 0.001 then
    if fade.white then lg.setColor(1, 0.96, 0.9, fade.a) else lg.setColor(0, 0, 0, fade.a) end
    lg.rectangle("fill", 0, 0, W, H)
  end
  if paused then
    lg.setColor(0, 0, 0, 0.55)
    lg.rectangle("fill", 0, 0, W, H)
    drawCentered("Paused", fonts.chapter, H * 0.33, 1)
    drawCentered("Esc  resume        Q  return to title", fonts.ui, H * 0.33 + 100, 0.8)
  end
  lg.setCanvas()
  lg.clear(0, 0, 0, 1)
  local ww, wh = lg.getDimensions()
  local sc = min(ww / W, wh / H)
  lg.setColor(1, 1, 1, 1)
  lg.setBlendMode("alpha", "premultiplied")
  lg.draw(canvas, floor((ww - W * sc) / 2), floor((wh - H * sc) / 2), 0, sc, sc)
  lg.setBlendMode("alpha")

  -- screenshots for the test harness
  for i = #shotQueue, 1, -1 do
    local q = shotQueue[i]
    if frame >= q.at then
      lg.captureScreenshot("shot_" .. q.name .. ".png")
      logf("[shot] " .. q.name)
      table.remove(shotQueue, i)
    end
  end
end

local function startGame()
  world = newGame()
  setState("play")
  fade.a, fade.target, fade.white = 1, 0, false
  Audio.layers = { pad = true, arp = 0, bass = false, rhythm = false, bells = false }
  Audio.musicTarget = 1
  Audio.sfxVol = 1
end

local function toTitle()
  if theme then theme:stop() end
  paused = false
  setState("title")
  fade.a, fade.target, fade.white = 1, 0, false
  Audio.stopAll()
  Audio.muted = false
  Audio.musicVol, Audio.musicTarget = 0, 1
  Audio.sfxVol = 1
  Audio.layers = { pad = true, arp = 0, bass = false, rhythm = false, bells = true }
end

function love.keypressed(key)
  if key == "f11" or (key == "return" and love.keyboard.isDown("lalt", "ralt")) then
    love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
    return
  end
  if state == "title" then
    if key == "escape" then love.event.quit()
    elseif key == "c" then setState("credits"); credits.t = 0; credits.scrollStop = false; fade.white = false
    elseif key == "space" or key == "return" then startGame() end
  elseif state == "play" then
    if paused then
      if key == "escape" then paused = false
      elseif key == "q" then toTitle() end
      return
    end
    if key == "escape" or key == "p" then paused = true; return end
    if key == "space" or key == "j" or key == "e" or key == "z" then singQueued = true end
  elseif state == "finale" then
    if key == "space" or key == "j" or key == "e" or key == "z" then singQueued = true end
    if key == "escape" and love.keyboard.isDown("lshift", "rshift") then toTitle() end
  elseif state == "credits" then
    if stateT > 1.5 then toTitle() end
  end
end

function love.mousepressed(x, y, button)
  if state == "title" and button == 1 then startGame()
  elseif state == "play" and not paused and button == 2 then singQueued = true
  elseif state == "finale" and button == 2 then singQueued = true
  elseif state == "credits" and stateT > 1.5 then toTitle() end
end

function love.focus(f)
  if not f and state == "play" and not OPT.autoplay then paused = true end
end

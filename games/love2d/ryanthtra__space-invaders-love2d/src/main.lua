--[[============================================================================
  SPACE INVADERS - a classic arcade clone for LOVE 2D (11.x)
  ----------------------------------------------------------------------------
  Files   : conf.lua + main.lua  (fully self-contained, no assets needed)
  Run     : love .            from this folder
  Controls:
    LEFT / RIGHT  or  A / D .... move the ship
    SPACE ....................... fire
    P ........................... pause
    M ........................... mute / unmute
    ESC .......................... quit

  Dev note: run with SI_SMOKE_TEST=1 to auto-play a short game and exit,
  writing smoke_result.txt (used for quick sanity checks).
============================================================================]] --

-- smoke-test trigger: env var SI_SMOKE_TEST or a smoke_test.flag file in the project dir
local function smokeEnabled()
  if os.getenv("SI_SMOKE_TEST") then return true end
  local f = io.open("smoke_test.flag", "r")
  if f then
    f:close()
    return true
  end
  return false
end

-- capture runtime errors to a file during smoke tests (normally LÖVE shows a dialog)
if smokeEnabled() then
  function love.errhand(msg)
    local f = io.open("love_error.log", "w")
    if f then
      f:write(tostring(msg) .. "\n")
      f:close()
    end
  end
end

------------------------------------------------------------------------------
-- Screen & layout
------------------------------------------------------------------------------
local W, H              = 800, 600
local HUD_TOP           = 44
local PLAYER_Y          = 532
local BARRIER_Y         = 448
local UFO_Y             = 72
local DEATH_LINE        = PLAYER_Y - 6 -- invaders reaching this line ends the game

------------------------------------------------------------------------------
-- Invader grid
------------------------------------------------------------------------------
local COLS, ROWS        = 11, 5
local PITCH_X, PITCH_Y  = 40, 38 -- spacing between invader cells
local STEP_X, STEP_DROP = 8, 16 -- march step / drop when hitting an edge
local GRID_START_Y      = 104

------------------------------------------------------------------------------
-- Tuning
------------------------------------------------------------------------------
local PLAYER_SPEED      = 300
local PLAYER_BULLET_VY  = -560
local FIRE_COOLDOWN     = 0.12
local PX                = 3 -- "pixel" size for the big sprites
local MISSILE_SCALE     = 2 -- "pixel" size for enemy bullets

------------------------------------------------------------------------------
-- Palette (r,g,b in 0..1)
------------------------------------------------------------------------------
local COL               = {
  bg      = { 0.02, 0.03, 0.07 },
  star    = { 0.55, 0.65, 0.85 },
  squid   = { 0.42, 0.90, 1.00 },
  crab    = { 0.31, 0.98, 0.48 },
  octopus = { 1.00, 0.72, 0.42 },
  player  = { 0.95, 0.97, 1.00 },
  pbullet = { 0.95, 0.98, 0.60 },
  ebullet = { 1.00, 0.47, 0.78 },
  ufo     = { 1.00, 0.33, 0.44 },
  barrier = { 0.31, 0.98, 0.48 },
  text    = { 0.85, 0.88, 0.95 },
  dim     = { 0.45, 0.50, 0.62 },
  red     = { 1.00, 0.30, 0.35 },
  gold    = { 1.00, 0.85, 0.30 },
}

------------------------------------------------------------------------------
-- Small helpers
------------------------------------------------------------------------------
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

-- axis-aligned bounding-box overlap (x,y = top-left corners)
local function overlaps(ax, ay, aw, ah, bx, by, bw, bh)
  return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

-- minimal class helper: Foo.new(...) creates the object and calls Foo:init(...)
local function class(name)
  local cls = { __name = name }
  cls.__index = cls
  function cls.new(...)
    local obj = setmetatable({ _class = cls }, cls)
    if cls.init then cls.init(obj, ...) end
    return obj
  end

  return cls
end

------------------------------------------------------------------------------
-- Procedural pixel-art sprites (rendered once into small textures)
------------------------------------------------------------------------------
local SHAPES = {
  squidA = {
    "...XX...",
    "..XXXX..",
    ".XXXXXX.",
    "XX.XX.XX",
    "XXXXXXXX",
    "..X..X..",
    ".X.XX.X.",
    "X.X..X.X",
  },
  squidB = {
    "...XX...", "..XXXX..", ".XXXXXX.", "XX.XX.XX",
    "XXXXXXXX", ".X.XX.X.", "X......X", ".X....X.",
  },
  crabA = {
    "..X.....X..", "...X...X...", "..XXXXXXX..", ".XX.XXX.XX.",
    "XXXXXXXXXXX", "X.XXXXXXX.X", "X.X.....X.X", "...XX.XX...",
  },
  crabB = {
    "..X.....X..", "X..X...X..X", "X.XXXXXXX.X", "XXX.XXX.XXX",
    "XXXXXXXXXXX", ".XXXXXXXXX.", "..X.....X..", ".X.......X.",
  },
  octopusA = {
    "....XXXX....", ".XXXXXXXXXX.", "XXXXXXXXXXXX", "XXX..XX..XXX",
    "XXXXXXXXXXXX", "...XX..XX...", "..XX.XX.XX..", "XX........XX",
  },
  octopusB = {
    "....XXXX....", ".XXXXXXXXXX.", "XXXXXXXXXXXX", "XXX..XX..XXX",
    "XXXXXXXXXXXX", "..XXX..XXX..", ".XX..XX..XX.", "..XX....XX..",
  },
  player = {
    "......X......", ".....XXX.....", ".....XXX.....",
    ".XXXXXXXXXXX.", "XXXXXXXXXXXXX", "XXXXXXXXXXXXX",
  },
  ufo = {
    ".....XXXXXX.....", "...XXXXXXXXXX...", "..XXXXXXXXXXXX..",
    "XXXXXXXXXXXXXXXX", ".XX.XX.XX.XX.XX.", "...XXXXXXXXXX...",
  },
  missileA = { ".X.", "X..", ".X.", "..X", ".X.", "X.." },
  missileB = { "X..", ".X.", "X..", ".X.", "X..", ".X." },
}

local KINDS = {
  squid   = { frames = { "squidA", "squidB" }, w = 8, h = 8, points = 40, color = COL.squid },
  crab    = { frames = { "crabA", "crabB" }, w = 11, h = 8, points = 20, color = COL.crab },
  octopus = { frames = { "octopusA", "octopusB" }, w = 12, h = 8, points = 10, color = COL.octopus },
}
local ROW_KIND = { "squid", "crab", "crab", "octopus", "octopus" }
-- center the 11-column grid horizontally (widest kind defines the span)
local GRID_START_X = math.floor((W - ((COLS - 1) * PITCH_X + KINDS.octopus.w * PX)) / 2)

-- build a pixel-art texture from an array of strings ('X' = filled)
local function makeSprite(rows, color, px)
  local w = #rows[1] * px
  local h = #rows * px
  local img = love.image.newImageData(w, h)
  for r = 1, #rows do
    for c = 1, #rows[r] do
      if rows[r]:sub(c, c) == "X" then
        for dy = 0, px - 1 do
          for dx = 0, px - 1 do
            img:setPixel((c - 1) * px + dx, (r - 1) * px + dy, color[1], color[2], color[3], 1)
          end
        end
      end
    end
  end
  return love.graphics.newImage(img)
end

local SPR = {} -- sprite textures: SPR[name] = image (px = PX), except missiles use MISSILE_SCALE
for name, rows in pairs(SHAPES) do
  local isMissile = name == "missileA" or name == "missileB"
  local color = isMissile and COL.ebullet or (name == "player" and COL.player
    or (name == "ufo" and COL.ufo) or COL.squid)
  SPR[name] = makeSprite(rows, color, isMissile and MISSILE_SCALE or PX)
end
-- recolor the invader frames per kind
for _, kind in ipairs({ "squid", "crab", "octopus" }) do
  local def = KINDS[kind]
  SPR[def.frames[1]] = makeSprite(SHAPES[def.frames[1]], def.color, PX)
  SPR[def.frames[2]] = makeSprite(SHAPES[def.frames[2]], def.color, PX)
end

------------------------------------------------------------------------------
-- Procedural retro sound effects (synthesized into SoundData at load time)
------------------------------------------------------------------------------
local function toneSample(t, dur, f0, f1, vol)
  -- linear sweep f0 -> f1 with exponential decay
  local f = f0 + (f1 - f0) * (t / dur)
  return math.sin(2 * math.pi * f * t) * vol * math.exp(-6 * (t / dur))
end

local function noiseSample(t, dur, vol)
  -- white noise with exponential decay
  local r = love.math.random() * 2 - 1
  return r * vol * math.exp(-8 * (t / dur))
end

-- build a Sound from a sample generator: gen(t, dur) -> amplitude in [-1,1]
local function makeSound(dur, gen, rate)
  rate = rate or 22050
  local n = math.floor(rate * dur)
  local sd = love.sound.newSoundData(n, rate, 16, 1)
  for i = 0, n - 1 do
    local t = i / rate
    local v = gen(t, dur)
    sd:setSample(i, clamp(v, -1, 1))
  end
  return love.audio.newSource(sd)
end

local SND = {}
local muted = false
-- play a sound unless muted (LÖVE 11 has no global volume API)
local function splay(snd, delay)
  if snd and not muted then snd:play(delay) end
end
local function initSounds()
  -- player laser: fast downward chirp
  SND.shoot = makeSound(0.12, function(t, d) return toneSample(t, d, 950, 320, 0.45) end)
  -- invader killed: short noisy crack + low blip
  SND.invaderDie = makeSound(0.16, function(t, d)
    return noiseSample(t, d, 0.5) + toneSample(t, d, 220, 90, 0.35)
  end)
  -- player explosion: longer noisy boom
  SND.playerDie = makeSound(0.7, function(t, d)
    return noiseSample(t, d, 0.8) + toneSample(t, d, 160, 40, 0.5)
  end)
  -- UFO: warbling two-tone loop (played on repeat while it's on screen)
  SND.ufo = makeSound(0.24, function(t, d)
    local f = t < d / 2 and 620 or 780
    return math.sin(2 * math.pi * f * t) * 0.18
  end)
  -- UFO bonus: quick ascending arpeggio
  SND.ufoDie = makeSound(0.3, function(t, d)
    local step = math.floor(t / (d / 3))
    local f = ({ 520, 660, 880 })[step + 1] or 880
    return toneSample(t - step * (d / 3), d / 3, f, f * 1.05, 0.4)
  end)
  -- march bass: four descending notes (one per step)
  local bassFreqs = { 110, 98, 87, 78 }
  for i = 1, 4 do
    SND["step" .. i] = makeSound(0.09, function(t, d)
      return toneSample(t, d, bassFreqs[i], bassFreqs[i] * 0.92, 0.5)
    end)
  end
  -- level clear jingle: little ascending scale
  local notes = { 392, 494, 587, 784 }
  for i = 1, #notes do
    SND["jingle" .. i] = makeSound(0.14, function(t, d)
      return toneSample(t, d, notes[i], notes[i], 0.35)
    end)
  end
end

------------------------------------------------------------------------------
-- Entities
------------------------------------------------------------------------------
local Player = class("Player")
function Player:init()
  self.w, self.h = SPR.player:getWidth(), SPR.player:getHeight()
  self.x, self.y = W / 2 - self.w / 2, PLAYER_Y
  self.alive     = true
  self.respawn   = 0 -- countdown before the ship reappears
  self.invinc    = 0 -- brief invulnerability after respawn
  self.fireCd    = 0
end

local Bullet = class("Bullet")
function Bullet:init(x, y, vy, hostile)
  self.x, self.y, self.vy = x, y, vy
  self.w                  = 3
  self.h                  = hostile and 14 or 12
  self.hostile            = hostile or false
  self.dead               = false
end

local Invader = class("Invader")
function Invader:init(col, row)
  self.kind  = ROW_KIND[row]
  self.def   = KINDS[self.kind]
  self.col   = col
  self.row   = row
  self.w     = self.def.w * PX
  self.h     = self.def.h * PX
  self.x     = GRID_START_X + (col - 1) * PITCH_X
  self.y     = GRID_START_Y + (row - 1) * PITCH_Y
  self.alive = true
end

local UFO = class("UFO")
function UFO:init()
  self.w, self.h = SPR.ufo:getWidth(), SPR.ufo:getHeight()
  local fromLeft = love.math.random() < 0.5
  self.x         = fromLeft and -self.w or W
  self.y         = UFO_Y
  self.vx        = fromLeft and 110 or -110
  self.bonus     = ({ 50, 100, 150, 300 })[love.math.random(4)]
  self.dead      = false
end

local Particle = class("Particle")
function Particle:init(x, y, color)
  local a          = love.math.random() * math.pi * 2
  local s          = love.math.random(40, 190)
  self.x, self.y   = x, y
  self.vx, self.vy = math.cos(a) * s, math.sin(a) * s
  self.life        = love.math.random(0.25, 0.6)
  self.t           = self.life
  self.color       = color or COL.gold
  self.size        = love.math.random(2, 4)
end

-- Destructible shield: a grid of small cells, eroded where bullets pass through.
local Barrier = class("Barrier")
function Barrier:init(x)
  self.cell            = 6
  self.cols, self.rows = 10, 7
  self.w               = self.cols * self.cell
  self.h               = self.rows * self.cell
  self.x, self.y       = x, BARRIER_Y
  -- classic arch shape: notch at the bottom center, flat top
  local mask           = {
    "XXXXXXXXXX",
    "XXXXXXXXXX",
    "XXXXXXXXXX",
    "XXXXXXXXXX",
    "XXX....XXX",
    "XX......XX",
    "X........X",
  }
  self.cells           = {}
  for r = 1, #mask do
    local rowCells = {}
    for c = 1, #mask[r] do
      rowCells[c] = mask[r]:sub(c, c) == "X"
    end
    self.cells[r] = rowCells
  end
end

-- damage a rectangular region of the shield; returns true if any cell was hit
function Barrier:hit(bx, by, bw, bh)
  local hitAny = false
  for r = 1, self.rows do
    for c = 1, self.cols do
      if self.cells[r][c] then
        local cx = self.x + (c - 1) * self.cell
        local cy = self.y + (r - 1) * self.cell
        if overlaps(bx, by, bw, bh, cx, cy, self.cell, self.cell) then
          -- erode the hit cell plus a little splash damage to neighbours
          self.cells[r][c] = false
          for _, dc in ipairs({ { 0, -1 }, { 0, 1 }, { -1, 0 } }) do
            local nr, nc = r + dc[1], c + dc[2]
            if nr >= 1 and nr <= self.rows and nc >= 1 and nc <= self.cols then
              if love.math.random() < 0.5 then self.cells[nr][nc] = false end
            end
          end
          hitAny = true
        end
      end
    end
  end
  return hitAny
end

------------------------------------------------------------------------------
-- Fonts (built once, used by the text helper below)
------------------------------------------------------------------------------
local FONT_SMALL, FONT_MED, FONT_BIG
local function initFonts()
  FONT_SMALL = love.graphics.newFont(14)
  FONT_MED   = love.graphics.newFont(20)
  FONT_BIG   = love.graphics.newFont(42)
end

------------------------------------------------------------------------------
-- Game state
------------------------------------------------------------------------------
local state = "title" -- title | playing | paused | levelclear | gameover
local player, ufo
local invaders = {}
local pBullets = {}
local eBullets = {}
local barriers = {}
local particles = {} -- pre-filled so update/draw are safe before the first game
local score, highScore, lives, level = 0, 0, 0, 1
local invaderDir, stepTimer, stepIndex, marchFrame
local enemyFireCd, ufoTimer, ufoSoundT
local clearJingleT, shakeT, smokeT, goTimer

function newGame()
  score, lives = 0, 3
  startLevel(1)
end

function startLevel(n)
  level       = n
  player      = Player.new()
  pBullets    = {}
  eBullets    = {}
  particles   = {}
  ufo         = nil
  invaderDir  = 1
  stepTimer   = 0
  stepIndex   = 0
  marchFrame  = 1
  enemyFireCd = love.math.random(0.8, 1.6)
  ufoTimer    = love.math.random(12, 22)
  ufoSoundT   = 0

  invaders    = {}
  for r = 1, ROWS do
    for c = 1, COLS do
      table.insert(invaders, Invader.new(c, r))
    end
  end

  barriers = {}
  local bw = Barrier.new(0).w -- width of one shield
  for i = 0, 3 do
    local x = (W / 4) * i + W / 8 - bw / 2
    table.insert(barriers, Barrier.new(x))
  end

  state = "playing"
end

-- how fast the formation marches: base speed scales with level and remaining count
local function marchInterval()
  local alive = 0
  for _, v in ipairs(invaders) do if v.alive then alive = alive + 1 end end
  local base = math.max(0.045, 0.28 - (level - 1) * 0.03)
  local factor = alive / (COLS * ROWS) -- 1.0 -> 0.0
  return base * (0.35 + 0.65 * factor) -- gets faster as they thin out
end

------------------------------------------------------------------------------
-- Explosion helper
------------------------------------------------------------------------------
local function explode(x, y, color, n)
  n = n or 14
  for _ = 1, n do
    table.insert(particles, Particle.new(x, y, color))
  end
end

-- player ship: movement, firing, respawn / invulnerability
local function updatePlayer(dt)
  local p = player
  if not p.alive then
    -- dead: wait, then respawn (if lives remain)
    p.respawn = p.respawn - dt
    if p.respawn <= 0 and lives > 0 then
      p.alive = true
      p.x = W / 2 - p.w / 2
      p.invinc = 1.5
    end
    return
  end

  p.invinc       = math.max(0, p.invinc - dt)
  p.fireCd       = math.max(0, p.fireCd - dt)

  local dir      = 0
  local wantFire = love.keyboard.isDown("space") or love.mouse.isDown(1)
  if smokeT then
    -- auto-play for the smoke test: weave left/right and keep firing,
    -- so bullets / collisions / scoring / barrier erosion all get exercised
    p.x = W / 2 + math.sin(love.timer.getTime() * 0.8) * 170 - p.w / 2
    wantFire = true
  else
    if love.keyboard.isDown("left", "a") then dir = dir - 1 end
    if love.keyboard.isDown("right", "d") then dir = dir + 1 end
    p.x = clamp(p.x + dir * PLAYER_SPEED * dt, 8, W - p.w - 8)
  end

  -- classic rule: only one player bullet on screen at a time
  if wantFire and p.fireCd <= 0 and #pBullets == 0 then
    table.insert(pBullets, Bullet.new(p.x + p.w / 2 - 1.5, p.y - 14, PLAYER_BULLET_VY, false))
    p.fireCd = FIRE_COOLDOWN
    splay(SND.shoot)
  end
end

-- the formation: timer-based march with edge drop/reverse, plus enemy fire
local function updateInvaders(dt)
  stepTimer = stepTimer - dt
  if stepTimer <= 0 then
    -- find current horizontal extent of live invaders
    local minX, maxX = W, 0
    for _, v in ipairs(invaders) do
      if v.alive then
        minX = math.min(minX, v.x)
        maxX = math.max(maxX, v.x + v.w)
      end
    end

    local hitEdge = (invaderDir > 0 and maxX + STEP_X > W - 8)
        or (invaderDir < 0 and minX - STEP_X < 8)

    if hitEdge then
      invaderDir = -invaderDir
      for _, v in ipairs(invaders) do
        if v.alive then v.y = v.y + STEP_DROP end
      end
    else
      for _, v in ipairs(invaders) do
        if v.alive then v.x = v.x + invaderDir * STEP_X end
      end
    end

    stepIndex = stepIndex % 4 + 1
    marchFrame = (marchFrame == 1) and 2 or 1
    splay(SND["step" .. stepIndex])
    stepTimer = marchInterval()

    -- reached the player's line? game over.
    for _, v in ipairs(invaders) do
      if v.alive and v.y + v.h >= DEATH_LINE then
        lives = 0
        explode(player.x + player.w / 2, player.y + player.h / 2, COL.player, 26)
        goTimer = 1.4
        return
      end
    end
  end

  -- enemy fire: pick a random column that still has invaders, shoot from its lowest one
  enemyFireCd = enemyFireCd - dt
  if enemyFireCd <= 0 then
    local cols = {}
    for _, v in ipairs(invaders) do
      if v.alive and not cols[v.col] then cols[v.col] = true end
    end
    local keys = {}
    for c in pairs(cols) do table.insert(keys, c) end
    if #keys > 0 then
      local c = keys[love.math.random(#keys)]
      local shooter
      for _, v in ipairs(invaders) do
        if v.alive and v.col == c then
          if not shooter or v.y > shooter.y then shooter = v end
        end
      end
      if shooter then
        table.insert(eBullets, Bullet.new(shooter.x + shooter.w / 2 - 1.5, shooter.y + shooter.h, 240 + level * 18, true))
      end
    end
    local base = math.max(0.35, 1.5 - (level - 1) * 0.12)
    enemyFireCd = base * love.math.random(0.6, 1.5)
  end
end

-- move bullets & resolve all bullet collisions (barriers, invaders, ufo, player)
local function updateBullets(dt)
  -- player bullets
  for i = #pBullets, 1, -1 do
    local b = pBullets[i]
    b.y = b.y + b.vy * dt
    if b.y + b.h < HUD_TOP then
      table.remove(pBullets, i)
    else
      local consumed = false

      -- shields absorb bullets
      for _, bar in ipairs(barriers) do
        if overlaps(b.x, b.y, b.w, b.h, bar.x, bar.y, bar.w, bar.h) and bar:hit(b.x, b.y, b.w, b.h) then
          consumed = true
          break
        end
      end

      -- invaders
      if not consumed then
        for _, v in ipairs(invaders) do
          if v.alive and overlaps(b.x, b.y, b.w, b.h, v.x, v.y, v.w, v.h) then
            v.alive = false
            score = score + v.def.points
            explode(v.x + v.w / 2, v.y + v.h / 2, v.def.color, 16)
            splay(SND.invaderDie)
            consumed = true
            break
          end
        end
      end

      -- ufo
      if not consumed and ufo and overlaps(b.x, b.y, b.w, b.h, ufo.x, ufo.y, ufo.w, ufo.h) then
        score = score + ufo.bonus
        explode(ufo.x + ufo.w / 2, ufo.y + ufo.h / 2, COL.ufo, 22)
        splay(SND.ufoDie)
        ufo = nil
        consumed = true
      end

      if consumed then table.remove(pBullets, i) end
    end
  end

  -- enemy bullets
  for i = #eBullets, 1, -1 do
    local b = eBullets[i]
    b.y = b.y + b.vy * dt
    if b.y > H - 24 then
      table.remove(eBullets, i)
    else
      local consumed = false

      for _, bar in ipairs(barriers) do
        if overlaps(b.x, b.y, b.w, b.h, bar.x, bar.y, bar.w, bar.h) and bar:hit(b.x, b.y, b.w, b.h) then
          consumed = true
          break
        end
      end

      local p = player
      if not consumed and p.alive and p.invinc <= 0
          and overlaps(b.x, b.y, b.w, b.h, p.x, p.y, p.w, p.h) then
        lives = lives - 1
        explode(p.x + p.w / 2, p.y + p.h / 2, COL.player, 26)
        splay(SND.playerDie)
        shakeT = 0.4
        p.alive = false
        p.respawn = 1.2
        consumed = true
      end

      if consumed then table.remove(eBullets, i) end
    end
  end
end

local function updateUfo(dt)
  if ufo then
    ufo.x = ufo.x + ufo.vx * dt
    ufoSoundT = ufoSoundT - dt
    if ufoSoundT <= 0 then
      splay(SND.ufo)
      ufoSoundT = 0.24
    end
    if ufo.x > W + 10 or ufo.x + ufo.w < -10 then
      ufo = nil
    end
  else
    ufoTimer = ufoTimer - dt
    if ufoTimer <= 0 then
      ufo = UFO.new()
      ufoSoundT = 0
      ufoTimer = love.math.random(15, 30)
    end
  end
end

local function updateParticles(dt)
  for i = #particles, 1, -1 do
    local pt = particles[i]
    pt.t = pt.t - dt
    if pt.t <= 0 then
      table.remove(particles, i)
    else
      pt.x = pt.x + pt.vx * dt
      pt.y = pt.y + pt.vy * dt
    end
  end
end

------------------------------------------------------------------------------
-- love callbacks
------------------------------------------------------------------------------
function love.load()
  math.randomseed(os.time())
  highScore = 0
  initFonts()
  initSounds()
  shakeT, goTimer = 0, 0
  smokeT = smokeEnabled() and 10 or nil
  if smokeT then print("SMOKE: loaded, auto-playing for 10s") end
end

local function checkLevelClear()
  for _, v in ipairs(invaders) do
    if v.alive then return false end
  end
  clearJingleT = 2.2
  state = "levelclear"
  if SND.jingle1 then
    local i, t = 1, 0
    while i <= 4 and t < 2 do
      splay(SND["jingle" .. i], t)
      i, t = i + 1, t + 0.14
    end
  end
  return true
end

function love.update(dt)
  dt = math.min(dt, 1 / 30) -- avoid huge steps after a stall

  if shakeT > 0 then shakeT = math.max(0, shakeT - dt) end

  if state == "playing" then
    updatePlayer(dt)
    updateInvaders(dt)
    updateBullets(dt)
    updateUfo(dt)
    updateParticles(dt)

    -- game-over delay (let the final explosion play out)
    if goTimer > 0 then
      goTimer = goTimer - dt
      if goTimer <= 0 then
        highScore = math.max(highScore, score)
        state = "gameover"
      end
    elseif lives <= 0 and player and not player.alive then
      -- out of lives with nothing left to respawn into
      goTimer = 1.0
    else
      checkLevelClear()
    end
  elseif state == "levelclear" then
    updateParticles(dt)
    clearJingleT = clearJingleT - dt
    if clearJingleT <= 0 then
      startLevel(level + 1)
    end
  elseif state == "title" or state == "gameover" then
    updateParticles(dt)
  end

  -- smoke test: auto-play for a few seconds then exit cleanly
  if smokeT then
    smokeT = smokeT - dt
    if state == "title" and smokeT < 9 then newGame() end
    if smokeT <= 0 then
      local f = io.open("smoke_result.txt", "w")
      if f then
        f:write(string.format("SMOKE OK state=%s score=%d level=%d lives=%d\n",
          state, score or -1, level or -1, lives or -1))
        f:close()
      end
      love.event.quit(0)
    end
  end
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
    return
  end

  if key == "m" then
    muted = not muted
    return
  end

  if state == "playing" or state == "paused" then
    if key == "p" then
      state = (state == "paused") and "playing" or "paused"
    end
    return
  end

  -- title / gameover: start a fresh run
  if key == "space" or key == "return" then
    newGame()
  end
end

function love.mousepressed()
  -- allow starting with the mouse on the menus too
  if state == "title" or state == "gameover" then
    newGame()
  end
end

------------------------------------------------------------------------------
-- Rendering
------------------------------------------------------------------------------
local stars = {}
for i = 1, 70 do
  table.insert(stars, {
    x = love.math.random(W),
    y = love.math.random(HUD_TOP + 10, H - 30),
    s = love.math.random(1, 2),
    b = love.math.random(0.25, 0.8),
  })
end

local function drawStars(t)
  for _, st in ipairs(stars) do
    local tw = 0.6 + 0.4 * math.sin(t * 1.5 + st.x)
    love.graphics.setColor(COL.star[1] * st.b * tw, COL.star[2] * st.b * tw, COL.star[3] * st.b * tw, 1)
    love.graphics.rectangle("fill", st.x, st.y, st.s, st.s)
  end
end

local function text(str, x, y, size, color, align)
  local f = (size >= 40) and FONT_BIG or ((size >= 20) and FONT_MED or FONT_SMALL)
  love.graphics.setFont(f)
  love.graphics.setColor(color[1], color[2], color[3], 1)
  -- LÖVE 11's print has no align parameter, so center/right are computed manually
  local w = f:getWidth(str)
  if align == "center" then
    x = x - w / 2
  elseif align == "right" then
    x = x - w
  end
  love.graphics.print(str, math.floor(x), math.floor(y))
end

local function drawHUD()
  text("SCORE " .. string.format("%06d", score), 16, 10, 14, COL.text)
  text("HIGH  " .. string.format("%06d", math.max(highScore, score)), W / 2, 10, 14, COL.gold, "center")
  text("WAVE " .. level, W - 16, 10, 14, COL.text, "right")

  -- lives as little ship icons
  for i = 1, math.max(0, lives) do
    love.graphics.setColor(COL.player[1], COL.player[2], COL.player[3], 1)
    love.graphics.draw(SPR.player, 16 + (i - 1) * 26, 30, 0, 0.55, 0.55)
  end
  if muted then
    text("MUTED", W - 16, 30, 14, COL.dim, "right")
  end
end

local function drawScene(t)
  -- shields
  for _, bar in ipairs(barriers) do
    love.graphics.setColor(COL.barrier[1], COL.barrier[2], COL.barrier[3], 1)
    for r = 1, bar.rows do
      for c = 1, bar.cols do
        if bar.cells[r][c] then
          love.graphics.rectangle("fill",
            bar.x + (c - 1) * bar.cell, bar.y + (r - 1) * bar.cell, bar.cell, bar.cell)
        end
      end
    end
  end

  -- invaders (2-frame animation)
  for _, v in ipairs(invaders) do
    if v.alive then
      local frame = SPR[v.def.frames[marchFrame]]
      love.graphics.draw(frame, math.floor(v.x), math.floor(v.y))
    end
  end

  -- ufo
  if ufo then
    love.graphics.draw(SPR.ufo, math.floor(ufo.x), math.floor(ufo.y))
  end

  -- bullets
  for _, b in ipairs(pBullets) do
    love.graphics.setColor(COL.pbullet[1], COL.pbullet[2], COL.pbullet[3], 1)
    love.graphics.rectangle("fill", math.floor(b.x), math.floor(b.y), b.w, b.h)
  end
  for _, b in ipairs(eBullets) do
    local frame = SPR[(b.vy > 0 and "missileA" or "missileB")]
    love.graphics.draw(frame, math.floor(b.x - 1.5), math.floor(b.y))
  end

  -- player (blinks while invulnerable)
  local p = player
  if p.alive then
    local blink = p.invinc > 0 and (math.floor(t * 12) % 2 == 0)
    if not blink then
      love.graphics.draw(SPR.player, math.floor(p.x), math.floor(p.y))
    end
  end

  -- particles
  for _, pt in ipairs(particles) do
    local a = pt.t / pt.life
    love.graphics.setColor(pt.color[1], pt.color[2], pt.color[3], a)
    love.graphics.rectangle("fill", pt.x, pt.y, pt.size, pt.size)
  end

  drawHUD()
end

function love.draw()
  local t = love.timer.getTime() -- LÖVE 11's love.draw takes no arguments
  love.graphics.setBackgroundColor(COL.bg[1], COL.bg[2], COL.bg[3])
  drawStars(t)

  -- screen shake on player death
  if shakeT > 0 then
    local m = shakeT * 14
    love.graphics.translate(love.math.random(-m, m), love.math.random(-m, m))
  end

  if state == "playing" or state == "paused" or state == "levelclear" then
    drawScene(t)

    if state == "paused" then
      text("PAUSED", W / 2, H / 2 - 30, 42, COL.gold, "center")
      text("press P to resume", W / 2, H / 2 + 16, 14, COL.dim, "center")
    elseif state == "levelclear" then
      text("WAVE " .. level .. " CLEAR", W / 2, H / 2 - 30, 42, COL.barrier, "center")
      text("get ready...", W / 2, H / 2 + 16, 14, COL.dim, "center")
    end
  elseif state == "title" then
    text("SPACE INVADERS", W / 2, 130, 42, COL.player, "center")

    -- score table
    love.graphics.draw(SPR.squidA, W / 2 - 150, 216)
    text("= 40 PTS", W / 2 - 128, 220, 14, COL.squid)
    love.graphics.draw(SPR.ufo, W / 2 - 150, 248)
    text("= ??? PTS", W / 2 - 128, 252, 14, COL.ufo)

    text("ARROWS / A D  move      SPACE  fire", W / 2, 330, 14, COL.text, "center")
    text("P pause      M mute      ESC quit", W / 2, 354, 14, COL.dim, "center")

    if highScore > 0 then
      text("HIGH SCORE  " .. string.format("%06d", highScore), W / 2, 400, 14, COL.gold, "center")
    end

    if math.floor(t * 2) % 2 == 0 then
      text("PRESS SPACE TO START", W / 2, 470, 20, COL.gold, "center")
    end
  elseif state == "gameover" then
    text("GAME OVER", W / 2, 200, 42, COL.red, "center")
    text("SCORE  " .. string.format("%06d", score), W / 2, 300, 20, COL.text, "center")
    text("HIGH   " .. string.format("%06d", highScore), W / 2, 330, 20, COL.gold, "center")

    if math.floor(t * 2) % 2 == 0 then
      text("PRESS SPACE TO TRY AGAIN", W / 2, 430, 20, COL.gold, "center")
    end
  end

  love.graphics.origin()
end

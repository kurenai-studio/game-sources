-- Astro Drift — Love 2D
-- Twist: authentic 1979-Asteroids phosphor / vector-display look.
-- Every shape is drawn three times with additive blending and decreasing
-- line widths to simulate CRT phosphor glow, plus a fragment shader for
-- scanlines and a barrel-distortion vignette. Asteroids split on hit.

local W, H = 960, 540
local THRUST, ROT_SPEED, DRAG_PER_SEC, MAX_SPEED = 350, 4, 0.55, 480
local BULLET_SPEED, BULLET_LIFE, SHOOT_COOLDOWN = 700, 1.0, 0.18
local ASTEROID_RADII = { 12, 22, 40 }
local SIZE_LARGE, SIZE_MEDIUM, SIZE_SMALL = 3, 2, 1

local ship = { x = W / 2, y = H / 2, vx = 0, vy = 0, rot = 0 }
local bullets, asteroids, stars = {}, {}, {}
local cooldown = 0
local score, wave, lives = 0, 1, 3
local game_over = false
local crt_canvas, crt_shader
local flicker = 0

local CRT_SOURCE = [[
extern number scanline = 0.35;
extern number vignette_strength = 0.45;
extern vec2 resolution;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    vec4 c = Texel(tex, uv);
    float scan = sin(uv.y * resolution.y * 1.5) * 0.5 + 0.5;
    c.rgb *= 1.0 - scanline * (1.0 - scan) * 0.6;
    vec2 vuv = uv * (1.0 - uv);
    float vig = clamp(vuv.x * vuv.y * 16.0, 0.0, 1.0);
    c.rgb *= mix(1.0, pow(vig, 0.35), vignette_strength);
    return c * color;
}
]]

local function len(x, y) return math.sqrt(x * x + y * y) end

local function wrap(o, w, h, pad)
	pad = pad or 20
	if o.x < -pad then o.x = w + pad end
	if o.x > w + pad then o.x = -pad end
	if o.y < -pad then o.y = h + pad end
	if o.y > h + pad then o.y = -pad end
end

local function make_asteroid_shape(r)
	local pts, n = {}, 11
	for i = 0, n - 1 do
		local a = (i / n) * math.pi * 2
		local rr = r * (0.75 + math.random() * 0.35)
		pts[#pts + 1] = math.cos(a) * rr
		pts[#pts + 1] = math.sin(a) * rr
	end
	return pts
end

local function spawn_asteroid(size, x, y)
	local r = ASTEROID_RADII[size]
	if not x then
		local edge = math.random(4)
		if edge == 1 then x, y = math.random() * W, -40
		elseif edge == 2 then x, y = W + 40, math.random() * H
		elseif edge == 3 then x, y = math.random() * W, H + 40
		else x, y = -40, math.random() * H end
	end
	local ang = math.random() * math.pi * 2
	local sp = 70 + math.random() * 90
	asteroids[#asteroids + 1] = {
		x = x, y = y,
		vx = math.cos(ang) * sp, vy = math.sin(ang) * sp,
		rot = 0, spin = (math.random() - 0.5) * 4,
		r = r, size = size, shape = make_asteroid_shape(r),
	}
end

local function spawn_wave()
	asteroids = {}
	for _ = 1, 3 + wave do spawn_asteroid(SIZE_LARGE) end
end

local function reset_game()
	score, wave, lives = 0, 1, 3
	game_over = false
	bullets = {}
	ship.x, ship.y, ship.vx, ship.vy, ship.rot = W / 2, H / 2, 0, 0, 0
	spawn_wave()
end

function love.load()
	love.window.setTitle("Astro Drift — Love 2D (phosphor)")
	love.graphics.setBackgroundColor(0.02, 0.025, 0.05)
	math.randomseed(os.time())
	for i = 1, 80 do
		stars[i] = { x = math.random() * W, y = math.random() * H, b = 0.3 + math.random() * 0.7 }
	end
	crt_canvas = love.graphics.newCanvas(W, H)
	crt_shader = love.graphics.newShader(CRT_SOURCE)
	crt_shader:send("resolution", { W, H })
	spawn_wave()
end

local function hit_asteroid(idx)
	local a = asteroids[idx]
	local size_score = { [SIZE_LARGE] = 20, [SIZE_MEDIUM] = 50, [SIZE_SMALL] = 100 }
	score = score + (size_score[a.size] or 0)
	if a.size > SIZE_SMALL then
		for _ = 1, 2 do spawn_asteroid(a.size - 1, a.x, a.y) end
	end
	table.remove(asteroids, idx)
end

function love.update(dt)
	flicker = flicker + dt * 50

	if not game_over then
		if love.keyboard.isDown("left") then ship.rot = ship.rot - ROT_SPEED * dt end
		if love.keyboard.isDown("right") then ship.rot = ship.rot + ROT_SPEED * dt end

		local thrusting = love.keyboard.isDown("up")
		local braking = love.keyboard.isDown("down")
		if thrusting then
			ship.vx = ship.vx + math.cos(ship.rot - math.pi / 2) * THRUST * dt
			ship.vy = ship.vy + math.sin(ship.rot - math.pi / 2) * THRUST * dt
		end
		local damp = (braking and 0.08 or DRAG_PER_SEC) ^ dt
		ship.vx, ship.vy = ship.vx * damp, ship.vy * damp
		local sp = len(ship.vx, ship.vy)
		if sp > MAX_SPEED then
			ship.vx, ship.vy = ship.vx / sp * MAX_SPEED, ship.vy / sp * MAX_SPEED
		end
		ship.x, ship.y = ship.x + ship.vx * dt, ship.y + ship.vy * dt
		wrap(ship, W, H)

		cooldown = cooldown - dt
		if love.keyboard.isDown("delete") and cooldown <= 0 then
			cooldown = SHOOT_COOLDOWN
			local dx, dy = math.cos(ship.rot - math.pi / 2), math.sin(ship.rot - math.pi / 2)
			bullets[#bullets + 1] = {
				x = ship.x + dx * 18, y = ship.y + dy * 18,
				vx = dx * BULLET_SPEED, vy = dy * BULLET_SPEED, life = BULLET_LIFE,
			}
		end
	end

	for i = #bullets, 1, -1 do
		local b = bullets[i]
		b.x, b.y = b.x + b.vx * dt, b.y + b.vy * dt
		b.life = b.life - dt
		wrap(b, W, H, 4)
		if b.life <= 0 then table.remove(bullets, i) end
	end

	for i = #asteroids, 1, -1 do
		local a = asteroids[i]
		a.x, a.y = a.x + a.vx * dt, a.y + a.vy * dt
		a.rot = a.rot + a.spin * dt
		wrap(a, W, H, a.r + 10)
	end

	for bi = #bullets, 1, -1 do
		local b = bullets[bi]
		for ai = #asteroids, 1, -1 do
			local a = asteroids[ai]
			if len(b.x - a.x, b.y - a.y) < a.r then
				table.remove(bullets, bi)
				hit_asteroid(ai)
				break
			end
		end
	end

	if not game_over then
		for _, a in ipairs(asteroids) do
			if len(ship.x - a.x, ship.y - a.y) < a.r + 10 then
				lives = lives - 1
				ship.x, ship.y, ship.vx, ship.vy = W / 2, H / 2, 0, 0
				if lives <= 0 then game_over = true end
				break
			end
		end
	end

	if #asteroids == 0 and not game_over then
		wave = wave + 1
		spawn_wave()
	end
end

local function with_phosphor(color, draw_fn)
	love.graphics.setBlendMode("add")
	love.graphics.setColor(color[1], color[2], color[3], 0.12)
	love.graphics.setLineWidth(8)
	draw_fn()
	love.graphics.setColor(color[1], color[2], color[3], 0.25)
	love.graphics.setLineWidth(4)
	draw_fn()
	love.graphics.setBlendMode("alpha")
	local flick = 0.92 + 0.08 * math.sin(flicker)
	love.graphics.setColor(color[1] * flick, color[2] * flick, color[3] * flick, 1.0)
	love.graphics.setLineWidth(1.4)
	draw_fn()
end

local function draw_polyline_loop(pts)
	local closed = { unpack(pts) }
	closed[#closed + 1] = pts[1]
	closed[#closed + 1] = pts[2]
	love.graphics.line(closed)
end

local function draw_ship_glow()
	love.graphics.push()
	love.graphics.translate(ship.x, ship.y)
	love.graphics.rotate(ship.rot)
	with_phosphor({ 0.85, 0.95, 1.0 }, function()
		draw_polyline_loop({ 0, -14, 10, 12, 0, 6, -10, 12 })
	end)
	if love.keyboard.isDown("up") then
		with_phosphor({ 1.0, 0.55, 0.15 }, function()
			love.graphics.line(-5, 8, 0, 18 + math.random() * 6, 5, 8)
		end)
	end
	love.graphics.pop()
end

function love.draw()
	love.graphics.setCanvas(crt_canvas)
	love.graphics.clear(0.02, 0.025, 0.05)
	for _, s in ipairs(stars) do
		love.graphics.setColor(s.b, s.b, s.b * 1.05)
		love.graphics.points(s.x, s.y)
	end
	for _, a in ipairs(asteroids) do
		love.graphics.push()
		love.graphics.translate(a.x, a.y)
		love.graphics.rotate(a.rot)
		with_phosphor({ 0.85, 0.8, 0.7 }, function()
			draw_polyline_loop(a.shape)
		end)
		love.graphics.pop()
	end
	for _, b in ipairs(bullets) do
		with_phosphor({ 1.0, 0.95, 0.55 }, function()
			love.graphics.circle("line", b.x, b.y, 3)
		end)
	end
	if not game_over then draw_ship_glow() end

	love.graphics.setColor(0.85, 0.9, 1.0)
	love.graphics.print(string.format("Score %d   Wave %d   Lives %d", score, wave, lives), 12, 12)
	if game_over then
		love.graphics.setColor(1, 0.9, 0.6)
		love.graphics.printf("GAME OVER — press End to restart", 0, H / 2 - 14, W, "center")
	end

	love.graphics.setColor(0.62, 0.7, 0.85)
	love.graphics.printf(
		"← → rotate   |   ↑ thrust   |   ↓ brake   |   Del fire   |   End restart   |   Esc quit",
		0, H - 22, W, "center")

	love.graphics.setCanvas()
	love.graphics.setColor(1, 1, 1)
	love.graphics.setShader(crt_shader)
	love.graphics.draw(crt_canvas)
	love.graphics.setShader()
end

function love.keypressed(k)
	if k == "escape" then love.event.quit() end
	if k == "end" and game_over then reset_game() end
end

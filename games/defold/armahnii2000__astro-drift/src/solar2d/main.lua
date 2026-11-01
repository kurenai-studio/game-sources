-- Astro Drift — Solar 2D / Corona SDK
-- Drifting-ship demo. Drop into the Solar 2D Simulator (CoronaSimulator) and run.

local W = display.contentWidth
local H = display.contentHeight

display.setDefault("background", 0.04, 0.05, 0.09)

local THRUST = 350
local ROT_SPEED = 4
local DRAG_PER_SEC = 0.55
local MAX_SPEED = 480

local stars = display.newGroup()
for i = 1, 80 do
	local b = 0.3 + math.random() * 0.7
	local s = display.newRect(stars, math.random() * W, math.random() * H, 2, 2)
	s:setFillColor(b)
end

local ship = display.newPolygon(W / 2, H / 2, { 0, -14, 10, 12, 0, 6, -10, 12 })
ship:setFillColor(0.9, 0.95, 1.0)
ship.strokeWidth = 1.5
ship:setStrokeColor(0.55, 0.75, 1.0)

local hud = display.newText({
	text = "Astro Drift — Solar 2D",
	x = W / 2, y = 18, font = native.systemFontBold, fontSize = 14,
})
hud:setFillColor(0.85, 0.9, 1.0)

local controls = display.newText({
	text = "← → rotate  |  ↑ thrust  |  ↓ brake  |  Del fire  |  Esc quit",
	x = W / 2, y = H - 14, font = native.systemFont, fontSize = 12,
})
controls:setFillColor(0.62, 0.7, 0.85)

local state = { vx = 0, vy = 0, heading = 0, cooldown = 0 }
local keys = {}
local bullets = {}

Runtime:addEventListener("key", function(e)
	keys[e.keyName] = (e.phase == "down")
	if e.keyName == "escape" and e.phase == "down" then native.requestExit() end
	return false
end)

local function wrap(o, w, h)
	if o.x < 0 then o.x = o.x + w end
	if o.x > w then o.x = o.x - w end
	if o.y < 0 then o.y = o.y + h end
	if o.y > h then o.y = o.y - h end
end

local function fire()
	local dx = math.cos(state.heading - math.pi / 2)
	local dy = math.sin(state.heading - math.pi / 2)
	local b = display.newCircle(ship.x + dx * 18, ship.y + dy * 18, 3)
	b:setFillColor(1.0, 0.95, 0.55)
	b.vx, b.vy, b.life = dx * 700, dy * 700, 1.0
	table.insert(bullets, b)
end

Runtime:addEventListener("enterFrame", function()
	local dt = 1 / 60

	if keys.left then state.heading = state.heading - ROT_SPEED * dt end
	if keys.right then state.heading = state.heading + ROT_SPEED * dt end
	if keys.up then
		state.vx = state.vx + math.cos(state.heading - math.pi / 2) * THRUST * dt
		state.vy = state.vy + math.sin(state.heading - math.pi / 2) * THRUST * dt
	end

	local damping = (keys.down and 0.08 or DRAG_PER_SEC) ^ dt
	state.vx, state.vy = state.vx * damping, state.vy * damping
	local sp = math.sqrt(state.vx * state.vx + state.vy * state.vy)
	if sp > MAX_SPEED then
		state.vx, state.vy = state.vx / sp * MAX_SPEED, state.vy / sp * MAX_SPEED
	end
	ship.x = ship.x + state.vx * dt
	ship.y = ship.y + state.vy * dt
	wrap(ship, W, H)
	ship.rotation = math.deg(state.heading)

	state.cooldown = state.cooldown - dt
	if keys.deleteForward and state.cooldown <= 0 then
		state.cooldown = 0.18
		fire()
	end

	for i = #bullets, 1, -1 do
		local b = bullets[i]
		b.x = b.x + b.vx * dt
		b.y = b.y + b.vy * dt
		b.life = b.life - dt
		wrap(b, W, H)
		if b.life <= 0 then
			b:removeSelf()
			table.remove(bullets, i)
		end
	end
end)

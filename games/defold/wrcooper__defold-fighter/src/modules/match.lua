-- Match simulation: two fighters, projectiles, hit resolution and round flow.
-- Pure Lua. The fight script feeds it inputs once per 60 Hz frame and turns
-- the resulting state and the queued events into sprites, sounds and HUD.
local config = require "modules.config"
local characters = require "modules.characters"
local Fighter = require "modules.fighter"

local M = {}
M.__index = M

local INTRO_FRAMES = 100
local KO_WAIT = 110
local WIN_POSE = 200

local function overlap(a, b)
	return a[1] < b[3] and b[1] < a[3] and a[2] < b[4] and b[2] < a[4]
end

function M.new(p1_char, p2_char)
	local self = setmetatable({}, M)
	self.fighters = { Fighter.new(p1_char, 1), Fighter.new(p2_char, 2) }
	self.round = 1
	self.frame = 0
	self.events = {}
	self.next_projectile_id = 1
	self:start_round()
	return self
end

function M:event(e)
	self.events[#self.events + 1] = e
end

function M:pop_events()
	local ev = self.events
	self.events = {}
	return ev
end

function M:start_round()
	local f1, f2 = self.fighters[1], self.fighters[2]
	f1:reset(config.START_X[1], 1)
	f2:reset(config.START_X[2], -1)
	self.projectiles = {}
	self.phase = "intro"
	self.phase_t = 0
	self.timer = config.ROUND_TIME * 60
	self.hitstop = 0
	self.slowmo = 0
	self.round_winner = nil
	self:event({ type = "round_start", round = self.round })
end

function M:seconds_left()
	return math.ceil(self.timer / 60)
end

function M:has_projectile(index)
	for _, p in ipairs(self.projectiles) do
		if p.owner == index then return true end
	end
	return false
end

function M:spawn_projectile(f, data)
	local p = {
		id = self.next_projectile_id,
		owner = f.index,
		data = data,
		dir = f.facing,
		x = f.x + data.x * f.facing,
		y = f.y + data.y,
		t = 0,
	}
	self.next_projectile_id = self.next_projectile_id + 1
	self.projectiles[#self.projectiles + 1] = p
	self:event({ type = "projectile_spawn", projectile = p })
end

function M:projectile_box(p)
	local d = p.data
	return { p.x - d.w / 2, p.y - d.h / 2, p.x + d.w / 2, p.y + d.h / 2 }
end

-- ---------------------------------------------------------------------------
-- frame step
-- ---------------------------------------------------------------------------

function M:step(inputs)
	self.frame = self.frame + 1
	if self.hitstop > 0 then
		self.hitstop = self.hitstop - 1
		-- buttons pressed during hitstop still go into the buffer (for cancels)
		if self.phase == "fight" then
			for i, f in ipairs(self.fighters) do
				for b in pairs(f.buffer) do
					if inputs[i][b] then f.buffer[b] = config.INPUT_BUFFER end
				end
			end
		end
		return
	end
	if self.slowmo > 0 then self.slowmo = self.slowmo - 1 end
	self.phase_t = self.phase_t + 1

	local f1, f2 = self.fighters[1], self.fighters[2]
	local live = self.phase == "fight"
	local i1 = live and inputs[1] or Fighter.NO_INPUT
	local i2 = live and inputs[2] or Fighter.NO_INPUT

	f1.threat = self:is_threatened(f1, f2)
	f2.threat = self:is_threatened(f2, f1)
	f1:step(i1, f2, self)
	f2:step(i2, f1, self)
	self:resolve_push()
	if live then
		self:resolve_hits()
	end
	self:step_projectiles(live)
	self:step_phase()
end

function M:is_threatened(f, opp)
	if opp.state == "attack" and math.abs(opp.x - f.x) < 320 then return true end
	for _, p in ipairs(self.projectiles) do
		if p.owner ~= f.index and math.abs(p.x - f.x) < 360 and (f.x - p.x) * p.dir > 0 then
			return true
		end
	end
	return false
end

function M:resolve_push()
	local a, b = self.fighters[1], self.fighters[2]
	local hw = config.PUSH_HALF_WIDTH
	local left, right = config.STAGE_LEFT, config.STAGE_RIGHT

	-- pushback into a wall moves the attacker away instead
	for i, f in ipairs(self.fighters) do
		local other = self.fighters[3 - i]
		if (f.state == "hitstun" or f.state == "blockstun") and f.push ~= 0 then
			if (f.x <= left and f.push < 0) or (f.x >= right and f.push > 0) then
				other.x = other.x - f.push
			end
		end
	end

	local function separate()
		if a.y >= b.y + config.PUSH_HEIGHT or b.y >= a.y + config.PUSH_HEIGHT then return end
		local dx = b.x - a.x
		local amount = 2 * hw - math.abs(dx)
		if amount <= 0 then return end
		local dir = dx > 0 and 1 or (dx < 0 and -1 or a.facing)
		local a_wall = (dir > 0 and a.x <= left) or (dir < 0 and a.x >= right)
		local b_wall = (dir > 0 and b.x >= right) or (dir < 0 and b.x <= left)
		if a_wall and not b_wall then
			b.x = b.x + dir * amount
		elseif b_wall and not a_wall then
			a.x = a.x - dir * amount
		else
			a.x = a.x - dir * amount / 2
			b.x = b.x + dir * amount / 2
		end
	end

	separate()
	for _, f in ipairs(self.fighters) do
		f.x = math.max(left, math.min(right, f.x))
	end
	separate()
	for _, f in ipairs(self.fighters) do
		f.x = math.max(left, math.min(right, f.x))
	end
end

function M:apply_hit(att, def, h, from_x, hx, hy)
	local blocked = def:can_block(h.height, from_x)
	local dir = from_x <= def.x and 1 or -1
	local dmg = def:take_hit(h, dir, blocked)
	if blocked then
		self.hitstop = math.max(self.hitstop, config.HITSTOP_BLOCK)
		self:event({ type = "spark", kind = "block", x = hx, y = hy })
		self:event({ type = "sfx", name = "block" })
	else
		self.hitstop = math.max(self.hitstop, h.heavy and config.HITSTOP_HEAVY or config.HITSTOP_LIGHT)
		self:event({ type = "spark", kind = "hit", x = hx, y = hy })
		self:event({ type = "sfx", name = h.sfx or "hit_light" })
		self:event({ type = "flash", index = def.index })
		self:event({ type = "shake", amount = h.heavy and 6 or 3 })
		if def.combo >= 2 then
			self:event({ type = "combo", index = att.index, hits = def.combo })
		end
	end
	self:event({ type = "damage", index = def.index, amount = dmg, blocked = blocked, source = h.id or "fireball" })
	return blocked
end

function M:resolve_hits()
	local pending = {}
	for i, att in ipairs(self.fighters) do
		local def = self.fighters[3 - i]
		local hb = att:hitbox()
		if hb and not def:is_invulnerable() then
			local hu = def:hurtbox()
			if overlap(hb, hu) then
				local hx = (math.max(hb[1], hu[1]) + math.min(hb[3], hu[3])) / 2
				local hy = (math.max(hb[2], hu[2]) + math.min(hb[4], hu[4])) / 2
				pending[#pending + 1] = { att, def, hx, hy, att.move }
			end
		end
	end
	-- apply after detection so simultaneous hits trade
	for _, p in ipairs(pending) do
		local att, def = p[1], p[2]
		att.has_hit = true
		att.move_stopped = true
		local blocked = self:apply_hit(att, def, p[5], att.x, p[3], p[4])
		att.hit_confirm = not blocked
	end
end

function M:step_projectiles(live)
	local alive = {}
	for _, p in ipairs(self.projectiles) do
		p.x = p.x + p.data.speed * p.dir
		p.t = p.t + 1
		alive[#alive + 1] = p
	end

	-- projectile vs projectile
	for i = 1, #alive do
		for j = i + 1, #alive do
			local a, b = alive[i], alive[j]
			if a.owner ~= b.owner and not a.dead and not b.dead and
				overlap(self:projectile_box(a), self:projectile_box(b)) then
				a.dead, b.dead = true, true
				self:event({ type = "spark", kind = "block", x = (a.x + b.x) / 2, y = a.y })
				self:event({ type = "sfx", name = "block" })
			end
		end
	end

	-- projectile vs fighter
	for _, p in ipairs(alive) do
		local def = self.fighters[3 - p.owner]
		if live and not p.dead and not def:is_invulnerable() and
			overlap(self:projectile_box(p), def:hurtbox()) then
			p.dead = true
			local att = self.fighters[p.owner]
			local blocked = self:apply_hit(att, def, p.data, p.x - p.dir * 40, p.x + p.dir * 20, p.y)
			if not blocked then att.hit_confirm = true end
		end
		if p.x < -120 or p.x > config.WIDTH + 120 or not live and self.phase ~= "intro" then
			p.dead = true
		end
	end

	local kept = {}
	for _, p in ipairs(alive) do
		if p.dead then
			self:event({ type = "projectile_end", projectile = p })
		else
			kept[#kept + 1] = p
		end
	end
	self.projectiles = kept
end

-- ---------------------------------------------------------------------------
-- round flow
-- ---------------------------------------------------------------------------

function M:step_phase()
	local f1, f2 = self.fighters[1], self.fighters[2]
	local t = self.phase_t
	if self.phase == "intro" then
		if t == 1 then
			self:event({ type = "announce", text = "ROUND " .. self.round, frames = 70 })
		elseif t == 70 then
			self:event({ type = "announce", text = "FIGHT!", frames = 40 })
			self:event({ type = "sfx", name = "fight" })
		elseif t >= INTRO_FRAMES then
			self.phase = "fight"
			self.phase_t = 0
		end
	elseif self.phase == "fight" then
		self.timer = self.timer - 1
		if f1.health <= 0 or f2.health <= 0 then
			self.phase = "ko"
			self.phase_t = 0
			self.slowmo = 50
			self:event({ type = "announce", text = "K.O.", frames = 100 })
			self:event({ type = "sfx", name = "ko" })
		elseif self.timer <= 0 then
			self.timer = 0
			self.phase = "ko"
			self.phase_t = 0
			self:event({ type = "announce", text = "TIME", frames = 100 })
		end
	elseif self.phase == "ko" then
		if t == KO_WAIT then
			local winner
			if f1.health > f2.health then winner = 1 elseif f2.health > f1.health then winner = 2 end
			self.round_winner = winner or 0
			if winner then
				local w = self.fighters[winner]
				w.wins = w.wins + 1
				self:event({ type = "announce", text = w.c.name .. " WINS", frames = 90 })
				self:event({ type = "round_won", index = winner })
			else
				self:event({ type = "announce", text = "DRAW", frames = 90 })
			end
		end
		-- winner strikes a pose once they are back on their feet
		if self.round_winner and self.round_winner > 0 then
			local w = self.fighters[self.round_winner]
			if w.state == "stand" or w.state == "crouch" then w:set_win() end
		end
		if t >= WIN_POSE then
			local need = config.ROUNDS_TO_WIN
			if f1.wins >= need or f2.wins >= need then
				self.phase = "match_over"
				self.phase_t = 0
				self.winner = f1.wins >= need and 1 or 2
				self:event({ type = "match_over", winner = self.winner })
			else
				self.round = self.round + 1
				self:start_round()
			end
		end
	end
end

return M

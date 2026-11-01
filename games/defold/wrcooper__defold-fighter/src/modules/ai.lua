-- CPU opponent. Produces the same input table a human produces.
--
-- The AI "sees" the opponent through a reaction delay: it records a snapshot
-- of the opponent every frame and makes decisions from the snapshot that is
-- `reaction` frames old. Each decision (block this attack, anti-air this
-- jump, punish this whiff) is rolled once per opponent action using the
-- difficulty's probabilities, then committed to, so the AI doesn't jitter.
-- Between reactions it follows short "plans" (walk in, poke, throw a
-- fireball, jump in...) weighted by distance and character personality.
local characters = require "modules.characters"

local M = {}
M.__index = M

M.LEVELS = {
	easy = {
		reaction = 24, block = 0.25, low_read = 0.3, antiair = 0.15, punish = 0.2,
		projectile = 0.3, combo = 0.0, aggression = 0.35, think = { 24, 50 }, poke_wait = { 20, 45 },
	},
	normal = {
		reaction = 14, block = 0.6, low_read = 0.6, antiair = 0.45, punish = 0.5,
		projectile = 0.6, combo = 0.4, aggression = 0.5, think = { 14, 34 }, poke_wait = { 8, 26 },
	},
	hard = {
		reaction = 8, block = 0.88, low_read = 0.9, antiair = 0.8, punish = 0.85,
		projectile = 0.85, combo = 0.85, aggression = 0.6, think = { 8, 22 }, poke_wait = { 3, 14 },
	},
}

-- Per-character play style. Weights feed the neutral plan picker.
local STYLE = {
	kenji = { zoner = true, aa_move = "kick", aa_range = 150 },
	vera = { rushdown = true, aa_move = "special", aa_range = 230 },
}

local OPP_HALF_WIDTH = 27

local function chance(p)
	return math.random() < p
end

local function rand_range(r)
	return math.random(r[1], r[2])
end

local function pick(weights)
	local total = 0
	for _, w in ipairs(weights) do total = total + w[2] end
	local r = math.random() * total
	for _, w in ipairs(weights) do
		r = r - w[2]
		if r <= 0 then return w[1] end
	end
	return weights[#weights][1]
end

function M.new(index, level)
	local self = setmetatable({}, M)
	self.index = index
	self.level = level
	self.p = M.LEVELS[level] or M.LEVELS.normal
	self.history = {}
	self.frame = 0
	self.plan = nil
	self.guard_t = 0
	self.guard_low = false
	self.seen = {}        -- decisions already rolled, keyed by "<kind><serial>"
	self.aa_pending = false
	self.cancel_serial = nil
	return self
end

-- what we remember about the opponent each frame
local function snapshot(f, match)
	local s = {
		x = f.x, y = f.y, vx = f.vx, vy = f.vy,
		state = f.state, serial = f.serial, jump_serial = f.jump_serial,
		move = f.state == "attack" and f.move or nil,
		phase = f:move_phase(),
		kd_phase = f.kd_phase,
		projectiles = {},
	}
	for _, p in ipairs(match.projectiles) do
		if p.owner == f.index then
			s.projectiles[#s.projectiles + 1] = { id = p.id, x = p.x, dir = p.dir, speed = p.data.speed }
		end
	end
	return s
end

function M:perceive(opp, match)
	self.frame = self.frame + 1
	self.history[self.frame] = snapshot(opp, match)
	self.history[self.frame - 90] = nil
	local delay = self.p.reaction + math.random(0, 3)
	local k = math.max(1, self.frame - delay)
	while not self.history[k] do k = k + 1 end
	return self.history[k]
end

function M:once(key)
	if self.seen[key] then return false end
	self.seen[key] = true
	return true
end

-- effective distance at which a move connects against the opponent's center
local function reach(me, id)
	local m = me.c.moves[id]
	return m.reach + OPP_HALF_WIDTH - 6
end

function M:update(match)
	local me = match.fighters[self.index]
	local opp = match.fighters[3 - self.index]
	local o = self:perceive(opp, match)
	local p = self.p
	local style = STYLE[me.char_id]

	local inp = {}
	local toward = o.x >= me.x and "right" or "left"
	local away = toward == "right" and "left" or "right"
	local dist = math.abs(o.x - me.x)

	if match.phase ~= "fight" then
		self.plan = nil
		return inp
	end

	-- combo: cancel a connected punch into the special
	if me.state == "attack" and me.move.cancel and me.hit_confirm and self.cancel_serial ~= me.serial then
		self.cancel_serial = me.serial
		if chance(p.combo) and not (me.c.moves.special.projectile and match:has_projectile(me.index)) then
			inp.special = true
		end
		return inp
	end

	-- keep guarding through block strings
	if me.state == "blockstun" then
		if chance(p.block) or self.guard_t > 0 then
			inp[away] = true
			inp.down = self.guard_low or nil
		end
		return inp
	end

	if me.state == "jump" or (me.state == "attack" and me.move.air) then
		-- jump-in: kick on the way down when close
		if me.state == "jump" and self.plan and self.plan.jump_attack and me.vy < 2 and dist < 190 then
			inp.kick = true
			self.plan.jump_attack = false
		end
		return inp
	end

	if not me:is_neutral() then
		return inp
	end

	-- ---------------------------------------------------------------- defense
	if o.move and (o.phase == "startup" or o.phase == "active") and self:once("atk" .. o.serial) then
		local threat_range = o.move.reach + o.move.travel + 70
		if dist < threat_range then
			if chance(p.block) then
				local h = o.move.height
				local low = me.state == "crouch"
				if h == "low" then
					low = chance(p.low_read)
				elseif h == "high" then
					low = not chance(p.low_read) and low
				end
				self.guard_t = o.move.total + 6
				self.guard_low = low
				self.plan = nil
			end
		end
	end

	-- fireballs heading our way
	for _, pr in ipairs(o.projectiles) do
		local pd = math.abs(pr.x - me.x)
		if (me.x - pr.x) * pr.dir > 0 and pd < 420 and self:once("proj" .. pr.id) then
			if chance(p.projectile) then
				local choice
				if me.char_id == "vera" and dist < 300 and chance(0.5) then
					choice = "special"          -- comet knee is invulnerable on startup
				elseif me.char_id == "kenji" and not match:has_projectile(me.index) and chance(0.5) then
					choice = "special"          -- cancel it out with our own
				elseif pd > 140 and pd < 340 then
					choice = "jump"
				else
					choice = "guard"
				end
				if choice == "special" then
					inp.special = true
					return inp
				elseif choice == "jump" then
					inp.up = true
					inp[toward] = true
					self.plan = { kind = "jump", t = 1, jump_attack = chance(p.aggression) }
					return inp
				else
					self.guard_t = math.ceil(pd / pr.speed) + 6
					self.guard_low = false
				end
			end
		end
	end

	if self.guard_t > 0 then
		self.guard_t = self.guard_t - 1
		inp[away] = true
		inp.down = self.guard_low or nil
		return inp
	end

	-- --------------------------------------------------------------- anti-air
	if o.y > 0 and o.state == "jump" or (o.y > 0 and o.move and o.move.air) then
		local coming = (me.x - o.x) * o.vx > 0 or dist < 120
		if coming and dist < 340 and self:once("jmp" .. o.jump_serial) then
			if chance(p.antiair) then
				self.aa_pending = true
			elseif chance(p.block) then
				self.guard_t = 36
				self.guard_low = false
			end
		end
		if self.aa_pending and o.vy < 4 and dist < style.aa_range then
			self.aa_pending = false
			inp[style.aa_move] = true
			return inp
		end
	else
		self.aa_pending = false
	end

	-- ----------------------------------------------------------------- punish
	local vulnerable = (o.move and o.phase == "recovery") or o.state == "land"
		or (o.state == "knockdown" and o.kd_phase == "rise")
	if vulnerable and self:once("pun" .. o.serial .. o.state .. (o.kd_phase or "")) and chance(p.punish) then
		local move
		if dist < reach(me, "punch") then
			move = "punch"
		elseif dist < reach(me, "kick") then
			move = "kick"
		elseif dist < reach(me, "sweep") then
			move = "sweep"
		elseif me.char_id == "vera" and dist < 250 then
			move = "special"
		end
		if move then
			return self:press(inp, move)
		end
	end

	-- ---------------------------------------------------------------- neutral
	if not self.plan or self.plan.t <= 0 then
		self:choose_plan(me, match, dist)
	end
	return self:run_plan(inp, me, match, dist, toward, away)
end

function M:press(inp, move)
	if move == "punch" then
		inp.punch = true
	elseif move == "kick" then
		inp.kick = true
	elseif move == "cpunch" then
		inp.punch, inp.down = true, true
	elseif move == "sweep" then
		inp.kick, inp.down = true, true
	elseif move == "special" then
		inp.special = true
	end
	return inp
end

function M:choose_plan(me, match, dist)
	local p = self.p
	local style = STYLE[me.char_id]
	local agg = p.aggression
	local cornered = me.x < 150 or me.x > 1130
	local can_fireball = style.zoner and not match:has_projectile(me.index)
	local think = rand_range(p.think)
	local kind

	if dist > 480 then
		kind = pick({
			{ "fireball", can_fireball and 4 or 0 },
			{ "advance", style.rushdown and 6 or 3 },
			{ "jump_in", style.rushdown and 1.5 or 0.5 },
			{ "wait", 1.5 },
		})
	elseif dist > 210 then
		kind = pick({
			{ "fireball", can_fireball and 3 or 0 },
			{ "advance", 2 + agg * 3 },
			{ "jump_in", (style.rushdown and 1.5 or 0.8) * agg * 2 },
			{ "comet", (me.char_id == "vera" and dist < 270) and agg * 1.5 or 0 },
			{ "retreat", style.zoner and 1.5 or 0.6 },
			{ "wait", 1.2 },
			{ "crouch_wait", 0.6 },
		})
	else
		kind = pick({
			{ "poke", 2 + agg * 4 },
			{ "low", 1 + agg * 2 },
			{ "sweep", 0.6 + agg },
			{ "jump_away", cornered and 1.5 or 0.2 },
			{ "jump_in", cornered and 1 or 0.3 },
			{ "retreat", style.zoner and 1.5 or 0.6 },
			{ "crouch_wait", 1.2 * (1 - agg) + 0.4 },
			{ "wait", 0.8 },
		})
	end

	local plan = { kind = kind, t = think }
	if kind == "poke" then
		plan.move = chance(0.55) and "punch" or "kick"
		plan.t = 40
	elseif kind == "low" then
		plan.move = "cpunch"
		plan.t = 40
	elseif kind == "sweep" then
		plan.move = "sweep"
		plan.t = 40
	elseif kind == "comet" then
		plan.move = "special"
		plan.t = 1
	elseif kind == "fireball" then
		plan.move = "special"
		plan.t = 1
	elseif kind == "jump_in" then
		plan.t = 1
		plan.jump_attack = chance(0.5 + agg * 0.5)
	elseif kind == "jump_away" then
		plan.t = 1
	elseif kind == "crouch_wait" then
		plan.guard = chance(p.block)
	end
	self.plan = plan
end

function M:run_plan(inp, me, match, dist, toward, away)
	local plan = self.plan
	plan.t = plan.t - 1
	local k = plan.kind
	if k == "advance" then
		inp[toward] = true
	elseif k == "retreat" then
		inp[away] = true
	elseif k == "crouch_wait" then
		inp.down = true
		if plan.guard then inp[away] = true end
	elseif k == "jump_in" then
		inp.up = true
		inp[toward] = true
		plan.kind = "jump"
	elseif k == "jump_away" then
		inp.up = true
		inp[away] = true
		plan.kind = "jump"
	elseif plan.move then
		-- walk into range, then attack
		local r = plan.move == "special" and 2000 or reach(me, plan.move)
		if dist > r then
			inp[toward] = true
		else
			self:press(inp, plan.move)
			self.plan = { kind = "wait", t = rand_range(self.p.poke_wait) }
		end
	end
	return inp
end

return M

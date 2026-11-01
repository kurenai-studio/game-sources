-- One fighter's state machine. Pure Lua: no Defold API calls, so the whole
-- simulation can run headless (see tests/sim.lua).
--
-- Input each frame is a table of booleans:
--   left, right, up, down  (held)
--   punch, kick, special   (pressed this frame)
local config = require "modules.config"
local characters = require "modules.characters"

local M = {}
M.__index = M

M.NO_INPUT = {}

local BUTTONS = { "punch", "kick", "special" }

function M.new(char_id, index)
	local self = setmetatable({}, M)
	self.c = characters[char_id]
	self.char_id = char_id
	self.index = index
	self.wins = 0
	self.serial = 0        -- increments every time a move starts
	self.jump_serial = 0   -- increments every jump
	return self
end

function M:reset(x, facing)
	self.x, self.y = x, 0
	self.vx, self.vy = 0, 0
	self.facing = facing
	self.health = config.MAX_HEALTH
	self.state = "stand"
	self.t = 0
	self.anim_t = 0
	self.walk = 0
	self.guard = false
	self.move = nil
	self.stun = 0
	self.push = 0
	self.combo = 0
	self.inp = M.NO_INPUT
	self.buffer = { punch = 0, kick = 0, special = 0 }
	self.air_attack_used = false
	self.hit_confirm = false
	self.threat = false
end

function M:set_state(state)
	self.state = state
	self.t = 0
end

-- forward/back relative to where the fighter faces
function M:dirs(inp)
	local fwd = (self.facing == 1 and inp.right) or (self.facing == -1 and inp.left)
	local back = (self.facing == 1 and inp.left) or (self.facing == -1 and inp.right)
	return fwd and true or false, back and true or false
end

function M:face(opp)
	if opp.x > self.x + 1 then
		self.facing = 1
	elseif opp.x < self.x - 1 then
		self.facing = -1
	end
end

function M:is_neutral()
	return self.state == "stand" or self.state == "crouch"
end

function M:current_frame()
	return self.move and self.move.frames[self.fr_i]
end

-- "startup" / "active" / "recovery" for the current move, used by the AI
function M:move_phase()
	if self.state ~= "attack" then return nil end
	local seen_hit = false
	for i = 1, self.fr_i do
		if self.move.frames[i].hit or self.move.frames[i].spawn then seen_hit = true end
	end
	local fr = self:current_frame()
	if fr.hit or fr.spawn then return "active" end
	return seen_hit and "recovery" or "startup"
end

function M:is_invulnerable()
	if self.state == "knockdown" or self.state == "ko" then return true end
	local fr = self:current_frame()
	return self.state == "attack" and fr and fr.invuln or false
end

function M:is_crouching()
	return self.state == "crouch"
		or (self.state == "attack" and self.move.crouch)
		or (self.state == "blockstun" and self.low)
		or (self.state == "hitstun" and self.low)
		or self.state == "land"
end

-- world-space box {x0, y0, x1, y1}
function M:box(b)
	local x0, x1
	if self.facing == 1 then
		x0, x1 = self.x + b.x, self.x + b.x + b.w
	else
		x0, x1 = self.x - b.x - b.w, self.x - b.x
	end
	return { x0, self.y + b.y, x1, self.y + b.y + b.h }
end

function M:hurtbox()
	local hurt = self.c.hurt
	if self.y > 0 then return self:box(hurt.air) end
	if self:is_crouching() then return self:box(hurt.crouch) end
	return self:box(hurt.stand)
end

function M:hitbox()
	local fr = self:current_frame()
	if self.state ~= "attack" or not fr or not fr.hit or self.has_hit then return nil end
	return self:box(self.move.hitbox)
end

-- ---------------------------------------------------------------------------
-- step
-- ---------------------------------------------------------------------------

function M:step(inp, opp, ctx)
	self.inp = inp
	for _, b in ipairs(BUTTONS) do
		if inp[b] then
			self.buffer[b] = config.INPUT_BUFFER
		elseif self.buffer[b] > 0 then
			self.buffer[b] = self.buffer[b] - 1
		end
	end
	self.t = self.t + 1
	self.anim_t = self.anim_t + 1

	local s = self.state
	if s == "stand" or s == "crouch" then
		self:step_neutral(inp, opp, ctx)
	elseif s == "jump" then
		self:step_jump(inp, opp, ctx)
	elseif s == "land" then
		if self.t >= config.LAND_FRAMES then self:to_neutral(inp, opp, ctx) end
	elseif s == "attack" then
		self:step_attack(inp, opp, ctx)
	elseif s == "hitstun" or s == "blockstun" then
		self.x = self.x + self.push
		self.push = self.push * 0.82
		self.stun = self.stun - 1
		if self.stun <= 0 then
			if s == "hitstun" then self.combo = 0 end
			self:to_neutral(inp, opp, ctx)
		end
	elseif s == "knockdown" or s == "ko" then
		self:step_knockdown(inp, opp, ctx)
	end
end

function M:to_neutral(inp, opp, ctx)
	self.move = nil
	self.push = 0
	self:face(opp)
	self:set_state(inp.down and "crouch" or "stand")
	-- allow buffered actions on the very first neutral frame
	self:step_neutral(inp, opp, ctx)
end

function M:step_neutral(inp, opp, ctx)
	self:face(opp)
	self.guard = false
	local fwd, back = self:dirs(inp)
	if self:try_attack(inp, ctx) then return end

	if inp.up then
		self:set_state("jump")
		self.vy = self.c.jump_vy
		local dir = fwd and 1 or (back and -1 or 0)
		self.vx = dir * self.c.jump_vx * self.facing
		self.air_attack_used = false
		self.jump_serial = self.jump_serial + 1
		self.walk = 0
		ctx:event({ type = "sfx", name = "jump" })
		return
	end

	if inp.down then
		if self.state ~= "crouch" then self:set_state("crouch") end
		self.walk = 0
		self.guard = back and self.threat
		return
	end

	if self.state ~= "stand" then self:set_state("stand") end
	if back and self.threat then
		-- holding back while being attacked: stand still in guard
		self.walk = 0
		self.guard = true
	elseif fwd then
		self.walk = 1
		self.x = self.x + self.c.walk_fwd * self.facing
	elseif back then
		self.walk = -1
		self.x = self.x - self.c.walk_back * self.facing
	else
		self.walk = 0
	end
end

function M:try_attack(inp, ctx)
	local b = self.buffer
	if b.special > 0 and self:start_move("special", ctx) then
		b.special = 0
		return true
	end
	if b.kick > 0 then
		b.kick = 0
		return self:start_move(inp.down and "sweep" or "kick", ctx)
	end
	if b.punch > 0 then
		b.punch = 0
		return self:start_move(inp.down and "cpunch" or "punch", ctx)
	end
	return false
end

function M:start_move(id, ctx)
	local move = self.c.moves[id]
	if move.projectile and ctx:has_projectile(self.index) then
		return false
	end
	self:set_state("attack")
	self.move = move
	self.fr_i, self.fr_t = 1, 0
	self.has_hit = false
	self.hit_confirm = false
	self.move_stopped = false
	self.serial = self.serial + 1
	self.walk = 0
	self.guard = false
	if not move.air then
		self.vx = 0
	end
	ctx:event({ type = "sfx", name = move.sfx_start or "whoosh" })
	return true
end

function M:air_physics()
	self.x = self.x + self.vx
	self.y = self.y + self.vy
	self.vy = self.vy - self.c.gravity
	if self.y <= 0 then
		self.y = 0
		self.vy = 0
		self.vx = 0
		return true
	end
	return false
end

function M:step_jump(inp, opp, ctx)
	local b = self.buffer
	if not self.air_attack_used and self.t > 3 and (b.kick > 0 or b.punch > 0) then
		b.kick, b.punch = 0, 0
		self.air_attack_used = true
		self:start_move("jkick", ctx)
		return
	end
	if self:air_physics() then
		self:set_state("land")
		ctx:event({ type = "dust", x = self.x, small = true })
	end
end

function M:step_attack(inp, opp, ctx)
	local move = self.move
	self.fr_t = self.fr_t + 1
	local fr = move.frames[self.fr_i]
	if self.fr_t > fr[2] then
		self.fr_i = self.fr_i + 1
		self.fr_t = 1
		fr = move.frames[self.fr_i]
		if not fr then
			self:to_neutral(inp, opp, ctx)
			return
		end
		if fr.spawn then
			ctx:spawn_projectile(self, move.projectile)
		end
	end

	if move.air then
		if self:air_physics() then
			self.move = nil
			self:set_state("land")
			ctx:event({ type = "dust", x = self.x, small = true })
		end
		return
	end

	local vx = fr.vx or 0
	if self.move_stopped then vx = 0 end
	self.x = self.x + vx * self.facing

	-- cancel a connected punch into the special
	if move.cancel and self.hit_confirm and self.buffer.special > 0 then
		if self:start_move("special", ctx) then
			self.buffer.special = 0
		end
	end
end

function M:step_knockdown(inp, opp, ctx)
	if self.kd_phase == "air" then
		if self:air_physics() then
			self.kd_phase = "down"
			self.t = 0
			ctx:event({ type = "dust", x = self.x })
			ctx:event({ type = "sfx", name = "thud" })
			ctx:event({ type = "shake", amount = 4 })
		end
	elseif self.kd_phase == "down" then
		if self.state == "knockdown" and self.t >= config.KNOCKDOWN_DOWN_FRAMES then
			self.kd_phase = "rise"
			self.t = 0
		end
	elseif self.kd_phase == "rise" then
		if self.t >= config.KNOCKDOWN_RISE_FRAMES then
			self.combo = 0
			self:to_neutral(M.NO_INPUT, opp, ctx)
		end
	end
end

-- ---------------------------------------------------------------------------
-- getting hit
-- ---------------------------------------------------------------------------

-- What this fighter is guarding against an attack coming from attacker_x:
-- "low", "high" or nil.
function M:guard_type(attacker_x)
	if self.y > 0 then return nil end
	local s = self.state
	if not (s == "stand" or s == "crouch" or s == "blockstun") then return nil end
	local dir = attacker_x >= self.x and 1 or -1
	local inp = self.inp
	local back = (dir == 1 and inp.left) or (dir == -1 and inp.right)
	if not back then return nil end
	return inp.down and "low" or "high"
end

function M:can_block(height, attacker_x)
	local g = self:guard_type(attacker_x)
	if not g then return false end
	return height == "mid" or height == g
end

-- h: damage data (move or projectile), dir: push direction (+1 = to the right)
function M:take_hit(h, dir, blocked)
	local was_low = self:is_crouching()
	self.move = nil
	self.walk = 0
	self.guard = false
	if blocked then
		self.health = math.max(0, self.health - (h.chip or 0))
		self.low = self.inp.down and true or false
		self:set_state("blockstun")
		self.stun = h.blockstun
		self.push = h.push * 0.8 * dir
		if self.health <= 0 then self:launch(dir, true) end
		return 0
	end
	self.combo = self.combo + 1
	local scale = math.max(0.4, 1 - 0.12 * (self.combo - 1))
	local dmg = math.max(1, math.floor(h.damage * scale + 0.5))
	self.health = math.max(0, self.health - dmg)
	if self.health <= 0 then
		self:launch(dir, true)
	elseif h.knockdown or self.y > 0 then
		self:launch(dir, false)
	else
		self.low = was_low
		self:set_state("hitstun")
		self.stun = h.hitstun
		self.push = h.push * dir
	end
	return dmg
end

function M:launch(dir, ko)
	self:set_state(ko and "ko" or "knockdown")
	self.kd_phase = "air"
	self.vx = (ko and 5 or 3.5) * dir
	self.vy = ko and 12 or 9
	self.y = math.max(self.y, 1)
	self.push = 0
	self.stun = 0
end

function M:set_win()
	self.move = nil
	self.walk = 0
	self.guard = false
	self:set_state("win")
end

-- ---------------------------------------------------------------------------
-- visuals
-- ---------------------------------------------------------------------------

function M:frame_name()
	local s = self.state
	local n
	if s == "stand" then
		if self.guard then
			n = "block_0"
		elseif self.walk ~= 0 then
			local i = math.floor(self.anim_t / 6) % 6
			if self.walk < 0 then i = 5 - i end
			n = "walk_" .. i
		else
			n = "idle_" .. (math.floor(self.anim_t / 9) % 4)
		end
	elseif s == "crouch" then
		n = self.guard and "cblock_0" or "crouch_0"
	elseif s == "jump" then
		n = self.vy > 4 and "jump_0" or "jump_1"
	elseif s == "land" then
		n = "crouch_0"
	elseif s == "attack" then
		n = self.move.frames[self.fr_i][1]
	elseif s == "blockstun" then
		n = self.low and "cblock_0" or "block_0"
	elseif s == "hitstun" then
		if self.low then
			n = "chit_0"
		else
			n = self.t < 5 and "hit_0" or "hit_1"
		end
	elseif s == "knockdown" or s == "ko" then
		if self.kd_phase == "air" then
			n = "fall_0"
		elseif self.kd_phase == "rise" then
			n = "rise_0"
		else
			n = "down_0"
		end
	elseif s == "win" then
		n = self.t < 20 and "win_0" or "win_1"
	else
		n = "idle_0"
	end
	return self.char_id .. "_" .. n
end

return M

-- Character definitions: movement stats, hurtboxes and move frame data.
--
-- Move frames are { sprite_frame, duration, flags... }. Flags:
--   hit    = hitbox is active during this frame
--   invuln = fighter can't be hit
--   vx     = forward speed while on this frame
--   spawn  = spawn the move's projectile when this frame starts
-- Boxes are relative to the fighter's feet: x is measured forward from the
-- fighter's center, y up from the ground.
-- Heights: "mid" (block standing or crouching), "low" (crouch block only),
-- "high" (overhead, standing block only).

local M = {}

local HURT = {
	stand = { x = -27, y = 0, w = 54, h = 168 },
	crouch = { x = -30, y = 0, w = 60, h = 105 },
	air = { x = -24, y = 12, w = 48, h = 150 },
}

M.kenji = {
	id = "kenji",
	name = "KENJI",
	walk_fwd = 4.2,
	walk_back = 3.4,
	jump_vy = 21,
	jump_vx = 5.5,
	gravity = 1.1,
	hurt = HURT,
	moves = {
		punch = {
			frames = { { "punch_0", 3 }, { "punch_1", 4, hit = true }, { "punch_2", 8 } },
			damage = 5, hitstun = 15, blockstun = 11, push = 6, height = "mid",
			hitbox = { x = 36, y = 112, w = 60, h = 34 },
			cancel = true, sfx = "hit_light",
		},
		kick = {
			frames = { { "kick_0", 7 }, { "kick_1", 5, hit = true }, { "kick_2", 13 } },
			damage = 10, hitstun = 18, blockstun = 13, push = 9, height = "mid",
			hitbox = { x = 28, y = 66, w = 78, h = 54 },
			heavy = true, sfx = "hit_heavy",
		},
		cpunch = {
			crouch = true,
			frames = { { "cpunch_0", 3 }, { "cpunch_1", 3, hit = true }, { "cpunch_0", 7 } },
			damage = 4, hitstun = 14, blockstun = 10, push = 5, height = "low",
			hitbox = { x = 36, y = 66, w = 58, h = 30 },
			cancel = true, sfx = "hit_light",
		},
		sweep = {
			crouch = true,
			frames = { { "sweep_0", 6 }, { "sweep_1", 5, hit = true }, { "sweep_2", 18 } },
			damage = 8, hitstun = 18, blockstun = 12, push = 8, height = "low",
			hitbox = { x = 24, y = 0, w = 78, h = 30 },
			knockdown = true, heavy = true, sfx = "hit_heavy",
		},
		jkick = {
			air = true,
			frames = { { "jkick_0", 4 }, { "jkick_1", 90, hit = true } },
			damage = 9, hitstun = 18, blockstun = 12, push = 6, height = "high",
			hitbox = { x = 15, y = -15, w = 70, h = 60 },
			heavy = true, sfx = "hit_heavy",
		},
		special = {
			name = "FIREBALL",
			frames = { { "special_0", 5 }, { "special_1", 7 }, { "special_2", 4, spawn = true }, { "special_3", 18 } },
			projectile = {
				x = 78, y = 112, w = 60, h = 48, speed = 9.5,
				damage = 10, chip = 2, hitstun = 20, blockstun = 16, push = 8, height = "mid",
				heavy = true, sfx = "hit_heavy",
			},
			sfx_start = "fireball",
		},
	},
}

M.vera = {
	id = "vera",
	name = "VERA",
	walk_fwd = 4.8,
	walk_back = 4.0,
	jump_vy = 22,
	jump_vx = 6.2,
	gravity = 1.15,
	hurt = HURT,
	moves = {
		punch = {
			frames = { { "punch_0", 2 }, { "punch_1", 3, hit = true }, { "punch_2", 7 } },
			damage = 4, hitstun = 14, blockstun = 10, push = 5, height = "mid",
			hitbox = { x = 36, y = 120, w = 56, h = 32 },
			cancel = true, sfx = "hit_light",
		},
		kick = {
			frames = { { "kick_0", 7 }, { "kick_1", 5, hit = true }, { "kick_2", 15 } },
			damage = 8, hitstun = 18, blockstun = 12, push = 9, height = "mid",
			hitbox = { x = 30, y = 100, w = 78, h = 56 },
			heavy = true, sfx = "hit_heavy",
		},
		cpunch = {
			crouch = true,
			frames = { { "cpunch_0", 3 }, { "cpunch_1", 3, hit = true }, { "cpunch_0", 7 } },
			damage = 4, hitstun = 14, blockstun = 10, push = 5, height = "low",
			hitbox = { x = 36, y = 66, w = 58, h = 30 },
			cancel = true, sfx = "hit_light",
		},
		sweep = {
			crouch = true,
			frames = { { "sweep_0", 5 }, { "sweep_1", 5, hit = true }, { "sweep_2", 19 } },
			damage = 7, hitstun = 18, blockstun = 12, push = 8, height = "low",
			hitbox = { x = 24, y = 0, w = 80, h = 30 },
			knockdown = true, heavy = true, sfx = "hit_heavy",
		},
		jkick = {
			air = true,
			frames = { { "jkick_0", 4 }, { "jkick_1", 90, hit = true } },
			damage = 8, hitstun = 18, blockstun = 12, push = 6, height = "high",
			hitbox = { x = 15, y = -15, w = 70, h = 60 },
			heavy = true, sfx = "hit_heavy",
		},
		special = {
			name = "COMET KNEE",
			frames = {
				{ "special_0", 4, invuln = true },
				{ "special_0", 3 },
				{ "special_1", 5, hit = true, vx = 11 },
				{ "special_2", 12, hit = true, vx = 8 },
				{ "special_3", 24 },
			},
			damage = 9, chip = 2, hitstun = 20, blockstun = 14, push = 10, height = "mid",
			hitbox = { x = 0, y = 55, w = 66, h = 90 },
			knockdown = true, heavy = true, sfx = "hit_heavy", sfx_start = "whoosh",
		},
	},
}

M.list = { "kenji", "vera" }

-- Derived data used by the fighter and the AI.
for _, id in ipairs(M.list) do
	for name, move in pairs(M[id].moves) do
		move.id = name
		local total, startup, travel, seen_hit = 0, 0, 0, false
		for _, fr in ipairs(move.frames) do
			if fr.hit then seen_hit = true end
			if not seen_hit and not fr.spawn then startup = startup + fr[2] end
			if fr.vx then travel = travel + fr.vx * fr[2] end
			total = total + fr[2]
		end
		move.total = total
		move.startup = startup
		move.travel = travel
		if move.hitbox then
			move.reach = move.hitbox.x + move.hitbox.w
		elseif move.projectile then
			move.reach = 2000
		end
	end
end

return M

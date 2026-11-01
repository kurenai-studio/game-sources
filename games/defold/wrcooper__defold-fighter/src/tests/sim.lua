-- Headless CPU-vs-CPU simulation of the game logic. Run from the project root:
--   lua tests/sim.lua [matches]
-- Checks that matches finish without errors and prints win rates per matchup,
-- which is a quick way to sanity check AI difficulty and character balance.
package.path = "./?.lua;" .. package.path

local Match = require "modules.match"
local AI = require "modules.ai"

local matches = tonumber(arg and arg[1]) or 20
math.randomseed(12345)

local function run(c1, l1, c2, l2)
	local m = Match.new(c1, c2)
	local ais = { AI.new(1, l1), AI.new(2, l2) }
	local stats = { hits = 0, blocks = 0, projectiles = 0, frames = 0, rounds = 0 }
	for frame = 1, 60 * 60 * 15 do
		local inputs = { ais[1]:update(m), ais[2]:update(m) }
		m:step(inputs)
		for _, e in ipairs(m:pop_events()) do
			if e.type == "damage" then
				if e.blocked then stats.blocks = stats.blocks + 1 else stats.hits = stats.hits + 1 end
			elseif e.type == "projectile_spawn" then
				stats.projectiles = stats.projectiles + 1
			elseif e.type == "round_start" then
				stats.rounds = stats.rounds + 1
			end
		end
		for _, f in ipairs(m.fighters) do
			assert(f.x >= 60 and f.x <= 1220, "fighter out of bounds")
			assert(f.y >= 0, "fighter below ground")
			assert(f.health >= 0, "negative health")
		end
		if m.phase == "match_over" then
			stats.frames = frame
			return m.winner, stats
		end
	end
	error("match did not finish")
end

local setups = {
	{ "kenji", "normal", "vera", "normal" },
	{ "vera", "normal", "kenji", "normal" },
	{ "kenji", "hard", "kenji", "easy" },
	{ "vera", "easy", "vera", "hard" },
	{ "kenji", "hard", "vera", "normal" },
	{ "kenji", "normal", "kenji", "normal" },
}

for _, s in ipairs(setups) do
	local wins = { 0, 0 }
	local tot = { hits = 0, blocks = 0, projectiles = 0, frames = 0, rounds = 0 }
	for _ = 1, matches do
		local w, st = run(s[1], s[2], s[3], s[4])
		wins[w] = wins[w] + 1
		for k, v in pairs(st) do tot[k] = tot[k] + v end
	end
	print(string.format("%-6s %-6s vs %-6s %-6s | P1 %2d - %2d P2 | per match: %.1fs, %.1f rounds, %.0f hits, %.0f blocks, %.1f fireballs",
		s[1], s[2], s[3], s[4], wins[1], wins[2],
		tot.frames / matches / 60, tot.rounds / matches, tot.hits / matches, tot.blocks / matches, tot.projectiles / matches))
end

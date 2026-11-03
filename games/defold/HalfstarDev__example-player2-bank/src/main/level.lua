local teller = require "main.teller"
local password = require "main.password"
local save = require "main.save"

local level = {}

local min = 1
local max = 7
local current = 1

local function get_unlocked()
	return save.get("level") or 1
end

local function unlock(n)
	if n > get_unlocked() then
		save.set("level", n)
	end
end

function level.is_unlocked(n)
	return n > 0 and n <= get_unlocked()
end

function level.get()
	return current
end

function level.is_final()
	return current >= max
end

function level.set(n)
	current = n or 1
	if current < min then
		current = min
	end
	if current > max then
		current = max
	end
	password.set(current)
	teller.set_level(current)
	unlock(current)
	return current
end

function level.load()
	level.set(get_unlocked())
end

function level.next()
	level.set(current + 1)
end

return level
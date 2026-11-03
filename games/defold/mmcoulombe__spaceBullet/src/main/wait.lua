-- Put functions in this file to use them in several other scripts.
-- To get access to the functions, you need to put:
-- require "my_directory.my_file"
-- in any script using the functions.

local Wait = {}

local WAITING_ON_TIME = {}
local CURRENT_TIME = 0

function Wait.seconds(seconds)
	local co = coroutine.running()

	assert(co ~= nul, "The main tread cannot wait!")

	local wakeUp = CURRENT_TIME + seconds
	WAITING_ON_TIME[co] = wakeUp

	return coroutine.yield(co)
end

function Wait.update(dt)
	CURRENT_TIME = CURRENT_TIME + dt

	local threadsToWake = {}
	for co, wakeUp in pairs(WAITING_ON_TIME) do
		if (wakeUp < CURRENT_TIME) then
			table.insert(threadsToWake, co)
		end
	end

	for _, co in ipairs(threadsToWake) do
		WAITING_ON_TIME[co] = nil
		coroutine.resume(co)
	end
end

return Wait
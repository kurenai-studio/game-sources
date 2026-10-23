local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
_G.PROF_CAPTURE = IS_DEBUG and arg[3] == "profile"

-- Load core libraries
_G.Gamestate = require("lib.hump.gamestate")

-- Set up debugging
if IS_DEBUG then
	require("lldebugger").start()
	function love.errorhandler(msg)
		error(msg, 2)
	end
end

-- Set up profiling
if PROF_CAPTURE then
	_G.prof = require("lib.jprof")

	-- Override love.run for frame profiling
	local original_run = love.run
	function love.run()
		local original_loop = original_run()
		return function()
			prof.push("frame")
			local result = original_loop()
			prof.pop("frame")
			return result
		end
	end

	-- Set up callback profiling
	local all_callbacks = { 'draw', 'update' }
	---@diagnostic disable-next-line
	for k in pairs(love.handlers) do
		table.insert(all_callbacks, k)
	end

	for _, f in ipairs(all_callbacks) do
		love[f] = function(...)
			prof.push(f)
			local results = { Gamestate[f](...) }
			prof.pop(f)
			return unpack(results)
		end
	end

	prof.connect(false)
end

-- Game initialization
function love.load()
	-- Load all game states
	local statePath = "src/states"
	local initState = "start"

	love.graphics.setDefaultFilter("nearest", "nearest")

	_G.States = {}
	for _, state in ipairs(love.filesystem.getDirectoryItems(statePath)) do
		local module = state:match("(.+)%.lua$") or state
		States[module] = require(statePath .. "." .. module)
	end

	-- Initialize the first state
	Gamestate.switch(States[initState])

	-- Register events if not using profiling
	if not PROF_CAPTURE then
		Gamestate.registerEvents()
	end
end

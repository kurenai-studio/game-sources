--- Usage:
--- local M = require("M")(...)

local IS_DEBUG = sys.get_engine_info().is_debug

local M = {}
M.reloadables = {}

function M.reloadable(path)
	if not IS_DEBUG then
		return {}
	end

	local t = M.reloadables[path] or {}
	for k, _ in pairs(t) do
		t[k] = nil
	end

	M.reloadables[path] = t
	return M.reloadables[path]
end

setmetatable(M, {
	__call = function(_, path)
		return M.reloadable(path)
	end
})

return M

local M = {}
local harmony = require("systems.harmony_rules")

M.energy = 0

function M.update(dt, sources)
	local total = 0

	for _, source in ipairs(sources) do
		local bonus = harmony.calculate_bonus(source, sources)
		total = total + (10 * bonus)
	end

	M.energy = M.energy + total * dt
end

return M
local M = {}

local function distance(a, b)
	return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
end

function M.calculate_bonus(source, all_sources)
	local multiplier = 1

	for _, other in ipairs(all_sources) do
		if other ~= source then
			local d = distance(source, other)

			if d < 1.5 then
				multiplier = multiplier * 0.5
			elseif d >= 2 and d <= 3 then
				multiplier = multiplier * 1.25
			elseif d > 4 then
				multiplier = multiplier * 0.9
			end
		end
	end

	return multiplier
end

return M
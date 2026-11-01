local M = {}

function M.table_length(t)
	local length = 0
	for _ in ipairs(t) do
		length = length + 1
	end
	return length
end

return M
local time = {}

local v3 = vmath.vector3

local midnight = {exposure = 0.25, saturation = 1.40, contrast = 1.20, tint = v3(0.55, 0.65, 1.10)}
local dawn     = {exposure = 0.50, saturation = 1.00, contrast = 1.00, tint = v3(1.15, 0.85, 0.75)}
local day      = {exposure = 1.00, saturation = 1.00, contrast = 1.00, tint = v3(1.00, 1.00, 1.00)}
local bright   = {exposure = 1.60, saturation = 0.90, contrast = 1.20, tint = v3(1.00, 1.00, 1.00)}

local times = {
	[00] = midnight,
	[04] = midnight,
	[06] = dawn,
	[10] = day,
	[12] = bright,
	[16] = day,
	[18] = dawn,
	[22] = midnight,
	[24] = midnight,
}

local function smoothstep(edge1, edge2, x)
	local factor = math.max(0, math.min(1, (x - edge1) / (edge2 - edge1)))
	return factor * factor * (3 - 2 * factor)
end

local function lerp(a, b, w)
	return a + (b - a) * w
end

function time.get_values(t)
	t = t % 24

	local keys = {}
	for hour in pairs(times) do
		keys[#keys + 1] = hour
	end
	table.sort(keys)

	for i = 1, #keys - 1 do
		local t1 = keys[i]
		local t2 = keys[i + 1]

		if t >= t1 and t <= t2 then
			local w = smoothstep(t1, t2, t)
			local v1 = times[t1]
			local v2 = times[t2]

			return {
				exposure   = lerp(v1.exposure, v2.exposure, w),
				saturation = lerp(v1.saturation, v2.saturation, w),
				contrast   = lerp(v1.contrast, v2.contrast, w),
				tint       = vmath.lerp(w, v1.tint, v2.tint)
			}
		end
	end

	return times[0]
end

return time
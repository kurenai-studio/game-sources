--- animate gui nodes
--- original project: https://github.com/defold/sample-main-menu-animation

local M = {}

M.DEFAULT_D = 0.4
M.MEDIUM_D = 0.1
M.FAST_D = 0.001
M.SLOW_D = 0.8

local function exists(url)
	return pcall(function(id) gui.get_node(id) end, url) == true
end

local function anim5(_, node)
	if not exists("background") or gui.get_node("background") ~= node then
		return
	end
	local to_color = gui.get_color(node)
	to_color.w = 0.6
	gui.animate(node, gui.PROP_COLOR, to_color, gui.EASING_OUT, 2.4, 0.1)
end

--- animate node
--- @param id string
--- @param d number
function M.animate(id, d)
	local node = gui.get_node(id)
	local start_scale = 0.7
	local old_scale = gui.get_scale(node)
	gui.set_scale(node, vmath.vector4(start_scale, start_scale, start_scale, 0))
	local from_color = gui.get_color(node)
	local to_color = gui.get_color(node)
	from_color.w = 0
	gui.set_color(node, from_color)
	gui.animate(node, gui.PROP_COLOR, to_color, gui.EASING_IN, 0.4, d)

	local function anim4()
		gui.animate(node, gui.PROP_SCALE, old_scale, gui.EASING_INOUT, 0.24, 0, anim5)
	end

	local function anim3()
		local vec = vmath.vector4(old_scale.x + 0.08, old_scale.y + 0.08, old_scale.z + 0.08, 0)
		gui.animate(node, gui.PROP_SCALE, vec, gui.EASING_INOUT, 0.24, 0, function() anim4() end)
	end

	local function anim2()
		local vec = vmath.vector4(old_scale.x - 0.04, old_scale.y - 0.04, old_scale.z -0,04, 0)
		gui.animate(node, gui.PROP_SCALE, vec, gui.EASING_INOUT, 0.24, 0, function() anim3() end)
	end
	
	gui.animate(
		node, gui.PROP_SCALE,
		vmath.vector4(old_scale.x + 0.14, old_scale.y + 0.14, old_scale.z + 0.14, 0),
		gui.EASING_IN, 0.4, d, function() anim2() end
	)
end

return M
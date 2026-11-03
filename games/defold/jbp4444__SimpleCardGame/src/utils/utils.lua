
local M = {}

function M.is_inside( tx,ty, pos, size )
	local rtn = false
	local x0 = pos.x - size.x/2
	local x1 = pos.x + size.x/2
	local y0 = pos.y - size.y/2
	local y1 = pos.y + size.y/2
	if( (tx>=x0) and (tx<=x1) and (ty>=y0) and (ty<=y1) ) then
		rtn = true
	end	
	return rtn
end

function M.is_inside_go( tx,ty, objid )
	-- TODO: test that objid is a gfx-obj (not a sprite)
	local pos  = go.get( objid, 'position' )
	local size = go.get( objid..'#sprite', 'size' )
	return M.is_inside( tx,ty, pos,size )
end

function M.is_inside_sprite( tx,ty, objid )
	-- TODO: test that objid is a gfx-obj (not a sprite)
	local pos  = go.get_position( objid )
	local size = go.get( objid, 'size' )
	return M.is_inside( tx,ty, pos,size )
end

return M

local ghosts = {}

local function get_selected_ghost_texture(bunny_type)
  if bunny_type == BunnyType.Dandelion then
    return Textures.ghost_dandelion
  elseif bunny_type == BunnyType.White then
    return Textures.ghost_white_bunny
  elseif bunny_type == BunnyType.Pyon then
    return Textures.ghost_pyon_bunny
  elseif bunny_type == BunnyType.Gameboy then
    return Textures.ghost_gameboy_bunny
  else
    return nil
  end
end

function ghosts.draw(camera)
  local texture = get_selected_ghost_texture(SelectedBunny)
  if texture ~= nil then
    local mx, my = love.mouse.getPosition();
    mx = mx / camera.scale;
    my = my / camera.scale;
    local grid_x, grid_y = Map:get_grid_location_from_xy(mx, my);
    if grid_x ~= nil and grid_y ~= nil then
      if Map:can_place_at(grid_x, grid_y) then
        local x, y = Map:get_xy_location(grid_x, grid_y);
        love.graphics.draw(texture, x, y)
      else
        love.graphics.setColor(1.0, 0.8, 0.8);
        love.graphics.draw(texture, mx - texture:getWidth() * 0.5, my - texture:getHeight() * 0.5)
        love.graphics.setColor(1.0, 1.0, 1.0);
      end
    end
  end
end

return ghosts;

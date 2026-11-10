Map = {
  offset_x = 0,
  offset_y = 0,
  grid_size = 10,
  map_bounds = {}
}

function CheckRectCollide(rect1, rect2)
  return rect1.x < rect2.x + rect2.width and
      rect1.x + rect1.width > rect2.x and
      rect1.y < rect2.y + rect2.height and
      rect1.y + rect1.height > rect2.y
end

function check_point_in_rect(px, py, rect)
  return px >= rect.x and px <= rect.x + rect.width and py >= rect.y and py <= rect.y + rect.height
end

function Map:load(camera)
  self.grid = {
    { 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  }

  self.grid_size = 48;                             --total_height / #self.grid;
  local total_height = self.grid_size * #self.grid --Canvas:getHeight(); --/ camera.scale * 0.85;

  --print(self.grid_size)
  -- self.offset_y = Canvas:getHeight() - total_height - self.grid_size;
  --self.offset_x = Canvas:getWidth() * 0.125;
  self.offset_x = 48;
  self.offset_y = 96;

  self.map_bounds = {
    x = self.offset_x,
    y = self.offset_y,
    width = self.grid_size * #self.grid[1],
    height = self.grid_size * #self.grid,
  }
end

function Map:can_place_at(grid_x, grid_y)
  if #self.grid < grid_y then
    return false;
  end
  return self.grid[grid_y][grid_x] == 0
end

function Map:fill_location(grid_x, grid_y)
  self.grid[grid_y][grid_x] = 1;
end

function Map:empty_location(grid_x, grid_y)
  self.grid[grid_y][grid_x] = 0;
end

function Map:get_xy_location(tile_x, tile_y)
  return self.offset_x + (tile_x - 1) * self.grid_size, self.offset_y + (tile_y - 1) * self.grid_size
end

function Map:get_grid_location_from_xy(x, y)
  if check_point_in_rect(x, y, self.map_bounds) then
    local lower_grid_x = math.floor((x - self.offset_x) / self.grid_size);
    local lower_grid_y = math.floor((y - self.offset_y) / self.grid_size);
    return lower_grid_x + 1, lower_grid_y + 1
  else
    return nil, nil
  end
end

function Map:is_grid_filled_at_xy(x, y)
  local grid_x, grid_y = Map:get_grid_location_from_xy(x, y)
  if grid_x ~= nil and grid_y ~= nil then
    return not Map:can_place_at(grid_x, grid_y)
  else
    return true
  end
end

function Map:draw()
  local px, py = self:get_xy_location(0, 0);
  love.graphics.draw(Textures.floor_background, 0, 0)
  -- for y = 1, #self.grid do
  --   for x = 1, #self.grid[y] do
  --     if (x + y) % 2 == 0 then
  --       love.graphics.setColor(0.1, 0.8, 0.1)
  --     else
  --       love.graphics.setColor(0.1, 0.6, 0.1)
  --     end

  --     local px, py = self:get_xy_location(x, y);

  --     love.graphics.rectangle("fill", px, py, self.grid_size, self.grid_size)
  --   end
  -- end
end

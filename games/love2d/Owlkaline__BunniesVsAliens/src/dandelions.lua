local dandelions = {
  texture = {},
  gravity = {}
}

local pop_scale = 30.0;
local movement_duration = 1.5;

function dandelions.load()
  dandelions.texture = Textures.dandelion_floating
  dandelions.gravity = 9.8;
end

function dandelions.new(x, y, value)
  local new_dandelion = setmetatable({}, { __index = dandelions })

  new_dandelion.x = x;
  new_dandelion.y = y;
  new_dandelion.velocity = { x = (math.random() * 2.0 - 1.0) * pop_scale, y = (math.random() - 1.0) * pop_scale }
  new_dandelion.movement_timer = movement_duration;
  new_dandelion.value = value

  table.insert(dandelions, new_dandelion)
end

function dandelions.update(dandelion_handler, camera, dt)
  local mx, my = love.mouse.getPosition()
  mx = mx / camera.scale;
  my = my / camera.scale;

  for idx, dandelion in ipairs(dandelions) do
    dandelion.movement_timer = dandelion.movement_timer - dt;
    if dandelion.movement_timer > 0 then
      dandelion.velocity.y = dandelion.velocity.y + dandelions.gravity * dt;
      dandelion.x = dandelion.x + dandelion.velocity.x * dt;
      dandelion.y = dandelion.y + dandelion.velocity.y * dt;
    end

    local dandelion_rect = {
      x = dandelion.x,
      y = dandelion.y,
      width = dandelion.texture:getWidth(),
      height = dandelion.texture:getHeight(),
    }
    if check_point_in_rect(mx, my, dandelion_rect) then
      dandelion_handler:add_dandelions(dandelion.value);
      table.remove(dandelions, idx)
    end
  end
end

function dandelions.draw()
  for _, dandelion in ipairs(dandelions) do
    love.graphics.draw(dandelions.texture, dandelion.x, dandelion.y)
  end
end

return dandelions;

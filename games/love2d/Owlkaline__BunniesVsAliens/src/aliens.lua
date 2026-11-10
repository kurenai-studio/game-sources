local attack_timer_value = 1.0;

AlienState = {
  Travelling = 1,
  MovingToAttack = 2,
  Attacking = 3,
  MovingToTravel = 4,
  MovingToGoal = 5,
  KnockedBack = 6,
}

local aliens = {}

function aliens.spawn(x, y, lane, texture, life, speed)
  local new_alien = setmetatable({}, { __index = aliens })
  local goal_x, goal_y = Map:get_xy_location(10, lane);

  new_alien.x = x
  new_alien.y = y - Map.grid_size
  new_alien.old_y = y
  new_alien.old_shadow_y = y
  new_alien.grid_y = lane; --grid_y or -1;
  new_alien.goal = { x = goal_x, y = y }
  new_alien.shadow_y_offset = 0
  new_alien.texture = texture
  new_alien.attack_texture = Textures.alien_attack
  new_alien.velocity = { x = speed, y = 0 }
  new_alien.speed = speed
  new_alien.attacking_timer = attack_timer_value
  new_alien.state = AlienState.MovingToGoal
  new_alien.life = life;
  new_alien.total_dt = math.random() * 16000.0;
  new_alien.alpha = 1.0;
  new_alien.gameboy_effect_duration_left = 0;
  new_alien.collision_box = {
    offset_x = 24,
    width = 10,
  }
  table.insert(aliens, new_alien)
end

function aliens:take_damage(damage)
  self.life = self.life - damage;
end

function aliens:apply_gameboy_effect(duration)
  self.gameboy_effect_duration_left = duration;
end

function aliens:gameboy_effect_active()
  return self.gameboy_effect_duration_left > 0
end

function aliens:knock_back(distance)
  self.state = AlienState.KnockedBack
  self.goal.x = self.x + distance; --Map.grid_size * 2.0;
  self.goal.y = self.old_y;

  self.velocity.x = -300.0;
  self.velocity.y = math.abs(self.y - self.goal.y);
end

function aliens:target_nearby()
  if Map:is_grid_filled_at_xy(self.x, self.old_y + Map.grid_size * 0.5) then
    local grid_x, _ = Map:get_grid_location_from_xy(self.x, self.old_y + Map.grid_size * 0.5);
    if grid_x == nil then
      return false;
    end

    self.state = AlienState.MovingToAttack
    self.velocity.x = 0
    --self.old_y = self.y;
    return true
  else
    return false
  end
end

function aliens.update(bunnies, dt)
  aliens.move_aliens(dt)

  for idx, alien in ipairs(aliens) do
    if alien.life <= 0.0 then
      table.remove(aliens, idx)
      goto continue;
    end

    if alien.state == AlienState.KnockedBack then
      if alien.x > alien.goal.x then
        alien.x = alien.goal.x
        alien.y = alien.goal.y
        alien.state = AlienState.Travelling;
        alien.goal.x = 0;
        alien.goal.y = 0;
        alien.velocity.x = alien.speed;
        alien.velocity.y = 0;
        alien.alien_shadow_y_offset = 0
      end
    end

    if alien:gameboy_effect_active() then
      alien.gameboy_effect_duration_left = alien.gameboy_effect_duration_left - dt;
      goto continue
    end

    if alien.state == AlienState.Travelling then
      if not alien:target_nearby() then
        alien.velocity.x = alien.speed
        alien.y = alien.old_y
      end
    elseif alien.state == AlienState.MovingToAttack then
      if alien.goal.x == 0 and alien.goal.y == 0 then
        local grid_x, _ = Map:get_grid_location_from_xy(alien.x, alien.y + Map.grid_size * 0.5)
        if grid_x ~= nil then
          local x, y = Map:get_xy_location(grid_x, alien.grid_y);
          y = y - Map.grid_size * 0.5;
          alien.goal.x = x;
          alien.goal.y = y;

          alien.velocity.x = math.min((alien.x - alien.goal.x) / 2, alien.speed);
          alien.velocity.y = math.min((alien.y - alien.goal.y) / 2, alien.speed);
        end
      end

      local x_in_position, y_in_position = false, false;
      if alien.x < alien.goal.x then
        alien.x = alien.goal.x
        x_in_position = true
      end
      if alien.y < alien.goal.y then
        alien.y = alien.goal.y
        y_in_position = true
      end

      if x_in_position and y_in_position then
        alien.state = AlienState.Attacking;
        alien.goal.x = 0;
        alien.goal.y = 0;
        alien.velocity.x = 0;
        alien.velocity.y = 0;
        alien.attacking_timer = attack_timer_value;
      end
    elseif alien.state == AlienState.Attacking then
      local timer_before = alien.attacking_timer;
      alien.attacking_timer = alien.attacking_timer - dt;

      if timer_before > 0.5 and alien.attacking_timer <= 0.5 then
        local grid_x, _ = Map:get_grid_location_from_xy(alien.x, alien.y + Map.grid_size * 0.5)
        bunnies.attack_grid_xy(grid_x, alien.grid_y);
      end

      if alien.attacking_timer < 0 then
        alien.attacking_timer = attack_timer_value
        local grid_x, _ = Map:get_grid_location_from_xy(alien.x, alien.y + Map.grid_size * 0.5)

        -- no bunny
        if grid_x ~= nil then
          if Map:can_place_at(grid_x, alien.grid_y) then
            alien.state = AlienState.MovingToTravel
          end
        end
      end
    elseif alien.state == AlienState.MovingToGoal then
      if alien.velocity.x == 0 or alien.velocity.y == 0 then
        alien.velocity.x = math.min((alien.x - alien.goal.x) * 0.5, 50.0);
        alien.velocity.y = (alien.y - alien.goal.y) * 0.5;
      end

      local x_in_position, y_in_position = false, false;
      if math.abs(alien.x - alien.goal.x) < 2 or alien.goal.x == 0 then
        alien.x = alien.goal.x
        x_in_position = true
      end
      if math.abs(alien.y - alien.goal.y) < 2 or alien.goal.y == 0 then
        alien.y = alien.goal.y
        y_in_position = true
      end

      if x_in_position and y_in_position then
        alien.state = AlienState.Travelling;
        alien.goal.x = 0;
        alien.goal.y = 0;
        alien.velocity.x = alien.speed;
        alien.velocity.y = 0;
      end
    elseif alien.state == AlienState.MovingToTravel then
      if alien.velocity.y == 0 then
        alien.velocity.x = alien.speed;
        alien.velocity.y = (alien.y - alien.old_y) * 0.5;
      end
      if alien.y > alien.old_y then
        alien.y = alien.old_y;
        alien.velocity.y = 0;
        alien.state = AlienState.Travelling
      end
      alien:target_nearby()
    end
    ::continue::
  end
end

function aliens.move_aliens(dt)
  for _, alien in ipairs(aliens) do
    if alien.x < -alien.texture:getWidth() then
      CurrentGameState = GameState.GameOver
    end

    if alien:gameboy_effect_active() and alien.state ~= AlienState.KnockedBack then
      goto continue
    end

    alien.x = alien.x - alien.velocity.x * dt;

    local dy = alien.velocity.y * dt;

    if alien.x < Map.map_bounds.x + Map.map_bounds.width + Map.grid_size * 2.8 then
      local difference = alien.y - dy + alien.old_y;
      if difference < 0 then
        alien.y = alien.old_y;
        dy = dy - difference;
      else
        alien.y = alien.y - dy;
      end
    end

    local shadow_dy_mod = 0.7;
    if alien.state == AlienState.MovingToAttack or alien.state == AlienState.MovingToTravel then
      alien.shadow_y_offset = alien.shadow_y_offset + dy * shadow_dy_mod;
      if dy < 0 then
        if math.abs(alien.shadow_y_offset) < 3 then
          alien.shadow_y_offset = 0;
        end
      end
    end
    alien.total_dt = alien.total_dt + dt;
    ::continue::
  end
end

function aliens.draw()
  for _, alien in ipairs(aliens) do
    if alien:gameboy_effect_active() then
      love.graphics.draw(Textures.gameboy_alien, alien.x, alien.y)
    else
      love.graphics.draw(alien.texture, alien.x, alien.y + math.sin(alien.total_dt))
      if alien.state == AlienState.Attacking and alien.attacking_timer < 0.5 then
        love.graphics.draw(alien.attack_texture, alien.x, alien.y)
      else
        love.graphics.draw(Textures.shadow_alien, alien.x + alien.texture:getWidth() * 0.25,
          alien.y + alien.texture:getHeight() * 0.85 + alien.shadow_y_offset)
      end
    end
  end
end

return aliens

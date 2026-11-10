local balls = {}

local gameboy_effect_duration = 1.0;

BallType = {
  Normal = 0,
  GameBoy = 1,
}

function GetBallDamage(ball_type)
  if ball_type == BallType.GameBoy then
    return 0
  else
    return 2
  end
end

function GetBallEffectDuration(ball_type)
  if ball_type == BallType.GameBoy then
    return gameboy_effect_duration
  else
    return 0
  end
end

function balls.spawn(x, y, lane, ball_type)
  local new_ball = setmetatable({}, { __index = balls })
  new_ball.x = x + Map.grid_size * 0.5;
  new_ball.y = y + Map.grid_size * 0.25;

  new_ball.type = ball_type;
  new_ball.damage = GetBallDamage(ball_type)
  new_ball.pierce = 0;
  if ball_type == BallType.GameBoy then
    new_ball.texture = Textures.gameboy_ball;
    new_ball.duration = gameboy_effect_duration;
    new_ball.pierce = GetPerkValue(PerkType.AdditionalpeirceGameboyBall, 0);
  else
    new_ball.texture = Textures.ball;
    new_ball.pierce = GetPerkValue(PerkType.AdditionalPeirceTennisBall, 0);
  end

  new_ball.width = new_ball.texture:getWidth();
  new_ball.height = new_ball.texture:getHeight();

  new_ball.velocity = { x = 200, y = 0 }
  new_ball.grid_y = lane;
  new_ball.total_duration = 0
  new_ball.taken_away = false;
  new_ball.entities_hit = {};

  table.insert(balls, new_ball);
end

function balls.update(aliens, dt)
  for idx, ball in ipairs(balls) do
    ball.x = ball.x + ball.velocity.x * dt;
    ball.y = ball.y + ball.velocity.y * dt;
    ball.total_duration = ball.total_duration + dt * 2.0;

    if ball.x > Map.map_bounds.x + Map.map_bounds.width then
      --table.remove(balls, idx);
      ball.taken_away = true;
      ball.velocity.x = 90.0;
      ball.velocity.y = -55.0;

      if ball.x > Map.map_bounds.x + Map.map_bounds.width * 2.0 then
        table.remove(balls, idx)
      end
      goto continue
    end

    for _, alien in ipairs(aliens) do
      if not TableContains(ball.entities_hit, alien) and alien.life > 0 and ball.grid_y == alien.grid_y and math.abs(ball.x - alien.x - alien.collision_box.offset_x) < alien.collision_box.width then
        alien:take_damage(ball.damage)
        if ball.type == BallType.GameBoy then
          alien:apply_gameboy_effect(ball.duration);
        end
        if ball.pierce > 0 then
          table.insert(ball.entities_hit, alien)
          ball.pierce = ball.pierce - 1;
        else
          table.remove(balls, idx)
        end
        break;
      end
    end
    ::continue::
  end
end

function balls.draw()
  for _, ball in ipairs(balls) do
    love.graphics.draw(ball.texture, ball.x, ball.y + 5.0 * math.sin(ball.total_duration - math.pi * 1.0))
    love.graphics.draw(Textures.ball_shadow, ball.x, ball.y + ball.texture:getHeight() * 1.1)
  end
end

return balls

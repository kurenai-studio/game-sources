local default_mag = 8.0;
local default_speed = 5.0;

local GameOverScreen = {
  alien = {
    x = 0,
    y = 12,
  },
  alien_goal = {
    x = 220,
    y = 12,
  },
  attack_times = 0,
  attack_timer = 1.0,
  delay_movement = 2.0,
  total_dt = 0.0,
  hover_speed = default_speed,
  hover_mag = default_mag,
  animation_over = false,
  background_alpha = 0.0,
  text_alpha = 0.0,
}

function GameOverScreen.load(camera)
  GameOverScreen.alien.x = 640.0;
end

function GameOverScreen.update(dt)
  if GameOverScreen.animation_over then
    if GameOverScreen.text_alpha < 1.0 then
      GameOverScreen.text_alpha = GameOverScreen.text_alpha + dt;
    end
  end
  if GameOverScreen.background_alpha < 1.0 then
    GameOverScreen.background_alpha = GameOverScreen.background_alpha + dt;
  end

  if GameOverScreen.alien.x < -Textures.game_over_alien:getWidth() then
    GameOverScreen.animation_over = true;
    return
  end

  GameOverScreen.total_dt = GameOverScreen.total_dt + GameOverScreen.hover_speed * dt;
  if GameOverScreen.delay_movement > 0 then
    GameOverScreen.delay_movement = GameOverScreen.delay_movement - dt;
  else
    GameOverScreen.alien.x = GameOverScreen.alien.x - dt * 150.0;
  end

  if GameOverScreen.attack_times < 5 and GameOverScreen.alien.x < GameOverScreen.alien_goal.x then
    GameOverScreen.alien.x = GameOverScreen.alien_goal.x;
    GameOverScreen.hover_speed = 1.0;

    GameOverScreen.attack_timer = GameOverScreen.attack_timer - dt;
    if GameOverScreen.attack_timer <= 0 then
      GameOverScreen.attack_times = GameOverScreen.attack_times + 1;
      GameOverScreen.attack_timer = 1.0
      if GameOverScreen.attack_times == 5 then
        GameOverScreen.delay_movement = 1;
        GameOverScreen.hover_speed = default_speed;
      end
    end
  end
end

function GameOverScreen.draw_ui()

end

function GameOverScreen.draw()
  love.graphics.setColor(1, 1, 1, GameOverScreen.background_alpha);
  love.graphics.draw(Textures.game_over_background, 0, 0)

  if GameOverScreen.attack_times < 5 then
    love.graphics.draw(Textures.game_over_earth, 264, 172)
  end

  love.graphics.draw(Textures.game_over_alien, GameOverScreen.alien.x,
    GameOverScreen.alien.y + GameOverScreen.hover_mag * math.sin(GameOverScreen.total_dt))

  if GameOverScreen.attack_times < 6 and GameOverScreen.attack_timer <= 0.5 then
    love.graphics.draw(Textures.game_over_alien_attack, GameOverScreen.alien.x,
      GameOverScreen.alien.y + GameOverScreen.hover_mag * math.sin(GameOverScreen.total_dt))
  end

  if GameOverScreen.animation_over then
    love.graphics.setColor(1, 1, 1, GameOverScreen.text_alpha);
    love.graphics.draw(Textures.game_over_text, 0, 0)
  end
end

function GameOverScreen.draw_text(camera, wave)
  if GameOverScreen.animation_over then
    love.graphics.setColor(1, 1, 1, GameOverScreen.text_alpha);
    love.graphics.setFont(PressStartFontBigBig)
    local text = string.gsub("Wave X", 'X', wave.wave_number);
    love.graphics.print(text, (Canvas:getWidth() * 0.5 - PressStartFontBigBig:getWidth(text) * 0.25) * camera.scale,
      274 * camera.scale)
    love.graphics.setFont(PressStartFont)
  end
end

return GameOverScreen;

local wave = {
  timer = 15.0,
  total_time = 0.0,

  enemy_max_spawn_wait = 5.0,
  spawn_timer_modifier = 1.0,

  wave_text = {},
  wave_number = 0,
  wave_timer = 20.0,
  wave_timer_cap = 15.0,
  wave_duration = 60,

  perk_selected = true
};

function wave.new(font)
  local new_wave = setmetatable({}, { __index = wave })

  wave.text = love.graphics.newText(font,
    { { 0.12, 0.13, 0.20 }, "Wave: " .. new_wave.wave_number }
  );

  return new_wave
end

function wave:update(camera, aliens, perk_cards, dt)
  if wave.wave_number > 0 and #aliens == 0 and self.wave_timer > 5 then
    self.wave_timer = 5.0;
    self.wave_timer_cap = self.wave_timer;
  end
  self.wave_timer = self.wave_timer - dt;
  if self.wave_timer <= 0 then
    self.wave_timer = self.wave_duration;
    self.wave_timer_cap = self.wave_timer;
    wave.wave_number = wave.wave_number + 1;
    wave.text:set({ { 0.12, 0.13, 0.20 }, "Wave: " .. wave.wave_number })
    self:spawn_wave(aliens);
    if wave.wave_number % 5 == 0 then
      GameSpeed = 0;
      -- show perks
      local perk_num = {}

      for i = 1, 3 do
        local idx = math.random(1, #Perks);

        while TableContains(perk_num, idx) do
          idx = math.random(1, #Perks);
        end

        perk_cards[i]:set_perk_index(camera, idx);
      end
    end
  end
end

function wave:spawn_wave(aliens)
  local number_of_aliens = math.random() * (5.0 * wave.wave_number) ^ 1.5; --* wave.wave_number;
  if wave.wave_number == 1 then
    number_of_aliens = 1;
  end

  number_of_aliens = math.ceil(number_of_aliens * 1.0 / GetPerkValue(PerkType.LessDensityAliens, 1.0));

  for i = 1, number_of_aliens do
    local lane = math.random(1, #Map.grid);

    local x, y = Map:get_xy_location(math.random(14, 14 + number_of_aliens), lane);

    x = x + math.random(0, 100)

    local texture = Textures.alien;

    -- Every second wave allow for up to +1 additional speed
    -- wave 1 = 3speed
    -- wave 2 = 3-4speed
    -- wave 3 = 3-4speed
    -- wave 4 = 3-5speed
    -- etc.
    local speed = math.min((3.0 + math.random() * math.floor(1.5 * wave.wave_number)), 30)
    -- plus 1 life per alien per 5 waves
    local life = 2 + math.random() * wave.wave_number

    y = y + math.random(-Map.grid_size * 0.25, Map.grid_size * 0.25)
    aliens.spawn(x, y, lane, texture, life, speed)
  end
end

function wave:draw(camera)
  local x = Canvas:getWidth() * 0.87 * camera.scale;
  local y = Canvas:getHeight() * 0.92 * camera.scale;
  local width = 80.0;
  love.graphics.draw(
    wave.text,
    x,
    y
  )
  love.graphics.setColor(0.1, 0.1, 0.5)
  love.graphics.rectangle("fill", x - 2.0, y + 15.0, width * (self.wave_timer / self.wave_timer_cap), 5.0)

  love.graphics.setColor(1.0, 1, 1)
end

return wave;

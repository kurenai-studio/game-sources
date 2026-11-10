local bunnies = {}

local attack_timer_value = 1.5;
local dandelion_drop_timer_value = 10.0;
local dandelion_value = 10
local attack_animation_value = 0.3;
local animation_magnitude = 3.0;

local pyon_damage = 1;
local pyon_attack_timer_value = 3.0;
local pyon_animation_magnitude = -20.0;
local pyon_knockback_distance = Map.grid_size * 2.0;

local dandelion_description =
"LIFE HP\nYield an average of ACTION dandelions per minute. The cost will increase with each dandelion on the field.";
local white_description = "LIFE HP\nThrows a tenis ball every ACTION second that deals DAMAGE HP damage an enemy.";
local pyon_description =
"LIFE HP\nVery cute, knockbacks an enemy close to her and deals DAMAGE HP damage every ACTION second."
local gameboy_description =
"LIFE HP\nThrows a gameboyified tennis ball every ACTION seconds, freezing all the enemies it's touching for ACTION2 seconds and dealing DAMAGE damage."

local function get_new_drop_timer()
  local timer = dandelion_drop_timer_value * (1.0 / GetPerkValue(PerkType.SpawnSpeedDandelion, 1.0));

  return math.random() * timer * 1.5 + timer * 0.5;
end

function GetBunnyLife(bunny_type)
  if bunny_type == BunnyType.Pyon then
    return 15
  else
    return 5
  end
end

function GetBunnyDamage(bunny_type)
  local ball_type = GetBunnyBallType(bunny_type);
  if ball_type then
    return GetBallDamage(ball_type)
  elseif bunny_type == BunnyType.Pyon then
    return pyon_damage
  else
    return ""
  end
end

function GetBunnyDescription(bunny_type)
  if bunny_type == BunnyType.Dandelion then
    return dandelion_description
  elseif bunny_type == BunnyType.White then
    return white_description
  elseif bunny_type == BunnyType.Pyon then
    return pyon_description
  elseif bunny_type == BunnyType.Gameboy then
    return gameboy_description
  else
    return "No Description"
  end
end

function GetBunnyTitle(bunny_type)
  if bunny_type == BunnyType.Dandelion then
    return "Dandelion"
  elseif bunny_type == BunnyType.White then
    return "White Bunny"
  elseif bunny_type == BunnyType.Pyon then
    return "Pyon"
  elseif bunny_type == BunnyType.Gameboy then
    return "Gameboy Bunny"
  else
    return "No Description"
  end
end

function GetBunnyBallType(bunny_type)
  if bunny_type == BunnyType.Dandelion then
    return nil
  elseif bunny_type == BunnyType.White then
    return BallType.Normal
  elseif bunny_type == BunnyType.Pyon then
    return nil
  elseif bunny_type == BunnyType.Gameboy then
    return BallType.GameBoy
  else
    return nil
  end
end

function GetBunnyAction(bunny_type)
  if bunny_type == BunnyType.Dandelion then
    return 60 / dandelion_drop_timer_value
  elseif bunny_type == BunnyType.White then
    return attack_timer_value
  elseif bunny_type == BunnyType.Pyon then
    return pyon_attack_timer_value
  elseif bunny_type == BunnyType.Gameboy then
    return attack_timer_value
  else
    return ""
  end
end

function GetBunnyAction2(bunny_type)
  local ball_type = GetBunnyBallType(bunny_type);
  if ball_type then
    return GetBallEffectDuration(ball_type)
  else
    return ""
  end
end

local function get_bunny_texture(bunny_type)
  if bunny_type == BunnyType.Dandelion then
    return Textures.dandelion
  elseif bunny_type == BunnyType.White then
    return Textures.white_bunny
  elseif bunny_type == BunnyType.Pyon then
    return Textures.pyon_bunny
  elseif bunny_type == BunnyType.Gameboy then
    return Textures.gameboy_bunny
  else
    return nil
  end
end

function bunnies.spawn(grid_x, grid_y, bunny_type)
  Map:fill_location(grid_x, grid_y);
  local bx, by = Map:get_xy_location(grid_x, grid_y);

  local new_bunny = setmetatable({}, { __index = bunnies })
  new_bunny.x = bx
  new_bunny.y = by
  new_bunny.grid_x = grid_x
  new_bunny.grid_y = grid_y

  new_bunny.animation = 0

  bunnies.spawn_bunny(new_bunny, bunny_type)

  table.insert(bunnies, new_bunny)
end

function bunnies.spawn_bunny(new_bunny, bunny_type)
  new_bunny.type = bunny_type;
  new_bunny.texture = get_bunny_texture(bunny_type);
  new_bunny.life = GetBunnyLife(bunny_type)

  if bunny_type == BunnyType.Dandelion then
    new_bunny.drop_timer = get_new_drop_timer();
    DandelionCost = DandelionCost + 10
  elseif bunny_type == BunnyType.White then
    new_bunny.attack_timer = 0.0;         --attack_timer_value;
    new_bunny.attack_animation_timer = 0; --attack_animation_value;
    new_bunny.animtation = 0.0;
    new_bunny.animation_magnitude = animation_magnitude;
  elseif bunny_type == BunnyType.Pyon then
    new_bunny.attack_timer = 0;           --pyon_attack_timer_value;
    new_bunny.attack_animation_timer = 0; --attack_animation_value;
    new_bunny.animation_magnitude = pyon_animation_magnitude;
  elseif bunny_type == BunnyType.Gameboy then
    new_bunny.attack_timer = 0.0;         --attack_timer_value;
    new_bunny.attack_animation_timer = 0; --attack_animation_value;
    new_bunny.animtation = 0.0;
    new_bunny.animation_magnitude = animation_magnitude;
  elseif bunny_type == BunnyType.Gameboy then
  else
    return nil
  end
end

function bunnies.attack_grid_xy(grid_x, grid_y)
  for idx, bunny in ipairs(bunnies) do
    if bunny.grid_x == grid_x and bunny.grid_y == grid_y then
      bunny.life = bunny.life - 1;
      if bunny.life <= 0 then
        Map:empty_location(grid_x, grid_y);
        if bunny.type == BunnyType.Dandelion then
          DandelionCost = DandelionCost - 10;
        end
        table.remove(bunnies, idx);
      end
    end
  end
end

function bunnies.update(aliens, balls, dandelions, dt)
  for i, bunny in ipairs(bunnies) do
    if bunny.type == BunnyType.White then
      bunny:update_white(aliens, balls, dt);
    elseif bunny.type == BunnyType.Dandelion then
      bunny:update_dandelion(dandelions, dt)
    elseif bunny.type == BunnyType.Pyon then
      bunny:update_pyon(aliens, dt);
    elseif bunny.type == BunnyType.Gameboy then
      bunny:update_gameboy(aliens, balls, dt);
    end
  end
end

function bunnies:update_pyon(aliens, dt)
  if self.attack_animation_timer > 0.0 then
    self.animation = self.animation + dt;
    self.attack_animation_timer = self.attack_animation_timer - dt;
    if self.attack_animation_timer <= 0 then
      self.animation = 0;
    end
  end

  for _, alien in ipairs(aliens) do
    if self.grid_y == alien.grid_y and self.x - self.texture:getWidth() * 0.3 < alien.x and alien.x < Map.map_bounds.x + Map.map_bounds.width then
      if alien.x < self.x + Map.grid_size * 1.5 then
        self.attack_timer = self.attack_timer - dt;
        if self.attack_timer <= 0.0 then
          --Attack
          self.attack_timer = pyon_attack_timer_value * (1.0 / GetPerkValue(PerkType.AttackSpeedPyon, 1.0));
          self.attack_animation_timer = attack_animation_value;
          local distance = GetPerkValue(PerkType.KnockBackDistancePyon, pyon_knockback_distance)
          alien:knock_back(distance);
          alien:take_damage(pyon_damage);
        end
        break;
      end
    end
  end
end

function bunnies:update_dandelion(dandelions, dt)
  self.drop_timer = self.drop_timer - dt;
  if self.drop_timer <= 0.0 then
    -- drop dandelion
    dandelions.new(self.x + self.texture:getWidth() * 0.5, self.y, dandelion_value);
    self.drop_timer = get_new_drop_timer();
  end
end

function bunnies:update_white(aliens, balls, dt)
  if self.attack_animation_timer > 0.0 then
    self.animation = self.animation + dt;
    self.attack_animation_timer = self.attack_animation_timer - dt;
    if self.attack_animation_timer <= 0 then
      self.animation = 0;
    end
  end


  for _, alien in ipairs(aliens) do
    if self.grid_y == alien.grid_y and self.x - self.texture:getWidth() * 0.3 < alien.x and alien.x < Map.map_bounds.x + Map.map_bounds.width then
      self.attack_timer = self.attack_timer - dt;
      if self.attack_timer <= 0.0 then
        --Attack
        balls.spawn(self.x, self.y + math.random(-3, 3), self.grid_y, BallType.Normal);
        self.attack_timer = attack_timer_value * (1.0 / GetPerkValue(PerkType.AttackSpeedWhite, 1.0))

        self.attack_animation_timer = attack_animation_value;
      end
      break;
    end
  end
end

function bunnies:update_gameboy(aliens, balls, dt)
  if self.attack_animation_timer > 0.0 then
    self.animation = self.animation + dt;
    self.attack_animation_timer = self.attack_animation_timer - dt;
    if self.attack_animation_timer <= 0 then
      self.animation = 0;
    end
  end


  for _, alien in ipairs(aliens) do
    if self.grid_y == alien.grid_y and self.x - self.texture:getWidth() * 0.3 < alien.x and alien.x < Map.map_bounds.x + Map.map_bounds.width then
      self.attack_timer = self.attack_timer - dt;
      if self.attack_timer <= 0.0 then
        --Attack
        balls.spawn(self.x, self.y + math.random(-3, 3), self.grid_y, BallType.GameBoy);
        self.attack_timer = attack_timer_value * (1.0 / GetPerkValue(PerkType.AttackSpeedGameboy, 1.0))
        self.attack_animation_timer = attack_animation_value;
      end
      break;
    end
  end
end

function bunnies.draw()
  for _, bunny in ipairs(bunnies) do
    if bunny.type == BunnyType.Dandelion then
      love.graphics.draw(bunny.texture, bunny.x, bunny.y)
    else
      if bunny.attack_animation_timer > 0.0 then
        love.graphics.draw(bunny.texture,
          bunny.x - (bunny.animation_magnitude - bunny.animation_magnitude * math.sin(bunny.animation)), bunny.y)
      else
        love.graphics.draw(bunny.texture, bunny.x, bunny.y)
      end
    end
  end
end

return bunnies;

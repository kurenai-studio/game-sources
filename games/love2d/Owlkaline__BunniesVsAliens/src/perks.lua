PerkValue = {}
PerkValue.__index = PerkValue

function PerkValue.new(perk_type, scale_type)
  local new_perk = setmetatable({}, PerkValue)

  new_perk.type = perk_type
  new_perk.scale = scale_type
  new_perk.level = 0
  new_perk.percent = 100
  new_perk.flat = 0

  return new_perk
end

function PerkValue:calculate_final_value(value)
  if self.scale == PerkScalingType.Percentage then
    return value * self.percent * 0.01;
  else
    return value + self.flat
  end
end

function PerkValue:upgrade()
  self.level = self.level + 1;
  if self.scale == PerkScalingType.Percentage then
    self.percent = self.percent + PerkValue.percent_at_level(self.level);
  else
    self.flat = self.level;
  end
end

--function PerkValue.percent_at_level(level)
--  return (level * level / 3000) + 10;
--end

function PerkValue.percent_at_level(n)
  if n == 0 then
    return 100
  else
    local current_percent = PerkValue.percent_at_level(n - 1);
    if current_percent > 1000000 then
      return 9999999999
    end

    local overall_percent = current_percent + (current_percent ^ 2 / 3000) + 10
    return overall_percent;
  end
end

function PerkValue:get_perk_details()
  local value = 1;
  local suffix = "";

  if self.scale == PerkScalingType.Percentage then
    value = 100.0
    suffix = "%"
  end

  local current = "\nCurrent: " .. GetPerkValue(self.type, value) .. suffix;
  if self.type == PerkType.AdditionalPeirceTennisBall then
    return "Tennis Ball", "+1 Pierce", current
  elseif self.type == PerkType.AdditionalpeirceGameboyBall then
    return "Gameboy Ball", "+1 Pierce", current
  elseif self.type == PerkType.AttackSpeedGameboy then
    return "Gameboy Bunny", "+X% attack speed", current
  elseif self.type == PerkType.AttackSpeedPyon then
    return "Pyon Bunny", "+X% attack speed", current
  elseif self.type == PerkType.AttackSpeedWhite then
    return "White Bunny", "+X% attack speed", current
  elseif self.type == PerkType.KnockBackDistancePyon then
    return "Pyon Bunny", "+X% Knock back distance", current
  elseif self.type == PerkType.LessDensityAliens then
    return "Aliens", "X% less density", current
  elseif self.type == PerkType.SpawnSpeedDandelion then
    return "Dandelions", "+X% spawn speed", current
  else
    return "Title", "Description", current
  end
end

PerkType = {
  AttackSpeedPyon = 0,
  AttackSpeedWhite = 1,
  AttackSpeedGameboy = 2,
  SpawnSpeedDandelion = 3,
  LessDensityAliens = 4,
  KnockBackDistancePyon = 5,
  AdditionalPeirceTennisBall = 6,
  AdditionalpeirceGameboyBall = 7,
}

PerkScalingType = {
  Flat = 0,
  Percentage = 1,
}

function GetPerkValue(perk_type, value)
  for _, perk in ipairs(Perks) do
    if perk.type == perk_type then
      return perk:calculate_final_value(value)
    end
  end

  return nil
end

Perks = {
  PerkValue.new(PerkType.AdditionalPeirceTennisBall, PerkScalingType.Flat),
  PerkValue.new(PerkType.AdditionalpeirceGameboyBall, PerkScalingType.Flat),
  PerkValue.new(PerkType.AttackSpeedGameboy, PerkScalingType.Percentage),
  PerkValue.new(PerkType.AttackSpeedPyon, PerkScalingType.Percentage),
  PerkValue.new(PerkType.AttackSpeedWhite, PerkScalingType.Percentage),
  PerkValue.new(PerkType.KnockBackDistancePyon, PerkScalingType.Percentage),
  PerkValue.new(PerkType.LessDensityAliens, PerkScalingType.Percentage),
  PerkValue.new(PerkType.SpawnSpeedDandelion, PerkScalingType.Percentage),
  --  AutoCollectDandelions             = false,
  --AdditionalPeirceForTennisBall     = 0,
  --AdditionalPeirceForGameboyBall    = 0,
  --PercentKnockBackDistance          = PercentPerk.new(),
  --PercentAttackSpeedIncreasePyon    = PercentPerk.new(),
  --PercentAttackSpeedIncreaseWhite   = PercentPerk.new(),
  --PercentAttackSpeedIncreaseGameBoy = PercentPerk.new(),
  --PercentLessEnemyDesnity           = PercentPerk.new(),
  --AdditionalLifeDandelion              = {
  --  level = 0,
  --  additional = 0,
  --},
  --AdditionalLifePyon                   = {
  --  level = 0,
  --  additional = 0,
  --},
  --AdditionalLifeWhite                  = {
  --  level = 0,
  --  additional = 0,
  --},
  --AdditionalLifeGameboy                = {
  --  level = 0,
  --  additional = 0,
  --},
  --  ExtraLife                         = 0, -- Every 10min
}

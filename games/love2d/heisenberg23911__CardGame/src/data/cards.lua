--[[
Card Data Definitions

Data-driven card definitions using Lua tables. Each card defines its
properties, abilities, and visual information separately from game logic.

Schema format:
{
  id = "unique_card_identifier",
  name = "Display Name",
  description = "Card description text",
  cost = mana_cost_number,
  type = "creature|spell|artifact|enchantment",
  
  -- Stats (for creatures)
  attack = attack_value,
  health = health_value,
  
  -- Abilities
  abilities = {
    "ability_name_1",
    "ability_name_2"
  },
  
  -- Visual properties
  artwork = "texture_atlas_key",
  rarity = "common|uncommon|rare|epic|legendary",
  
  -- Metadata
  collectible = true/false,
  set = "set_name",
  flavor_text = "Optional flavor text"
}
--]]

local Cards = {}

-- Card definitions organized by set/category
Cards.basic_set = {
  -- Starter creatures
  {
    id = "fire_sprite",
    name = "Fire Sprite",
    description = "A small elemental creature that deals burn damage.",
    cost = 1,
    type = "creature",
    attack = 1,
    health = 1,
    abilities = {"burn"},
    artwork = "fire_sprite",
    rarity = "common",
    collectible = true,
    set = "basic",
    flavor_text = "Born from ember, destined for flame."
  },
  
  {
    id = "water_elemental",
    name = "Water Elemental",
    description = "Fluid defender with regeneration abilities.",
    cost = 2,
    type = "creature", 
    attack = 1,
    health = 3,
    abilities = {"regenerate"},
    artwork = "water_elemental",
    rarity = "common",
    collectible = true,
    set = "basic",
    flavor_text = "Ever-flowing, ever-healing."
  },
  
  {
    id = "earth_guardian",
    name = "Earth Guardian",
    description = "Sturdy protector with high defense.",
    cost = 3,
    type = "creature",
    attack = 2,
    health = 5,
    abilities = {"taunt", "armor"},
    artwork = "earth_guardian",
    rarity = "uncommon",
    collectible = true,
    set = "basic",
    flavor_text = "Mountains bend to its will."
  },
  
  {
    id = "air_wisp",
    name = "Air Wisp",
    description = "Swift creature that can bypass ground defenses.",
    cost = 2,
    type = "creature",
    attack = 3,
    health = 1,
    abilities = {"flying", "haste"},
    artwork = "air_wisp",
    rarity = "common",
    collectible = true,
    set = "basic",
    flavor_text = "Here one moment, gone the next."
  },
  
  -- Spells
  {
    id = "lightning_bolt",
    name = "Lightning Bolt",
    description = "Deal 3 damage to target creature or player.",
    cost = 1,
    type = "spell",
    abilities = {"direct_damage"},
    artwork = "lightning_bolt",
    rarity = "common",
    collectible = true,
    set = "basic",
    flavor_text = "Nature's own conductor."
  },
  
  {
    id = "healing_potion",
    name = "Healing Potion",
    description = "Restore 5 health to target creature or player.",
    cost = 1,
    type = "spell",
    abilities = {"heal"},
    artwork = "healing_potion",
    rarity = "common",
    collectible = true,
    set = "basic",
    flavor_text = "Life in liquid form."
  },
  
  {
    id = "fireball",
    name = "Fireball",
    description = "Deal 4 damage to target and 2 damage to adjacent targets.",
    cost = 3,
    type = "spell",
    abilities = {"area_damage"},
    artwork = "fireball",
    rarity = "uncommon",
    collectible = true,
    set = "basic",
    flavor_text = "Sometimes the direct approach is best."
  },
  
  -- Artifacts and Enchantments
  {
    id = "crystal_blade",
    name = "Crystal Blade",
    description = "Equip creature: +2 Attack. When equipped creature dies, deal 2 damage to random enemy.",
    cost = 2,
    type = "artifact",
    abilities = {"equipment", "deathrattle"},
    artwork = "crystal_blade",
    rarity = "rare",
    collectible = true,
    set = "basic",
    flavor_text = "Forged in the heart of a dying star."
  },
  
  {
    id = "mana_crystal",
    name = "Mana Crystal", 
    description = "Gain +1 mana per turn.",
    cost = 1,
    type = "artifact",
    abilities = {"mana_ramp"},
    artwork = "mana_crystal",
    rarity = "common",
    collectible = true,
    set = "basic",
    flavor_text = "Power crystallized."
  },
  
  {
    id = "shield_of_valor",
    name = "Shield of Valor",
    description = "All friendly creatures gain +0/+2.",
    cost = 2,
    type = "enchantment",
    abilities = {"global_buff"},
    artwork = "shield_of_valor",
    rarity = "uncommon",
    collectible = true,
    set = "basic",
    flavor_text = "Courage made manifest."
  }
}

Cards.advanced_set = {
  -- Legendary creatures
  {
    id = "dragon_lord",
    name = "Dragon Lord Pyraxis",
    description = "Flying. When played, deal 2 damage to all enemies. While alive, your spells deal +1 damage.",
    cost = 7,
    type = "creature",
    attack = 8,
    health = 8,
    abilities = {"flying", "battlecry", "spell_power"},
    artwork = "dragon_lord",
    rarity = "legendary",
    collectible = true,
    set = "advanced",
    flavor_text = "The sky bends to his will, the earth trembles at his roar."
  },
  
  {
    id = "phoenix_rebirth",
    name = "Phoenix of Rebirth",
    description = "When this creature dies, return it to your hand with +1/+1.",
    cost = 4,
    type = "creature",
    attack = 3,
    health = 2,
    abilities = {"flying", "rebirth"},
    artwork = "phoenix_rebirth",
    rarity = "epic",
    collectible = true,
    set = "advanced",
    flavor_text = "Death is but another beginning."
  },
  
  -- Complex spells
  {
    id = "time_warp",
    name = "Time Warp",
    description = "Take an extra turn after this one.",
    cost = 8,
    type = "spell",
    abilities = {"extra_turn"},
    artwork = "time_warp",
    rarity = "epic",
    collectible = true,
    set = "advanced",
    flavor_text = "Time is the ultimate currency."
  },
  
  {
    id = "chain_lightning",
    name = "Chain Lightning",
    description = "Deal 2 damage to target, then to 2 random other enemies for 1 damage each.",
    cost = 2,
    type = "spell",
    abilities = {"chain_damage"},
    artwork = "chain_lightning",
    rarity = "rare",
    collectible = true,
    set = "advanced",
    flavor_text = "Lightning seeks the path of least resistance."
  }
}

-- Non-collectible cards (tokens, generated cards)
Cards.tokens = {
  {
    id = "spark_token",
    name = "Spark",
    description = "A small burst of elemental energy.",
    cost = 0,
    type = "creature",
    attack = 1,
    health = 1,
    abilities = {},
    artwork = "spark_token",
    rarity = "token",
    collectible = false,
    set = "tokens"
  },
  
  {
    id = "treasure_token",
    name = "Treasure",
    description = "Sacrifice: Gain 1 mana this turn.",
    cost = 0,
    type = "artifact",
    abilities = {"sacrifice_mana"},
    artwork = "treasure_token",
    rarity = "token", 
    collectible = false,
    set = "tokens"
  }
}

-- Utility functions for card management
function Cards.getAllCards()
  local all_cards = {}
  
  -- Combine all sets
  for set_name, set_cards in pairs(Cards) do
    if type(set_cards) == "table" and set_name ~= "getAllCards" and 
       set_name ~= "getCardById" and set_name ~= "getCardsByType" and
       set_name ~= "getCardsByRarity" and set_name ~= "getCardsBySet" then
      for _, card in ipairs(set_cards) do
        table.insert(all_cards, card)
      end
    end
  end
  
  return all_cards
end

function Cards.getCardById(card_id)
  local all_cards = Cards.getAllCards()
  for _, card in ipairs(all_cards) do
    if card.id == card_id then
      return card
    end
  end
  return nil
end

function Cards.getCardsByType(card_type)
  local filtered_cards = {}
  local all_cards = Cards.getAllCards()
  
  for _, card in ipairs(all_cards) do
    if card.type == card_type then
      table.insert(filtered_cards, card)
    end
  end
  
  return filtered_cards
end

function Cards.getCardsByRarity(rarity)
  local filtered_cards = {}
  local all_cards = Cards.getAllCards()
  
  for _, card in ipairs(all_cards) do
    if card.rarity == rarity then
      table.insert(filtered_cards, card)
    end
  end
  
  return filtered_cards
end

function Cards.getCardsBySet(set_name)
  return Cards[set_name] or {}
end

function Cards.getCollectibleCards()
  local collectible_cards = {}
  local all_cards = Cards.getAllCards()
  
  for _, card in ipairs(all_cards) do
    if card.collectible then
      table.insert(collectible_cards, card)
    end
  end
  
  return collectible_cards
end

-- Deep copy function for card instances
function Cards.copyCard(card)
  local copy = {}
  for key, value in pairs(card) do
    if type(value) == "table" then
      copy[key] = {}
      for k, v in pairs(value) do
        copy[key][k] = v
      end
    else
      copy[key] = value
    end
  end
  return copy
end

-- Validation function to check card schema
function Cards.validateCard(card)
  local required_fields = {"id", "name", "cost", "type"}
  
  for _, field in ipairs(required_fields) do
    if not card[field] then
      return false, "Missing required field: " .. field
    end
  end
  
  -- Type-specific validation
  if card.type == "creature" then
    if not card.attack or not card.health then
      return false, "Creature cards must have attack and health values"
    end
  end
  
  -- Cost validation
  if type(card.cost) ~= "number" or card.cost < 0 then
    return false, "Card cost must be a non-negative number"
  end
  
  return true, "Valid card"
end

return Cards

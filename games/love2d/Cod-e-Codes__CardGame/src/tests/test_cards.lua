--[[
Card System Tests

Unit tests for the card data system, validation, and utilities.
--]]

local Cards = require('data.cards')
local TestRunner = require('tests.test_runner')

local CardTests = {}

function CardTests.test_get_all_cards()
    local all_cards = Cards.getAllCards()
    
    TestRunner.assertNotNil(all_cards, "getAllCards should return a table")
    TestRunner.assertType(all_cards, "table", "getAllCards should return a table")
    TestRunner.assert(#all_cards > 0, "Should have at least one card")
    
    -- Check that all items are card tables
    for i, card in ipairs(all_cards) do
        TestRunner.assertType(card, "table", "Card " .. i .. " should be a table")
        TestRunner.assertNotNil(card.id, "Card " .. i .. " should have an id")
        TestRunner.assertNotNil(card.name, "Card " .. i .. " should have a name")
    end
end

function CardTests.test_get_card_by_id()
    local fire_sprite = Cards.getCardById("fire_sprite")
    
    TestRunner.assertNotNil(fire_sprite, "Should find fire_sprite card")
    TestRunner.assertEqual(fire_sprite.id, "fire_sprite", "Card ID should match")
    TestRunner.assertEqual(fire_sprite.name, "Fire Sprite", "Card name should match")
    TestRunner.assertEqual(fire_sprite.cost, 1, "Fire sprite should cost 1 mana")
    
    -- Test non-existent card
    local fake_card = Cards.getCardById("nonexistent_card")
    TestRunner.assert(fake_card == nil, "Should return nil for non-existent card")
end

function CardTests.test_get_cards_by_type()
    local creatures = Cards.getCardsByType("creature")
    local spells = Cards.getCardsByType("spell")
    local artifacts = Cards.getCardsByType("artifact")
    
    TestRunner.assertType(creatures, "table", "Should return table for creatures")
    TestRunner.assertType(spells, "table", "Should return table for spells")
    TestRunner.assertType(artifacts, "table", "Should return table for artifacts")
    
    TestRunner.assert(#creatures > 0, "Should have at least one creature")
    TestRunner.assert(#spells > 0, "Should have at least one spell")
    TestRunner.assert(#artifacts > 0, "Should have at least one artifact")
    
    -- Verify all returned cards have the correct type
    for _, card in ipairs(creatures) do
        TestRunner.assertEqual(card.type, "creature", "All creatures should have type 'creature'")
    end
    
    for _, card in ipairs(spells) do
        TestRunner.assertEqual(card.type, "spell", "All spells should have type 'spell'")
    end
end

function CardTests.test_get_cards_by_rarity()
    local common_cards = Cards.getCardsByRarity("common")
    local rare_cards = Cards.getCardsByRarity("rare")
    
    TestRunner.assertType(common_cards, "table", "Should return table for common cards")
    TestRunner.assertType(rare_cards, "table", "Should return table for rare cards")
    
    TestRunner.assert(#common_cards > 0, "Should have at least one common card")
    TestRunner.assert(#rare_cards > 0, "Should have at least one rare card")
    
    -- Verify rarities
    for _, card in ipairs(common_cards) do
        TestRunner.assertEqual(card.rarity, "common", "All cards should have rarity 'common'")
    end
    
    for _, card in ipairs(rare_cards) do
        TestRunner.assertEqual(card.rarity, "rare", "All cards should have rarity 'rare'")
    end
end

function CardTests.test_get_collectible_cards()
    local collectible = Cards.getCollectibleCards()
    
    TestRunner.assertType(collectible, "table", "Should return table")
    TestRunner.assert(#collectible > 0, "Should have collectible cards")
    
    -- Verify all returned cards are collectible
    for _, card in ipairs(collectible) do
        TestRunner.assertEqual(card.collectible, true, "All cards should be collectible")
    end
end

function CardTests.test_copy_card()
    local original = Cards.getCardById("fire_sprite")
    TestRunner.assertNotNil(original, "Should find original card")
    
    local copy = Cards.copyCard(original)
    
    TestRunner.assertNotNil(copy, "Copy should not be nil")
    TestRunner.assert(copy ~= original, "Copy should be a different object")
    TestRunner.assertEqual(copy.id, original.id, "Copy should have same id")
    TestRunner.assertEqual(copy.name, original.name, "Copy should have same name")
    TestRunner.assertEqual(copy.cost, original.cost, "Copy should have same cost")
    
    -- Test that modifying copy doesn't affect original
    copy.name = "Modified Name"
    TestRunner.assert(original.name ~= copy.name, "Original should be unchanged")
end

function CardTests.test_validate_card()
    -- Test valid card
    local valid_card = {
        id = "test_card",
        name = "Test Card",
        cost = 3,
        type = "creature",
        attack = 2,
        health = 3,
        description = "A test card"
    }
    
    local is_valid, message = Cards.validateCard(valid_card)
    TestRunner.assertEqual(is_valid, true, "Valid card should pass validation: " .. (message or ""))
    
    -- Test card missing required field
    local invalid_card = {
        name = "Incomplete Card",
        cost = 2
        -- Missing id and type
    }
    
    local is_invalid, error_message = Cards.validateCard(invalid_card)
    TestRunner.assertEqual(is_invalid, false, "Incomplete card should fail validation")
    TestRunner.assertNotNil(error_message, "Should provide error message")
    
    -- Test creature without attack/health
    local invalid_creature = {
        id = "invalid_creature",
        name = "Invalid Creature", 
        cost = 1,
        type = "creature"
        -- Missing attack and health
    }
    
    local is_creature_invalid, creature_message = Cards.validateCard(invalid_creature)
    TestRunner.assertEqual(is_creature_invalid, false, "Creature without stats should fail")
    TestRunner.assertNotNil(creature_message, "Should provide creature-specific error message")
    
    -- Test negative cost
    local negative_cost_card = {
        id = "negative_cost",
        name = "Negative Cost Card",
        cost = -1,
        type = "spell"
    }
    
    local is_negative_invalid = Cards.validateCard(negative_cost_card)
    TestRunner.assertEqual(is_negative_invalid, false, "Negative cost should fail validation")
end

function CardTests.test_card_schema_consistency()
    local all_cards = Cards.getAllCards()
    
    for _, card in ipairs(all_cards) do
        local is_valid, message = Cards.validateCard(card)
        TestRunner.assertEqual(is_valid, true, 
            "Card '" .. (card.id or "unknown") .. "' should be valid: " .. (message or ""))
        
        -- Check required fields
        TestRunner.assertType(card.id, "string", "Card ID should be string")
        TestRunner.assertType(card.name, "string", "Card name should be string")
        TestRunner.assertType(card.cost, "number", "Card cost should be number")
        TestRunner.assertType(card.type, "string", "Card type should be string")
        
        -- Check type-specific fields
        if card.type == "creature" then
            TestRunner.assertType(card.attack, "number", "Creature attack should be number")
            TestRunner.assertType(card.health, "number", "Creature health should be number")
        end
        
        -- Check optional fields
        if card.abilities then
            TestRunner.assertType(card.abilities, "table", "Abilities should be table")
        end
        
        if card.description then
            TestRunner.assertType(card.description, "string", "Description should be string")
        end
    end
end

function CardTests.test_card_sets()
    local basic_cards = Cards.getCardsBySet("basic_set")
    local advanced_cards = Cards.getCardsBySet("advanced_set")
    local token_cards = Cards.getCardsBySet("tokens")
    
    TestRunner.assertType(basic_cards, "table", "Basic set should be table")
    TestRunner.assertType(advanced_cards, "table", "Advanced set should be table")
    TestRunner.assertType(token_cards, "table", "Token set should be table")
    
    TestRunner.assert(#basic_cards > 0, "Should have basic cards")
    TestRunner.assert(#advanced_cards > 0, "Should have advanced cards")
    TestRunner.assert(#token_cards > 0, "Should have token cards")
    
    -- Verify set consistency
    for _, card in ipairs(basic_cards) do
        TestRunner.assertEqual(card.set, "basic", "Basic cards should have 'basic' set")
    end
    
    for _, card in ipairs(advanced_cards) do
        TestRunner.assertEqual(card.set, "advanced", "Advanced cards should have 'advanced' set")
    end
end

function CardTests.test_unique_card_ids()
    local all_cards = Cards.getAllCards()
    local seen_ids = {}
    
    for _, card in ipairs(all_cards) do
        TestRunner.assert(not seen_ids[card.id], 
            "Card ID '" .. card.id .. "' should be unique")
        seen_ids[card.id] = true
    end
end

function CardTests.test_cost_ranges()
    local all_cards = Cards.getAllCards()
    
    for _, card in ipairs(all_cards) do
        TestRunner.assert(card.cost >= 0, 
            "Card '" .. card.id .. "' should have non-negative cost")
        TestRunner.assert(card.cost <= 20, 
            "Card '" .. card.id .. "' should have reasonable cost (<=20)")
    end
end

function CardTests.test_creature_stats()
    local creatures = Cards.getCardsByType("creature")
    
    for _, creature in ipairs(creatures) do
        TestRunner.assert(creature.attack >= 0, 
            "Creature '" .. creature.id .. "' should have non-negative attack")
        TestRunner.assert(creature.health >= 1, 
            "Creature '" .. creature.id .. "' should have positive health")
        TestRunner.assert(creature.attack <= 20, 
            "Creature '" .. creature.id .. "' should have reasonable attack")
        TestRunner.assert(creature.health <= 20, 
            "Creature '" .. creature.id .. "' should have reasonable health")
    end
end

return CardTests

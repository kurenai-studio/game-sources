--[[
Quick Framework Test

Simple test to verify the framework loads and runs without errors.
Run with: love . --test
--]]

-- Test basic module loading
local function testModuleLoading()
    print("Testing module loading...")
    
    local modules = {
        "lib.utils",
        "lib.animation", 
        "lib.layout",
        "lib.input",
        "lib.scene_manager",
        "lib.card_renderer",
        "lib.audio_manager",
        "data.cards",
        "data.atlas_config"
    }
    
    for _, module_name in ipairs(modules) do
        local success, module = pcall(require, module_name)
        if success then
            print("✓ " .. module_name .. " loaded successfully")
        else
            print("✗ " .. module_name .. " failed to load: " .. tostring(module))
            return false
        end
    end
    
    return true
end

-- Test basic functionality
local function testBasicFunctionality()
    print("\nTesting basic functionality...")
    
    -- Test Utils
    local Utils = require('lib.utils')
    Utils.setSeed(12345)
    local random_val = Utils.random()
    assert(random_val >= 0 and random_val < 1, "Random value should be in [0,1)")
    print("✓ Utils RNG working")
    
    -- Test Cards
    local Cards = require('data.cards')
    local all_cards = Cards.getAllCards()
    assert(#all_cards > 0, "Should have cards loaded")
    print("✓ Cards loaded: " .. #all_cards .. " cards")
    
    -- Test Animation
    local Animation = require('lib.animation')
    local test_obj = {x = 0, y = 0}
    local tween = Animation.Tween:new(test_obj, 1.0, {x = 100}, Animation.Easing.linear)
    assert(tween ~= nil, "Should create tween")
    print("✓ Animation system working")
    
    -- Test Layout
    local Layout = require('lib.layout')
    local container = Layout.Container:new(0, 0, 100, 100)
    assert(container ~= nil, "Should create container")
    print("✓ Layout system working")
    
    return true
end

-- Main test function
local function runTests()
    -- Check if we have the full test suite
    local has_full_suite = love.filesystem.getInfo("tests/test_runner.lua") ~= nil
    
    if has_full_suite then
        -- Run comprehensive test suite
        local TestRunner = require('tests.test_runner')
        return TestRunner.runAll()
    else
        -- Fall back to basic tests
        print("=== Love2D Card Game Framework Basic Test ===\n")
        
        local success = true
        
        success = success and testModuleLoading()
        success = success and testBasicFunctionality()
        
        print("\n=== Test Results ===")
        if success then
            print("✓ Basic tests passed! Framework core is working.")
            print("Run 'love .' to start the game.")
            print("Note: Install full test suite in tests/ directory for comprehensive testing.")
        else
            print("✗ Some basic tests failed. Check the errors above.")
        end
        
        return success
    end
end

-- Check if running as test
local function shouldRunTests()
    -- Check command line arguments
    if arg then
        for i, argument in ipairs(arg) do
            if argument == "--test" then
                return true
            end
        end
    end
    
    -- Check Love2D arguments
    if love.arg then
        for i, argument in ipairs(love.arg) do
            if argument == "--test" then
                return true
            end
        end
    end
    
    return false
end

if shouldRunTests() then
    local success = runTests()
    love.event.quit(success and 0 or 1)
else
    return {
        runTests = runTests
    }
end

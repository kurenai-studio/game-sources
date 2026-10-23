--[[
Utility System Tests

Tests for math functions, RNG, table operations, and helper utilities.
--]]

local Utils = require('lib.utils')
local TestRunner = require('tests.test_runner')

local UtilsTests = {}

-- RNG Tests
function UtilsTests.test_rng_deterministic()
    local rng1 = Utils.RNG:new(12345)
    local rng2 = Utils.RNG:new(12345)
    
    -- Same seed should produce same sequence
    for i = 1, 10 do
        local val1 = rng1:random()
        local val2 = rng2:random()
        TestRunner.assertEqual(val1, val2, "Same seed should produce same random values")
    end
end

function UtilsTests.test_rng_range()
    local rng = Utils.RNG:new(54321)
    
    -- Test random() returns values in [0, 1)
    for i = 1, 100 do
        local val = rng:random()
        TestRunner.assert(val >= 0 and val < 1, "random() should return value in [0, 1)")
    end
    
    -- Test randomInt returns integers in specified range
    for i = 1, 100 do
        local val = rng:randomInt(5, 15)
        TestRunner.assertType(val, "number", "randomInt should return number")
        TestRunner.assert(val == math.floor(val), "randomInt should return integer")
        TestRunner.assert(val >= 5 and val <= 15, "randomInt should be in specified range")
    end
    
    -- Test randomFloat returns floats in specified range
    for i = 1, 100 do
        local val = rng:randomFloat(2.5, 7.5)
        TestRunner.assert(val >= 2.5 and val <= 7.5, "randomFloat should be in specified range")
    end
end

function UtilsTests.test_rng_shuffle()
    local rng = Utils.RNG:new(98765)
    local original = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    local shuffled = rng:shuffle(original)
    
    -- Should have same length
    TestRunner.assertEqual(#shuffled, #original, "Shuffled array should have same length")
    
    -- Should contain all original elements
    for _, val in ipairs(original) do
        local found = false
        for _, shuffled_val in ipairs(shuffled) do
            if val == shuffled_val then
                found = true
                break
            end
        end
        TestRunner.assert(found, "Shuffled array should contain all original elements")
    end
    
    -- Should be different order (with high probability)
    local differences = 0
    for i = 1, #original do
        if original[i] ~= shuffled[i] then
            differences = differences + 1
        end
    end
    TestRunner.assert(differences > 5, "Shuffle should change order significantly")
end

function UtilsTests.test_rng_choice()
    local rng = Utils.RNG:new(11111)
    local array = {"apple", "banana", "cherry", "date"}
    
    -- Test choice returns valid elements
    for i = 1, 20 do
        local choice = rng:choice(array)
        TestRunner.assertNotNil(choice, "Choice should not be nil")
        
        local found = false
        for _, item in ipairs(array) do
            if item == choice then
                found = true
                break
            end
        end
        TestRunner.assert(found, "Choice should be from the array")
    end
    
    -- Test empty array
    local empty_choice = rng:choice({})
    TestRunner.assert(empty_choice == nil, "Choice from empty array should be nil")
end

-- Math Tests
function UtilsTests.test_math_clamp()
    TestRunner.assertEqual(Utils.Math.clamp(5, 1, 10), 5, "Value within range should be unchanged")
    TestRunner.assertEqual(Utils.Math.clamp(-5, 1, 10), 1, "Value below min should be clamped to min")
    TestRunner.assertEqual(Utils.Math.clamp(15, 1, 10), 10, "Value above max should be clamped to max")
    TestRunner.assertEqual(Utils.Math.clamp(1, 1, 10), 1, "Value equal to min should be unchanged")
    TestRunner.assertEqual(Utils.Math.clamp(10, 1, 10), 10, "Value equal to max should be unchanged")
end

function UtilsTests.test_math_lerp()
    TestRunner.assertEqual(Utils.Math.lerp(0, 10, 0), 0, "Lerp at t=0 should return first value")
    TestRunner.assertEqual(Utils.Math.lerp(0, 10, 1), 10, "Lerp at t=1 should return second value")
    TestRunner.assertEqual(Utils.Math.lerp(0, 10, 0.5), 5, "Lerp at t=0.5 should return midpoint")
    TestRunner.assertEqual(Utils.Math.lerp(5, 15, 0.3), 8, "Lerp should interpolate correctly")
end

function UtilsTests.test_math_distance()
    TestRunner.assertEqual(Utils.Math.distance(0, 0, 3, 4), 5, "Distance should calculate correctly")
    TestRunner.assertEqual(Utils.Math.distance(1, 1, 1, 1), 0, "Distance to same point should be 0")
    TestRunner.assertEqual(Utils.Math.distance(0, 0, 0, 5), 5, "Distance along axis should be correct")
end

function UtilsTests.test_math_round()
    TestRunner.assertEqual(Utils.Math.round(3.14159, 2), 3.14, "Should round to 2 decimals")
    TestRunner.assertEqual(Utils.Math.round(3.14159, 0), 3, "Should round to integer")
    TestRunner.assertEqual(Utils.Math.round(2.5), 3, "Should round 0.5 up")
    TestRunner.assertEqual(Utils.Math.round(2.4), 2, "Should round down")
end

function UtilsTests.test_math_sign()
    TestRunner.assertEqual(Utils.Math.sign(5), 1, "Positive number should return 1")
    TestRunner.assertEqual(Utils.Math.sign(-3), -1, "Negative number should return -1")
    TestRunner.assertEqual(Utils.Math.sign(0), 0, "Zero should return 0")
end

-- Table Tests
function UtilsTests.test_table_copy()
    local original = {a = 1, b = 2, c = "test"}
    local copy = Utils.Table.copy(original)
    
    TestRunner.assert(copy ~= original, "Copy should be different object")
    TestRunner.assertEqual(copy.a, original.a, "Copy should have same values")
    TestRunner.assertEqual(copy.b, original.b, "Copy should have same values")
    TestRunner.assertEqual(copy.c, original.c, "Copy should have same values")
    
    -- Test that modifying copy doesn't affect original
    copy.a = 999
    TestRunner.assertEqual(original.a, 1, "Original should be unchanged")
end

function UtilsTests.test_table_deep_copy()
    local original = {
        a = 1,
        b = {x = 10, y = 20},
        c = {nested = {value = "deep"}}
    }
    
    local copy = Utils.Table.deepCopy(original)
    
    TestRunner.assert(copy ~= original, "Deep copy should be different object")
    TestRunner.assert(copy.b ~= original.b, "Nested tables should be copied")
    TestRunner.assert(copy.c.nested ~= original.c.nested, "Deep nested tables should be copied")
    
    TestRunner.assertEqual(copy.a, original.a, "Values should match")
    TestRunner.assertEqual(copy.b.x, original.b.x, "Nested values should match")
    TestRunner.assertEqual(copy.c.nested.value, original.c.nested.value, "Deep values should match")
    
    -- Test that modifying deep copy doesn't affect original
    copy.b.x = 999
    TestRunner.assertEqual(original.b.x, 10, "Original nested value should be unchanged")
end

function UtilsTests.test_table_contains()
    local array = {"apple", "banana", "cherry"}
    
    TestRunner.assertEqual(Utils.Table.contains(array, "banana"), true, "Should find existing element")
    TestRunner.assertEqual(Utils.Table.contains(array, "grape"), false, "Should not find non-existing element")
end

function UtilsTests.test_table_index_of()
    local array = {"apple", "banana", "cherry"}
    
    TestRunner.assertEqual(Utils.Table.indexOf(array, "banana"), 2, "Should return correct index")
    TestRunner.assertEqual(Utils.Table.indexOf(array, "grape"), nil, "Should return nil for non-existing element")
end

function UtilsTests.test_table_remove()
    local array = {"apple", "banana", "cherry"}
    
    local removed = Utils.Table.remove(array, "banana")
    TestRunner.assertEqual(removed, true, "Should return true when element removed")
    TestRunner.assertEqual(#array, 2, "Array should have one less element")
    TestRunner.assertEqual(Utils.Table.contains(array, "banana"), false, "Element should be gone")
    
    local not_removed = Utils.Table.remove(array, "grape")
    TestRunner.assertEqual(not_removed, false, "Should return false when element not found")
end

function UtilsTests.test_table_filter()
    local numbers = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    
    local evens = Utils.Table.filter(numbers, function(n) return n % 2 == 0 end)
    TestRunner.assertEqual(#evens, 5, "Should have 5 even numbers")
    
    for _, n in ipairs(evens) do
        TestRunner.assertEqual(n % 2, 0, "All filtered numbers should be even")
    end
end

function UtilsTests.test_table_map()
    local numbers = {1, 2, 3, 4, 5}
    
    local doubled = Utils.Table.map(numbers, function(n) return n * 2 end)
    TestRunner.assertEqual(#doubled, #numbers, "Mapped array should have same length")
    
    for i, n in ipairs(doubled) do
        TestRunner.assertEqual(n, numbers[i] * 2, "Values should be doubled")
    end
end

function UtilsTests.test_table_is_empty()
    TestRunner.assertEqual(Utils.Table.isEmpty({}), true, "Empty table should return true")
    TestRunner.assertEqual(Utils.Table.isEmpty({a = 1}), false, "Non-empty table should return false")
    TestRunner.assertEqual(Utils.Table.isEmpty({1, 2, 3}), false, "Array should return false")
end

-- String Tests
function UtilsTests.test_string_split()
    local result = Utils.String.split("apple,banana,cherry", ",")
    TestRunner.assertEqual(#result, 3, "Should split into 3 parts")
    TestRunner.assertEqual(result[1], "apple", "First part should be 'apple'")
    TestRunner.assertEqual(result[2], "banana", "Second part should be 'banana'")
    TestRunner.assertEqual(result[3], "cherry", "Third part should be 'cherry'")
    
    local space_result = Utils.String.split("one two three")
    TestRunner.assertEqual(#space_result, 3, "Should split by whitespace by default")
end

function UtilsTests.test_string_trim()
    TestRunner.assertEqual(Utils.String.trim("  hello  "), "hello", "Should trim whitespace")
    TestRunner.assertEqual(Utils.String.trim("hello"), "hello", "Should not change string without whitespace")
    TestRunner.assertEqual(Utils.String.trim("   "), "", "Should trim string of only whitespace")
end

function UtilsTests.test_string_starts_with()
    TestRunner.assertEqual(Utils.String.startsWith("hello world", "hello"), true, "Should detect prefix")
    TestRunner.assertEqual(Utils.String.startsWith("hello world", "world"), false, "Should not detect non-prefix")
    TestRunner.assertEqual(Utils.String.startsWith("test", "test"), true, "Should match exact string")
end

function UtilsTests.test_string_ends_with()
    TestRunner.assertEqual(Utils.String.endsWith("hello world", "world"), true, "Should detect suffix")
    TestRunner.assertEqual(Utils.String.endsWith("hello world", "hello"), false, "Should not detect non-suffix")
    TestRunner.assertEqual(Utils.String.endsWith("test", "test"), true, "Should match exact string")
end

function UtilsTests.test_string_capitalize()
    TestRunner.assertEqual(Utils.String.capitalize("hello"), "Hello", "Should capitalize first letter")
    TestRunner.assertEqual(Utils.String.capitalize("HELLO"), "HELLO", "Should not change already capitalized")
    TestRunner.assertEqual(Utils.String.capitalize("h"), "H", "Should work with single character")
end

-- Color Tests
function UtilsTests.test_color_hex()
    local red = Utils.Color.hex("#FF0000")
    TestRunner.assertEqual(red[1], 1, "Red component should be 1")
    TestRunner.assertEqual(red[2], 0, "Green component should be 0")
    TestRunner.assertEqual(red[3], 0, "Blue component should be 0")
    TestRunner.assertEqual(red[4], 1, "Alpha should default to 1")
    
    local semi_transparent = Utils.Color.hex("#FF000080")
    TestRunner.assert(math.abs(semi_transparent[4] - 0.5) < 0.01, "Alpha should be approximately 0.5")
end

function UtilsTests.test_color_lerp()
    local red = {1, 0, 0, 1}
    local blue = {0, 0, 1, 1}
    
    local purple = Utils.Color.lerp(red, blue, 0.5)
    TestRunner.assertEqual(purple[1], 0.5, "Red component should be 0.5")
    TestRunner.assertEqual(purple[2], 0, "Green component should be 0")
    TestRunner.assertEqual(purple[3], 0.5, "Blue component should be 0.5")
    TestRunner.assertEqual(purple[4], 1, "Alpha should be 1")
end

-- Global RNG Tests
function UtilsTests.test_global_rng()
    Utils.setSeed(123456)
    
    local val1 = Utils.random()
    local val2 = Utils.randomInt(1, 100)
    local val3 = Utils.randomFloat(0, 1)
    
    TestRunner.assertType(val1, "number", "Global random should return number")
    TestRunner.assertType(val2, "number", "Global randomInt should return number")
    TestRunner.assertType(val3, "number", "Global randomFloat should return number")
    
    TestRunner.assert(val1 >= 0 and val1 < 1, "Global random should be in [0, 1)")
    TestRunner.assert(val2 >= 1 and val2 <= 100, "Global randomInt should be in range")
    TestRunner.assert(val3 >= 0 and val3 <= 1, "Global randomFloat should be in range")
end

function UtilsTests.test_global_shuffle()
    Utils.setSeed(789)
    
    local original = {1, 2, 3, 4, 5}
    local shuffled = Utils.shuffle(original)
    
    TestRunner.assertEqual(#shuffled, #original, "Shuffled should have same length")
    
    for _, val in ipairs(original) do
        TestRunner.assert(Utils.Table.contains(shuffled, val), "Shuffled should contain all original elements")
    end
end

return UtilsTests

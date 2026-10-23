--[[
Test Runner - Unit Testing Framework

Simple testing framework for validating core game systems.
Provides test discovery, execution, and reporting.

Usage:
  love . --test  # Run all tests
  love . --test cards  # Run specific test suite
--]]

local TestRunner = {}

-- Test framework
function TestRunner.assert(condition, message)
    if not condition then
        error(message or "Assertion failed", 2)
    end
end

function TestRunner.assertEqual(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", 
              message or "Assertion failed", 
              tostring(expected), 
              tostring(actual)), 2)
    end
end

function TestRunner.assertNotNil(value, message)
    if value == nil then
        error(message or "Value should not be nil", 2)
    end
end

function TestRunner.assertType(value, expected_type, message)
    local actual_type = type(value)
    if actual_type ~= expected_type then
        error(string.format("%s: expected %s, got %s", 
              message or "Type assertion failed",
              expected_type, actual_type), 2)
    end
end

-- Test suite runner
function TestRunner.runSuite(suite_name, test_functions)
    print("Running test suite: " .. suite_name)
    print(string.rep("-", 40))
    
    local passed = 0
    local failed = 0
    local start_time = love.timer.getTime()
    
    for test_name, test_func in pairs(test_functions) do
        if type(test_func) == "function" then
            local success, error_msg = pcall(test_func)
            
            if success then
                passed = passed + 1
                print("[PASS] " .. test_name)
            else
                failed = failed + 1
                print("[FAIL] " .. test_name .. ": " .. error_msg)
            end
        end
    end
    
    local end_time = love.timer.getTime()
    local duration = (end_time - start_time) * 1000
    
    print(string.rep("-", 40))
    print(string.format("Results: %d passed, %d failed (%.2f ms)", passed, failed, duration))
    
    return failed == 0, passed, failed
end

-- Test discovery and execution
function TestRunner.runAll()
    -- Initialize coverage tracking
    local TestCoverage = require('tests.test_coverage')
    TestCoverage.reset()
    TestCoverage.autoInstrument()
    
    local test_suites = {
        "test_cards",
        "test_utils", 
        "test_animation",
        "test_layout",
        "test_input",
        "test_scenes"
    }
    
    local total_passed = 0
    local total_failed = 0
    local suite_results = {}
    local start_time = love.timer.getTime()
    
    print("=== LOVE2D CARD GAME FRAMEWORK TEST SUITE ===")
    print("")
    
    for _, suite_name in ipairs(test_suites) do
        local success, suite_module = pcall(require, "tests." .. suite_name)
        
        if success and type(suite_module) == "table" then
            local suite_success, passed, failed = TestRunner.runSuite(suite_name, suite_module)
            
            total_passed = total_passed + passed
            total_failed = total_failed + failed
            
            table.insert(suite_results, {
                name = suite_name,
                success = suite_success,
                passed = passed,
                failed = failed
            })
        else
            print("Could not load test suite: " .. suite_name)
            table.insert(suite_results, {
                name = suite_name,
                success = false,
                passed = 0,
                failed = 1
            })
            total_failed = total_failed + 1
        end
        
        print() -- Empty line between suites
    end
    
    local end_time = love.timer.getTime()
    local total_time = (end_time - start_time) * 1000
    
    -- Print summary
    print(string.rep("=", 60))
    print("TEST SUMMARY")
    print(string.rep("=", 60))
    
    for _, result in ipairs(suite_results) do
        local status = result.success and "PASS" or "FAIL"
        local icon = result.success and "[OK]" or "[!!]"
        print(string.format("%-20s %s %s (%d/%d)", result.name, icon, status, 
                          result.passed, result.passed + result.failed))
    end
    
    print(string.rep("-", 60))
    print(string.format("TOTAL: %d passed, %d failed (%.2f ms)", total_passed, total_failed, total_time))
    
    -- Print coverage report
    print("")
    print(TestCoverage.generateReport())
    
    local success_rate = total_passed + total_failed > 0 and (total_passed / (total_passed + total_failed) * 100) or 0
    local coverage_stats = TestCoverage.getStats()
    
    print("")
    print(string.rep("=", 60))
    print("FINAL RESULTS")
    print(string.rep("=", 60))
    print(string.format("Test Success Rate: %.1f%% (%d/%d tests)", success_rate, total_passed, total_passed + total_failed))
    print(string.format("Code Coverage:     %.1f%% (%d/%d functions)", coverage_stats.function_coverage, coverage_stats.tested_functions, coverage_stats.total_functions))
    print(string.format("Total Test Time:   %.2f ms", total_time))
    
    if total_failed == 0 and coverage_stats.function_coverage >= 70 then
        print("")
        print("EXCELLENT! All tests pass with good coverage!")
        print("Framework is ready for production use.")
    elseif total_failed == 0 then
        print("")
        print("All tests pass, but coverage could be improved.")
        print("Consider adding more tests for better coverage.")
    else
        print("")
        print("Some tests failed. Please fix issues before release.")
    end
    
    return total_failed == 0
end

return TestRunner

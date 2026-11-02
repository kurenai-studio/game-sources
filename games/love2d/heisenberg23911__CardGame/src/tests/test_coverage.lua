--[[
Test Coverage Reporter

Tracks which functions and modules are tested and provides coverage statistics.
--]]

local TestCoverage = {}

-- Coverage tracking
TestCoverage.coverage_data = {
    modules = {},
    functions = {},
    lines = {},
    total_functions = 0,
    tested_functions = 0,
    total_lines = 0,
    tested_lines = 0
}

-- Track function calls during testing
function TestCoverage.trackFunction(module_name, function_name)
    if not TestCoverage.coverage_data.modules[module_name] then
        TestCoverage.coverage_data.modules[module_name] = {
            functions = {},
            tested_functions = 0,
            total_functions = 0
        }
    end
    
    local module_data = TestCoverage.coverage_data.modules[module_name]
    if not module_data.functions[function_name] then
        module_data.functions[function_name] = {
            called = false,
            call_count = 0
        }
        module_data.total_functions = module_data.total_functions + 1
        TestCoverage.coverage_data.total_functions = TestCoverage.coverage_data.total_functions + 1
    end
    
    local func_data = module_data.functions[function_name]
    if not func_data.called then
        func_data.called = true
        module_data.tested_functions = module_data.tested_functions + 1
        TestCoverage.coverage_data.tested_functions = TestCoverage.coverage_data.tested_functions + 1
    end
    func_data.call_count = func_data.call_count + 1
end

-- Analyze module for functions
function TestCoverage.analyzeModule(module_name, module_table)
    if not TestCoverage.coverage_data.modules[module_name] then
        TestCoverage.coverage_data.modules[module_name] = {
            functions = {},
            tested_functions = 0,
            total_functions = 0
        }
    end
    
    local module_data = TestCoverage.coverage_data.modules[module_name]
    
    -- Find all functions in the module
    local function analyzeTable(t, prefix)
        for key, value in pairs(t) do
            if type(value) == "function" then
                local func_name = prefix and (prefix .. "." .. key) or key
                if not module_data.functions[func_name] then
                    module_data.functions[func_name] = {
                        called = false,
                        call_count = 0
                    }
                    module_data.total_functions = module_data.total_functions + 1
                    TestCoverage.coverage_data.total_functions = TestCoverage.coverage_data.total_functions + 1
                end
            elseif type(value) == "table" and key ~= "__index" and not string.match(key, "^_") then
                -- Recursively analyze nested tables (like classes)
                analyzeTable(value, prefix and (prefix .. "." .. key) or key)
            end
        end
    end
    
    analyzeTable(module_table)
end

-- Instrument a module for coverage tracking
function TestCoverage.instrumentModule(module_name, module_table)
    TestCoverage.analyzeModule(module_name, module_table)
    
    local function instrumentTable(t, prefix)
        for key, value in pairs(t) do
            if type(value) == "function" then
                local func_name = prefix and (prefix .. "." .. key) or key
                local original_func = value
                
                t[key] = function(...)
                    TestCoverage.trackFunction(module_name, func_name)
                    return original_func(...)
                end
            elseif type(value) == "table" and key ~= "__index" and not string.match(key, "^_") then
                instrumentTable(value, prefix and (prefix .. "." .. key) or key)
            end
        end
    end
    
    instrumentTable(module_table)
    return module_table
end

-- Generate coverage report
function TestCoverage.generateReport()
    local report = {}
    table.insert(report, "=== TEST COVERAGE REPORT ===")
    table.insert(report, "")
    
    -- Overall statistics
    local overall_func_coverage = TestCoverage.coverage_data.total_functions > 0 
        and (TestCoverage.coverage_data.tested_functions / TestCoverage.coverage_data.total_functions * 100) or 0
    
    table.insert(report, string.format("Overall Function Coverage: %.1f%% (%d/%d functions)", 
        overall_func_coverage,
        TestCoverage.coverage_data.tested_functions,
        TestCoverage.coverage_data.total_functions))
    table.insert(report, "")
    
    -- Per-module breakdown
    table.insert(report, "Module Breakdown:")
    table.insert(report, string.rep("-", 60))
    
    local modules = {}
    for module_name, module_data in pairs(TestCoverage.coverage_data.modules) do
        table.insert(modules, {name = module_name, data = module_data})
    end
    
    -- Sort modules by coverage percentage
    table.sort(modules, function(a, b)
        local coverage_a = a.data.total_functions > 0 and (a.data.tested_functions / a.data.total_functions) or 0
        local coverage_b = b.data.total_functions > 0 and (b.data.tested_functions / b.data.total_functions) or 0
        return coverage_a > coverage_b
    end)
    
    for _, module_info in ipairs(modules) do
        local module_name = module_info.name
        local module_data = module_info.data
        
        local coverage_percent = module_data.total_functions > 0 
            and (module_data.tested_functions / module_data.total_functions * 100) or 0
        
        local status_icon = coverage_percent >= 80 and "[OK]" or coverage_percent >= 50 and "[!]" or "[X]"
        
        table.insert(report, string.format("%-20s %s %5.1f%% (%2d/%2d)", 
            module_name, status_icon, coverage_percent,
            module_data.tested_functions, module_data.total_functions))
        
        -- Show untested functions for modules with low coverage
        if coverage_percent < 80 then
            local untested = {}
            for func_name, func_data in pairs(module_data.functions) do
                if not func_data.called then
                    table.insert(untested, func_name)
                end
            end
            
            if #untested > 0 then
                table.sort(untested)
                for i, func_name in ipairs(untested) do
                    if i <= 5 then -- Show first 5 untested functions
                        table.insert(report, "    - " .. func_name)
                    elseif i == 6 then
                        table.insert(report, "    ... and " .. (#untested - 5) .. " more")
                        break
                    end
                end
            end
        end
    end
    
    table.insert(report, string.rep("-", 60))
    
    -- Coverage goals
    table.insert(report, "")
    table.insert(report, "Coverage Goals:")
    table.insert(report, "[OK] Excellent: >= 80%")
    table.insert(report, "[!]  Good:      >= 50%")
    table.insert(report, "[X]  Needs work: < 50%")
    
    return table.concat(report, "\n")
end

-- Reset coverage data
function TestCoverage.reset()
    TestCoverage.coverage_data = {
        modules = {},
        functions = {},
        lines = {},
        total_functions = 0,
        tested_functions = 0,
        total_lines = 0,
        tested_lines = 0
    }
end

-- Get coverage statistics
function TestCoverage.getStats()
    local stats = {
        total_functions = TestCoverage.coverage_data.total_functions,
        tested_functions = TestCoverage.coverage_data.tested_functions,
        function_coverage = TestCoverage.coverage_data.total_functions > 0 
            and (TestCoverage.coverage_data.tested_functions / TestCoverage.coverage_data.total_functions * 100) or 0,
        modules = {}
    }
    
    for module_name, module_data in pairs(TestCoverage.coverage_data.modules) do
        stats.modules[module_name] = {
            total_functions = module_data.total_functions,
            tested_functions = module_data.tested_functions,
            coverage = module_data.total_functions > 0 
                and (module_data.tested_functions / module_data.total_functions * 100) or 0
        }
    end
    
    return stats
end

-- Auto-instrument common modules
function TestCoverage.autoInstrument()
    local modules_to_instrument = {
        "lib.utils",
        "lib.animation", 
        "lib.layout",
        "lib.input",
        "lib.scene_manager",
        "lib.card_renderer",
        "lib.audio_manager",
        "data.cards"
    }
    
    for _, module_name in ipairs(modules_to_instrument) do
        local success, module_table = pcall(require, module_name)
        if success and type(module_table) == "table" then
            TestCoverage.instrumentModule(module_name, module_table)
        end
    end
end

return TestCoverage

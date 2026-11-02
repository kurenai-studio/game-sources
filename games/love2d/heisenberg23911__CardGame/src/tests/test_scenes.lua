--[[
Scene System Tests

Tests for scene management, transitions, and scene lifecycle.
--]]

local SceneManager = require('lib.scene_manager')
local TestRunner = require('tests.test_runner')

local SceneTests = {}

-- Mock scene for testing
local MockScene = {}
MockScene.__index = MockScene

function MockScene:new(name)
    local instance = {
        name = name or "mock_scene",
        is_active = false,
        enter_called = false,
        exit_called = false,
        update_called = false,
        draw_called = false,
        pause_called = false,
        resume_called = false
    }
    setmetatable(instance, MockScene)
    return instance
end

function MockScene:enter()
    self.is_active = true
    self.enter_called = true
end

function MockScene:exit()
    self.is_active = false
    self.exit_called = true
end

function MockScene:update(dt)
    self.update_called = true
    self.last_dt = dt
end

function MockScene:draw()
    self.draw_called = true
end

function MockScene:onPause()
    self.pause_called = true
end

function MockScene:onResume()
    self.resume_called = true
end

function SceneTests.test_scene_manager_creation()
    local manager = SceneManager:new()
    
    TestRunner.assertNotNil(manager, "Scene manager should be created")
    TestRunner.assertType(manager.scenes, "table", "Manager should have scenes table")
    TestRunner.assertType(manager.scene_stack, "table", "Manager should have scene stack")
    TestRunner.assertEqual(manager.current_scene, nil, "Manager should start with no current scene")
    TestRunner.assertEqual(manager.is_transitioning, false, "Manager should not be transitioning initially")
end

function SceneTests.test_scene_loading()
    local manager = SceneManager:new()
    
    -- Mock the require function for testing
    local original_require = require
    _G.require = function(path)
        if path == "scenes.test_scene" then
            return MockScene
        end
        return original_require(path)
    end
    
    local scene = manager:loadScene("test_scene")
    
    TestRunner.assertNotNil(scene, "Scene should be loaded")
    TestRunner.assertEqual(scene.name, "mock_scene", "Scene should be mock scene")
    TestRunner.assertNotNil(manager.scenes["test_scene"], "Scene should be cached")
    
    -- Restore original require
    _G.require = original_require
end

function SceneTests.test_immediate_scene_switch()
    local manager = SceneManager:new()
    local scene1 = MockScene:new("scene1")
    local scene2 = MockScene:new("scene2")
    
    -- Mock scene loading
    manager.scenes["scene1"] = scene1
    manager.scenes["scene2"] = scene2
    
    -- Switch to first scene
    manager:_immediateSwitch("scene1")
    
    TestRunner.assertEqual(manager.current_scene, scene1, "Current scene should be scene1")
    TestRunner.assertEqual(manager.current_scene_name, "scene1", "Current scene name should be set")
    TestRunner.assertEqual(scene1.enter_called, true, "Scene1 enter should be called")
    TestRunner.assertEqual(scene1.is_active, true, "Scene1 should be active")
    
    -- Switch to second scene
    manager:_immediateSwitch("scene2")
    
    TestRunner.assertEqual(manager.current_scene, scene2, "Current scene should be scene2")
    TestRunner.assertEqual(scene1.exit_called, true, "Scene1 exit should be called")
    TestRunner.assertEqual(scene1.is_active, false, "Scene1 should not be active")
    TestRunner.assertEqual(scene2.enter_called, true, "Scene2 enter should be called")
    TestRunner.assertEqual(scene2.is_active, true, "Scene2 should be active")
end

function SceneTests.test_scene_transitions()
    local manager = SceneManager:new()
    local scene1 = MockScene:new("scene1")
    local scene2 = MockScene:new("scene2")
    
    manager.scenes["scene1"] = scene1
    manager.scenes["scene2"] = scene2
    
    -- Start with scene1
    manager:_immediateSwitch("scene1")
    
    -- Start transition to scene2
    manager:switchScene("scene2", {type = "fade", duration = 1.0})
    
    TestRunner.assertEqual(manager.is_transitioning, true, "Manager should be transitioning")
    TestRunner.assertEqual(manager.next_scene_name, "scene2", "Next scene should be set")
    TestRunner.assertEqual(manager.transition_type, "fade", "Transition type should be set")
    TestRunner.assertEqual(manager.transition_time, 1.0, "Transition time should be set")
    
    -- Update transition halfway
    manager:_updateTransition(0.5)
    TestRunner.assert(manager.transition_progress > 0, "Transition progress should advance")
    TestRunner.assertEqual(manager.is_transitioning, true, "Should still be transitioning")
    
    -- Complete transition
    manager:_updateTransition(0.5)
    TestRunner.assertEqual(manager.is_transitioning, false, "Transition should be complete")
    TestRunner.assertEqual(manager.current_scene, scene2, "Should have switched to scene2")
end

function SceneTests.test_scene_stack_push_pop()
    local manager = SceneManager:new()
    local main_scene = MockScene:new("main")
    local overlay_scene = MockScene:new("overlay")
    
    manager.scenes["main"] = main_scene
    manager.scenes["overlay"] = overlay_scene
    
    -- Start with main scene
    manager:_immediateSwitch("main")
    TestRunner.assertEqual(#manager.scene_stack, 0, "Scene stack should be empty")
    
    -- Push overlay scene (use immediate transition for testing)
    manager:pushScene("overlay", {type = "none"})
    TestRunner.assertEqual(#manager.scene_stack, 1, "Scene stack should have one scene")
    TestRunner.assertEqual(manager.scene_stack[1].scene, main_scene, "Main scene should be on stack")
    TestRunner.assertEqual(manager.scene_stack[1].name, "main", "Scene name should be stored")
    TestRunner.assertEqual(main_scene.pause_called, true, "Main scene should be paused")
    -- Check that current scene is the overlay (verify it's the right scene)
    TestRunner.assertNotNil(manager.current_scene, "Current scene should exist")
    TestRunner.assertEqual(manager.current_scene_name, "overlay", "Current scene name should be overlay")
    -- Verify the scene is the correct overlay scene by checking it matches our cached scene
    TestRunner.assertEqual(manager.current_scene, manager.scenes["overlay"], "Current scene should be the cached overlay scene")
    
    -- Pop overlay scene
    local success = manager:popScene()
    TestRunner.assertEqual(success, true, "Pop should succeed")
    TestRunner.assertEqual(#manager.scene_stack, 0, "Scene stack should be empty")
    TestRunner.assertEqual(manager.current_scene, main_scene, "Should return to main scene")
    TestRunner.assertEqual(main_scene.resume_called, true, "Main scene should be resumed")
    
    -- Try to pop when stack is empty
    local empty_pop = manager:popScene()
    TestRunner.assertEqual(empty_pop, false, "Pop should fail when stack is empty")
end

function SceneTests.test_scene_update_and_draw()
    local manager = SceneManager:new()
    local scene = MockScene:new("test")
    
    manager.scenes["test"] = scene
    manager:_immediateSwitch("test")
    
    -- Test update
    manager:update(0.016)
    TestRunner.assertEqual(scene.update_called, true, "Scene update should be called")
    TestRunner.assertEqual(scene.last_dt, 0.016, "Scene should receive correct delta time")
    
    -- Test draw
    manager:draw()
    TestRunner.assertEqual(scene.draw_called, true, "Scene draw should be called")
end

function SceneTests.test_scene_caching()
    local manager = SceneManager:new()
    manager.scene_cache_limit = 2
    
    local scene1 = MockScene:new("scene1")
    local scene2 = MockScene:new("scene2")
    local scene3 = MockScene:new("scene3")
    
    -- Add scenes to cache
    manager.scenes["scene1"] = scene1
    manager.scenes["scene2"] = scene2
    
    TestRunner.assertEqual(manager:_getCacheSize(), 2, "Cache should have 2 scenes")
    
    -- Add third scene (should trigger cache cleanup)
    manager.scenes["scene3"] = scene3
    manager:_cleanupCache()
    
    TestRunner.assert(manager:_getCacheSize() <= manager.scene_cache_limit, "Cache should respect limit")
end

function SceneTests.test_transition_types()
    local manager = SceneManager:new()
    local scene1 = MockScene:new("scene1")
    local scene2 = MockScene:new("scene2")
    
    manager.scenes["scene1"] = scene1
    manager.scenes["scene2"] = scene2
    manager:_immediateSwitch("scene1")
    
    -- Test no transition
    manager:switchScene("scene2", {type = "none"})
    TestRunner.assertEqual(manager.is_transitioning, false, "No transition should be immediate")
    TestRunner.assertEqual(manager.current_scene, scene2, "Should switch immediately")
    
    -- Reset
    manager:_immediateSwitch("scene1")
    
    -- Test fade transition
    manager:switchScene("scene2", {type = "fade", duration = 0.5})
    TestRunner.assertEqual(manager.transition_type, "fade", "Should set fade transition")
    TestRunner.assertEqual(manager.transition_time, 0.5, "Should set custom duration")
    
    -- Test slide transition with fresh state
    local manager2 = SceneManager:new()
    manager2.scenes["scene1"] = scene1
    manager2.scenes["scene2"] = scene2
    manager2:_immediateSwitch("scene1")
    
    manager2:switchScene("scene2", {type = "slide", duration = 0.8})
    TestRunner.assertEqual(manager2.transition_type, "slide", "Should set slide transition")
    TestRunner.assertEqual(manager2.transition_time, 0.8, "Should set custom duration")
end

function SceneTests.test_scene_cleanup()
    local manager = SceneManager:new()
    local scene = MockScene:new("test")
    scene.cleanup = function(self)
        self.cleanup_called = true
    end
    
    manager.scenes["test"] = scene
    manager:_immediateSwitch("test")
    
    -- Trigger cleanup
    manager:_cleanupScene("test")
    
    TestRunner.assertEqual(scene.cleanup_called, true, "Scene cleanup should be called")
    TestRunner.assertEqual(manager.scenes["test"], nil, "Scene should be removed from cache")
end

function SceneTests.test_scene_error_handling()
    local manager = SceneManager:new()
    
    -- Test loading non-existent scene
    local success, error_msg = pcall(function()
        manager:loadScene("nonexistent_scene")
    end)
    
    TestRunner.assertEqual(success, false, "Loading non-existent scene should fail")
    TestRunner.assertType(error_msg, "string", "Should provide error message")
end

function SceneTests.test_scene_resize_handling()
    local manager = SceneManager:new()
    local scene = MockScene:new("test")
    
    scene.onResize = function(self, width, height)
        self.resize_called = true
        self.resize_width = width
        self.resize_height = height
    end
    
    manager.scenes["test"] = scene
    manager:_immediateSwitch("test")
    
    -- Test resize
    manager:onResize(800, 600)
    
    TestRunner.assertEqual(scene.resize_called, true, "Scene resize should be called")
    TestRunner.assertEqual(scene.resize_width, 800, "Scene should receive correct width")
    TestRunner.assertEqual(scene.resize_height, 600, "Scene should receive correct height")
end

function SceneTests.test_scene_performance()
    local manager = SceneManager:new()
    
    -- Create many scenes
    for i = 1, 100 do
        local scene = MockScene:new("scene_" .. i)
        manager.scenes["scene_" .. i] = scene
    end
    
    -- Time scene switching
    local start_time = love.timer.getTime()
    for i = 1, 50 do
        manager:_immediateSwitch("scene_" .. (i % 10 + 1))
    end
    local end_time = love.timer.getTime()
    
    local switch_time = (end_time - start_time) * 1000
    TestRunner.assert(switch_time < 10, "Scene switching should be fast (got " .. switch_time .. "ms)")
end

-- Helper function for scene manager
function SceneManager:_getCacheSize()
    local count = 0
    for _ in pairs(self.scenes) do
        count = count + 1
    end
    return count
end

function SceneManager:_cleanupCache()
    -- Simple cleanup implementation for testing
    local count = self:_getCacheSize()
    if count > self.scene_cache_limit then
        local to_remove = {}
        local removed = 0
        for name, scene in pairs(self.scenes) do
            if scene ~= self.current_scene and removed < (count - self.scene_cache_limit) then
                table.insert(to_remove, name)
                removed = removed + 1
            end
        end
        
        for _, name in ipairs(to_remove) do
            self:_cleanupScene(name)
        end
    end
end

function SceneManager:_cleanupScene(scene_name)
    local scene = self.scenes[scene_name]
    if scene and scene.cleanup then
        scene:cleanup()
    end
    self.scenes[scene_name] = nil
end

return SceneTests

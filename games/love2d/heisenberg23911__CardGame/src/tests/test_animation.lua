--[[
Animation System Tests

Tests for the animation/tweening system, easing functions, and animation manager.
--]]

local AnimationManager = require('lib.animation')
local TestRunner = require('tests.test_runner')

local AnimationTests = {}

function AnimationTests.test_animation_manager_creation()
    local manager = AnimationManager.AnimationManager:new()
    
    TestRunner.assertNotNil(manager, "Animation manager should be created")
    TestRunner.assertType(manager.active_tweens, "table", "Manager should have active_tweens table")
    TestRunner.assertEqual(#manager.active_tweens, 0, "Manager should start with no active tweens")
end

function AnimationTests.test_tween_creation()
    local target = {x = 0, y = 0}
    local tween = AnimationManager.Tween:new(target, 1.0, {x = 100, y = 50}, AnimationManager.Easing.linear)
    
    TestRunner.assertNotNil(tween, "Tween should be created")
    TestRunner.assertEqual(tween.target, target, "Tween should reference target object")
    TestRunner.assertEqual(tween.duration, 1.0, "Tween should have correct duration")
    TestRunner.assertEqual(tween.properties.x, 100, "Tween should have correct target x")
    TestRunner.assertEqual(tween.properties.y, 50, "Tween should have correct target y")
end

function AnimationTests.test_tween_update()
    local target = {x = 0, y = 0}
    local tween = AnimationManager.Tween:new(target, 1.0, {x = 100, y = 50}, AnimationManager.Easing.linear)
    
    -- Start the tween first
    tween:start()
    
    -- Test at 50% completion
    tween:update(0.5)
    TestRunner.assertEqual(target.x, 50, "Target x should be halfway")
    TestRunner.assertEqual(target.y, 25, "Target y should be halfway")
    TestRunner.assertEqual(tween.is_complete, false, "Tween should not be complete")
    
    -- Test at 100% completion
    tween:update(0.5)
    TestRunner.assertEqual(target.x, 100, "Target x should be at final value")
    TestRunner.assertEqual(target.y, 50, "Target y should be at final value")
    TestRunner.assertEqual(tween.is_complete, true, "Tween should be complete")
end

function AnimationTests.test_easing_functions()
    -- Test linear easing
    TestRunner.assertEqual(AnimationManager.Easing.linear(0), 0, "Linear easing at 0 should be 0")
    TestRunner.assertEqual(AnimationManager.Easing.linear(0.5), 0.5, "Linear easing at 0.5 should be 0.5")
    TestRunner.assertEqual(AnimationManager.Easing.linear(1), 1, "Linear easing at 1 should be 1")
    
    -- Test cubic easing (using actual available functions)
    TestRunner.assertEqual(AnimationManager.Easing.inCubic(0), 0, "InCubic at 0 should be 0")
    TestRunner.assertEqual(AnimationManager.Easing.inCubic(1), 1, "InCubic at 1 should be 1")
    TestRunner.assert(AnimationManager.Easing.inCubic(0.5) < 0.5, "InCubic should be slower at start")
    
    TestRunner.assertEqual(AnimationManager.Easing.outCubic(0), 0, "OutCubic at 0 should be 0")
    TestRunner.assertEqual(AnimationManager.Easing.outCubic(1), 1, "OutCubic at 1 should be 1")
    TestRunner.assert(AnimationManager.Easing.outCubic(0.5) > 0.5, "OutCubic should be faster at start")
    
    -- Test bounce easing (just check it doesn't crash)
    local bounce_val = AnimationManager.Easing.outBounce(0.5)
    TestRunner.assertType(bounce_val, "number", "Bounce easing should return number")
    TestRunner.assert(bounce_val >= 0 and bounce_val <= 2, "Bounce easing should be in reasonable range")
end

function AnimationTests.test_tween_chaining()
    local target = {x = 0}
    local tween1 = AnimationManager.Tween:new(target, 0.5, {x = 50}, AnimationManager.Easing.linear)
    local tween2 = AnimationManager.Tween:new(target, 0.5, {x = 100}, AnimationManager.Easing.linear)
    
    tween1:chain(tween2)
    
    TestRunner.assertEqual(tween1.next_tween, tween2, "First tween should chain to second")
    
    -- Start and complete first tween
    tween1:start()
    tween1:update(0.5)
    TestRunner.assertEqual(target.x, 50, "Target should be at first tween's end value")
    TestRunner.assertEqual(tween1.is_complete, true, "First tween should be complete")
end

function AnimationTests.test_animation_manager_play()
    local manager = AnimationManager.AnimationManager:new()
    local target = {x = 0}
    local tween = AnimationManager.Tween:new(target, 1.0, {x = 100}, AnimationManager.Easing.linear)
    
    local callback_called = false
    manager:play(tween, function() callback_called = true end)
    
    TestRunner.assertEqual(#manager.active_tweens, 1, "Manager should have one active tween")
    TestRunner.assertEqual(manager.active_tweens[1], tween, "Manager should store the tween")
    
    -- Update to completion
    manager:update(1.0)
    TestRunner.assertEqual(target.x, 100, "Target should reach final value")
    TestRunner.assertEqual(callback_called, true, "Callback should be called")
    TestRunner.assertEqual(#manager.active_tweens, 0, "Completed tween should be removed")
end

function AnimationTests.test_animation_manager_stop()
    local manager = AnimationManager.AnimationManager:new()
    local target = {x = 0}
    local tween = AnimationManager.Tween:new(target, 1.0, {x = 100}, AnimationManager.Easing.linear)
    
    manager:play(tween)
    TestRunner.assertEqual(#manager.active_tweens, 1, "Manager should have one active tween")
    
    manager:stop(tween)
    TestRunner.assertEqual(#manager.active_tweens, 0, "Tween should be stopped and removed")
end

function AnimationTests.test_animation_manager_stop_all()
    local manager = AnimationManager.AnimationManager:new()
    local target1 = {x = 0}
    local target2 = {y = 0}
    
    local tween1 = AnimationManager.Tween:new(target1, 1.0, {x = 100}, AnimationManager.Easing.linear)
    local tween2 = AnimationManager.Tween:new(target2, 1.0, {y = 100}, AnimationManager.Easing.linear)
    
    manager:play(tween1)
    manager:play(tween2)
    TestRunner.assertEqual(#manager.active_tweens, 2, "Manager should have two active tweens")
    
    manager:stopAll()
    TestRunner.assertEqual(#manager.active_tweens, 0, "All tweens should be stopped")
end

function AnimationTests.test_parallel_animations()
    local manager = AnimationManager.AnimationManager:new()
    local target = {x = 0, y = 0, scale = 1}
    
    local tween_x = AnimationManager.Tween:new(target, 1.0, {x = 100}, AnimationManager.Easing.linear)
    local tween_y = AnimationManager.Tween:new(target, 1.0, {y = 50}, AnimationManager.Easing.linear)
    local tween_scale = AnimationManager.Tween:new(target, 0.5, {scale = 2}, AnimationManager.Easing.linear)
    
    manager:play(tween_x)
    manager:play(tween_y)
    manager:play(tween_scale)
    
    TestRunner.assertEqual(#manager.active_tweens, 3, "Manager should have three parallel tweens")
    
    -- Update halfway through
    manager:update(0.5)
    TestRunner.assertEqual(target.x, 50, "X should be halfway")
    TestRunner.assertEqual(target.y, 25, "Y should be halfway")
    TestRunner.assertEqual(target.scale, 2, "Scale should be complete")
    TestRunner.assertEqual(#manager.active_tweens, 2, "Scale tween should be complete and removed")
    
    -- Complete remaining tweens
    manager:update(0.5)
    TestRunner.assertEqual(target.x, 100, "X should be complete")
    TestRunner.assertEqual(target.y, 50, "Y should be complete")
    TestRunner.assertEqual(#manager.active_tweens, 0, "All tweens should be complete")
end

function AnimationTests.test_sequence_creation()
    -- Test chaining instead since createSequence doesn't exist
    local target = {x = 0}
    local tween1 = AnimationManager.Tween:new(target, 0.5, {x = 50}, AnimationManager.Easing.linear)
    local tween2 = AnimationManager.Tween:new(target, 0.5, {x = 100}, AnimationManager.Easing.linear)
    
    tween1:chain(tween2)
    TestRunner.assertNotNil(tween1.next_tween, "Tween should have next_tween for sequence")
    TestRunner.assertEqual(tween1.next_tween, tween2, "Chained tween should be correct")
end

function AnimationTests.test_tween_pause_resume()
    local manager = AnimationManager.AnimationManager:new()
    local target = {x = 0}
    local tween = AnimationManager.Tween:new(target, 1.0, {x = 100}, AnimationManager.Easing.linear)
    
    -- Play tween through manager
    manager:play(tween)
    
    -- Update to 50%
    manager:update(0.5)
    TestRunner.assertEqual(target.x, 50, "Target should be halfway")
    
    -- Pause manager (not individual tween)
    manager:pause()
    TestRunner.assertEqual(manager.paused, true, "Manager should be paused")
    
    -- Try to update while paused
    manager:update(0.5)
    TestRunner.assertEqual(target.x, 50, "Target should not change while paused")
    
    -- Resume manager
    manager:resume()
    TestRunner.assertEqual(manager.paused, false, "Manager should be resumed")
    
    -- Continue updating
    manager:update(0.5)
    TestRunner.assertEqual(target.x, 100, "Target should complete after resume")
end

function AnimationTests.test_animation_performance()
    local manager = AnimationManager.AnimationManager:new()
    local targets = {}
    
    -- Create many targets and animations
    for i = 1, 100 do
        local target = {x = 0, y = 0}
        targets[i] = target
        
        local tween = AnimationManager.Tween:new(target, 1.0, {x = i, y = i * 2}, AnimationManager.Easing.linear)
        manager:play(tween)
    end
    
    TestRunner.assertEqual(#manager.active_tweens, 100, "Manager should handle many active tweens")
    
    -- Time the update
    local start_time = love.timer.getTime()
    manager:update(0.016) -- Simulate 60fps frame
    local end_time = love.timer.getTime()
    
    local update_time = (end_time - start_time) * 1000 -- Convert to milliseconds
    TestRunner.assert(update_time < 5, "Update should be fast even with many tweens (got " .. update_time .. "ms)")
    
    -- Verify all targets were updated
    for i, target in ipairs(targets) do
        TestRunner.assert(target.x > 0, "Target " .. i .. " should have been updated")
    end
end

return AnimationTests

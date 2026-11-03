package com.stickman.tower.input

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class GamepadAndTouchSettingsTest {

    @Test
    fun testTouchControlSettingsDefaultsAndClamping() {
        val defaultSettings = TouchControlSettings()
        assertEquals(1.0f, defaultSettings.scale)
        assertEquals(0.85f, defaultSettings.opacity)
        assertEquals(0f, defaultSettings.dpadOffsetX)
        assertEquals(0f, defaultSettings.dpadOffsetY)
        assertEquals(0f, defaultSettings.actionOffsetX)
        assertEquals(0f, defaultSettings.actionOffsetY)
        assertTrue(defaultSettings.autoHideOnGamepad)

        // Test Clamping
        val clamped = defaultSettings.clamp()
        assertEquals(1.0f, clamped.scale)

        val outOfBoundsSettings = TouchControlSettings(
            scale = 2.5f,
            opacity = 0.1f,
            dpadOffsetX = -300f,
            dpadOffsetY = 400f,
            actionOffsetX = 500f,
            actionOffsetY = -250f
        ).clamp()

        assertEquals(1.30f, outOfBoundsSettings.scale)
        assertEquals(0.30f, outOfBoundsSettings.opacity)
        assertEquals(-50f, outOfBoundsSettings.dpadOffsetX)
        assertEquals(250f, outOfBoundsSettings.dpadOffsetY)
        assertEquals(50f, outOfBoundsSettings.actionOffsetX)
        assertEquals(-50f, outOfBoundsSettings.actionOffsetY)
    }

    @Test
    fun testVirtualControllerCustomSettingsApplication() {
        val controller = VirtualController()
        val customSettings = TouchControlSettings(
            scale = 1.2f,
            opacity = 0.9f,
            dpadOffsetX = 30f,
            dpadOffsetY = 20f,
            actionOffsetX = -40f,
            actionOffsetY = 10f
        )
        controller.applySettings(customSettings, 1280, 720)

        assertEquals(1.2f, controller.settings.scale)
        assertEquals(0.9f, controller.settings.opacity)

        // D-Pad base: 85 + 30 = 115
        assertEquals(115f, controller.btnLeft.x)
        assertEquals(45f * 1.2f, controller.btnLeft.radius)

        // Action base X: 1280 - 120 - 40 = 1120. Action base Y: 110 + 10 = 120
        assertEquals(1120f, controller.btnAttack.x)
        assertEquals(120f, controller.btnAttack.y)
        assertEquals(54f * 1.2f, controller.btnAttack.radius)
    }

    @Test
    fun testGamepadInputSimulationAndDeadzone() {
        val gamepad = GamepadInput()

        // Initially no buttons pressed
        assertFalse(gamepad.isMoveLeft())
        assertFalse(gamepad.isMoveRight())
        assertFalse(gamepad.isJumpJustPressed())
        assertFalse(gamepad.isAttackJustPressed())
        assertFalse(gamepad.isDodgeJustPressed())
        assertFalse(gamepad.isSkillJustPressed())
        assertFalse(gamepad.isUltimateJustPressed())
        assertFalse(gamepad.isPauseJustPressed())
        assertFalse(gamepad.isUpJustPressed())
        assertFalse(gamepad.isDownJustPressed())

        // Simulate Left Analog Stick X Axis
        gamepad.setAxisXForTesting(-0.2f) // Inside deadzone (0.25)
        assertFalse(gamepad.isMoveLeft())

        gamepad.setAxisXForTesting(-0.75f) // Outside deadzone
        assertTrue(gamepad.isMoveLeft())
        assertFalse(gamepad.isMoveRight())

        gamepad.setAxisXForTesting(0.8f) // Move Right
        assertTrue(gamepad.isMoveRight())
        assertFalse(gamepad.isMoveLeft())

        gamepad.setAxisXForTesting(0.0f) // Released
        assertFalse(gamepad.isMoveLeft())
        assertFalse(gamepad.isMoveRight())

        // Simulate Button Press and JustPressed single-frame behavior
        gamepad.isConnectedForTesting = true
        gamepad.setButtonPressedForTesting(GamepadInput.BTN_A, true)
        gamepad.update()
        assertTrue(gamepad.isJumpPressed())
        assertTrue(gamepad.isJumpJustPressed())

        // Frame kedua: justPressed should be consumed while isPressed remains true
        gamepad.update()
        assertTrue(gamepad.isJumpPressed())
        assertFalse(gamepad.isJumpJustPressed())

        // Release Button
        gamepad.setButtonPressedForTesting(GamepadInput.BTN_A, false)
        gamepad.update()
        assertFalse(gamepad.isJumpPressed())
        assertFalse(gamepad.isJumpJustPressed())

        // Test D-Pad Up / Down JustPressed
        gamepad.setButtonPressedForTesting(GamepadInput.BTN_UP, true)
        gamepad.update()
        assertTrue(gamepad.isUpJustPressed())
        gamepad.update()
        assertFalse(gamepad.isUpJustPressed())
        gamepad.setButtonPressedForTesting(GamepadInput.BTN_UP, false)
        gamepad.update()

        gamepad.setButtonPressedForTesting(GamepadInput.BTN_DOWN, true)
        gamepad.update()
        assertTrue(gamepad.isDownJustPressed())
        gamepad.update()
        assertFalse(gamepad.isDownJustPressed())
        gamepad.setButtonPressedForTesting(GamepadInput.BTN_DOWN, false)
        gamepad.update()

        // Test Multi-Skill: BTN_Y (Skill 2) dan BTN_R1 (Skill 3)
        gamepad.setButtonPressedForTesting(GamepadInput.BTN_Y, true)
        gamepad.update()
        assertTrue(gamepad.isSkill2JustPressed())
        gamepad.update()
        assertFalse(gamepad.isSkill2JustPressed())
        gamepad.setButtonPressedForTesting(GamepadInput.BTN_Y, false)
        gamepad.update()

        gamepad.setButtonPressedForTesting(GamepadInput.BTN_R1, true)
        gamepad.update()
        assertTrue(gamepad.isSkill3JustPressed())
        gamepad.update()
        assertFalse(gamepad.isSkill3JustPressed())
        gamepad.setButtonPressedForTesting(GamepadInput.BTN_R1, false)
        gamepad.update()
    }

    @Test
    fun testCompositeInputMultiSourceAggregation() {
        val keyboard = KeyboardInput()
        val virtual = VirtualController()
        val gamepad = GamepadInput()
        val composite = CompositeInput(keyboard, virtual, gamepad)

        // By default nothing is pressed
        assertFalse(composite.isMoveLeft())
        assertFalse(composite.isJumpJustPressed())
        assertFalse(composite.isPauseJustPressed())

        // Gamepad triggers jump
        gamepad.isConnectedForTesting = true
        gamepad.setButtonPressedForTesting(GamepadInput.BTN_A, true)
        gamepad.update()
        assertTrue(composite.isJumpJustPressed())

        // Gamepad triggers pause
        gamepad.setButtonPressedForTesting(GamepadInput.BTN_START, true)
        gamepad.update()
        assertTrue(composite.isPauseJustPressed())

        // Initial virtual controller visibility
        assertTrue(virtual.isVisible)
    }
}

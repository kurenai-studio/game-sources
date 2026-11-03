package com.stickman.tower.input

import com.badlogic.gdx.controllers.Controller
import com.badlogic.gdx.controllers.ControllerListener
import com.badlogic.gdx.controllers.ControllerMapping
import com.badlogic.gdx.controllers.Controllers
import kotlin.math.abs

/**
 * Pengelola input fisik gamepad controller (Bluetooth / USB) via gdx-controllers.
 * Mendukung controller XInput (Xbox), DualShock/DualSense (PlayStation), dan gamepad Android standar.
 */
class GamepadInput : GameInput, ControllerListener {

    var activeController: Controller? = null
        private set

    var isConnectedForTesting: Boolean = false

    // Status Penekanan Tombol
    private var moveLeftPressed = false
    private var moveRightPressed = false
    private var upPressed = false
    private var downPressed = false
    private var jumpPressed = false
    private var attackPressed = false
    private var dodgePressed = false
    private var skillPressed = false
    private var skill2Pressed = false
    private var skill3Pressed = false
    private var ultimatePressed = false
    private var pausePressed = false

    private var justPressedJump = false
    private var justPressedAttack = false
    private var justPressedDodge = false
    private var justPressedSkill = false
    private var justPressedSkill2 = false
    private var justPressedSkill3 = false
    private var justPressedUltimate = false
    private var justPressedPause = false
    private var justPressedUp = false
    private var justPressedDown = false

    // State Pelacakan Frame
    private var wasJump = false
    private var wasAttack = false
    private var wasDodge = false
    private var wasSkill = false
    private var wasSkill2 = false
    private var wasSkill3 = false
    private var wasUltimate = false
    private var wasPause = false
    private var wasUp = false
    private var wasDown = false

    var isGamepadInUse: Boolean = false
        private set

    companion object {
        const val BTN_A = 0
        const val BTN_B = 1
        const val BTN_X = 2
        const val BTN_Y = 3
        const val BTN_L1 = 4
        const val BTN_R1 = 5
        const val BTN_START = 7
        const val BTN_UP = 11
        const val BTN_DOWN = 12
        const val BTN_LEFT = 13
        const val BTN_RIGHT = 14
    }

    init {
        try {
            Controllers.addListener(this)
            refreshActiveController()
        } catch (_: Exception) {
            // Abaikan jika runtime platform belum menginisialisasi controller backend (misal saat headless unit test)
        }
    }

    fun refreshActiveController() {
        try {
            val list = Controllers.getControllers()
            if (list != null && list.size > 0) {
                activeController = list.first()
            }
        } catch (_: Exception) {
            activeController = null
        }
    }

    /**
     * Memperbarui status polling controller setiap frame.
     */
    fun update() {
        val controller = activeController ?: run {
            refreshActiveController()
            activeController
        }

        if (controller == null || !controller.isConnected) {
            if (!isConnectedForTesting) {
                moveLeftPressed = false
                moveRightPressed = false
                upPressed = false
                downPressed = false
                jumpPressed = false
                attackPressed = false
                dodgePressed = false
                skillPressed = false
                skill2Pressed = false
                skill3Pressed = false
                ultimatePressed = false
                pausePressed = false
                justPressedJump = false
                justPressedAttack = false
                justPressedDodge = false
                justPressedSkill = false
                justPressedSkill2 = false
                justPressedSkill3 = false
                justPressedUltimate = false
                justPressedPause = false
                justPressedUp = false
                justPressedDown = false
                isGamepadInUse = false
                return
            } else {
                justPressedJump = jumpPressed && !wasJump
                justPressedAttack = attackPressed && !wasAttack
                justPressedDodge = dodgePressed && !wasDodge
                justPressedSkill = skillPressed && !wasSkill
                justPressedSkill2 = skill2Pressed && !wasSkill2
                justPressedSkill3 = skill3Pressed && !wasSkill3
                justPressedUltimate = ultimatePressed && !wasUltimate
                justPressedPause = pausePressed && !wasPause
                justPressedUp = upPressed && !wasUp
                justPressedDown = downPressed && !wasDown

                wasJump = jumpPressed
                wasAttack = attackPressed
                wasDodge = dodgePressed
                wasSkill = skillPressed
                wasSkill2 = skill2Pressed
                wasSkill3 = skill3Pressed
                wasUltimate = ultimatePressed
                wasPause = pausePressed
                wasUp = upPressed
                wasDown = downPressed
                return
            }
        }

        val mapping = controller.mapping

        // 1. Polling Axis Thumbstick Kiri & D-Pad
        val axisX = if (mapping != null && mapping.axisLeftX != ControllerMapping.UNDEFINED) {
            controller.getAxis(mapping.axisLeftX)
        } else {
            if (controller.axisCount > 0) controller.getAxis(0) else 0f
        }

        val axisY = if (mapping != null && mapping.axisLeftY != ControllerMapping.UNDEFINED) {
            controller.getAxis(mapping.axisLeftY)
        } else {
            if (controller.axisCount > 1) controller.getAxis(1) else 0f
        }

        val dpadLeft = mapping?.buttonDpadLeft?.takeIf { it != ControllerMapping.UNDEFINED }?.let { controller.getButton(it) } ?: false
        val dpadRight = mapping?.buttonDpadRight?.takeIf { it != ControllerMapping.UNDEFINED }?.let { controller.getButton(it) } ?: false
        val dpadUp = mapping?.buttonDpadUp?.takeIf { it != ControllerMapping.UNDEFINED }?.let { controller.getButton(it) } ?: false
        val dpadDown = mapping?.buttonDpadDown?.takeIf { it != ControllerMapping.UNDEFINED }?.let { controller.getButton(it) } ?: false

        moveLeftPressed = axisX < -0.35f || dpadLeft
        moveRightPressed = axisX > 0.35f || dpadRight
        upPressed = axisY < -0.35f || dpadUp
        downPressed = axisY > 0.35f || dpadDown

        // 2. Polling Tombol Aksi
        val btnA = mapping?.buttonA?.takeIf { it != ControllerMapping.UNDEFINED }?.let { controller.getButton(it) }
            ?: (if (controller.maxButtonIndex >= 0) controller.getButton(0) else false)

        val btnX = mapping?.buttonX?.takeIf { it != ControllerMapping.UNDEFINED }?.let { controller.getButton(it) }
            ?: (if (controller.maxButtonIndex >= 2) controller.getButton(2) else false)

        val btnB = mapping?.buttonB?.takeIf { it != ControllerMapping.UNDEFINED }?.let { controller.getButton(it) }
            ?: (if (controller.maxButtonIndex >= 1) controller.getButton(1) else false)

        val btnY = mapping?.buttonY?.takeIf { it != ControllerMapping.UNDEFINED }?.let { controller.getButton(it) }
            ?: (if (controller.maxButtonIndex >= 3) controller.getButton(3) else false)

        val btnL1 = mapping?.buttonL1?.takeIf { it != ControllerMapping.UNDEFINED }?.let { controller.getButton(it) }
            ?: (if (controller.maxButtonIndex >= 4) controller.getButton(4) else false)

        val btnR1 = mapping?.buttonR1?.takeIf { it != ControllerMapping.UNDEFINED }?.let { controller.getButton(it) }
            ?: (if (controller.maxButtonIndex >= 5) controller.getButton(5) else false)

        val btnStart = mapping?.buttonStart?.takeIf { it != ControllerMapping.UNDEFINED }?.let { controller.getButton(it) }
            ?: (if (controller.maxButtonIndex >= 7) controller.getButton(7) else false)

        jumpPressed = btnA
        attackPressed = btnX
        dodgePressed = btnB
        skillPressed = btnL1
        skill2Pressed = btnY
        skill3Pressed = btnR1
        ultimatePressed = (btnL1 && btnR1) || (btnY && btnB)
        pausePressed = btnStart

        // 3. Evaluasi Just Pressed
        justPressedJump = btnA && !wasJump
        justPressedAttack = btnX && !wasAttack
        justPressedDodge = btnB && !wasDodge
        justPressedSkill = btnL1 && !wasSkill
        justPressedSkill2 = btnY && !wasSkill2
        justPressedSkill3 = btnR1 && !wasSkill3
        justPressedUltimate = ultimatePressed && !wasUltimate
        justPressedPause = btnStart && !wasPause
        justPressedUp = upPressed && !wasUp
        justPressedDown = downPressed && !wasDown

        wasJump = btnA
        wasAttack = btnX
        wasDodge = btnB
        wasSkill = btnL1
        wasSkill2 = btnY
        wasSkill3 = btnR1
        wasUltimate = ultimatePressed
        wasPause = btnStart
        wasUp = upPressed
        wasDown = downPressed

        // 4. Deteksi Interaktivitas Gamepad (Abaikan sensor noise/drift, utamakan tombol fisik nyata)
        val hasExplicitButtonInput = btnA || btnX || btnB || btnL1 || btnR1 || btnStart || dpadLeft || dpadRight || dpadUp || dpadDown
        val hasDefiniteStickMotion = abs(axisX) > 0.65f || abs(axisY) > 0.65f
        if (hasExplicitButtonInput || hasDefiniteStickMotion) {
            isGamepadInUse = true
        }
    }

    /**
     * Memeriksa apakah terdapat gamepad aktif yang terhubung.
     */
    fun hasActiveGamepad(): Boolean = isConnectedForTesting || (activeController != null && activeController!!.isConnected)

    /**
     * Memicu getaran fisik motor controller (Rumble / Haptic).
     */
    fun vibrate(durationMillis: Int, strength: Float = 0.8f) {
        val ctrl = activeController
        if (ctrl != null && ctrl.isConnected && ctrl.canVibrate()) {
            try {
                ctrl.startVibration(durationMillis, strength)
            } catch (_: Exception) {
            }
        }
    }

    fun setAxisXForTesting(value: Float) {
        moveLeftPressed = value < -0.25f
        moveRightPressed = value > 0.25f
        if (abs(value) > 0.15f) isGamepadInUse = true
    }

    fun setButtonPressedForTesting(buttonCode: Int, pressed: Boolean) {
        when (buttonCode) {
            BTN_A -> {
                jumpPressed = pressed
                justPressedJump = pressed
            }
            BTN_X -> {
                attackPressed = pressed
                justPressedAttack = pressed
            }
            BTN_B -> {
                dodgePressed = pressed
                justPressedDodge = pressed
            }
            BTN_Y -> {
                skill2Pressed = pressed
                justPressedSkill2 = pressed
            }
            BTN_L1 -> {
                skillPressed = pressed
                justPressedSkill = pressed
            }
            BTN_R1 -> {
                skill3Pressed = pressed
                justPressedSkill3 = pressed
            }
            BTN_START -> {
                pausePressed = pressed
                justPressedPause = pressed
            }
            BTN_UP -> {
                upPressed = pressed
                justPressedUp = pressed
            }
            BTN_DOWN -> {
                downPressed = pressed
                justPressedDown = pressed
            }
            BTN_LEFT -> {
                moveLeftPressed = pressed
            }
            BTN_RIGHT -> {
                moveRightPressed = pressed
            }
        }
        if (pressed) isGamepadInUse = true
    }

    // GameInput Implementation
    override fun isMoveLeft(): Boolean = moveLeftPressed
    override fun isMoveRight(): Boolean = moveRightPressed
    override fun isMoveDown(): Boolean = downPressed
    override fun isJumpJustPressed(): Boolean = justPressedJump
    override fun isJumpPressed(): Boolean = jumpPressed
    override fun isAttackJustPressed(): Boolean = justPressedAttack
    override fun isDodgeJustPressed(): Boolean = justPressedDodge
    override fun isSkillJustPressed(): Boolean = justPressedSkill
    override fun isSkill1JustPressed(): Boolean = justPressedSkill
    override fun isSkill2JustPressed(): Boolean = justPressedSkill2
    override fun isSkill3JustPressed(): Boolean = justPressedSkill3
    override fun isUltimateJustPressed(): Boolean = justPressedUltimate
    fun isPauseJustPressed(): Boolean = justPressedPause
    fun isUpJustPressed(): Boolean = justPressedUp
    fun isDownJustPressed(): Boolean = justPressedDown

    // ControllerListener Implementation
    override fun connected(controller: Controller) {
        activeController = controller
        isGamepadInUse = true
    }

    override fun disconnected(controller: Controller) {
        if (activeController == controller) {
            activeController = null
            isGamepadInUse = false
            refreshActiveController()
        }
    }

    override fun buttonDown(controller: Controller, buttonCode: Int): Boolean {
        if (activeController == null) activeController = controller
        isGamepadInUse = true
        return false
    }

    override fun buttonUp(controller: Controller, buttonCode: Int): Boolean = false

    override fun axisMoved(controller: Controller, axisCode: Int, value: Float): Boolean {
        if (abs(value) > 0.25f) {
            if (activeController == null) activeController = controller
            isGamepadInUse = true
        }
        return false
    }
}

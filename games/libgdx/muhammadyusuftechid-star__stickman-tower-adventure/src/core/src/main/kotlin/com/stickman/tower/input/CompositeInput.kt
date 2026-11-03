package com.stickman.tower.input

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.utils.viewport.Viewport

/**
 * Menggabungkan input keyboard (Desktop), virtual touch controller (Android),
 * dan Gamepad fisik (Bluetooth/USB) ke dalam satu antarmuka GameInput yang mulus.
 */
class CompositeInput(
    val keyboard: KeyboardInput,
    val virtual: VirtualController,
    val gamepad: GamepadInput = GamepadInput()
) : GameInput {

    fun update(viewport: Viewport? = null) {
        gamepad.update()

        // Auto-detection: Sembunyikan tombol layar sentuh HANYA jika gamepad fisik aktif digunakan dan autoHide diaktifkan.
        // Segera pulihkan visibilitas tombol jika pemain menyentuh layar.
        val settings = virtual.settings
        if (settings.autoHideOnGamepad && gamepad.hasActiveGamepad() && gamepad.isGamepadInUse) {
            val isScreenTouched = Gdx.input != null && (Gdx.input.isTouched(0) || Gdx.input.isTouched(1))
            virtual.isVisible = isScreenTouched
        } else {
            virtual.isVisible = true
        }

        virtual.update(viewport)
    }

    override fun isMoveLeft() = keyboard.isMoveLeft() || virtual.isMoveLeft() || gamepad.isMoveLeft()
    override fun isMoveRight() = keyboard.isMoveRight() || virtual.isMoveRight() || gamepad.isMoveRight()
    override fun isMoveDown() = keyboard.isMoveDown() || virtual.isMoveDown() || gamepad.isMoveDown()
    override fun isJumpJustPressed() = keyboard.isJumpJustPressed() || virtual.isJumpJustPressed() || gamepad.isJumpJustPressed()
    override fun isJumpPressed() = keyboard.isJumpPressed() || virtual.isJumpPressed() || gamepad.isJumpPressed()
    override fun isAttackJustPressed() = keyboard.isAttackJustPressed() || virtual.isAttackJustPressed() || gamepad.isAttackJustPressed()
    override fun isDodgeJustPressed() = keyboard.isDodgeJustPressed() || virtual.isDodgeJustPressed() || gamepad.isDodgeJustPressed()
    override fun isSkillJustPressed() = keyboard.isSkillJustPressed() || virtual.isSkillJustPressed() || gamepad.isSkillJustPressed()
    override fun isSkill1JustPressed() = keyboard.isSkill1JustPressed() || virtual.isSkill1JustPressed() || gamepad.isSkill1JustPressed()
    override fun isSkill2JustPressed() = keyboard.isSkill2JustPressed() || virtual.isSkill2JustPressed() || gamepad.isSkill2JustPressed()
    override fun isSkill3JustPressed() = keyboard.isSkill3JustPressed() || virtual.isSkill3JustPressed() || gamepad.isSkill3JustPressed()
    override fun isUltimateJustPressed() = keyboard.isUltimateJustPressed() || virtual.isUltimateJustPressed() || gamepad.isUltimateJustPressed()
    fun isPauseJustPressed() = gamepad.isPauseJustPressed()
}

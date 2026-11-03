package com.stickman.tower.input

/**
 * Antarmuka abstraksi input untuk kontrol gameplay.
 * Memisahkan logika karakter dari platform fisik (Keyboard vs Android Touchscreen).
 */
interface GameInput {
    fun isMoveLeft(): Boolean
    fun isMoveRight(): Boolean
    fun isMoveDown(): Boolean = false
    fun isJumpJustPressed(): Boolean
    fun isJumpPressed(): Boolean
    fun isAttackJustPressed(): Boolean
    fun isDodgeJustPressed(): Boolean
    fun isSkillJustPressed(): Boolean // Skill 1
    fun isSkill1JustPressed(): Boolean = isSkillJustPressed()
    fun isSkill2JustPressed(): Boolean = false
    fun isSkill3JustPressed(): Boolean = false
    fun isUltimateJustPressed(): Boolean
}

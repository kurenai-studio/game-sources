package com.stickman.tower.input

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.Input.Buttons
import com.badlogic.gdx.Input.Keys

/**
 * Implementasi input keyboard untuk build Desktop (LWJGL3).
 * Mendukung tombol A/D, Panah Kiri/Kanan, serta Space/W/K untuk melompat.
 */
class KeyboardInput : GameInput {
    override fun isMoveLeft(): Boolean {
        val input = Gdx.input ?: return false
        return input.isKeyPressed(Keys.A) || input.isKeyPressed(Keys.LEFT)
    }

    override fun isMoveRight(): Boolean {
        val input = Gdx.input ?: return false
        return input.isKeyPressed(Keys.D) || input.isKeyPressed(Keys.RIGHT)
    }

    override fun isMoveDown(): Boolean {
        val input = Gdx.input ?: return false
        return input.isKeyPressed(Keys.S) || input.isKeyPressed(Keys.DOWN)
    }

    override fun isJumpJustPressed(): Boolean {
        val input = Gdx.input ?: return false
        return input.isKeyJustPressed(Keys.SPACE) ||
               input.isKeyJustPressed(Keys.W) ||
               input.isKeyJustPressed(Keys.UP) ||
               input.isKeyJustPressed(Keys.K)
    }

    override fun isJumpPressed(): Boolean {
        val input = Gdx.input ?: return false
        return input.isKeyPressed(Keys.SPACE) ||
               input.isKeyPressed(Keys.W) ||
               input.isKeyPressed(Keys.UP) ||
               input.isKeyPressed(Keys.K)
    }

    override fun isAttackJustPressed(): Boolean {
        val input = Gdx.input ?: return false
        return input.isKeyJustPressed(Keys.J) ||
               input.isKeyJustPressed(Keys.ENTER) ||
               input.isKeyJustPressed(Keys.X) ||
               input.isButtonJustPressed(Buttons.LEFT)
    }

    override fun isDodgeJustPressed(): Boolean {
        val input = Gdx.input ?: return false
        return input.isKeyJustPressed(Keys.L) ||
               input.isKeyJustPressed(Keys.SHIFT_LEFT) ||
               input.isKeyJustPressed(Keys.C)
    }

    override fun isSkillJustPressed(): Boolean {
        val input = Gdx.input ?: return false
        return input.isKeyJustPressed(Keys.U) ||
               input.isKeyJustPressed(Keys.NUM_1) ||
               input.isKeyJustPressed(Keys.E)
    }

    override fun isSkill1JustPressed(): Boolean = isSkillJustPressed()

    override fun isSkill2JustPressed(): Boolean {
        val input = Gdx.input ?: return false
        return input.isKeyJustPressed(Keys.I) ||
               input.isKeyJustPressed(Keys.NUM_2) ||
               input.isKeyJustPressed(Keys.R)
    }

    override fun isSkill3JustPressed(): Boolean {
        val input = Gdx.input ?: return false
        return input.isKeyJustPressed(Keys.O) ||
               input.isKeyJustPressed(Keys.NUM_3) ||
               input.isKeyJustPressed(Keys.F)
    }

    override fun isUltimateJustPressed(): Boolean {
        val input = Gdx.input ?: return false
        return input.isKeyJustPressed(Keys.P) ||
               input.isKeyJustPressed(Keys.NUM_4) ||
               input.isKeyJustPressed(Keys.Q) ||
               input.isKeyJustPressed(Keys.V)
    }
}

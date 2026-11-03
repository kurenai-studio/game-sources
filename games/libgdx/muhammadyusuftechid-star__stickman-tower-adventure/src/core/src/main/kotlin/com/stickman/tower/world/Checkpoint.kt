package com.stickman.tower.world

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Rectangle

/**
 * Objek Lentera Checkpoint.
 * Saat disentuh pemain, api lentera menyala biru cerah (CYAN) dan mencatat lokasi respawn.
 */
class Checkpoint(val x: Float, val y: Float) {
    val bounds = Rectangle(x - 0.6f, y, 1.2f, 2.0f)
    var isActivated: Boolean = false
        private set

    companion object {
        private val COLOR_PILLAR = Color(0.2f, 0.22f, 0.28f, 1f)
        private val COLOR_HOLDER = Color(0.35f, 0.38f, 0.45f, 1f)
        private val COLOR_INACTIVE_FLAME = Color(0.45f, 0.45f, 0.45f, 0.7f)
    }

    fun checkTrigger(playerBounds: Rectangle): Boolean {
        if (!isActivated && bounds.overlaps(playerBounds)) {
            isActivated = true
            return true
        }
        return false
    }

    fun render(shapeRenderer: ShapeRenderer) {
        // 1. Tiang Batu (Pillar)
        shapeRenderer.color = COLOR_PILLAR
        shapeRenderer.rect(x - 0.15f, y, 0.3f, 1.2f)

        // Dudukan Lentera
        shapeRenderer.color = COLOR_HOLDER
        shapeRenderer.rect(x - 0.25f, y + 1.2f, 0.5f, 0.15f)

        // 2. Api Lentera (Dim Amber jika belum aktif, Cyan Menyala jika sudah aktif)
        val flameColor = if (isActivated) Color.CYAN else COLOR_INACTIVE_FLAME
        shapeRenderer.color = flameColor
        shapeRenderer.circle(x, y + 1.55f, if (isActivated) 0.22f else 0.14f, 12)

        // Inti Api Terang
        if (isActivated) {
            shapeRenderer.color = Color.WHITE
            shapeRenderer.circle(x, y + 1.55f, 0.09f, 8)
        }
    }
}

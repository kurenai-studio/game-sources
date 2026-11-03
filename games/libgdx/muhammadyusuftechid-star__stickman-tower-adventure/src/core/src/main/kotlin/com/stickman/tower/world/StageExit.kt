package com.stickman.tower.world

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Rectangle

/**
 * Pintu Portal Menara (Stage Exit).
 * Terletak di ujung stage dan memicu kemenangan saat dimasuki pemain.
 */
class StageExit(val x: Float, val y: Float, val width: Float = 1.6f, val height: Float = 2.8f) {
    val bounds = Rectangle(x, y, width, height)

    companion object {
        private val COLOR_FRAME = Color(0.18f, 0.2f, 0.26f, 1f)
        private val COLOR_PORTAL_GLOW = Color(0.95f, 0.8f, 0.25f, 0.75f)
        private val COLOR_PORTAL_CORE = Color(1f, 1f, 0.85f, 0.9f)
    }

    fun render(shapeRenderer: ShapeRenderer) {
        // 1. Bingkai Pintu Batu (Door Arch Frame)
        shapeRenderer.color = COLOR_FRAME
        shapeRenderer.rect(x - 0.2f, y, 0.2f, height + 0.2f)           // Pilar Kiri
        shapeRenderer.rect(x + width, y, 0.2f, height + 0.2f)          // Pilar Kanan
        shapeRenderer.rect(x - 0.2f, y + height, width + 0.4f, 0.25f)  // Atap Lengkung

        // 2. Efek Cahaya Portal (Glowing Portal Interior)
        shapeRenderer.color = COLOR_PORTAL_GLOW
        shapeRenderer.rect(x, y, width, height)

        // Inti Cahaya Terang di Tengah
        shapeRenderer.color = COLOR_PORTAL_CORE
        shapeRenderer.rect(x + 0.25f, y + 0.25f, width - 0.5f, height - 0.5f)
    }
}

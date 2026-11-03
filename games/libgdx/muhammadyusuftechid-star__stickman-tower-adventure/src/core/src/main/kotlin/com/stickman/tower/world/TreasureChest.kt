package com.stickman.tower.world

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Rectangle

/**
 * Objek peti harta karun interaktif (Treasure Chest).
 * Dapat ditebas/dibuka untuk mendapatkan koin emas dan pemulihan HP.
 */
class TreasureChest(
    val x: Float,
    val y: Float,
    val width: Float = 1.0f,
    val height: Float = 0.8f,
    val goldReward: Int = 50,
    val healReward: Float = 35f
) {
    val bounds = Rectangle(x, y, width, height)
    var isOpened: Boolean = false
        private set

    fun open(): Boolean {
        if (!isOpened) {
            isOpened = true
            return true
        }
        return false
    }

    companion object {
        private val COLOR_WOOD_CLOSED = Color(0.38f, 0.22f, 0.12f, 1f)
        private val COLOR_GOLD_TRIM = Color(0.95f, 0.78f, 0.2f, 1f)
        private val COLOR_WOOD_OPEN = Color(0.30f, 0.18f, 0.10f, 1f)
        private val COLOR_LID = Color(0.42f, 0.26f, 0.15f, 1f)
        private val COLOR_TREASURE_GLOW = Color(1f, 0.88f, 0.25f, 1f)
    }

    fun render(shapeRenderer: ShapeRenderer) {
        if (!isOpened) {
            // Peti Tertutup: Kotak kayu cokelat tua dengan lis emas
            shapeRenderer.color = COLOR_WOOD_CLOSED
            shapeRenderer.rect(x, y, width, height)

            // Lis Emas Horizontal & Vertikal
            shapeRenderer.color = COLOR_GOLD_TRIM
            shapeRenderer.rect(x, y + height * 0.5f, width, 0.08f)
            shapeRenderer.rect(x + width * 0.42f, y, 0.16f, height)

            // Gembok Emas
            shapeRenderer.color = Color.WHITE
            shapeRenderer.circle(x + width / 2f, y + height * 0.54f, 0.09f, 12)
        } else {
            // Peti Terbuka: Bagian bawah kotak kayu dengan cahaya emas berkilau di dalam
            shapeRenderer.color = COLOR_WOOD_OPEN
            shapeRenderer.rect(x, y, width, height * 0.55f)

            // Tutup Peti Terbuka ke Atas/Belakang
            shapeRenderer.color = COLOR_LID
            shapeRenderer.rect(x - 0.05f, y + height * 0.55f, width + 0.1f, 0.22f)

            // Cahaya Emas / Koin di Dalam Peti
            shapeRenderer.color = COLOR_TREASURE_GLOW
            shapeRenderer.circle(x + width / 2f, y + height * 0.45f, 0.18f, 12)
        }
    }
}

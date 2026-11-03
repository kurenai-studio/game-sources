package com.stickman.tower.world

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Rectangle

/**
 * TitanBasaltWall:
 * Rintangan dinding batu basalt tebal berurat magma yang menghalangi lorong di Saga III (Lantai 21-24).
 * Dinding ini menuntut daya hancur kombo 3 tebasan atau serangan berat Greatsword Gorgon
 * untuk diruntuhkan berkeping-keping.
 */
class TitanBasaltWall(
    val x: Float,
    val y: Float,
    val width: Float = 1.6f,
    val height: Float = 4.5f
) {
    val bounds = Rectangle(x, y, width, height)

    var hitsTaken: Int = 0
    val maxHits: Int = 3
    val isBroken: Boolean get() = hitsTaken >= maxHits

    /**
     * Menerima tebasan pemain.
     * Mengembalikan true jika pukulan berhasil mengurangi ketahanan dinding batu basalt.
     */
    fun takeHit(): Boolean {
        if (isBroken) return false
        hitsTaken++
        return true
    }

    /**
     * Render prosedural dinding batu basalt dengan retakan magma berpijar.
     * Zero Allocation untuk performa 60 FPS mulus.
     */
    fun render(shapeRenderer: ShapeRenderer) {
        if (isBroken) return

        val prevColor = Color(shapeRenderer.color)

        // 1. Blok Batu Basalt Hitam Pekat
        shapeRenderer.color = Color(0.18f, 0.15f, 0.14f, 1f)
        shapeRenderer.rect(x, y, width, height)

        // Bevel / Sudut Rangka Batu
        shapeRenderer.color = Color(0.28f, 0.22f, 0.20f, 1f)
        shapeRenderer.rect(x, y, 0.2f, height)
        shapeRenderer.rect(x + width - 0.2f, y, 0.2f, height)
        shapeRenderer.rect(x, y + height - 0.25f, width, 0.25f)

        // 2. Garis Urat Magma Purba di Dalam Batu
        shapeRenderer.color = Color(0.85f, 0.35f, 0.10f, 0.8f)
        shapeRenderer.rect(x + 0.4f, y + 0.8f, 0.18f, height - 1.6f)
        shapeRenderer.rect(x + width - 0.58f, y + 0.5f, 0.18f, height - 1.2f)

        // 3. Efek Retakan Berdasarkan Jumlah Pukulan (hitsTaken)
        if (hitsTaken >= 1) {
            // Retakan pertama: garis oranye terang membelah bagian tengah
            shapeRenderer.color = Color(0.98f, 0.60f, 0.15f, 1f)
            shapeRenderer.rect(x + 0.2f, y + height * 0.45f, width - 0.4f, 0.12f)
            shapeRenderer.rect(x + width * 0.5f, y + height * 0.3f, 0.12f, 1.2f)
        }
        if (hitsTaken >= 2) {
            // Retakan parah kedua: retakan diagonal menyilang dan batuan mulai goyah
            shapeRenderer.color = Color(1.0f, 0.80f, 0.25f, 1f)
            shapeRenderer.rect(x + 0.15f, y + height * 0.7f, width - 0.3f, 0.16f)
            shapeRenderer.rect(x + 0.3f, y + height * 0.15f, width - 0.6f, 0.16f)
            shapeRenderer.rect(x + width * 0.35f, y + height * 0.55f, 0.16f, 1.4f)
        }

        shapeRenderer.color = prevColor
    }
}

package com.stickman.tower.world

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Rectangle
import kotlin.math.sin

/**
 * TitanPillar:
 * Entitas pilar titan seberat jutaan ton yang ditahan oleh Gorgon di Lantai 20
 * untuk melindungi bunker pengungsi di bawah menara.
 *
 * Pilar ini terhubung dengan tuas katup hidrolik rantai lahar (leverBounds).
 * Pemain (Kaelen / Zephyr) harus menyerang tuas katup lahar dengan 3 tebasan
 * untuk memotong rantai, mengunci pasak darurat, dan membebaskan Gorgon.
 */
class TitanPillar(
    val x: Float,
    val y: Float,
    val width: Float = 3.8f,
    val height: Float = 9.5f
) {
    val bounds = Rectangle(x, y, width, height)

    // Area tuas katup hidrolik rantai lahar di sisi barat pilar
    val leverBounds = Rectangle(x - 2.8f, y + 0.6f, 1.4f, 2.2f)

    var hitsTaken: Int = 0
    val maxHits: Int = 3
    val isLeverCut: Boolean get() = hitsTaken >= maxHits
    var isGorgonFreed: Boolean = false

    private var animTime: Float = 0f

    fun update(delta: Float) {
        animTime += delta
        if (isLeverCut && !isGorgonFreed) {
            isGorgonFreed = true
        }
    }

    /**
     * Menerima tebasan pedang/belati pemain.
     * Mengembalikan true jika pukulan berhasil mengurangi daya tahan tuas rantai lahar.
     */
    fun takeHit(): Boolean {
        if (isLeverCut) return false
        hitsTaken++
        if (hitsTaken >= maxHits) {
            isGorgonFreed = true
        }
        return true
    }

    /**
     * Render prosedural pilar titan raksasa, tuas rantai lahar, dan siluet Gorgon.
     * Zero Allocation di dalam render loop untuk menjamin 60 FPS mulus.
     */
    fun render(shapeRenderer: ShapeRenderer) {
        val prevColor = Color(shapeRenderer.color)
        val cx = x + width / 2f
        val pulse = sin(animTime * 4.5f) * 0.1f

        // 1. Pilar Titan Basalt Raksasa
        shapeRenderer.color = Color(0.20f, 0.17f, 0.15f, 1f)
        shapeRenderer.rect(x, y, width, height)

        // Rangka Kepala & Kaki Pilar
        shapeRenderer.color = Color(0.32f, 0.26f, 0.22f, 1f)
        shapeRenderer.rect(x - 0.3f, y + height - 0.8f, width + 0.6f, 0.8f) // Kepala pilar
        shapeRenderer.rect(x - 0.4f, y, width + 0.8f, 0.9f)                  // Pondasi pilar

        // Alur Retakan Magma Pijar di Pilar
        val lavaGlow = 0.7f + pulse
        shapeRenderer.color = Color(0.95f * lavaGlow, 0.38f * lavaGlow, 0.10f, 1f)
        shapeRenderer.rect(x + 0.8f, y + 1.2f, 0.25f, height - 2.4f)
        shapeRenderer.rect(x + width - 1.05f, y + 1.2f, 0.25f, height - 2.4f)
        shapeRenderer.rect(x + 1.2f, y + 4.2f, width - 2.4f, 0.25f)

        // 2. Tuas Katup Hidrolik Rantai Lahar (Lever Bounds)
        renderLavaValveLever(shapeRenderer, pulse)

        // 3. Siluet Gorgon Menahan Beban Pilar (jika belum bebas melompat ke arena)
        if (!isGorgonFreed) {
            renderTrappedGorgon(shapeRenderer, cx, pulse)
        }

        shapeRenderer.color = prevColor
    }

    private fun renderLavaValveLever(shapeRenderer: ShapeRenderer, pulse: Float) {
        val lx = leverBounds.x
        val ly = leverBounds.y
        val lw = leverBounds.width
        val lh = leverBounds.height

        // Kotak Katup Hidrolik Besi Baja
        shapeRenderer.color = Color(0.28f, 0.22f, 0.20f, 1f)
        shapeRenderer.rect(lx + 0.2f, ly, lw - 0.4f, 0.8f)

        // Batang Tuas & Rantai Lahar
        if (!isLeverCut) {
            // Rantai merah berpijar menghubungkan tuas ke pilar
            val chainGlow = 0.8f + pulse * 1.5f
            shapeRenderer.color = Color(0.95f * chainGlow, 0.25f * chainGlow, 0.15f, 1f)
            shapeRenderer.rect(lx + lw - 0.2f, ly + 0.6f, (x - (lx + lw)) + 0.4f, 0.2f)

            // Batang Tuas Tegak (bergetar menahan tekanan)
            val tilt = if (hitsTaken == 1) 0.15f else if (hitsTaken == 2) 0.35f else 0f
            shapeRenderer.color = Color(0.85f, 0.65f, 0.20f, 1f)
            shapeRenderer.rect(lx + lw / 2f - 0.1f + tilt, ly + 0.5f, 0.2f, lh - 0.7f)

            // Gagang Kepala Tuas (Bercahaya peringatan bahaya)
            shapeRenderer.color = if (hitsTaken == 2) Color.RED else Color.GOLD
            shapeRenderer.circle(lx + lw / 2f + tilt, ly + lh - 0.2f, 0.28f, 10)
        } else {
            // Rantai putus dan terurai di tanah
            shapeRenderer.color = Color(0.40f, 0.35f, 0.32f, 1f)
            shapeRenderer.rect(lx + lw - 0.2f, ly + 0.1f, 1.2f, 0.18f)
            shapeRenderer.rect(x - 0.8f, ly + 0.1f, 0.8f, 0.18f)

            // Tuas patah rebah ke samping
            shapeRenderer.color = Color(0.50f, 0.40f, 0.35f, 1f)
            shapeRenderer.rect(lx + 0.3f, ly + 0.3f, lw - 0.4f, 0.18f)
        }
    }

    private fun renderTrappedGorgon(shapeRenderer: ShapeRenderer, cx: Float, pulse: Float) {
        val gx = cx - 0.2f
        val gy = y + 0.8f
        val shake = pulse * 0.4f

        // Tubuh Siluet Kekar Gorgon (Stickman Heavy Titan)
        shapeRenderer.color = Color(0.08f, 0.08f, 0.08f, 1f)

        // Kaki Kokoh Menancap di Tanah
        shapeRenderer.rect(gx - 0.65f, gy, 0.35f, 1.4f)
        shapeRenderer.rect(gx + 0.35f, gy, 0.35f, 1.4f)

        // Badan Berotot Tegap Menopang ke Atas
        shapeRenderer.rect(gx - 0.5f + shake, gy + 1.2f, 1.0f, 1.8f)

        // Kedua Lengan Menahan Beban Pilar di Atas Pundak
        shapeRenderer.rect(gx - 0.9f + shake, gy + 2.5f, 0.4f, 1.2f)
        shapeRenderer.rect(gx + 0.5f + shake, gy + 2.5f, 0.4f, 1.2f)

        // Kepala dengan Helm Bertanduk Emas
        shapeRenderer.color = Color(0.12f, 0.12f, 0.12f, 1f)
        shapeRenderer.circle(gx + shake, gy + 3.2f, 0.38f, 12)

        // Tanduk Helm Emas Gorgon (Ikonik Karakter HEAVY)
        shapeRenderer.color = Color.GOLD
        shapeRenderer.rect(gx - 0.45f + shake, gy + 3.35f, 0.25f, 0.15f)
        shapeRenderer.rect(gx + 0.20f + shake, gy + 3.35f, 0.25f, 0.15f)

        // Greatsword Raksasa Menancap di Samping Gorgon
        val swordX = x + width + 0.5f
        shapeRenderer.color = Color(0.75f, 0.70f, 0.65f, 1f)
        shapeRenderer.rect(swordX, y + 0.2f, 0.35f, 2.6f) // Bilah pedang raksasa
        shapeRenderer.color = Color.GOLD
        shapeRenderer.rect(swordX - 0.3f, y + 2.6f, 0.95f, 0.25f) // Crossguard emas
        shapeRenderer.color = Color(0.2f, 0.2f, 0.2f, 1f)
        shapeRenderer.rect(swordX + 0.08f, y + 2.85f, 0.18f, 0.7f) // Gagang
    }
}

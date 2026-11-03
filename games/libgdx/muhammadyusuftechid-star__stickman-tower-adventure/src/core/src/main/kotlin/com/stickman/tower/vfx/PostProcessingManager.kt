package com.stickman.tower.vfx

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.OrthographicCamera
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.MathUtils
import kotlin.math.sin

/**
 * Manajer Efek Pasca-Pemrosesan Grafis (Post-Processing & Visual Fidelity 10/10):
 * Menghadirkan atmosfer grafis kelas atas (AAA Game Feel) tanpa alokasi memori (Zero Allocation):
 * 1. Living Canvas Vignette: Bingkai gradien tinta gelap di sekeliling viewport menyerupai naskah kanvas hidup.
 * 2. Critical Low-HP Crimson Pulse: Denyut merah berdetak di pinggir layar saat nyawa kritis (< 30%).
 * 3. Screen Impact Flash: Kilatan cahaya eksponensial saat Perfect Parry, Boss Defeat, atau Super Finish.
 * 4. Chromatic Shockwave Distortion Ring: Cincin pembiasan cahaya radial saat ledakan bos atau benturan masif.
 */
class PostProcessingManager {

    // Parameter Screen Impact Flash
    private var flashTimer = 0f
    private var flashDuration = 0f
    private var flashR = 1f
    private var flashG = 1f
    private var flashB = 1f
    private var flashMaxAlpha = 0.5f

    // Parameter Heartbeat Crimson Pulse (Near-Death Feedback)
    private var pulseAnimTime = 0f

    // Parameter Chromatic Distortion Shockwave
    private var shockwaveActive = false
    private var shockwaveCenterX = 0f
    private var shockwaveCenterY = 0f
    private var shockwaveRadius = 0f
    private var shockwaveMaxRadius = 24f
    private var shockwaveSpeed = 38f
    private var shockwaveLife = 0f
    private var shockwaveMaxLife = 0.65f

    companion object {
        // Cached colors untuk zero GC allocation
        private val COLOR_VIGNETTE_OUTER = Color(0.02f, 0.02f, 0.05f, 0.72f)
        private val COLOR_VIGNETTE_INNER = Color(0f, 0f, 0f, 0f)
        private val COLOR_CRIMSON_PULSE = Color(0.75f, 0.05f, 0.08f, 0.45f)
        private val COLOR_CHROMA_RED = Color(1.0f, 0.2f, 0.2f, 0.5f)
        private val COLOR_CHROMA_CYAN = Color(0.2f, 0.9f, 1.0f, 0.5f)
        private val COLOR_CHROMA_GOLD = Color(1.0f, 0.85f, 0.2f, 0.8f)
    }

    fun update(delta: Float) {
        pulseAnimTime += delta

        if (flashTimer > 0f) {
            flashTimer = (flashTimer - delta).coerceAtLeast(0f)
        }

        if (shockwaveActive) {
            shockwaveLife += delta
            shockwaveRadius += shockwaveSpeed * delta
            if (shockwaveLife >= shockwaveMaxLife || shockwaveRadius >= shockwaveMaxRadius) {
                shockwaveActive = false
            }
        }
    }

    /**
     * Memicu kilatan cahaya layar penuh (Flash Effect).
     * @param r, g, b Komponen warna kilatan (misal 1, 1, 1 untuk Whiteout Parry, 1, 0.85, 0.2 untuk Gold Victory)
     * @param duration Durasi kilatan dalam detik (misal 0.15s - 0.35s)
     * @param maxAlpha Intensitas puncak transparansi (0.0f - 1.0f)
     */
    fun triggerFlash(r: Float, g: Float, b: Float, duration: Float = 0.22f, maxAlpha: Float = 0.45f) {
        flashR = r
        flashG = g
        flashB = b
        flashDuration = duration
        flashTimer = duration
        flashMaxAlpha = maxAlpha
    }

    /**
     * Memicu gelombang kejut radial kromatik (Chromatic Shockwave Wave).
     */
    fun triggerChromaticShockwave(x: Float, y: Float, maxRadius: Float = 22f, speed: Float = 36f, duration: Float = 0.6f) {
        shockwaveActive = true
        shockwaveCenterX = x
        shockwaveCenterY = y
        shockwaveRadius = 0.5f
        shockwaveMaxRadius = maxRadius
        shockwaveSpeed = speed
        shockwaveLife = 0f
        shockwaveMaxLife = duration
    }

    /**
     * Merender pass post-processing dunia (misal Chromatic Shockwave) dalam ruang koordinat kamera dunia.
     * Dipanggil sebelum penutupan ShapeRenderer pass dunia.
     */
    fun renderWorldPostEffects(shapeRenderer: ShapeRenderer) {
        if (!shockwaveActive || shockwaveRadius <= 0f) return

        val progress = (shockwaveLife / shockwaveMaxLife).coerceIn(0f, 1f)
        val alpha = (1f - progress) * 0.85f

        // Cincin Luar (Cyan Chromatic Ring)
        shapeRenderer.setColor(COLOR_CHROMA_CYAN.r, COLOR_CHROMA_CYAN.g, COLOR_CHROMA_CYAN.b, alpha * 0.6f)
        shapeRenderer.circle(shockwaveCenterX, shockwaveCenterY, shockwaveRadius + 0.35f, 40)

        // Cincin Tengah (Golden High-Energy Wave)
        shapeRenderer.setColor(COLOR_CHROMA_GOLD.r, COLOR_CHROMA_GOLD.g, COLOR_CHROMA_GOLD.b, alpha * 0.9f)
        shapeRenderer.circle(shockwaveCenterX, shockwaveCenterY, shockwaveRadius, 44)

        // Cincin Dalam (Red Chromatic Ring)
        shapeRenderer.setColor(COLOR_CHROMA_RED.r, COLOR_CHROMA_RED.g, COLOR_CHROMA_RED.b, alpha * 0.6f)
        val innerR = (shockwaveRadius - 0.35f).coerceAtLeast(0.1f)
        shapeRenderer.circle(shockwaveCenterX, shockwaveCenterY, innerR, 40)
    }

    /**
     * Merender pass post-processing layar penuh (Vignette, Crimson Pulse, Flash) dalam koordinat layar (UI Camera).
     * Dipanggil di atas tampilan game untuk memberikan bingkai sinematik.
     */
    fun renderScreenPostEffects(
        shapeRenderer: ShapeRenderer,
        uiWidth: Float,
        uiHeight: Float,
        playerHpRatio: Float
    ) {
        val borderWidth = uiWidth * 0.085f
        val borderHeight = uiHeight * 0.085f

        // 1. Living Canvas Edge Vignette (Bingkai Tinta Lembut di Tepi Layar)
        // Atas
        shapeRenderer.rect(0f, uiHeight - borderHeight, uiWidth, borderHeight,
            COLOR_VIGNETTE_INNER, COLOR_VIGNETTE_INNER, COLOR_VIGNETTE_OUTER, COLOR_VIGNETTE_OUTER)
        // Bawah
        shapeRenderer.rect(0f, 0f, uiWidth, borderHeight,
            COLOR_VIGNETTE_OUTER, COLOR_VIGNETTE_OUTER, COLOR_VIGNETTE_INNER, COLOR_VIGNETTE_INNER)
        // Kiri
        shapeRenderer.rect(0f, 0f, borderWidth, uiHeight,
            COLOR_VIGNETTE_OUTER, COLOR_VIGNETTE_INNER, COLOR_VIGNETTE_INNER, COLOR_VIGNETTE_OUTER)
        // Kanan
        shapeRenderer.rect(uiWidth - borderWidth, 0f, borderWidth, uiHeight,
            COLOR_VIGNETTE_INNER, COLOR_VIGNETTE_OUTER, COLOR_VIGNETTE_OUTER, COLOR_VIGNETTE_INNER)

        // 2. Critical Low-HP Crimson Pulse (Denyut Merah Horor saat HP < 30%)
        if (playerHpRatio in 0.001f..0.30f) {
            val pulseFreq = 6.5f + (1f - playerHpRatio / 0.30f) * 4.5f
            val pulseIntensity = (sin(pulseAnimTime * pulseFreq) * 0.5f + 0.5f) * (1f - playerHpRatio / 0.30f)
            val crimsonAlpha = MathUtils.clamp(pulseIntensity * 0.42f, 0f, 0.45f)

            shapeRenderer.setColor(COLOR_CRIMSON_PULSE.r, COLOR_CRIMSON_PULSE.g, COLOR_CRIMSON_PULSE.b, crimsonAlpha)
            // Bingkai denyut merah di 4 sisi
            shapeRenderer.rect(0f, uiHeight - borderHeight * 1.5f, uiWidth, borderHeight * 1.5f)
            shapeRenderer.rect(0f, 0f, uiWidth, borderHeight * 1.5f)
            shapeRenderer.rect(0f, 0f, borderWidth * 1.5f, uiHeight)
            shapeRenderer.rect(uiWidth - borderWidth * 1.5f, 0f, borderWidth * 1.5f, uiHeight)
        }

        // 3. Screen Impact Flash (Whiteout / Gold Burst)
        if (flashTimer > 0f && flashDuration > 0f) {
            val progress = (flashTimer / flashDuration).coerceIn(0f, 1f)
            val currentAlpha = progress * flashMaxAlpha
            shapeRenderer.setColor(flashR, flashG, flashB, currentAlpha)
            shapeRenderer.rect(0f, 0f, uiWidth, uiHeight)
        }
    }
}

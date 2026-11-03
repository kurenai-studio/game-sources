package com.stickman.tower.world

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.OrthographicCamera
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.MathUtils
import kotlin.math.sin

/**
 * Procedural Multi-Layer Parallax Background & Atmospheric Renderer:
 * Menghasilkan latar belakang arsitektur menara bertingkat (gothic ruins, obsidian forge,
 * celestial spires, dan void abyss) dengan paralaks kamera, efek atmosferik, dan partikel
 * ambien tanpa alokasi memori (Zero GC Allocation) pada hot render loop.
 */
class ProceduralBackgroundRenderer {

    // Kumpulan warna statis untuk mencegah GC churn
    companion object {
        // Sanctuary (Floors 1-3)
        private val SANC_FAR_TOWER = Color(0.06f, 0.08f, 0.12f, 0.90f)
        private val SANC_MID_PILLAR = Color(0.09f, 0.11f, 0.16f, 0.95f)
        private val SANC_WINDOW_GLOW = Color(0.85f, 0.70f, 0.30f, 0.35f)
        private val SANC_MOTE = Color(0.70f, 0.80f, 0.95f, 0.40f)

        // Obsidian Crucible (Floors 4-6)
        private val OBSID_FAR_RIDGE = Color(0.08f, 0.04f, 0.08f, 0.92f)
        private val OBSID_MID_PILLAR = Color(0.12f, 0.05f, 0.07f, 0.95f)
        private val OBSID_VENT_GLOW = Color(0.95f, 0.35f, 0.10f, 0.50f)
        private val OBSID_EMBER = Color(1.0f, 0.55f, 0.15f, 0.65f)

        // Celestial Zenith (Floors 7-9)
        private val CELEST_FAR_SPIRE = Color(0.03f, 0.04f, 0.10f, 0.92f)
        private val CELEST_MID_PILLAR = Color(0.05f, 0.08f, 0.16f, 0.95f)
        private val CELEST_RUNE_GLOW = Color(0.25f, 0.75f, 1.0f, 0.45f)
        private val CELEST_STARDUST = Color(0.80f, 0.92f, 1.0f, 0.55f)

        // Apex of the Abyss (Floor 10)
        private val ABYSS_FAR_RIFT = Color(0.02f, 0.02f, 0.04f, 0.95f)
        private val ABYSS_MID_MONOLITH = Color(0.05f, 0.03f, 0.08f, 0.98f)
        private val ABYSS_PULSE_GLOW = Color(0.75f, 0.20f, 0.85f, 0.40f)
        private val ABYSS_VOID_MOTE = Color(0.60f, 0.15f, 0.70f, 0.50f)

        private const val MAX_AMBIENT_MOTES = 24
    }

    // Pre-allocated arrays untuk partikel ambien (Zero Allocation)
    private val moteX = FloatArray(MAX_AMBIENT_MOTES)
    private val moteY = FloatArray(MAX_AMBIENT_MOTES)
    private val moteSize = FloatArray(MAX_AMBIENT_MOTES)
    private val moteSpeed = FloatArray(MAX_AMBIENT_MOTES)
    private val motePhase = FloatArray(MAX_AMBIENT_MOTES)
    private var isMotesInitialized = false

    private fun initMotes() {
        if (isMotesInitialized) return
        for (i in 0 until MAX_AMBIENT_MOTES) {
            moteX[i] = MathUtils.random(-10f, 40f)
            moteY[i] = MathUtils.random(-5f, 25f)
            moteSize[i] = MathUtils.random(0.04f, 0.10f)
            moteSpeed[i] = MathUtils.random(0.4f, 1.2f)
            motePhase[i] = MathUtils.random(0f, 6.28f)
        }
        isMotesInitialized = true
    }

    /**
     * Merender latar belakang berlapis paralaks langsung ke ShapeRenderer
     * yang sedang aktif di pass dunia (sebelum platform & entitas).
     */
    fun render(
        shapeRenderer: ShapeRenderer,
        camera: OrthographicCamera,
        floorNumber: Int,
        animTime: Float,
        mapWidth: Float
    ) {
        initMotes()

        val camX = camera.position.x
        val camY = camera.position.y
        val halfW = camera.viewportWidth / 2f
        val halfH = camera.viewportHeight / 2f

        val viewLeft = camX - halfW
        val viewRight = camX + halfW
        val viewBottom = camY - halfH
        val viewTop = camY + halfH

        // 1. Tentukan Biome dan Warna tanpa alokasi objek
        val farColor: Color
        val midColor: Color
        val glowColor: Color
        val moteColor: Color

        when {
            floorNumber == 10 -> {
                farColor = ABYSS_FAR_RIFT
                midColor = ABYSS_MID_MONOLITH
                glowColor = ABYSS_PULSE_GLOW
                moteColor = ABYSS_VOID_MOTE
            }
            floorNumber in 7..9 -> {
                farColor = CELEST_FAR_SPIRE
                midColor = CELEST_MID_PILLAR
                glowColor = CELEST_RUNE_GLOW
                moteColor = CELEST_STARDUST
            }
            floorNumber in 4..6 -> {
                farColor = OBSID_FAR_RIDGE
                midColor = OBSID_MID_PILLAR
                glowColor = OBSID_VENT_GLOW
                moteColor = OBSID_EMBER
            }
            else -> {
                farColor = SANC_FAR_TOWER
                midColor = SANC_MID_PILLAR
                glowColor = SANC_WINDOW_GLOW
                moteColor = SANC_MOTE
            }
        }

        // ==========================================
        // 2. LAYER 1: Distant Silhouette Towers (Parallax Factor: 0.15)
        // ==========================================
        val farParallax = 0.15f
        val farOffset = camX * farParallax
        val towerSpacing = 6.0f
        val startFarIdx = ((viewLeft - farOffset) / towerSpacing).toInt() - 1
        val endFarIdx = ((viewRight - farOffset) / towerSpacing).toInt() + 2

        shapeRenderer.color = farColor
        for (i in startFarIdx..endFarIdx) {
            val towerBaseX = (i * towerSpacing) + farOffset
            val towerW = 2.2f + ((i % 3) * 0.4f)
            val towerH = 12f + ((i * 7) % 5) * 1.5f
            val towerBaseY = viewBottom - 1f

            // Menara Siluet Jauh
            shapeRenderer.rect(towerBaseX, towerBaseY, towerW, towerH)

            // Puncak Menara / Atap Segitiga
            shapeRenderer.triangle(
                towerBaseX - 0.2f, towerBaseY + towerH,
                towerBaseX + towerW + 0.2f, towerBaseY + towerH,
                towerBaseX + towerW / 2f, towerBaseY + towerH + 1.8f
            )

            // Jendela Siluet Cahaya Samar
            shapeRenderer.color = glowColor
            val winY = towerBaseY + 4f + ((i % 4) * 1.2f)
            if (winY < viewTop) {
                shapeRenderer.rect(towerBaseX + towerW / 2f - 0.2f, winY, 0.4f, 0.7f)
            }
            shapeRenderer.color = farColor
        }

        // ==========================================
        // 3. LAYER 2: Midground Columns & Arches (Parallax Factor: 0.35)
        // ==========================================
        val midParallax = 0.35f
        val midOffset = camX * midParallax
        val pillarSpacing = 8.5f
        val startMidIdx = ((viewLeft - midOffset) / pillarSpacing).toInt() - 1
        val endMidIdx = ((viewRight - midOffset) / pillarSpacing).toInt() + 2

        shapeRenderer.color = midColor
        for (i in startMidIdx..endMidIdx) {
            val pillarX = (i * pillarSpacing) + midOffset
            val pillarW = 1.0f
            val pillarH = 16f
            val pillarY = viewBottom - 2f

            // Pilar Arsitektur Menara
            shapeRenderer.rect(pillarX, pillarY, pillarW, pillarH)

            // Kepala Pilar & Balok Horizontal (Arch Architrave)
            shapeRenderer.rect(pillarX - 0.3f, pillarY + 7.5f, pillarW + 0.6f, 0.5f)
            shapeRenderer.rect(pillarX - 0.15f, pillarY + 7.3f, pillarW + 0.3f, 0.2f)

            // Runic / Vent Inset Glow pada Pilar Tengah
            val pulse = (sin((animTime * 2.5f + i * 1.2f).toDouble()).toFloat() + 1f) * 0.5f
            shapeRenderer.setColor(glowColor.r, glowColor.g, glowColor.b, glowColor.a * (0.6f + 0.4f * pulse))
            shapeRenderer.rect(pillarX + 0.35f, pillarY + 4.0f, 0.3f, 2.2f)

            shapeRenderer.color = midColor
        }

        // ==========================================
        // 4. LAYER 3: Ambient Atmospheric Motes / Embers (Zero Allocation)
        // ==========================================
        for (i in 0 until MAX_AMBIENT_MOTES) {
            val px = (moteX[i] + sin((animTime * 0.8f + motePhase[i]).toDouble()).toFloat() * 1.2f)
            var py = (moteY[i] + animTime * moteSpeed[i])

            // Wrap partikel di sekitar pandangan kamera
            val wrapH = viewTop - viewBottom + 6f
            while (py > viewTop + 3f) py -= wrapH
            while (py < viewBottom - 3f) py += wrapH

            if (px in (viewLeft - 1f)..(viewRight + 1f) && py in (viewBottom - 1f)..(viewTop + 1f)) {
                val moteAlpha = moteColor.a * (0.6f + 0.4f * sin((animTime * 3f + motePhase[i]).toDouble()).toFloat())
                shapeRenderer.setColor(moteColor.r, moteColor.g, moteColor.b, moteAlpha)
                shapeRenderer.circle(px, py, moteSize[i], 6)
            }
        }
    }
}

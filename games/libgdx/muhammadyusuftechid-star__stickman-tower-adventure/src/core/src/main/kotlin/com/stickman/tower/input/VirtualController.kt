package com.stickman.tower.input

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.GL20
import com.badlogic.gdx.graphics.g2d.BitmapFont
import com.badlogic.gdx.graphics.g2d.SpriteBatch
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Circle
import com.badlogic.gdx.math.Vector3
import com.badlogic.gdx.utils.viewport.Viewport
import com.stickman.tower.combat.Skill
import com.stickman.tower.combat.UltimateEnergy

/**
 * On-Screen Virtual Touch Controller untuk target layar sentuh Android dan playtesting desktop.
 * Mengimplementasikan arsitektur multi-skill melengkung (Skill 1, Skill 2, Skill 3, Ultimate)
 * yang melingkari tombol Attack utama, terinspirasi dari Action RPG mobile modern.
 */
class VirtualController : GameInput {
    // Tombol D-Pad Kiri Layar (Floating Circles)
    val btnLeft = Circle()
    val btnRight = Circle()

    // Tombol Aksi Kanan Layar (Floating Circles)
    val btnAttack = Circle()
    val btnJump = Circle()
    val btnDodge = Circle()

    // Tombol Multi-Skill Melengkung (Arc Arrangement)
    val btnSkill1 = Circle()
    val btnSkill2 = Circle()
    val btnSkill3 = Circle()
    val btnUltimate = Circle()

    // Backward-compatibility alias
    val btnSkill: Circle get() = btnSkill1

    // Status Penekanan Frame
    private var pressedLeft = false
    private var pressedRight = false
    private var pressedDown = false
    private var pressedJump = false
    private var justPressedJump = false
    private var justPressedAttack = false
    private var justPressedDodge = false
    private var justPressedSkill1 = false
    private var justPressedSkill2 = false
    private var justPressedSkill3 = false
    private var justPressedUltimate = false

    // State Pelacakan Tombol
    private var wasAttackPressed = false
    private var wasJumpPressed = false
    private var wasDodgePressed = false
    private var wasSkill1Pressed = false
    private var wasSkill2Pressed = false
    private var wasSkill3Pressed = false
    private var wasUltimatePressed = false

    private val touchVec = Vector3()
    var isVisible = true
    var settings: TouchControlSettings = TouchSettingsManager.load()

    /**
     * Menerapkan konfigurasi tata letak dan ergonomi tombol baru.
     */
    fun applySettings(newSettings: TouchControlSettings, virtualWidth: Int = 1280, virtualHeight: Int = 720) {
        settings = newSettings.copy()
        resize(virtualWidth, virtualHeight)
    }

    /**
     * Mengatur posisi dan ukuran tombol dalam koordinat virtual UI Canvas (default 1280x720)
     * membentuk busur ergonomis konsentris (concentric arc) di sekitar tombol Attack utama,
     * memastikan nol tumpang-tindih (zero overlap) dan jangkauan sapuan jempol alami (Fitts's Law).
     */
    fun resize(virtualWidth: Int = 1280, virtualHeight: Int = 720) {
        val w = virtualWidth.toFloat()
        val h = virtualHeight.toFloat()
        val scale = settings.scale

        // Ukuran dan Posisi D-Pad Lingkaran Ergonomis (Kiri Bawah dengan offset pengguna)
        val dpadRadius = 45f * scale
        val dpadBaseX = 85f + settings.dpadOffsetX
        val dpadBaseY = 95f + settings.dpadOffsetY
        val dpadSpacing = 115f * scale

        btnLeft.set(dpadBaseX, dpadBaseY, dpadRadius)
        btnRight.set(dpadBaseX + dpadSpacing, dpadBaseY, dpadRadius)

        // Posisi Tombol Attack Utama (Jangkar Aksi Kanan Bawah)
        val atkX = (w - 120f) + settings.actionOffsetX
        val atkY = 110f + settings.actionOffsetY

        btnAttack.set(atkX, atkY, 54f * scale)

        // Tombol Mobilitas (Jump di kiri-bawah Attack, Dodge di kiri-atas Attack)
        btnJump.set(atkX - 110f * scale, atkY - 22f * scale, 38f * scale)
        btnDodge.set(atkX - 128f * scale, atkY + 65f * scale, 38f * scale)

        // Susunan Melengkung Busur Multi-Skill & Ultimate (Concentric Fan Arc)
        // SK1: Flank Kanan Atas Attack
        btnSkill1.set(atkX + 16f * scale, atkY + 128f * scale, 36f * scale)
        // SK2: Tengah Atas Busur
        btnSkill2.set(atkX - 68f * scale, atkY + 162f * scale, 36f * scale)
        // SK3: Flank Kiri Atas Busur
        btnSkill3.set(atkX - 156f * scale, atkY + 150f * scale, 36f * scale)
        // ULT: Mahkota Puncak (Apex Crown) di atas SK2 & SK3
        btnUltimate.set(atkX - 106f * scale, atkY + 246f * scale, 42f * scale)
    }

    private fun isCircleTouched(c: Circle, tx: Float, ty: Float, padding: Float): Boolean {
        val r = c.radius + padding
        val dx = tx - c.x
        val dy = ty - c.y
        return (dx * dx + dy * dy) <= (r * r)
    }

    /**
     * Memperbarui status penekanan tombol menggunakan deteksi multi-touch (pointer 0..4)
     * dengan toleransi sentuh presisi tanpa kebocoran antar-tombol.
     */
    fun update(viewport: Viewport? = null) {
        val prevAttack = wasAttackPressed
        val prevJump = wasJumpPressed
        val prevDodge = wasDodgePressed
        val prevSkill1 = wasSkill1Pressed
        val prevSkill2 = wasSkill2Pressed
        val prevSkill3 = wasSkill3Pressed
        val prevUltimate = wasUltimatePressed

        pressedLeft = false
        pressedRight = false
        pressedDown = false
        pressedJump = false
        var curAttack = false
        var curJump = false
        var curDodge = false
        var curSkill1 = false
        var curSkill2 = false
        var curSkill3 = false
        var curUltimate = false

        val sc = settings.scale
        val dpadMidX = (btnLeft.x + btnRight.x) / 2f
        val dpadPad = 12f * sc
        val actionPad = 6f * sc
        val atkPad = 10f * sc

        for (pointer in 0..4) {
            if (Gdx.input != null && Gdx.input.isTouched(pointer)) {
                touchVec.set(Gdx.input.getX(pointer).toFloat(), Gdx.input.getY(pointer).toFloat(), 0f)
                if (viewport != null) {
                    viewport.unproject(touchVec)
                } else if (Gdx.graphics != null) {
                    touchVec.y = Gdx.graphics.height - touchVec.y
                }
                val touchX = touchVec.x
                val touchY = touchVec.y

                // D-Pad Kiri: Toleransi radius + zona slider kontinu
                val isDpadYRange = touchY in (btnLeft.y - 70f * sc)..(btnLeft.y + 70f * sc)
                if (isCircleTouched(btnLeft, touchX, touchY, dpadPad) ||
                    (touchX <= dpadMidX && touchX >= btnLeft.x - 100f * sc && isDpadYRange)) {
                    pressedLeft = true
                }
                if (isCircleTouched(btnRight, touchX, touchY, dpadPad) ||
                    (touchX > dpadMidX && touchX <= btnRight.x + 100f * sc && isDpadYRange)) {
                    pressedRight = true
                }
                // Deteksi Down / Geser Bawah pada D-Pad untuk Drop-through platform & Fast Fall
                if (touchX in (btnLeft.x - 70f * sc)..(btnRight.x + 70f * sc) &&
                    touchY in (btnLeft.y - 85f * sc)..(btnLeft.y - 12f * sc)) {
                    pressedDown = true
                }

                // Tombol Attack Utama
                if (isCircleTouched(btnAttack, touchX, touchY, atkPad)) {
                    curAttack = true
                }

                // Tombol Jump & Dodge
                if (isCircleTouched(btnJump, touchX, touchY, actionPad)) {
                    curJump = true
                    pressedJump = true
                }
                if (isCircleTouched(btnDodge, touchX, touchY, actionPad)) {
                    curDodge = true
                }

                // Multi-Skill & Ultimate Touch Detection
                if (isCircleTouched(btnSkill1, touchX, touchY, actionPad)) curSkill1 = true
                if (isCircleTouched(btnSkill2, touchX, touchY, actionPad)) curSkill2 = true
                if (isCircleTouched(btnSkill3, touchX, touchY, actionPad)) curSkill3 = true
                if (isCircleTouched(btnUltimate, touchX, touchY, actionPad + 2f * sc)) curUltimate = true
            }
        }

        justPressedAttack = curAttack && !prevAttack
        justPressedJump = curJump && !prevJump
        justPressedDodge = curDodge && !prevDodge
        justPressedSkill1 = curSkill1 && !prevSkill1
        justPressedSkill2 = curSkill2 && !prevSkill2
        justPressedSkill3 = curSkill3 && !prevSkill3
        justPressedUltimate = curUltimate && !prevUltimate

        wasAttackPressed = curAttack
        wasJumpPressed = curJump
        wasDodgePressed = curDodge
        wasSkill1Pressed = curSkill1
        wasSkill2Pressed = curSkill2
        wasSkill3Pressed = curSkill3
        wasUltimatePressed = curUltimate
    }

    override fun isMoveLeft() = pressedLeft
    override fun isMoveRight() = pressedRight
    override fun isMoveDown() = pressedDown
    override fun isJumpJustPressed() = justPressedJump
    override fun isJumpPressed() = pressedJump
    override fun isAttackJustPressed() = justPressedAttack
    override fun isDodgeJustPressed() = justPressedDodge
    override fun isSkillJustPressed() = justPressedSkill1
    override fun isSkill1JustPressed() = justPressedSkill1
    override fun isSkill2JustPressed() = justPressedSkill2
    override fun isSkill3JustPressed() = justPressedSkill3
    override fun isUltimateJustPressed() = justPressedUltimate

    /**
     * Overload backward-compatible untuk 1 skill.
     */
    fun render(
        shapeRenderer: ShapeRenderer,
        batch: SpriteBatch,
        font: BitmapFont,
        skill: Skill,
        ultimate: UltimateEnergy
    ) {
        render(shapeRenderer, batch, font, skill, skill, skill, ultimate)
    }

    /**
     * Menggambar tombol kontrol melayang dengan arsitektur busur konsentris profesional Action RPG.
     * Menggunakan glassmorphism backdrop, glowing dual-rim, ikon vektor tajam, dan indikator status visual.
     */
    fun render(
        shapeRenderer: ShapeRenderer,
        batch: SpriteBatch,
        font: BitmapFont,
        skill1: Skill,
        skill2: Skill,
        skill3: Skill,
        ultimate: UltimateEnergy
    ) {
        if (!isVisible) return
        renderShapes(shapeRenderer, skill1, skill2, skill3, ultimate)
        val needBatch = !batch.isDrawing
        if (needBatch) batch.begin()
        renderText(batch, font, skill1, skill2, skill3, ultimate)
        if (needBatch) batch.end()
    }

    /**
     * Pass 1 & 2: Merender semua geometri dan outline tombol virtual controller.
     */
    fun renderShapes(
        shapeRenderer: ShapeRenderer,
        skill1: Skill,
        skill2: Skill,
        skill3: Skill,
        ultimate: UltimateEnergy
    ) {
        if (!isVisible) return

        val op = settings.opacity
        val sc = settings.scale

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        // 1. Gambar Backdrop & Isi Tombol (Filled Pass)
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Glassmorphism Dark Shadow Base untuk semua tombol
        shapeRenderer.setColor(0.04f, 0.06f, 0.10f, 0.50f * op)
        shapeRenderer.circle(btnLeft.x, btnLeft.y, btnLeft.radius, 24)
        shapeRenderer.circle(btnRight.x, btnRight.y, btnRight.radius, 24)
        shapeRenderer.circle(btnAttack.x, btnAttack.y, btnAttack.radius, 28)
        shapeRenderer.circle(btnJump.x, btnJump.y, btnJump.radius, 24)
        shapeRenderer.circle(btnDodge.x, btnDodge.y, btnDodge.radius, 24)
        shapeRenderer.circle(btnSkill1.x, btnSkill1.y, btnSkill1.radius, 24)
        shapeRenderer.circle(btnSkill2.x, btnSkill2.y, btnSkill2.radius, 24)
        shapeRenderer.circle(btnSkill3.x, btnSkill3.y, btnSkill3.radius, 24)
        shapeRenderer.circle(btnUltimate.x, btnUltimate.y, btnUltimate.radius, 28)

        // D-Pad Kiri & Kanan (Cobalt Navigation)
        if (pressedLeft) shapeRenderer.setColor(0.25f, 0.65f, 1f, 0.80f * op) else shapeRenderer.setColor(0.10f, 0.16f, 0.25f, 0.55f * op)
        shapeRenderer.circle(btnLeft.x, btnLeft.y, btnLeft.radius - 2f * sc, 24)

        if (pressedRight) shapeRenderer.setColor(0.25f, 0.65f, 1f, 0.80f * op) else shapeRenderer.setColor(0.10f, 0.16f, 0.25f, 0.55f * op)
        shapeRenderer.circle(btnRight.x, btnRight.y, btnRight.radius - 2f * sc, 24)

        // Panah Segitiga D-Pad
        if (pressedLeft) shapeRenderer.setColor(1f, 1f, 1f, op) else shapeRenderer.setColor(0.80f, 0.90f, 1f, 0.85f * op)
        shapeRenderer.triangle(
            btnLeft.x - 14f * sc, btnLeft.y,
            btnLeft.x + 10f * sc, btnLeft.y + 15f * sc,
            btnLeft.x + 10f * sc, btnLeft.y - 15f * sc
        )
        if (pressedRight) shapeRenderer.setColor(1f, 1f, 1f, op) else shapeRenderer.setColor(0.80f, 0.90f, 1f, 0.85f * op)
        shapeRenderer.triangle(
            btnRight.x + 14f * sc, btnRight.y,
            btnRight.x - 10f * sc, btnRight.y + 15f * sc,
            btnRight.x - 10f * sc, btnRight.y - 15f * sc
        )

        // Tombol Attack Utama (Crimson Flame Core)
        if (wasAttackPressed) shapeRenderer.setColor(1f, 0.25f, 0.30f, 0.90f * op) else shapeRenderer.setColor(0.80f, 0.16f, 0.22f, 0.60f * op)
        shapeRenderer.circle(btnAttack.x, btnAttack.y, btnAttack.radius - 2f * sc, 28)

        // Ikon Pedang Bilah Ganda ATK
        val atkCx = btnAttack.x
        val atkCy = btnAttack.y + 3f * sc
        shapeRenderer.setColor(1f, 1f, 1f, 0.95f * op)
        shapeRenderer.rectLine(atkCx - 15f * sc, atkCy - 15f * sc, atkCx + 17f * sc, atkCy + 17f * sc, 4f * sc)
        shapeRenderer.setColor(1f, 0.85f, 0.25f, 0.95f * op)
        shapeRenderer.rectLine(atkCx - 10f * sc, atkCy - 2f * sc, atkCx - 2f * sc, atkCy - 10f * sc, 4.5f * sc)
        shapeRenderer.circle(atkCx - 14f * sc, atkCy - 14f * sc, 3.5f * sc)

        // Tombol Jump (Emerald Green Core)
        if (wasJumpPressed) shapeRenderer.setColor(0.25f, 0.90f, 0.45f, 0.90f * op) else shapeRenderer.setColor(0.15f, 0.65f, 0.32f, 0.55f * op)
        shapeRenderer.circle(btnJump.x, btnJump.y, btnJump.radius - 2f * sc, 24)
        val jmpCx = btnJump.x
        val jmpCy = btnJump.y + 3f * sc
        shapeRenderer.setColor(0.95f, 1f, 0.95f, 0.95f * op)
        shapeRenderer.rectLine(jmpCx - 10f * sc, jmpCy + 2f * sc, jmpCx, jmpCy + 10f * sc, 3.2f * sc)
        shapeRenderer.rectLine(jmpCx, jmpCy + 10f * sc, jmpCx + 10f * sc, jmpCy + 2f * sc, 3.2f * sc)
        shapeRenderer.rectLine(jmpCx - 8f * sc, jmpCy - 5f * sc, jmpCx, jmpCy + 2f * sc, 2.5f * sc)
        shapeRenderer.rectLine(jmpCx, jmpCy + 2f * sc, jmpCx + 8f * sc, jmpCy - 5f * sc, 2.5f * sc)

        // Tombol Dodge / Sprint (Azure Sky Core)
        if (wasDodgePressed) shapeRenderer.setColor(0.25f, 0.70f, 1f, 0.90f * op) else shapeRenderer.setColor(0.16f, 0.48f, 0.88f, 0.55f * op)
        shapeRenderer.circle(btnDodge.x, btnDodge.y, btnDodge.radius - 2f * sc, 24)
        val ddgCx = btnDodge.x
        val ddgCy = btnDodge.y + 2f * sc
        shapeRenderer.setColor(0.85f, 0.95f, 1f, 0.95f * op)
        shapeRenderer.rectLine(ddgCx - 12f * sc, ddgCy + 6f * sc, ddgCx + 5f * sc, ddgCy + 6f * sc, 2.5f * sc)
        shapeRenderer.rectLine(ddgCx - 9f * sc, ddgCy, ddgCx + 12f * sc, ddgCy, 3.5f * sc)
        shapeRenderer.rectLine(ddgCx - 12f * sc, ddgCy - 6f * sc, ddgCx + 5f * sc, ddgCy - 6f * sc, 2.5f * sc)

        // === SKILL 1: Azure Gale / Frost Dart ===
        if (skill1.isReady) {
            shapeRenderer.setColor(0.22f, 0.75f, 1f, 0.70f * op)
        } else {
            shapeRenderer.setColor(0.12f, 0.20f, 0.32f, 0.50f * op)
        }
        shapeRenderer.circle(btnSkill1.x, btnSkill1.y, btnSkill1.radius - 2f * sc, 24)
        val s1x = btnSkill1.x
        val s1y = btnSkill1.y + 3f * sc
        shapeRenderer.setColor(if (skill1.isReady) Color(0.90f, 0.98f, 1f, op) else Color(0.50f, 0.65f, 0.80f, 0.50f * op))
        shapeRenderer.rectLine(s1x - 9f * sc, s1y + 8f * sc, s1x + 9f * sc, s1y, 3f * sc)
        shapeRenderer.rectLine(s1x + 9f * sc, s1y, s1x - 9f * sc, s1y - 8f * sc, 3f * sc)
        shapeRenderer.circle(s1x - 2f * sc, s1y, 3.5f * sc)

        // === SKILL 2: Amber Magma / Flame Spires ===
        if (skill2.isReady) {
            shapeRenderer.setColor(1f, 0.55f, 0.15f, 0.70f * op)
        } else {
            shapeRenderer.setColor(0.30f, 0.18f, 0.10f, 0.50f * op)
        }
        shapeRenderer.circle(btnSkill2.x, btnSkill2.y, btnSkill2.radius - 2f * sc, 24)
        val s2x = btnSkill2.x
        val s2y = btnSkill2.y + 3f * sc
        shapeRenderer.setColor(if (skill2.isReady) Color(1f, 0.92f, 0.45f, op) else Color(0.70f, 0.50f, 0.30f, 0.50f * op))
        shapeRenderer.triangle(s2x - 8f * sc, s2y - 9f * sc, s2x - 2f * sc, s2y + 10f * sc, s2x + 4f * sc, s2y - 9f * sc)
        shapeRenderer.triangle(s2x + 2f * sc, s2y - 9f * sc, s2x + 8f * sc, s2y + 7f * sc, s2x + 12f * sc, s2y - 9f * sc)

        // === SKILL 3: Violet Thunder / Void Blitz ===
        if (skill3.isReady) {
            shapeRenderer.setColor(0.68f, 0.32f, 0.98f, 0.70f * op)
        } else {
            shapeRenderer.setColor(0.24f, 0.14f, 0.32f, 0.50f * op)
        }
        shapeRenderer.circle(btnSkill3.x, btnSkill3.y, btnSkill3.radius - 2f * sc, 24)
        val s3x = btnSkill3.x
        val s3y = btnSkill3.y + 3f * sc
        shapeRenderer.setColor(if (skill3.isReady) Color(0.96f, 0.82f, 1f, op) else Color(0.60f, 0.45f, 0.70f, 0.50f * op))
        shapeRenderer.rectLine(s3x - 5f * sc, s3y + 10f * sc, s3x + 4f * sc, s3y + 2f * sc, 3f * sc)
        shapeRenderer.rectLine(s3x + 4f * sc, s3y + 2f * sc, s3x - 4f * sc, s3y - 1f * sc, 2.5f * sc)
        shapeRenderer.rectLine(s3x - 4f * sc, s3y - 1f * sc, s3x + 5f * sc, s3y - 10f * sc, 3f * sc)

        // === ULTIMATE: Celestial Solar Crown ===
        if (ultimate.isReady) {
            shapeRenderer.setColor(1f, 0.85f, 0.20f, 0.85f * op)
        } else {
            shapeRenderer.setColor(0.32f, 0.26f, 0.12f, 0.50f * op)
        }
        shapeRenderer.circle(btnUltimate.x, btnUltimate.y, btnUltimate.radius - 2f * sc, 28)
        val ultCx = btnUltimate.x
        val ultCy = btnUltimate.y + 3f * sc
        if (ultimate.isReady) shapeRenderer.setColor(1f, 0.98f, 0.50f, op) else shapeRenderer.setColor(0.75f, 0.68f, 0.45f, 0.60f * op)
        shapeRenderer.circle(ultCx, ultCy, 6f * sc, 16)
        // 8 Sinar Mahkota Solar
        shapeRenderer.rectLine(ultCx, ultCy + 7f * sc, ultCx, ultCy + 14f * sc, 3f * sc)
        shapeRenderer.rectLine(ultCx, ultCy - 7f * sc, ultCx, ultCy - 14f * sc, 3f * sc)
        shapeRenderer.rectLine(ultCx - 7f * sc, ultCy, ultCx - 14f * sc, ultCy, 3f * sc)
        shapeRenderer.rectLine(ultCx + 7f * sc, ultCy, ultCx + 14f * sc, ultCy, 3f * sc)
        shapeRenderer.rectLine(ultCx - 5f * sc, ultCy + 5f * sc, ultCx - 10f * sc, ultCy + 10f * sc, 2f * sc)
        shapeRenderer.rectLine(ultCx + 5f * sc, ultCy + 5f * sc, ultCx + 10f * sc, ultCy + 10f * sc, 2f * sc)
        shapeRenderer.rectLine(ultCx - 5f * sc, ultCy - 5f * sc, ultCx - 10f * sc, ultCy - 10f * sc, 2f * sc)
        shapeRenderer.rectLine(ultCx + 5f * sc, ultCy - 5f * sc, ultCx + 10f * sc, ultCy - 10f * sc, 2f * sc)

        shapeRenderer.end()

        // 2. Gambar Outline & Glowing Accent Rims (Line Pass)
        shapeRenderer.begin(ShapeRenderer.ShapeType.Line)

        // D-Pad Outlines
        shapeRenderer.setColor(0.80f, 0.90f, 1f, 0.55f * op)
        shapeRenderer.circle(btnLeft.x, btnLeft.y, btnLeft.radius, 24)
        shapeRenderer.circle(btnRight.x, btnRight.y, btnRight.radius, 24)

        // Attack Outline
        shapeRenderer.setColor(1f, 0.50f, 0.55f, 0.70f * op)
        shapeRenderer.circle(btnAttack.x, btnAttack.y, btnAttack.radius, 28)
        shapeRenderer.setColor(1f, 0.75f, 0.75f, 0.35f * op)
        shapeRenderer.circle(btnAttack.x, btnAttack.y, btnAttack.radius + 2f * sc, 28)

        // Jump Outline
        shapeRenderer.setColor(0.55f, 1f, 0.70f, 0.65f * op)
        shapeRenderer.circle(btnJump.x, btnJump.y, btnJump.radius, 24)

        // Dodge Outline
        shapeRenderer.setColor(0.55f, 0.85f, 1f, 0.65f * op)
        shapeRenderer.circle(btnDodge.x, btnDodge.y, btnDodge.radius, 24)

        // Skill 1 Outline & Cooldown Arc
        shapeRenderer.setColor(if (skill1.isReady) Color(0.40f, 0.90f, 1f, 0.85f * op) else Color(0.25f, 0.40f, 0.60f, 0.45f * op))
        shapeRenderer.circle(btnSkill1.x, btnSkill1.y, btnSkill1.radius, 24)
        if (!skill1.isReady) {
            shapeRenderer.setColor(0.40f, 0.90f, 1f, 0.75f * op)
            shapeRenderer.circle(btnSkill1.x, btnSkill1.y, btnSkill1.radius * (1f - skill1.cooldownPercent), 20)
        }

        // Skill 2 Outline & Cooldown Arc
        shapeRenderer.setColor(if (skill2.isReady) Color(1f, 0.75f, 0.30f, 0.85f * op) else Color(0.50f, 0.35f, 0.20f, 0.45f * op))
        shapeRenderer.circle(btnSkill2.x, btnSkill2.y, btnSkill2.radius, 24)
        if (!skill2.isReady) {
            shapeRenderer.setColor(1f, 0.75f, 0.30f, 0.75f * op)
            shapeRenderer.circle(btnSkill2.x, btnSkill2.y, btnSkill2.radius * (1f - skill2.cooldownPercent), 20)
        }

        // Skill 3 Outline & Cooldown Arc
        shapeRenderer.setColor(if (skill3.isReady) Color(0.88f, 0.60f, 1f, 0.85f * op) else Color(0.45f, 0.30f, 0.50f, 0.45f * op))
        shapeRenderer.circle(btnSkill3.x, btnSkill3.y, btnSkill3.radius, 24)
        if (!skill3.isReady) {
            shapeRenderer.setColor(0.88f, 0.60f, 1f, 0.75f * op)
            shapeRenderer.circle(btnSkill3.x, btnSkill3.y, btnSkill3.radius * (1f - skill3.cooldownPercent), 20)
        }

        // Ultimate Outline & Radiant Corona
        if (ultimate.isReady) {
            shapeRenderer.setColor(1f, 0.95f, 0.45f, 0.95f * op)
            shapeRenderer.circle(btnUltimate.x, btnUltimate.y, btnUltimate.radius, 28)
            shapeRenderer.setColor(1f, 0.85f, 0.25f, 0.45f * op)
            shapeRenderer.circle(btnUltimate.x, btnUltimate.y, btnUltimate.radius + 3f * sc, 28)
        } else {
            shapeRenderer.setColor(0.60f, 0.50f, 0.30f, 0.45f * op)
            shapeRenderer.circle(btnUltimate.x, btnUltimate.y, btnUltimate.radius, 28)
            shapeRenderer.setColor(1f, 0.85f, 0.25f, 0.75f * op)
            shapeRenderer.circle(btnUltimate.x, btnUltimate.y, btnUltimate.radius * ultimate.energyPercent, 20)
        }

        shapeRenderer.end()
    }

    /**
     * Pass 3: Merender semua label teks dan counter cooldown tombol virtual controller.
     * Dapat dipanggil di dalam active SpriteBatch pass tanpa memicu shader/texture swaps tambahan.
     */
    fun renderText(
        batch: SpriteBatch,
        font: BitmapFont,
        skill1: Skill,
        skill2: Skill,
        skill3: Skill,
        ultimate: UltimateEnergy
    ) {
        if (!isVisible) return

        val op = settings.opacity
        val sc = settings.scale

        font.setColor(0.92f, 0.92f, 0.96f, 0.88f * op)

        font.draw(batch, "ATK", btnAttack.x - 14f * sc, btnAttack.y - 24f * sc)
        font.draw(batch, "JUMP", btnJump.x - 16f * sc, btnJump.y - 14f * sc)
        font.draw(batch, "DASH", btnDodge.x - 16f * sc, btnDodge.y - 14f * sc)

        // Skill 1 Countdown / Label
        if (skill1.isReady) {
            font.setColor(0.92f, 0.92f, 0.96f, 0.88f * op)
            font.draw(batch, "SK1", btnSkill1.x - 12f * sc, btnSkill1.y - 14f * sc)
        } else {
            font.setColor(1f, 1f, 0.25f, op)
            val t1 = (skill1.remainingCooldown * 10).toInt().coerceAtLeast(0)
            font.draw(batch, "${t1 / 10}.${t1 % 10}s", btnSkill1.x - 14f * sc, btnSkill1.y + 4f * sc)
        }

        // Skill 2 Countdown / Label
        if (skill2.isReady) {
            font.setColor(0.92f, 0.92f, 0.96f, 0.88f * op)
            font.draw(batch, "SK2", btnSkill2.x - 12f * sc, btnSkill2.y - 14f * sc)
        } else {
            font.setColor(1f, 1f, 0.25f, op)
            val t2 = (skill2.remainingCooldown * 10).toInt().coerceAtLeast(0)
            font.draw(batch, "${t2 / 10}.${t2 % 10}s", btnSkill2.x - 14f * sc, btnSkill2.y + 4f * sc)
        }

        // Skill 3 Countdown / Label
        if (skill3.isReady) {
            font.setColor(0.92f, 0.92f, 0.96f, 0.88f * op)
            font.draw(batch, "SK3", btnSkill3.x - 12f * sc, btnSkill3.y - 14f * sc)
        } else {
            font.setColor(1f, 1f, 0.25f, op)
            val t3 = (skill3.remainingCooldown * 10).toInt().coerceAtLeast(0)
            font.draw(batch, "${t3 / 10}.${t3 % 10}s", btnSkill3.x - 14f * sc, btnSkill3.y + 4f * sc)
        }

        // Ultimate Energy % / Ready Badge
        if (ultimate.isReady) {
            font.setColor(1f, 0.90f, 0.25f, op)
            font.draw(batch, "ULT!", btnUltimate.x - 14f * sc, btnUltimate.y - 16f * sc)
        } else {
            font.setColor(0.95f, 0.88f, 0.70f, 0.85f * op)
            font.draw(batch, "${(ultimate.energyPercent * 100).toInt()}%", btnUltimate.x - 14f * sc, btnUltimate.y + 4f * sc)
        }
    }
}

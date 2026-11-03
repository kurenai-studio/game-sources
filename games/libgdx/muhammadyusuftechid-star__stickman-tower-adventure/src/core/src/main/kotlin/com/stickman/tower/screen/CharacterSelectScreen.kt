package com.stickman.tower.screen

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.Input.Keys
import com.badlogic.gdx.Screen
import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.GL20
import com.badlogic.gdx.graphics.OrthographicCamera
import com.badlogic.gdx.graphics.g2d.BitmapFont
import com.badlogic.gdx.graphics.g2d.GlyphLayout
import com.badlogic.gdx.graphics.g2d.SpriteBatch
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.MathUtils
import com.badlogic.gdx.math.Vector3
import com.badlogic.gdx.utils.Align
import com.badlogic.gdx.utils.ScreenUtils
import com.badlogic.gdx.utils.viewport.FitViewport
import com.badlogic.gdx.utils.viewport.Viewport
import com.stickman.tower.StickmanGame
import com.stickman.tower.audio.AudioManager
import com.stickman.tower.audio.HapticManager
import com.stickman.tower.character.CharacterArchetype
import com.stickman.tower.character.CharacterUnlockManager
import com.stickman.tower.rpg.SaveData
import com.stickman.tower.rpg.SaveManager
import com.stickman.tower.ui.FontManager
import kotlin.math.sin

/**
 * Screen Pemilihan Karakter:
 * Menampilkan preview stickman beranimasi di atas altar runic dengan senjata khasnya,
 * kartu statistik lengkap (Speed, Attack, Defense, Crit, Skill, Ult),
 * serta navigasi vektor panah dan tipografi FreeType anti-aliased.
 */
class CharacterSelectScreen(private val game: StickmanGame) : Screen {
    companion object {
        val COLOR_CYAN_PIP = Color(0.35f, 0.85f, 1f, 1f)
        val COLOR_GOLD_PIP = Color(1f, 0.85f, 0.25f, 1f)
        val COLOR_MUTED_PIP = Color(0.65f, 0.72f, 0.82f, 1f)
        val COLOR_PURPLE_PIP = Color(0.85f, 0.50f, 1f, 1f)
        val COLOR_RED_PIP = Color(1f, 0.35f, 0.35f, 1f)
        val COLOR_GREEN_PIP = Color(0.25f, 0.88f, 0.45f, 1f)
        val COLOR_ORANGE_PIP = Color(1f, 0.75f, 0.2f, 1f)
    }
    private val camera = OrthographicCamera()
    private val viewport: Viewport = FitViewport(1280f, 720f, camera)
    private val shapeRenderer = ShapeRenderer()
    private val batch = SpriteBatch()
    private val glyphLayout = GlyphLayout()
    private val touchVec = Vector3()

    private val archetypes = CharacterArchetype.entries.toTypedArray()
    private var selectedIndex = 0
    private var animTime = 0f
    private var inputCooldown = 0.25f
    private var currentSave = SaveData()

    override fun show() {
        Gdx.input?.setCatchKey(Keys.BACK, true)
        FontManager.init()
        inputCooldown = 0.25f
        currentSave = SaveManager.load()
        selectedIndex = archetypes.indexOfFirst { it.name.equals(currentSave.selectedArchetype, ignoreCase = true) }
            .coerceAtLeast(0)
    }

    override fun render(delta: Float) {
        animTime += delta
        if (inputCooldown > 0f) {
            inputCooldown -= delta
        } else {
            handleInput()
        }
        if (game.screen !== this) return

        ScreenUtils.clear(0.06f, 0.08f, 0.14f, 1f)
        camera.update()
        shapeRenderer.projectionMatrix = camera.combined
        batch.projectionMatrix = camera.combined

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        val currentArchetype = archetypes[selectedIndex]

        // 1. Gambar Geometri & Podium
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Latar Belakang Kartu Kanan (Statistik & Kemampuan)
        shapeRenderer.setColor(0.06f, 0.09f, 0.15f, 0.92f)
        shapeRenderer.rect(620f, 120f, 560f, 480f)
        shapeRenderer.setColor(0.9f, 0.75f, 0.25f, 0.85f)
        shapeRenderer.rect(620f, 596f, 560f, 3f)

        // Skill Showcase Card Containers (Kanan Bawah - 3 Active Skills + 1 Ultimate)
        // Skill 1 (Cyan)
        shapeRenderer.setColor(0.08f, 0.12f, 0.18f, 0.85f)
        shapeRenderer.rect(645f, 238f, 510f, 32f)
        shapeRenderer.setColor(0.2f, 0.85f, 1f, 0.9f)
        shapeRenderer.rect(645f, 238f, 4f, 32f)

        // Skill 2 (Amber)
        shapeRenderer.setColor(0.08f, 0.12f, 0.18f, 0.85f)
        shapeRenderer.rect(645f, 200f, 510f, 32f)
        shapeRenderer.setColor(1f, 0.65f, 0.2f, 0.9f)
        shapeRenderer.rect(645f, 200f, 4f, 32f)

        // Skill 3 (Purple)
        shapeRenderer.setColor(0.08f, 0.12f, 0.18f, 0.85f)
        shapeRenderer.rect(645f, 162f, 510f, 32f)
        shapeRenderer.setColor(0.85f, 0.45f, 1f, 0.9f)
        shapeRenderer.rect(645f, 162f, 4f, 32f)

        // Ultimate (Solar Gold)
        shapeRenderer.setColor(0.08f, 0.12f, 0.18f, 0.85f)
        shapeRenderer.rect(645f, 124f, 510f, 32f)
        shapeRenderer.setColor(1f, 0.8f, 0.2f, 0.9f)
        shapeRenderer.rect(645f, 124f, 4f, 32f)

        // Podium Karakter di Kiri (Runic Slate Altar)
        val podiumCenterX = 350f
        val podiumBaseY = 170f
        shapeRenderer.setColor(0.09f, 0.13f, 0.20f, 0.95f)
        shapeRenderer.rect(podiumCenterX - 180f, podiumBaseY - 24f, 360f, 34f)
        shapeRenderer.setColor(0.85f, 0.70f, 0.25f, 0.85f)
        shapeRenderer.rectLine(podiumCenterX - 180f, podiumBaseY + 10f, podiumCenterX + 180f, podiumBaseY + 10f, 3f)

        // Cincin Cahaya Aura Berbasis Kelas Karakter
        val (auraR, auraG, auraB) = when (currentArchetype) {
            CharacterArchetype.BALANCED -> Triple(0.35f, 0.70f, 1f)
            CharacterArchetype.AGILE -> Triple(0.15f, 0.95f, 0.85f)
            CharacterArchetype.HEAVY -> Triple(1f, 0.45f, 0.15f)
        }
        val auraPulse = sin(animTime * 3.5f) * 0.08f
        shapeRenderer.setColor(auraR, auraG, auraB, 0.22f + auraPulse)
        shapeRenderer.circle(podiumCenterX, podiumBaseY + 10f, 95f, 30)
        shapeRenderer.setColor(auraR, auraG, auraB, 0.45f + auraPulse)
        shapeRenderer.circle(podiumCenterX, podiumBaseY + 10f, 65f, 24)

        // Mote Orbital Runik Berputar di Sekitar Cincin Altar
        for (angleIdx in 0 until 4) {
            val ang = animTime * 1.6f + angleIdx * (Math.PI.toFloat() / 2f)
            val rx = podiumCenterX + kotlin.math.cos(ang.toDouble()).toFloat() * 95f
            val ry = (podiumBaseY + 10f) + kotlin.math.sin(ang.toDouble()).toFloat() * 22f
            shapeRenderer.setColor(1f, 1f, 1f, 0.75f)
            shapeRenderer.circle(rx, ry, 3.5f, 8)
        }

        // Gambar Karakter Stickman Preview di Podium
        renderStickmanPreview(shapeRenderer, podiumCenterX, podiumBaseY + 10f, currentArchetype)

        // Jika karakter belum terbuka, gambar Rantai & Segel Runik Merah di atas Podium
        val isCurrentUnlocked = CharacterUnlockManager.isUnlocked(currentArchetype, currentSave)
        if (!isCurrentUnlocked) {
            // Rantai Silang Obsidian Runic di atas Karakter
            val pulseLock = (sin(animTime * 4f) + 1f) * 0.5f
            shapeRenderer.setColor(0.85f, 0.15f, 0.15f, 0.75f + 0.25f * pulseLock)
            shapeRenderer.rectLine(podiumCenterX - 110f, podiumBaseY + 20f, podiumCenterX + 110f, podiumBaseY + 230f, 4f)
            shapeRenderer.rectLine(podiumCenterX - 110f, podiumBaseY + 230f, podiumCenterX + 110f, podiumBaseY + 20f, 4f)

            // Badan Gembok Runic di Tengah Dada Karakter
            val lockX = podiumCenterX - 22f
            val lockY = podiumBaseY + 105f
            shapeRenderer.setColor(0.12f, 0.05f, 0.05f, 0.95f)
            shapeRenderer.rect(lockX, lockY, 44f, 36f)
            shapeRenderer.setColor(1f, 0.3f, 0.2f, 0.95f)
            shapeRenderer.rectLine(lockX, lockY, lockX + 44f, lockY, 2f)
            shapeRenderer.rectLine(lockX, lockY + 36f, lockX + 44f, lockY + 36f, 2f)
            shapeRenderer.rectLine(lockX, lockY, lockX, lockY + 36f, 2f)
            shapeRenderer.rectLine(lockX + 44f, lockY, lockX + 44f, lockY + 36f, 2f)

            // Lengkungan Belenggu Gembok Runic
            shapeRenderer.circle(podiumCenterX, lockY + 36f, 14f, 16)
            shapeRenderer.setColor(0.12f, 0.05f, 0.05f, 1f)
            shapeRenderer.circle(podiumCenterX, lockY + 36f, 8f, 16)

            // Lubang Kunci Bercahaya
            shapeRenderer.setColor(1f, 0.85f, 0.2f, 0.95f)
            shapeRenderer.circle(podiumCenterX, lockY + 20f, 3f, 8)
            shapeRenderer.rectLine(podiumCenterX, lockY + 20f, podiumCenterX, lockY + 12f, 2.5f)
        }

        // Stat Segmented Pip Bars & Tier Badges di Kartu Kanan
        renderStatBars(shapeRenderer, currentArchetype)

        // Tombol Navigasi Bawah
        val btnPlayX = 720f
        val btnPlayY = 45f
        val btnPulse = (sin(animTime * 5f) + 1f) * 0.5f

        if (isCurrentUnlocked) {
            // Tombol Select & Play (Gilded Obsidian dengan Pulsing Emerald Accent)
            shapeRenderer.setColor(0.10f, 0.18f, 0.14f, 0.95f)
            shapeRenderer.rect(btnPlayX, btnPlayY, 260f, 52f)
            shapeRenderer.setColor(0.2f + 0.15f * btnPulse, 0.85f + 0.15f * btnPulse, 0.45f, 0.92f)
            shapeRenderer.rectLine(btnPlayX, btnPlayY + 52f, btnPlayX + 260f, btnPlayY + 52f, 3f)
        } else {
            // Tombol Locked (Crimson Obsidian dengan Pulsing Red Accent)
            shapeRenderer.setColor(0.18f, 0.07f, 0.08f, 0.95f)
            shapeRenderer.rect(btnPlayX, btnPlayY, 260f, 52f)
            shapeRenderer.setColor(0.85f + 0.15f * btnPulse, 0.2f, 0.2f, 0.92f)
            shapeRenderer.rectLine(btnPlayX, btnPlayY + 52f, btnPlayX + 260f, btnPlayY + 52f, 3f)
        }

        // Tombol Back (Muted Obsidian)
        val btnBackX = 300f
        val btnBackY = 45f
        shapeRenderer.setColor(0.12f, 0.15f, 0.22f, 0.95f)
        shapeRenderer.rect(btnBackX, btnBackY, 220f, 52f)
        shapeRenderer.setColor(0.6f, 0.7f, 0.85f, 0.8f)
        shapeRenderer.rectLine(btnBackX, btnBackY + 52f, btnBackX + 220f, btnBackY + 52f, 3f)

        // Tombol Panah Kiri / Kanan Podium (Vektor Segitiga)
        shapeRenderer.setColor(0.12f, 0.16f, 0.25f, 0.85f)
        shapeRenderer.rect(podiumCenterX - 230f, 320f, 44f, 56f)
        shapeRenderer.rect(podiumCenterX + 190f, 320f, 44f, 56f)

        // Vektor Segitiga Panah Kiri
        shapeRenderer.setColor(1f, 0.85f, 0.25f, 0.95f)
        shapeRenderer.triangle(
            podiumCenterX - 218f, 348f,
            podiumCenterX - 200f, 362f,
            podiumCenterX - 200f, 334f
        )
        // Vektor Segitiga Panah Kanan
        shapeRenderer.triangle(
            podiumCenterX + 222f, 348f,
            podiumCenterX + 204f, 362f,
            podiumCenterX + 204f, 334f
        )

        shapeRenderer.end()

        // 2. Render Tipografi & Teks (FontManager FreeType Anti-Aliased)
        batch.begin()
        val titleF = FontManager.titleFont
        val headF = FontManager.headerFont
        val regF = FontManager.regularFont
        val smallF = FontManager.smallFont

        // Judul Atas
        titleF.color = Color.WHITE
        glyphLayout.setText(titleF, "CHOOSE YOUR HERO")
        titleF.draw(batch, "CHOOSE YOUR HERO", (1280f - glyphLayout.width) / 2f, 675f)

        // Nama & Gelar Karakter Terpilih (Kiri Atas Podium)
        headF.setColor(auraR, auraG, auraB, 1f)
        val nameLabel = currentArchetype.characterName
        glyphLayout.setText(headF, nameLabel)
        headF.draw(batch, nameLabel, podiumCenterX - glyphLayout.width / 2f, 595f)

        regF.color = Color.GOLD
        val titleLabel = "${currentArchetype.canonTitle} • [${currentArchetype.displayName}]"
        glyphLayout.setText(regF, titleLabel)
        regF.draw(batch, titleLabel, podiumCenterX - glyphLayout.width / 2f, 560f)

        if (!isCurrentUnlocked) {
            smallF.color = Color(1f, 0.45f, 0.45f, 1f)
            val lockNotice = "[SEGELLAH RUNIK AKTIF - TERKUNCI]"
            glyphLayout.setText(smallF, lockNotice)
            smallF.draw(batch, lockNotice, podiumCenterX - glyphLayout.width / 2f, 532f)

            smallF.color = Color(1f, 0.85f, 0.35f, 1f)
            val reqNotice = CharacterUnlockManager.getUnlockRequirementText(currentArchetype)
            glyphLayout.setText(smallF, reqNotice)
            smallF.draw(batch, reqNotice, podiumCenterX - glyphLayout.width / 2f, 514f)
        }

        // Teks Kartu Statistik (Kanan)
        headF.color = Color.WHITE
        headF.draw(batch, "ATTRIBUTES & SKILLS", 650f, 570f)

        regF.setColor(0.85f, 0.88f, 0.95f, 1f)
        regF.draw(batch, "${currentArchetype.description} Senjata: ${currentArchetype.weaponName}.", 650f, 525f, 500f, -1, true)

        regF.color = Color.WHITE
        regF.draw(batch, "Movement Speed:", 650f, 435f)
        regF.draw(batch, "Attack Multiplier:", 650f, 395f)
        regF.draw(batch, "Defense Power:", 650f, 355f)
        regF.draw(batch, "Critical Chance:", 650f, 315f)

        // Huruf Tier Badges S / A / B / C
        val spdRank = when (currentArchetype) {
            CharacterArchetype.BALANCED -> "B"
            CharacterArchetype.AGILE -> "S"
            CharacterArchetype.HEAVY -> "C"
        }
        val spdColor = when (currentArchetype) {
            CharacterArchetype.BALANCED -> COLOR_CYAN_PIP
            CharacterArchetype.AGILE -> COLOR_GOLD_PIP
            CharacterArchetype.HEAVY -> COLOR_MUTED_PIP
        }
        val atkRank = when (currentArchetype) {
            CharacterArchetype.BALANCED -> "B"
            CharacterArchetype.AGILE -> "A"
            CharacterArchetype.HEAVY -> "S"
        }
        val atkColor = when (currentArchetype) {
            CharacterArchetype.BALANCED -> COLOR_CYAN_PIP
            CharacterArchetype.AGILE -> COLOR_PURPLE_PIP
            CharacterArchetype.HEAVY -> COLOR_GOLD_PIP
        }
        val defRank = when (currentArchetype) {
            CharacterArchetype.BALANCED -> "B"
            CharacterArchetype.AGILE -> "C"
            CharacterArchetype.HEAVY -> "S"
        }
        val defColor = when (currentArchetype) {
            CharacterArchetype.BALANCED -> COLOR_CYAN_PIP
            CharacterArchetype.AGILE -> COLOR_MUTED_PIP
            CharacterArchetype.HEAVY -> COLOR_GOLD_PIP
        }
        val critRank = when (currentArchetype) {
            CharacterArchetype.BALANCED -> "B"
            CharacterArchetype.AGILE -> "S"
            CharacterArchetype.HEAVY -> "C"
        }
        val critColor = when (currentArchetype) {
            CharacterArchetype.BALANCED -> COLOR_CYAN_PIP
            CharacterArchetype.AGILE -> COLOR_GOLD_PIP
            CharacterArchetype.HEAVY -> COLOR_MUTED_PIP
        }

        regF.color = spdColor
        regF.draw(batch, spdRank, 1104f, 435f)
        regF.color = atkColor
        regF.draw(batch, atkRank, 1104f, 395f)
        regF.color = defColor
        regF.draw(batch, defRank, 1104f, 355f)
        regF.color = critColor
        regF.draw(batch, critRank, 1104f, 315f)

        // Info Kemampuan Unik (Multi-Skill & Ult Showcase)
        val (s1Desc, s2Desc, s3Desc, ultDesc) = when (currentArchetype) {
            CharacterArchetype.BALANCED -> listOf(
                "Blade wave projectile slices ahead",
                "Rising dragon leap uppercut",
                "Piercing high-speed dash thrust",
                "Cataclysmic 360° cyclone sword storm"
            )
            CharacterArchetype.AGILE -> listOf(
                "Triple shadow shuriken fan burst",
                "Rapid venom shadow dagger flurry",
                "Instant teleport blink behind target",
                "Torrent of multi-target shadowblades"
            )
            CharacterArchetype.HEAVY -> listOf(
                "Earth-shattering ground shockwave",
                "Whirling cyclone greatsword cleave",
                "War roar: heals 15% HP & knocks foes back",
                "Cataclysmic overhead ground-shattering strike"
            )
        }

        smallF.color = Color.CYAN
        smallF.draw(batch, "SKILL 1 [U]: ${currentArchetype.skill1Name} (${currentArchetype.skill1Cooldown.toInt()}s) - $s1Desc", 655f, 258f, 560f, Align.left, false)

        smallF.color = Color(1f, 0.65f, 0.2f, 1f)
        smallF.draw(batch, "SKILL 2 [I]: ${currentArchetype.skill2Name} (${currentArchetype.skill2Cooldown.toInt()}s) - $s2Desc", 655f, 220f, 560f, Align.left, false)

        smallF.color = Color(0.85f, 0.45f, 1f, 1f)
        smallF.draw(batch, "SKILL 3 [O]: ${currentArchetype.skill3Name} (${currentArchetype.skill3Cooldown.toInt()}s) - $s3Desc", 655f, 182f, 560f, Align.left, false)

        smallF.color = Color.GOLD
        smallF.draw(batch, "ULTIMATE [P]: ${currentArchetype.ultName} - $ultDesc", 655f, 144f, 560f, Align.left, false)

        // Teks Tombol Bawah
        if (isCurrentUnlocked) {
            headF.color = Color.WHITE
            glyphLayout.setText(headF, "CONFIRM & PLAY")
            headF.draw(batch, "CONFIRM & PLAY", btnPlayX + (260f - glyphLayout.width) / 2f, btnPlayY + 36f)
        } else {
            headF.color = Color(1f, 0.45f, 0.45f, 1f)
            glyphLayout.setText(headF, "🔒 TERKUNCI")
            headF.draw(batch, "🔒 TERKUNCI", btnPlayX + (260f - glyphLayout.width) / 2f, btnPlayY + 36f)
        }

        regF.setColor(0.9f, 0.9f, 0.95f, 1f)
        glyphLayout.setText(regF, "< MAIN MENU")
        regF.draw(batch, "< MAIN MENU", btnBackX + (220f - glyphLayout.width) / 2f, btnBackY + 34f)

        batch.end()
    }

    private fun renderStickmanPreview(shapeRenderer: ShapeRenderer, x: Float, y: Float, archetype: CharacterArchetype) {
        val headRadius = 26f
        val headY = y + 175f
        val neckY = headY - headRadius
        val pelvisY = y + 75f
        val shoulderY = neckY - 14f

        val breath = sin(animTime * 3f) * 3f

        // Kepala
        shapeRenderer.color = Color.WHITE
        shapeRenderer.circle(x, headY + breath, headRadius, 20)

        // Mata
        shapeRenderer.color = Color.DARK_GRAY
        shapeRenderer.circle(x + 10f, headY + breath + 4f, 4f, 8)

        // Tubuh / Tulang Belakang
        shapeRenderer.color = Color.WHITE
        shapeRenderer.rectLine(x, neckY + breath, x, pelvisY, 8f)

        // Kaki Tegak
        shapeRenderer.rectLine(x, pelvisY, x - 28f, y, 7f)
        shapeRenderer.rectLine(x, pelvisY, x + 28f, y, 7f)

        // Lengan & Senjata Berdasarkan Arketipe
        when (archetype) {
            CharacterArchetype.BALANCED -> {
                // Tangan Kiri
                shapeRenderer.rectLine(x, shoulderY + breath, x - 32f, shoulderY - 30f + breath, 6f)
                // Tangan Kanan (Pegang Pedang Tegak)
                val handX = x + 35f
                val handY = shoulderY - 20f + breath
                shapeRenderer.rectLine(x, shoulderY + breath, handX, handY, 6f)

                // Pedang Perak Elegan
                val swordTipX = handX + 25f
                val swordTipY = handY + 110f
                shapeRenderer.setColor(0.9f, 0.95f, 1f, 1f)
                shapeRenderer.rectLine(handX, handY, swordTipX, swordTipY, 9f)
                // Crossguard
                shapeRenderer.color = Color.GOLD
                shapeRenderer.rectLine(handX - 16f, handY + 16f, handX + 16f, handY + 12f, 7f)
            }
            CharacterArchetype.AGILE -> {
                // Dual Daggers: Pose Siaga Assassin
                // Tangan Kiri (Belati Terbalik)
                val leftHandX = x - 38f
                val leftHandY = shoulderY - 10f + breath
                shapeRenderer.rectLine(x, shoulderY + breath, leftHandX, leftHandY, 6f)
                shapeRenderer.setColor(0.2f, 0.95f, 0.85f, 1f)
                shapeRenderer.rectLine(leftHandX, leftHandY, leftHandX - 25f, leftHandY + 45f, 6f)

                // Tangan Kanan (Belati Siaga Depan)
                shapeRenderer.color = Color.WHITE
                val rightHandX = x + 42f
                val rightHandY = shoulderY - 5f + breath
                shapeRenderer.rectLine(x, shoulderY + breath, rightHandX, rightHandY, 6f)
                shapeRenderer.setColor(0.2f, 0.95f, 0.85f, 1f)
                shapeRenderer.rectLine(rightHandX, rightHandY, rightHandX + 35f, rightHandY + 35f, 6f)
            }
            CharacterArchetype.HEAVY -> {
                // Colossal Greatsword: Pedang Raksasa di Punggung/Samping
                val handX = x + 32f
                val handY = shoulderY - 25f + breath
                shapeRenderer.rectLine(x, shoulderY + breath, handX, handY, 7f)

                // Bilah Raksasa Slab Tebal
                val swordTipX = handX + 30f
                val swordTipY = handY + 145f
                shapeRenderer.setColor(0.28f, 0.30f, 0.36f, 1f)
                shapeRenderer.rectLine(handX, handY, swordTipX, swordTipY, 20f)
                // Tepian Berapi Magma
                shapeRenderer.setColor(1f, 0.45f, 0.1f, 1f)
                shapeRenderer.rectLine(handX, handY, swordTipX, swordTipY, 7f)
                // Crossguard Raksasa Emas
                shapeRenderer.color = Color.GOLD
                shapeRenderer.rectLine(handX - 22f, handY + 20f, handX + 22f, handY + 16f, 10f)
            }
        }
    }

    private fun renderStatBars(shapeRenderer: ShapeRenderer, archetype: CharacterArchetype) {
        val barX = 890f
        val totalW = 190f
        val segCount = 5
        val segGap = 5f
        val segW = (totalW - (segCount - 1) * segGap) / segCount
        val segH = 14f

        fun drawPips(y: Float, filledCount: Int, color: Color) {
            for (i in 0 until segCount) {
                val sx = barX + i * (segW + segGap)
                if (i < filledCount) {
                    shapeRenderer.color = color
                    shapeRenderer.rect(sx, y, segW, segH)
                    shapeRenderer.setColor(1f, 1f, 1f, 0.35f)
                    shapeRenderer.rectLine(sx, y + segH - 1f, sx + segW, y + segH - 1f, 1f)
                } else {
                    shapeRenderer.setColor(0.12f, 0.16f, 0.22f, 0.9f)
                    shapeRenderer.rect(sx, y, segW, segH)
                    shapeRenderer.setColor(0.18f, 0.24f, 0.32f, 0.5f)
                    shapeRenderer.rectLine(sx, y, sx + segW, y, 1f)
                }
            }
        }

        val spdCount = when (archetype) {
            CharacterArchetype.BALANCED -> 3
            CharacterArchetype.AGILE -> 5
            CharacterArchetype.HEAVY -> 2
        }
        val spdColor = when (archetype) {
            CharacterArchetype.BALANCED -> COLOR_CYAN_PIP
            CharacterArchetype.AGILE -> COLOR_GOLD_PIP
            CharacterArchetype.HEAVY -> COLOR_MUTED_PIP
        }
        val atkCount = when (archetype) {
            CharacterArchetype.BALANCED -> 3
            CharacterArchetype.AGILE -> 4
            CharacterArchetype.HEAVY -> 5
        }
        val atkColor = when (archetype) {
            CharacterArchetype.BALANCED -> COLOR_CYAN_PIP
            CharacterArchetype.AGILE -> COLOR_PURPLE_PIP
            CharacterArchetype.HEAVY -> COLOR_GOLD_PIP
        }
        val defCount = when (archetype) {
            CharacterArchetype.BALANCED -> 3
            CharacterArchetype.AGILE -> 2
            CharacterArchetype.HEAVY -> 5
        }
        val defColor = when (archetype) {
            CharacterArchetype.BALANCED -> COLOR_CYAN_PIP
            CharacterArchetype.AGILE -> COLOR_MUTED_PIP
            CharacterArchetype.HEAVY -> COLOR_GOLD_PIP
        }
        val critCount = when (archetype) {
            CharacterArchetype.BALANCED -> 3
            CharacterArchetype.AGILE -> 5
            CharacterArchetype.HEAVY -> 2
        }
        val critColor = when (archetype) {
            CharacterArchetype.BALANCED -> COLOR_CYAN_PIP
            CharacterArchetype.AGILE -> COLOR_GOLD_PIP
            CharacterArchetype.HEAVY -> COLOR_MUTED_PIP
        }

        drawPips(422f, spdCount, Color.CYAN)
        drawPips(382f, atkCount, COLOR_RED_PIP)
        drawPips(342f, defCount, COLOR_GREEN_PIP)
        drawPips(302f, critCount, COLOR_ORANGE_PIP)

        // Tier Badge Boxes:
        fun drawBadgeBox(y: Float, borderColor: Color) {
            val bx = 1094f
            shapeRenderer.setColor(0.10f, 0.14f, 0.22f, 0.95f)
            shapeRenderer.rect(bx, y - 2f, 32f, 18f)
            shapeRenderer.color = borderColor
            shapeRenderer.rectLine(bx, y - 2f, bx + 32f, y - 2f, 1.5f)
            shapeRenderer.rectLine(bx, y + 16f, bx + 32f, y + 16f, 1.5f)
            shapeRenderer.rectLine(bx, y - 2f, bx, y + 16f, 1.5f)
            shapeRenderer.rectLine(bx + 32f, y - 2f, bx + 32f, y + 16f, 1.5f)
        }

        drawBadgeBox(422f, spdColor)
        drawBadgeBox(382f, atkColor)
        drawBadgeBox(342f, defColor)
        drawBadgeBox(302f, critColor)
    }

    private fun handleInput() {
        if (Gdx.input.isKeyJustPressed(Keys.LEFT) || Gdx.input.isKeyJustPressed(Keys.A)) {
            selectedIndex = (selectedIndex - 1 + archetypes.size) % archetypes.size
            AudioManager.playJump()
        }
        if (Gdx.input.isKeyJustPressed(Keys.RIGHT) || Gdx.input.isKeyJustPressed(Keys.D)) {
            selectedIndex = (selectedIndex + 1) % archetypes.size
            AudioManager.playJump()
        }

        if (Gdx.input.isKeyJustPressed(Keys.ENTER) || Gdx.input.isKeyJustPressed(Keys.SPACE)) {
            confirmSelection()
        }
        if (Gdx.input.isKeyJustPressed(Keys.ESCAPE) || Gdx.input.isKeyJustPressed(Keys.BACK)) {
            saveSelection()
            AudioManager.playDodge()
            game.setScreen(MainMenuScreen(game))
            return
        }

        // Klik Mouse & Layar Sentuh Mobile
        if (Gdx.input.justTouched()) {
            touchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
            viewport.unproject(touchVec)

            // Panah Kiri Podium & Zona Sentuh Kiri
            if (touchVec.x in 50f..220f && touchVec.y in 260f..440f) {
                selectedIndex = (selectedIndex - 1 + archetypes.size) % archetypes.size
                AudioManager.playJump()
                return
            }
            // Panah Kanan Podium & Zona Sentuh Kanan
            if (touchVec.x in 460f..620f && touchVec.y in 260f..440f) {
                selectedIndex = (selectedIndex + 1) % archetypes.size
                AudioManager.playJump()
                return
            }
            // Ketuk Karakter / Altar di Podium untuk ganti karakter
            if (touchVec.x in 220f..350f && touchVec.y in 140f..580f) {
                selectedIndex = (selectedIndex - 1 + archetypes.size) % archetypes.size
                AudioManager.playJump()
                return
            }
            if (touchVec.x in 350f..460f && touchVec.y in 140f..580f) {
                selectedIndex = (selectedIndex + 1) % archetypes.size
                AudioManager.playJump()
                return
            }

            // Tombol Confirm & Play (Area sentuh ekstra luas)
            if (touchVec.x in 660f..1040f && touchVec.y in 25f..115f) {
                confirmSelection()
                return
            }
            // Tombol Back (Area sentuh ekstra luas)
            if (touchVec.x in 240f..580f && touchVec.y in 25f..115f) {
                saveSelection()
                AudioManager.playDodge()
                game.setScreen(MainMenuScreen(game))
                return
            }
        }
    }

    private fun saveSelection() {
        val selected = archetypes[selectedIndex]
        if (!CharacterUnlockManager.isUnlocked(selected, currentSave)) return
        val save = SaveManager.load()
        save.selectedArchetype = selected.name
        SaveManager.save(save)
    }

    private fun confirmSelection() {
        val selected = archetypes[selectedIndex]
        if (!CharacterUnlockManager.isUnlocked(selected, currentSave)) {
            AudioManager.playDodge()
            HapticManager.vibrateHeavy()
            return
        }
        saveSelection()
        AudioManager.playLevelUp()
        game.setScreen(PlayScreen(game, 1, GameMode.STORY))
    }

    override fun resize(width: Int, height: Int) {
        viewport.update(width, height, true)
    }

    override fun pause() {}
    override fun resume() {}
    override fun hide() {}

    override fun dispose() {
        shapeRenderer.dispose()
        batch.dispose()
    }
}

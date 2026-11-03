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
import com.badlogic.gdx.math.Vector2
import com.badlogic.gdx.math.Vector3
import com.badlogic.gdx.utils.ScreenUtils
import com.badlogic.gdx.utils.viewport.FitViewport
import com.badlogic.gdx.utils.viewport.Viewport
import com.stickman.tower.StickmanGame
import com.stickman.tower.audio.AudioManager
import com.stickman.tower.audio.HapticManager
import com.stickman.tower.rpg.CharacterStats
import com.stickman.tower.rpg.SaveData
import com.stickman.tower.rpg.SaveManager
import com.stickman.tower.rune.RuneManager
import com.stickman.tower.rune.RuneType
import com.stickman.tower.ui.FontManager
import kotlin.math.sin

/**
 * Layar Toko Tempa Senjata Blacksmith (Fase 10 & 22):
 * Mengizinkan pemain membelanjakan Gold yang diperoleh dari menara untuk meningkatkan
 * statistik senjata permanen serta memasang / menukar Rune Kuno pada 2 soket senjata.
 */
class BlacksmithScreen(private val game: StickmanGame, val returnScreen: Screen? = null) : Screen {

    private val camera = OrthographicCamera()
    private val viewport: Viewport = FitViewport(1280f, 720f, camera)
    private val shapeRenderer = ShapeRenderer()
    private val batch = SpriteBatch()
    private val glyphLayout = GlyphLayout()
    private val touchVec = Vector3()

    private var saveData: SaveData = SaveManager.load()
    private val stats: CharacterStats = CharacterStats().apply { loadFromSaveData(saveData) }

    private var selectedIndex = 0
    private val totalItems = 6 // 0: ATK, 1: CRIT, 2: SPD, 3: SOKET 1, 4: SOKET 2, 5: RETURN
    private var animTime = 0f
    private var noticeText = ""
    private var noticeTimer = 0f
    private var hammerImpactFlash = 0f
    private var inputCooldown = 0.25f

    // Partikel Ember Percikan Api Tempa
    private class ForgeSpark(
        val pos: Vector2 = Vector2(),
        val vel: Vector2 = Vector2(),
        var size: Float = 0f,
        var color: Color = Color.ORANGE,
        var maxLife: Float = 1f
    ) {
        var life: Float = 0f
        val isExpired: Boolean get() = life >= maxLife

        fun reset(initial: Boolean = false) {
            pos.set(MathUtils.random(100f, 1180f), if (initial) MathUtils.random(0f, 720f) else -10f)
            vel.set(MathUtils.random(-25f, 25f), MathUtils.random(40f, 110f))
            size = MathUtils.random(2f, 5f)
            val isGold = MathUtils.randomBoolean(0.6f)
            color = if (isGold) Color(1f, 0.75f, 0.2f, MathUtils.random(0.4f, 0.8f))
                    else Color(1f, 0.35f, 0.1f, MathUtils.random(0.3f, 0.7f))
            maxLife = MathUtils.random(4f, 9f)
            life = 0f
        }
    }
    private val sparks = mutableListOf<ForgeSpark>()

    override fun show() {
        Gdx.input?.setCatchKey(Keys.BACK, true)
        AudioManager.init()
        HapticManager.init()
        FontManager.init()
        inputCooldown = 0.25f
        saveData = SaveManager.load()
        stats.loadFromSaveData(saveData)

        sparks.clear()
        for (i in 0 until 40) {
            val s = ForgeSpark()
            s.reset(initial = true)
            sparks.add(s)
        }
    }

    override fun render(delta: Float) {
        if (game.screen !== this) return

        animTime += delta
        if (noticeTimer > 0f) {
            noticeTimer = (noticeTimer - delta).coerceAtLeast(0f)
            if (noticeTimer <= 0f) noticeText = ""
        }
        if (hammerImpactFlash > 0f) {
            hammerImpactFlash = (hammerImpactFlash - delta * 4f).coerceAtLeast(0f)
        }

        updateSparks(delta)
        if (inputCooldown > 0f) {
            inputCooldown -= delta
        } else {
            handleInput()
        }

        ScreenUtils.clear(0.05f, 0.06f, 0.09f, 1f)
        viewport.apply()
        camera.update()
        shapeRenderer.projectionMatrix = camera.combined
        batch.projectionMatrix = camera.combined

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        // 1. Gambar Background & Arsitektur Bengkel Tempa
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Pilar Bengkel
        shapeRenderer.setColor(0.08f, 0.10f, 0.15f, 0.95f)
        shapeRenderer.rect(0f, 0f, 80f, 720f)
        shapeRenderer.rect(1200f, 0f, 80f, 720f)
        shapeRenderer.setColor(0.95f, 0.55f, 0.15f, 0.4f)
        shapeRenderer.rectLine(80f, 0f, 80f, 720f, 2f)
        shapeRenderer.rectLine(1200f, 0f, 1200f, 720f, 2f)

        // Partikel Percikan Api
        for (s in sparks) {
            val alpha = (1f - (s.life / s.maxLife)).coerceIn(0f, 1f)
            shapeRenderer.setColor(s.color.r, s.color.g, s.color.b, s.color.a * alpha)
            shapeRenderer.circle(s.pos.x, s.pos.y, s.size)
        }

        // Header Card (Tungku Tempa Emas)
        shapeRenderer.setColor(0.08f, 0.11f, 0.18f, 0.95f)
        shapeRenderer.rect(120f, 600f, 1040f, 95f)
        shapeRenderer.setColor(0.95f, 0.65f, 0.2f, 0.85f)
        shapeRenderer.rectLine(120f, 600f, 1160f, 600f, 2.5f)

        // Flash Efek Palu Tempa (Hammer Impact)
        if (hammerImpactFlash > 0f) {
            shapeRenderer.setColor(1f, 0.85f, 0.3f, hammerImpactFlash * 0.45f)
            shapeRenderer.rect(120f, 140f, 1040f, 440f)
        }

        // Kartu Kategori Upgrade Senjata
        val cardW = 1040f
        val cardH = 100f
        val startY = 460f
        val spacingY = 115f
        val cardX = 120f

        for (i in 0 until 3) {
            val cardY = startY - (i * spacingY)
            val isSelected = i == selectedIndex

            // Latar Belakang Kartu
            if (isSelected) {
                shapeRenderer.setColor(0.14f, 0.18f, 0.28f, 0.95f)
            } else {
                shapeRenderer.setColor(0.08f, 0.10f, 0.16f, 0.85f)
            }
            shapeRenderer.rect(cardX, cardY, cardW, cardH)

            // Garis Tepi (Oranye Emas jika terpilih)
            val pulse = if (isSelected) (sin(animTime * 6f) + 1f) * 0.15f else 0f
            if (isSelected) {
                shapeRenderer.setColor(1f, 0.72f, 0.2f, 0.8f + pulse)
            } else {
                shapeRenderer.setColor(0.2f, 0.25f, 0.35f, 0.5f)
            }
            val borderThick = if (isSelected) 2.5f else 1.5f
            shapeRenderer.rectLine(cardX, cardY, cardX + cardW, cardY, borderThick)
            shapeRenderer.rectLine(cardX, cardY + cardH, cardX + cardW, cardY + cardH, borderThick)

            // Indikator Pip Level 1..5
            val currentLevel = when (i) {
                0 -> stats.weaponAtkLevel
                1 -> stats.weaponCritLevel
                else -> stats.weaponSpdLevel
            }
            val pipStartX = cardX + 380f
            val pipY = cardY + 28f
            val pipW = 32f
            val pipH = 16f
            val pipSpacing = 8f
            for (p in 0 until CharacterStats.MAX_WEAPON_LEVEL) {
                val px = pipStartX + (p * (pipW + pipSpacing))
                if (p < currentLevel) {
                    shapeRenderer.setColor(1f, 0.75f, 0.2f, 1f)
                } else {
                    shapeRenderer.setColor(0.18f, 0.22f, 0.30f, 1f)
                }
                shapeRenderer.rect(px, pipY, pipW, pipH)
            }

            // Tombol Upgrade di Sisi Kanan Kartu
            val btnW = 200f
            val btnH = 50f
            val btnX = cardX + cardW - btnW - 25f
            val btnY = cardY + 25f
            val isMax = currentLevel >= CharacterStats.MAX_WEAPON_LEVEL
            val cost = CharacterStats.getUpgradeCost(currentLevel)
            val canAfford = stats.gold >= cost

            when {
                isMax -> shapeRenderer.setColor(0.22f, 0.26f, 0.32f, 0.8f)
                canAfford -> if (isSelected) shapeRenderer.setColor(0.85f, 0.45f, 0.10f, 0.95f) else shapeRenderer.setColor(0.65f, 0.35f, 0.10f, 0.85f)
                else -> shapeRenderer.setColor(0.35f, 0.18f, 0.18f, 0.75f)
            }
            shapeRenderer.rect(btnX, btnY, btnW, btnH)
            if (isSelected && !isMax && canAfford) {
                shapeRenderer.color = Color.GOLD
            } else {
                shapeRenderer.setColor(0.4f, 0.45f, 0.55f, 0.6f)
            }
            shapeRenderer.rectLine(btnX, btnY, btnX + btnW, btnY, 1.5f)
            shapeRenderer.rectLine(btnX, btnY + btnH, btnX + btnW, btnY + btnH, 1.5f)
        }

        // Kartu Soket Rune 1 & 2 (Fase 22)
        val socketW = 505f
        val socketH = 82f
        val socketY = 115f

        for (s in 0 until 2) {
            val sockX = if (s == 0) 120f else 655f
            val isSockSelected = selectedIndex == (3 + s)
            val equippedRune = RuneType.fromString(saveData.equippedRunes.getOrNull(s))

            if (isSockSelected) {
                shapeRenderer.setColor(0.16f, 0.20f, 0.32f, 0.95f)
            } else {
                shapeRenderer.setColor(0.08f, 0.10f, 0.17f, 0.88f)
            }
            shapeRenderer.rect(sockX, socketY, socketW, socketH)

            // Garis border dengan warna rune jika terpasang
            val borderPulse = if (isSockSelected) (sin(animTime * 6f) + 1f) * 0.15f else 0f
            if (isSockSelected) {
                shapeRenderer.setColor(1f, 0.72f, 0.2f, 0.8f + borderPulse)
            } else if (equippedRune != RuneType.NONE) {
                shapeRenderer.setColor(equippedRune.primaryColor.r, equippedRune.primaryColor.g, equippedRune.primaryColor.b, 0.6f)
            } else {
                shapeRenderer.setColor(0.2f, 0.25f, 0.35f, 0.5f)
            }
            shapeRenderer.rectLine(sockX, socketY, sockX + socketW, socketY, if (isSockSelected) 2.5f else 1.5f)
            shapeRenderer.rectLine(sockX, socketY + socketH, sockX + socketW, socketY + socketH, if (isSockSelected) 2.5f else 1.5f)

            // Lingkaran ornamen soket
            shapeRenderer.setColor(equippedRune.primaryColor)
            shapeRenderer.circle(sockX + 45f, socketY + socketH / 2f, 22f, 16)
        }

        // Tombol Kembali (Return to Main Menu / PlayScreen)
        val returnY = 28f
        val returnW = 340f
        val returnH = 44f
        val returnX = (1280f - returnW) / 2f
        val isReturnSelected = selectedIndex == 5

        if (isReturnSelected) {
            shapeRenderer.setColor(0.18f, 0.25f, 0.38f, 0.95f)
        } else {
            shapeRenderer.setColor(0.08f, 0.11f, 0.18f, 0.85f)
        }
        shapeRenderer.rect(returnX, returnY, returnW, returnH)
        if (isReturnSelected) {
            shapeRenderer.color = Color.YELLOW
        } else {
            shapeRenderer.setColor(0.4f, 0.45f, 0.55f, 0.7f)
        }
        shapeRenderer.rectLine(returnX, returnY, returnX + returnW, returnY, 2f)
        shapeRenderer.rectLine(returnX, returnY + returnH, returnX + returnW, returnY + returnH, 2f)

        shapeRenderer.end()

        // 2. Render Tipografi & Teks
        batch.begin()
        val titleF = FontManager.titleFont
        val headF = FontManager.headerFont
        val regF = FontManager.regularFont

        // Judul Utama
        titleF.setColor(1f, 0.85f, 0.35f, 1f)
        titleF.draw(batch, "BLACKSMITH WEAPON FORGE", 160f, 672f)

        // Subtitle & Gold Player
        regF.setColor(0.85f, 0.88f, 0.95f, 0.9f)
        regF.draw(batch, "Forge your steel with ancient spire gold for permanent combat prowess", 160f, 630f)

        headF.color = Color.GOLD
        val goldStr = "❖ ${stats.gold} GOLD"
        glyphLayout.setText(headF, goldStr)
        headF.draw(batch, goldStr, 1140f - glyphLayout.width, 660f)

        // Informasi Tiap Kategori Upgrade
        val upgradeTitles = listOf("SHARPENING STONE", "HOLLOW EDGE", "LIGHTWEIGHT HILT")
        val upgradeDescs = listOf(
            "+4.0 Flat ATK per tier",
            "+2.5% Critical Rate per tier",
            "+3.5% Agility & Attack Speed per tier"
        )

        for (i in 0 until 3) {
            val cardY = startY - (i * spacingY)
            val currentLevel = when (i) {
                0 -> stats.weaponAtkLevel
                1 -> stats.weaponCritLevel
                else -> stats.weaponSpdLevel
            }
            val currentStatBonus = when (i) {
                0 -> "+${stats.weaponAtkBonus.toInt()} ATK (Total: ${stats.attackPower.toInt()})"
                1 -> "+${(stats.weaponCritBonus * 100).toInt()}% CRIT (Total: ${(stats.critRate * 100).toInt()}%)"
                else -> "+${(stats.weaponSpdBonus * 100).toInt()}% SPD & Attack Speed"
            }

            // Judul Kategori
            if (i == selectedIndex) headF.setColor(1f, 0.9f, 0.4f, 1f) else headF.color = Color.WHITE
            headF.draw(batch, "${i + 1}. ${upgradeTitles[i]}", cardX + 25f, cardY + 80f)

            // Deskripsi & Stat Saat Ini
            regF.setColor(0.75f, 0.8f, 0.9f, 0.9f)
            regF.draw(batch, upgradeDescs[i], cardX + 25f, cardY + 52f)
            regF.setColor(0.4f, 0.9f, 1f, 1f)
            regF.draw(batch, "Current: $currentStatBonus", cardX + 25f, cardY + 28f)

            // Teks Level & Tombol Upgrade
            regF.color = Color.GOLD
            regF.draw(batch, "Tier $currentLevel / ${CharacterStats.MAX_WEAPON_LEVEL}", cardX + 380f, cardY + 70f)

            val isMax = currentLevel >= CharacterStats.MAX_WEAPON_LEVEL
            val cost = CharacterStats.getUpgradeCost(currentLevel)
            val btnX = cardX + cardW - 200f - 25f
            val btnY = cardY + 25f

            val btnText = if (isMax) "MAX TIER" else "UPGRADE (${cost}G)"
            regF.color = if (isMax) Color.LIGHT_GRAY else Color.WHITE
            glyphLayout.setText(regF, btnText)
            regF.draw(batch, btnText, btnX + (200f - glyphLayout.width) / 2f, btnY + 32f)
        }

        // Teks Soket Rune 1 & 2 (Fase 22)
        for (s in 0 until 2) {
            val sockX = if (s == 0) 120f else 655f
            val isSockSelected = selectedIndex == (3 + s)
            val equippedRune = RuneType.fromString(saveData.equippedRunes.getOrNull(s))

            // Simbol Rune
            headF.color = equippedRune.primaryColor
            headF.draw(batch, equippedRune.runeSymbol, sockX + 38f, socketY + 50f)

            // Nama Soket & Rune
            headF.color = if (isSockSelected) Color.YELLOW else Color.WHITE
            headF.draw(batch, "SOKET ${s + 1}: ${equippedRune.displayName}", sockX + 80f, socketY + 64f)

            // Subtitle & Status
            regF.setColor(0.75f, 0.85f, 0.95f, 0.85f)
            val actionHint = if (isSockSelected) "[ KLIK / ENTER: GANTI ]" else "[ KETUK GANTI ]"
            regF.draw(batch, "${equippedRune.subtitle} • $actionHint", sockX + 80f, socketY + 32f)
        }

        // Teks Tombol Kembali
        val returnText = if (isReturnSelected) "⚔  BACK TO MAIN MENU  ⚔" else "BACK TO MAIN MENU"
        headF.color = if (isReturnSelected) Color.YELLOW else Color.WHITE
        glyphLayout.setText(headF, returnText)
        headF.draw(batch, returnText, (1280f - glyphLayout.width) / 2f, returnY + 30f)

        // Notifikasi / Feedback Pembelian
        if (noticeText.isNotEmpty()) {
            regF.color = Color.GREEN
            glyphLayout.setText(regF, noticeText)
            regF.draw(batch, noticeText, (1280f - glyphLayout.width) / 2f, 88f)
        }

        batch.end()
    }

    private fun handleInput() {
        if (Gdx.input.isKeyJustPressed(Keys.UP) || Gdx.input.isKeyJustPressed(Keys.W)) {
            selectedIndex = (selectedIndex - 1 + totalItems) % totalItems
            AudioManager.playJump()
        }
        if (Gdx.input.isKeyJustPressed(Keys.DOWN) || Gdx.input.isKeyJustPressed(Keys.S)) {
            selectedIndex = (selectedIndex + 1) % totalItems
            AudioManager.playJump()
        }

        if (Gdx.input.isKeyJustPressed(Keys.ENTER) || Gdx.input.isKeyJustPressed(Keys.SPACE)) {
            executeSelection()
        }

        if (Gdx.input.isKeyJustPressed(Keys.BACK) || Gdx.input.isKeyJustPressed(Keys.ESCAPE)) {
            returnToMenu()
        }

        // Sentuh / Klik Mouse (Area Sentuh Ekstra Luas)
        if (Gdx.input.justTouched()) {
            touchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
            viewport.unproject(touchVec)

            val cardW = 1040f
            val cardH = 100f
            val startY = 460f
            val spacingY = 115f
            val cardX = 120f

            for (i in 0 until 3) {
                val cardY = startY - (i * spacingY)
                if (touchVec.x in (cardX - 40f)..(cardX + cardW + 40f) && touchVec.y in (cardY - 8f)..(cardY + cardH + 8f)) {
                    selectedIndex = i
                    executeSelection()
                    return
                }
            }

            // Sentuhan Soket Rune 1 & 2 (Fase 22)
            if (touchVec.y in 105f..205f) {
                if (touchVec.x in 110f..635f) {
                    selectedIndex = 3
                    executeSelection()
                    return
                } else if (touchVec.x in 645f..1170f) {
                    selectedIndex = 4
                    executeSelection()
                    return
                }
            }

            // Tombol Kembali
            val returnY = 28f
            val returnW = 340f
            val returnH = 44f
            val returnX = (1280f - returnW) / 2f
            if (touchVec.x in (returnX - 80f)..(returnX + returnW + 80f) && touchVec.y in (returnY - 15f)..(returnY + returnH + 25f)) {
                selectedIndex = 5
                executeSelection()
            }
        }
    }

    private fun executeSelection() {
        when (selectedIndex) {
            0 -> {
                if (stats.upgradeAtk()) {
                    onUpgradeSuccess("Sharpening Stone Tier ${stats.weaponAtkLevel} Forged! (+4 ATK)")
                } else {
                    onUpgradeFailed(stats.weaponAtkLevel)
                }
            }
            1 -> {
                if (stats.upgradeCrit()) {
                    onUpgradeSuccess("Hollow Edge Tier ${stats.weaponCritLevel} Forged! (+2.5% CRIT)")
                } else {
                    onUpgradeFailed(stats.weaponCritLevel)
                }
            }
            2 -> {
                if (stats.upgradeSpd()) {
                    onUpgradeSuccess("Lightweight Hilt Tier ${stats.weaponSpdLevel} Forged! (+3.5% SPD)")
                } else {
                    onUpgradeFailed(stats.weaponSpdLevel)
                }
            }
            3 -> { // Ganti Rune Soket 1
                cycleRuneSocket(0)
            }
            4 -> { // Ganti Rune Soket 2
                cycleRuneSocket(1)
            }
            5 -> {
                returnToMenu()
            }
        }
    }

    private fun cycleRuneSocket(slotIndex: Int) {
        val available = listOf(RuneType.NONE) + RuneType.values().filter { it != RuneType.NONE && saveData.unlockedRunes.contains(it.id) }.distinct()
        val currentRune = RuneType.fromString(saveData.equippedRunes.getOrNull(slotIndex))
        val currentIdx = available.indexOf(currentRune)
        val nextRune = available[(if (currentIdx >= 0) currentIdx + 1 else 0) % available.size]

        RuneManager.equipRune(slotIndex, nextRune, saveData)
        stats.loadFromSaveData(saveData)
        SaveManager.save(saveData)

        hammerImpactFlash = 0.8f
        AudioManager.playChest()
        HapticManager.vibrateMedium()
        noticeText = "Soket ${slotIndex + 1}: ${nextRune.displayName} Terpasang! (${nextRune.subtitle})"
        noticeTimer = 3.0f
    }

    private fun onUpgradeSuccess(message: String) {
        saveData = stats.applyToSaveData(saveData)
        com.stickman.tower.achievement.AchievementManager.onWeaponUpgraded(stats.weaponAtkLevel, saveData)
        com.stickman.tower.quest.QuestManager.notifyEvent(com.stickman.tower.quest.ObjectiveType.UPGRADE_WEAPON, "FORGE_WEAPON")
        com.stickman.tower.quest.QuestManager.saveTo(saveData)
        SaveManager.save(saveData)

        hammerImpactFlash = 1.0f
        noticeText = message
        noticeTimer = 2.5f

        AudioManager.playSlashHeavy()
        HapticManager.vibrateHeavy()
    }

    private fun onUpgradeFailed(currentLevel: Int) {
        if (currentLevel >= CharacterStats.MAX_WEAPON_LEVEL) {
            noticeText = "Senjata ini telah mencapai batas tier maksimal (MAX LEVEL)!"
        } else {
            val cost = CharacterStats.getUpgradeCost(currentLevel)
            noticeText = "Gold tidak mencukupi! Butuh $cost Gold untuk menempa tier berikutnya."
        }
        noticeTimer = 2.0f
        AudioManager.playDeath()
        HapticManager.vibrateLight()
    }

    private fun returnToMenu() {
        AudioManager.playSlashLight()
        if (returnScreen != null) {
            game.setScreen(returnScreen)
        } else {
            game.setScreen(MainMenuScreen(game))
        }
    }

    private fun updateSparks(delta: Float) {
        for (s in sparks) {
            s.life += delta
            s.pos.x += s.vel.x * delta
            s.pos.y += s.vel.y * delta
            if (s.isExpired || s.pos.y > 730f) {
                s.reset(initial = false)
            }
        }
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

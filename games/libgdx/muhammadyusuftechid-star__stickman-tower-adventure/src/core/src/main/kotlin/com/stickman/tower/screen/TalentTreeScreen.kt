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
import com.badlogic.gdx.math.Vector3
import com.badlogic.gdx.utils.ScreenUtils
import com.badlogic.gdx.utils.viewport.FitViewport
import com.badlogic.gdx.utils.viewport.Viewport
import com.stickman.tower.StickmanGame
import com.stickman.tower.audio.AudioManager
import com.stickman.tower.audio.HapticManager
import com.stickman.tower.character.CharacterArchetype
import com.stickman.tower.rpg.SaveData
import com.stickman.tower.rpg.SaveManager
import com.stickman.tower.talent.SubClass
import com.stickman.tower.talent.Talent
import com.stickman.tower.talent.TalentCatalog
import com.stickman.tower.talent.TalentManager
import com.stickman.tower.ui.FontManager
import kotlin.math.sin

/**
 * Layar Visualisasi dan Pengalokasian Talent Tree & Sub-Class (Fase 13).
 * Menyajikan antarmuka pemilihan spesialisasi arketipe dan pembukaan nodus pasif.
 */
class TalentTreeScreen(
    private val game: StickmanGame?,
    private val returnScreen: Screen
) : Screen {
    companion object {
        val COLOR_UNLOCKED_HDR = Color(0.4f, 1.0f, 0.5f, 1f)
        val COLOR_LOCKED_HDR = Color(0.6f, 0.65f, 0.75f, 1f)
    }

    private val camera = OrthographicCamera()
    private val viewport: Viewport = FitViewport(1280f, 720f, camera)
    private val shapeRenderer = ShapeRenderer()
    private val batch = SpriteBatch()
    private val glyphLayout = GlyphLayout()
    private val touchVec = Vector3()

    private val saveData: SaveData = SaveManager.load()
    private val currentArchetype = CharacterArchetype.fromString(saveData.selectedArchetype)
    private val talentManager = TalentManager()

    private val subClasses = SubClass.getSubClassesFor(currentArchetype)
    private var feedbackText = ""
    private var feedbackTimer = 0f
    private var animTime = 0f
    private var inputCooldown = 0.25f

    override fun show() {
        Gdx.input?.setCatchKey(Keys.BACK, true)
        AudioManager.init()
        HapticManager.init()
        FontManager.init()
        inputCooldown = 0.25f
        talentManager.loadFromSave(saveData)
        // Otomatis sinkronkan sub-class agar selalu sesuai dengan archetype aktif
        if (talentManager.selectedSubClass == SubClass.NONE || talentManager.selectedSubClass.archetype != currentArchetype) {
            if (subClasses.isNotEmpty()) {
                talentManager.selectSubClass(subClasses.first(), currentArchetype)
            }
        }
    }

    override fun render(delta: Float) {
        animTime += delta
        if (feedbackTimer > 0f) {
            feedbackTimer -= delta
            if (feedbackTimer <= 0f) feedbackText = ""
        }

        if (inputCooldown > 0f) {
            inputCooldown -= delta
        } else {
            handleInput()
        }

        ScreenUtils.clear(0.04f, 0.06f, 0.10f, 1f)
        camera.update()
        shapeRenderer.projectionMatrix = camera.combined
        batch.projectionMatrix = camera.combined

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        renderVisualBackground()
        renderTalentColumns()
        renderHeaderAndFooter()
    }

    private fun handleInput() {
        if (Gdx.input.isKeyJustPressed(Keys.BACK) || Gdx.input.isKeyJustPressed(Keys.ESCAPE)) {
            exitAndSave()
            return
        }

        if (Gdx.input.isKeyJustPressed(Keys.R)) {
            talentManager.respecTalents()
            AudioManager.playDodge()
            HapticManager.vibrateMedium()
            feedbackText = "Talent Points berhasil di-reset!"
            feedbackTimer = 2.0f
        }

        if (Gdx.input.justTouched()) {
            touchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
            viewport.unproject(touchVec)
            val tx = touchVec.x
            val ty = touchVec.y

            // Cek Tombol Exit (Pojok Kiri Bawah - Area Sentuh Ekstra Luas)
            if (tx in 15f..280f && ty in 10f..85f) {
                exitAndSave()
                return
            }

            // Cek Tombol Respec (Pojok Kanan Bawah - Area Sentuh Ekstra Luas)
            if (tx in 980f..1265f && ty in 10f..85f) {
                talentManager.respecTalents()
                AudioManager.playDodge()
                HapticManager.vibrateMedium()
                feedbackText = "Talent Points di-reset!"
                feedbackTimer = 2.0f
                return
            }

            // Cek Interaksi Tiap Kolom Sub-Class
            val colW = 560f
            val startY = 100f
            val colH = 490f

            for (cIndex in subClasses.indices) {
                val subClass = subClasses[cIndex]
                val colX = if (cIndex == 0) 65f else 655f

                // Tombol Select Sub-Class (Hitbox responsif)
                val selectBtnY = startY + colH - 95f
                if (tx in (colX - 10f)..(colX + colW + 10f) && ty in (selectBtnY - 12f)..(selectBtnY + 48f)) {
                    talentManager.selectSubClass(subClass, currentArchetype)
                    AudioManager.playParry()
                    HapticManager.vibrateHeavy()
                    feedbackText = "Sub-Class ${subClass.displayName} Dipilih!"
                    feedbackTimer = 2.0f
                    return
                }

                // Cek Klik Tiap Talent Card (Otomatis aktifkan sub-class jika disentuh)
                val talents = TalentCatalog.getTalentsFor(subClass)
                val nodeStartY = selectBtnY - 95f
                for (tIndex in talents.indices) {
                    val talent = talents[tIndex]
                    val nodeY = nodeStartY - (tIndex * 98f)
                    val nodeH = 88f

                    if (tx in (colX - 10f)..(colX + colW + 10f) && ty in (nodeY - 6f)..(nodeY + nodeH + 6f)) {
                        if (talentManager.selectedSubClass != subClass) {
                            talentManager.selectSubClass(subClass, currentArchetype)
                            HapticManager.vibrateLight()
                        }

                        if (talentManager.isTalentUnlocked(talent.id)) {
                            feedbackText = "Talent ${talent.name} sudah aktif!"
                            feedbackTimer = 1.5f
                        } else if (talentManager.canUnlockTalent(talent)) {
                            talentManager.unlockTalent(talent)
                            com.stickman.tower.achievement.AchievementManager.onTalentsUnlocked(talentManager.unlockedTalentIds.size, saveData)
                            AudioManager.playChest()
                            HapticManager.vibrateHeavy()
                            feedbackText = "Talent ${talent.name} Berhasil Dipelajari!"
                            feedbackTimer = 2.0f
                        } else {
                            feedbackText = "Poin tidak cukup atau butuh tier sebelumnya!"
                            feedbackTimer = 2.0f
                            AudioManager.playHit()
                        }
                        return
                    }
                }
            }
        }
    }

    private fun renderVisualBackground() {
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Gradient Ornamen Latar
        shapeRenderer.setColor(0.06f, 0.09f, 0.16f, 0.85f)
        shapeRenderer.rect(0f, 0f, 1280f, 720f)

        // Garis Pembatas Menara & Sinar Mistis
        shapeRenderer.setColor(0.15f, 0.22f, 0.35f, 0.40f)
        shapeRenderer.rectLine(640f, 90f, 640f, 610f, 2f)

        shapeRenderer.end()
    }

    private fun renderTalentColumns() {
        val colW = 560f
        val startY = 95f
        val colH = 505f

        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        for (cIndex in subClasses.indices) {
            val subClass = subClasses[cIndex]
            val colX = if (cIndex == 0) 65f else 655f
            val isSelected = talentManager.selectedSubClass == subClass

            // Background Card Sub-Class
            if (isSelected) {
                shapeRenderer.setColor(0.10f, 0.16f, 0.26f, 0.95f)
            } else {
                shapeRenderer.setColor(0.07f, 0.09f, 0.14f, 0.90f)
            }
            shapeRenderer.rect(colX, startY, colW, colH)

            // Accent Top Border
            if (isSelected) {
                shapeRenderer.color = subClass.themeColor
            } else {
                shapeRenderer.setColor(0.25f, 0.32f, 0.45f, 0.8f)
            }
            shapeRenderer.rectLine(colX, startY + colH, colX + colW, startY + colH, if (isSelected) 4f else 2f)

            // Button Select Sub-Class Background (Zero Overlap with Subtitle)
            val selectBtnY = startY + colH - 95f
            if (isSelected) {
                shapeRenderer.color = subClass.themeColor
            } else {
                shapeRenderer.setColor(0.18f, 0.24f, 0.36f, 0.8f)
            }
            shapeRenderer.rect(colX + 20f, selectBtnY, colW - 40f, 38f)

            // Talent Nodes Cards
            val talents = TalentCatalog.getTalentsFor(subClass)
            val nodeStartY = selectBtnY - 95f
            for (tIndex in talents.indices) {
                val talent = talents[tIndex]
                val nodeY = nodeStartY - (tIndex * 98f)
                val nodeH = 88f
                val nodeW = colW - 40f
                val isUnlocked = talentManager.isTalentUnlocked(talent.id)
                val canUnlock = isSelected && talentManager.canUnlockTalent(talent)

                when {
                    isUnlocked -> if (isSelected) shapeRenderer.setColor(0.12f, 0.28f, 0.20f, 0.95f) else shapeRenderer.setColor(0.09f, 0.12f, 0.18f, 0.90f)
                    canUnlock -> shapeRenderer.setColor(0.16f, 0.22f, 0.36f, 0.90f)
                    else -> shapeRenderer.setColor(0.08f, 0.09f, 0.13f, 0.85f)
                }
                shapeRenderer.rect(colX + 20f, nodeY, nodeW, nodeH)

                // Left Accent Strip
                when {
                    isUnlocked -> if (isSelected) shapeRenderer.setColor(0.25f, 0.95f, 0.45f, 1f) else shapeRenderer.setColor(0.40f, 0.55f, 0.65f, 0.7f)
                    canUnlock -> shapeRenderer.color = Color.GOLD
                    else -> shapeRenderer.setColor(0.35f, 0.38f, 0.45f, 0.5f)
                }
                shapeRenderer.rect(colX + 20f, nodeY, 6f, nodeH)
            }
        }

        shapeRenderer.end()

        // Render Teks & Tipografi
        batch.begin()
        val regF = FontManager.regularFont
        val headF = FontManager.headerFont
        val smallF = FontManager.smallFont

        for (cIndex in subClasses.indices) {
            val subClass = subClasses[cIndex]
            val colX = if (cIndex == 0) 65f else 655f
            val isSelected = talentManager.selectedSubClass == subClass

            // Sub-Class Title & Icon
            headF.color = if (isSelected) subClass.themeColor else Color.WHITE
            headF.draw(batch, "${subClass.iconSymbol} ${subClass.displayName}", colX + 25f, startY + colH - 16f)

            smallF.setColor(0.75f, 0.85f, 0.95f, 0.85f)
            smallF.draw(batch, subClass.title, colX + 25f, startY + colH - 40f)

            // Select Button Text
            val selectBtnY = startY + colH - 95f
            val btnText = if (isSelected) "✓ SPECIALIZATION ACTIVE" else "ACTIVATE ${subClass.displayName.uppercase()}"
            regF.color = if (isSelected) Color.BLACK else Color.WHITE
            glyphLayout.setText(regF, btnText)
            regF.draw(batch, btnText, colX + (colW - glyphLayout.width) / 2f, selectBtnY + 25f)

            // Talent Nodes Texts
            val talents = TalentCatalog.getTalentsFor(subClass)
            val nodeStartY = selectBtnY - 95f
            for (tIndex in talents.indices) {
                val talent = talents[tIndex]
                val nodeY = nodeStartY - (tIndex * 98f)
                val isUnlocked = talentManager.isTalentUnlocked(talent.id)
                val canUnlock = isSelected && talentManager.canUnlockTalent(talent)

                // Talent Header
                regF.color = when {
                    isUnlocked -> if (isSelected) COLOR_UNLOCKED_HDR else Color(0.65f, 0.75f, 0.85f, 0.85f)
                    canUnlock -> Color.YELLOW
                    else -> COLOR_LOCKED_HDR
                }
                val tierBadge = "[T${talent.tier}]"
                regF.draw(batch, "$tierBadge ${talent.name}", colX + 35f, nodeY + 70f)

                // Cost & Status Badge
                val statusText = when {
                    isUnlocked -> if (isSelected) "✓ ACTIVE BONUS" else "✓ UNLOCKED (INACTIVE)"
                    canUnlock -> "UNLOCK (${talent.cost} PT)"
                    else -> "LOCKED (${talent.cost} PT)"
                }
                smallF.color = when {
                    isUnlocked -> if (isSelected) Color.GREEN else Color(0.60f, 0.70f, 0.80f, 0.80f)
                    canUnlock -> Color.GOLD
                    else -> Color.GRAY
                }
                glyphLayout.setText(smallF, statusText)
                smallF.draw(batch, statusText, colX + colW - 30f - glyphLayout.width, nodeY + 70f)

                // Description (Auto-Wrap Anti-Clipping)
                smallF.setColor(0.85f, 0.88f, 0.92f, 0.90f)
                val descMaxW = colW - 75f
                smallF.draw(batch, talent.description, colX + 35f, nodeY + 45f, descMaxW, com.badlogic.gdx.utils.Align.left, true)
            }
        }

        batch.end()
    }

    private fun renderHeaderAndFooter() {
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Top Banner Bar
        shapeRenderer.setColor(0.06f, 0.08f, 0.14f, 0.95f)
        shapeRenderer.rect(0f, 630f, 1280f, 90f)
        shapeRenderer.color = Color.GOLD
        shapeRenderer.rectLine(0f, 630f, 1280f, 630f, 2f)

        // Bottom Bar
        shapeRenderer.setColor(0.06f, 0.08f, 0.14f, 0.95f)
        shapeRenderer.rect(0f, 0f, 1280f, 80f)
        shapeRenderer.setColor(0.18f, 0.25f, 0.38f, 0.8f)
        shapeRenderer.rectLine(0f, 80f, 1280f, 80f, 2f)

        // Buttons: Return & Respec
        shapeRenderer.setColor(0.16f, 0.22f, 0.34f, 0.95f)
        shapeRenderer.rect(50f, 20f, 180f, 42f)
        shapeRenderer.setColor(0.35f, 0.18f, 0.22f, 0.95f)
        shapeRenderer.rect(1280f - 240f, 20f, 190f, 42f)

        shapeRenderer.end()

        batch.begin()
        val regF = FontManager.regularFont
        val headF = FontManager.headerFont
        val smallF = FontManager.smallFont

        // Header Title
        headF.color = Color.GOLD
        headF.draw(batch, "✦ TALENT TREE & SUB-CLASS ✦", 65f, 690f)

        smallF.color = Color.CYAN
        smallF.draw(batch, "ARCHETYPE: ${currentArchetype.displayName.uppercase()}", 65f, 655f)

        // Talent Points Badge
        val pointsText = "TALENT POINTS: ${talentManager.talentPoints} ✦"
        headF.color = Color.YELLOW
        glyphLayout.setText(headF, pointsText)
        headF.draw(batch, pointsText, 1280f - 65f - glyphLayout.width, 680f)

        // Feedback Notice
        if (feedbackText.isNotEmpty()) {
            val popY = 110f + (sin(animTime * 6f) * 4f)
            regF.color = Color.GOLD
            glyphLayout.setText(regF, feedbackText)
            regF.draw(batch, feedbackText, (1280f - glyphLayout.width) / 2f, popY)
        }

        // Footer Button Labels
        regF.color = Color.WHITE
        glyphLayout.setText(regF, "◀ BACK (ESC)")
        regF.draw(batch, "◀ BACK (ESC)", 50f + (180f - glyphLayout.width) / 2f, 47f)

        regF.setColor(1.0f, 0.6f, 0.6f, 1f)
        glyphLayout.setText(regF, "↺ RESET (R)")
        regF.draw(batch, "↺ RESET (R)", (1280f - 240f) + (190f - glyphLayout.width) / 2f, 47f)

        batch.end()
    }

    private fun exitAndSave() {
        talentManager.syncToSave(saveData)
        SaveManager.save(saveData)
        AudioManager.playDodge()
        if (game != null) {
            if (returnScreen != null) {
                game.setScreen(returnScreen)
            } else {
                game.setScreen(MainMenuScreen(game))
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

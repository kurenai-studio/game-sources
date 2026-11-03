package com.stickman.tower.quest

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.g2d.BitmapFont
import com.badlogic.gdx.graphics.g2d.GlyphLayout
import com.badlogic.gdx.graphics.g2d.SpriteBatch
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Rectangle
import kotlin.math.sin

/**
 * HUD Quest Compass Tracker Widget:
 * Menampilkan ringkasan misi aktif, objektif terdekat, dan progress bar di layar permainan PlayScreen
 * dengan desain estetika gelap bertema obsidian-emas dan penanganan zero-allocation per frame.
 */
class QuestCompassWidget {

    val bounds = Rectangle(920f, 580f, 340f, 85f)
    var isExpanded: Boolean = true

    private val glyphLayout = GlyphLayout()
    private var pulseTimer = 0f

    /**
     * Render pass shape latar belakang kompas misi.
     */
    fun renderShapes(shapeRenderer: ShapeRenderer, delta: Float) {
        val quest = QuestManager.getActiveMainQuest() ?: return
        pulseTimer += delta

        val x = bounds.x
        val y = bounds.y
        val w = bounds.width
        val h = bounds.height

        // 1. Kartu Latar Belakang Transparan
        shapeRenderer.setColor(0.06f, 0.08f, 0.12f, 0.78f)
        shapeRenderer.rect(x, y, w, h)

        // 2. Garis Aksen Kiri (Warna Emas untuk Main Quest)
        val isReady = QuestManager.isAllObjectivesComplete(quest)
        if (isReady) {
            val pulse = (sin(pulseTimer * 5f) + 1f) * 0.5f
            shapeRenderer.setColor(1f, 0.85f * pulse + 0.5f, 0.2f, 0.95f)
        } else {
            shapeRenderer.setColor(0.85f, 0.70f, 0.25f, 0.90f)
        }
        shapeRenderer.rect(x, y, 4f, h)

        // 3. Progress Bar Objektif Utama
        val firstIncomplete = quest.objectives.firstOrNull { !it.isComplete } ?: quest.objectives.firstOrNull()
        if (firstIncomplete != null) {
            val barX = x + 12f
            val barY = y + 10f
            val barW = w - 24f
            val barH = 5f

            // Background bar
            shapeRenderer.setColor(0.15f, 0.18f, 0.25f, 0.8f)
            shapeRenderer.rect(barX, barY, barW, barH)

            // Fill bar
            val current = QuestManager.getObjectiveCount(firstIncomplete.id)
            val fillPct = if (firstIncomplete.targetCount > 0) (current.toFloat() / firstIncomplete.targetCount).coerceIn(0f, 1f) else 1f
            if (isReady) {
                shapeRenderer.setColor(0.3f, 0.95f, 0.4f, 0.9f)
            } else {
                shapeRenderer.setColor(0.3f, 0.75f, 1f, 0.9f)
            }
            shapeRenderer.rect(barX, barY, barW * fillPct, barH)
        }
    }

    /**
     * Render pass tipografi teks kompas misi.
     */
    fun renderText(batch: SpriteBatch, headerFont: BitmapFont, bodyFont: BitmapFont, smallFont: BitmapFont) {
        val quest = QuestManager.getActiveMainQuest() ?: return

        val x = bounds.x
        val y = bounds.y
        val h = bounds.height

        val isReady = QuestManager.isAllObjectivesComplete(quest)

        // Judul Misi
        bodyFont.setColor(0.95f, 0.82f, 0.35f, 1f)
        bodyFont.draw(batch, "◈ ${quest.title}", x + 12f, y + h - 10f)

        // Status atau Deskripsi Objektif
        val firstIncomplete = quest.objectives.firstOrNull { !it.isComplete } ?: quest.objectives.firstOrNull()
        if (isReady) {
            smallFont.setColor(0.4f, 1f, 0.5f, 1f)
            smallFont.draw(batch, "✓ Objektif Terpenuhi! [Klaim di Quest Log]", x + 12f, y + h - 34f)
        } else if (firstIncomplete != null) {
            val current = QuestManager.getObjectiveCount(firstIncomplete.id)
            smallFont.setColor(0.85f, 0.9f, 0.95f, 1f)
            val text = "• ${firstIncomplete.description} [${current}/${firstIncomplete.targetCount}]"
            smallFont.draw(batch, text, x + 12f, y + h - 34f)
        }

        // Petunjuk Tombol Pintas
        smallFont.setColor(0.55f, 0.60f, 0.70f, 0.8f)
        smallFont.draw(batch, "Tekan [J] Buka Quest Log", x + 12f, y + 25f)
    }

    /**
     * Memeriksa apakah sentuhan layar berada dalam area kompas misi.
     */
    fun contains(screenX: Float, screenY: Float): Boolean {
        return bounds.contains(screenX, screenY)
    }
}

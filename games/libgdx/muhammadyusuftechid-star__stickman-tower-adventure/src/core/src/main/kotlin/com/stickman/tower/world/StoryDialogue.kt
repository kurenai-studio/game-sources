package com.stickman.tower.world

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.math.Rectangle
import kotlin.math.sin

/**
 * Tipe buff moril percabangan dialog (Morale Surge Buffs).
 */
enum class MoraleBuffType(val displayName: String, val effectDescription: String) {
    NONE("Tanpa Efek", "Tiada modifikasi tempur."),
    KINETIC_SURGE("Kinetic Surge", "+8% ATK Power di Lantai 7"),
    SPIRITUAL_WARD("Spiritual Ward", "+15% Max HP & +1 HP/s Regen di Lantai 7")
}

/**
 * Pilihan percabangan respon pemain dalam dialog interaktif.
 */
data class DialogueBranchOption(
    val choiceId: String,
    val promptText: String,
    val reactionSpeaker: String,
    val reactionTitle: String,
    val reactionText: String,
    val moraleBuff: MoraleBuffType = MoraleBuffType.NONE
)

/**
 * Satu baris dialog naratif cerita dengan dukungan percabangan.
 */
data class DialogueLine(
    val speaker: String,
    val title: String,
    val text: String,
    val speakerColor: Color = Color.GOLD,
    val branchOptions: List<DialogueBranchOption> = emptyList()
)

/**
 * Pemicu dialog naratif (NPC atau cutscene trigger) terintegrasi dengan mesin Typewriter
 * dan percabangan keputusan moril.
 */
class StoryDialogue(
    val triggerX: Float,
    val triggerY: Float,
    val triggerRadius: Float = 2.0f,
    val lines: List<DialogueLine>
) {
    var isTriggered: Boolean = false
    var currentLineIndex: Int = 0

    // State Typewriter (35 karakter/detik)
    var revealedCharCount: Int = 0
    private var charTimer: Float = 0f
    private var pauseTimer: Float = 0f
    val charsPerSecond: Float = 35f

    // State Percabangan
    var isWaitingForChoice: Boolean = false
    var activeBranchReaction: DialogueLine? = null
    var chosenMoraleBuff: MoraleBuffType = MoraleBuffType.NONE

    val currentLine: DialogueLine?
        get() = activeBranchReaction ?: if (currentLineIndex in lines.indices) lines[currentLineIndex] else null

    /**
     * Memperbarui pergerakan karakter typewriter.
     * Mengembalikan true jika sebuah karakter baru (selain spasi) berhasil diungkapkan
     * (untuk memicu sintesis suara voice chirp).
     */
    fun updateTypewriter(delta: Float): Boolean {
        val line = currentLine ?: return false
        val fullText = line.text

        if (revealedCharCount >= fullText.length) {
            if (line.branchOptions.isNotEmpty() && activeBranchReaction == null) {
                isWaitingForChoice = true
            }
            return false
        }

        if (pauseTimer > 0f) {
            pauseTimer -= delta
            return false
        }

        charTimer += delta
        val interval = 1f / charsPerSecond
        var revealedNewChar = false

        while (charTimer >= interval && revealedCharCount < fullText.length) {
            charTimer -= interval
            val charRevealed = fullText[revealedCharCount]
            revealedCharCount++

            // Jeda tanda baca
            when (charRevealed) {
                '.' -> pauseTimer = 0.35f
                ',', ';', ':' -> pauseTimer = 0.15f
                '!', '?' -> pauseTimer = 0.30f
            }

            if (!charRevealed.isWhitespace()) {
                revealedNewChar = true
            }

            if (pauseTimer > 0f) break
        }

        if (revealedCharCount >= fullText.length && line.branchOptions.isNotEmpty() && activeBranchReaction == null) {
            isWaitingForChoice = true
        }

        return revealedNewChar
    }

    /**
     * Mengambil potongan teks yang saat ini telah terungkap oleh efek typewriter.
     */
    fun getDisplayText(): String {
        val line = currentLine ?: return ""
        return line.text.take(revealedCharCount.coerceIn(0, line.text.length))
    }

    /**
     * Memeriksa apakah teks pada baris saat ini telah selesai terungkap seutuhnya.
     */
    fun isCurrentLineCompleted(): Boolean {
        val line = currentLine ?: return true
        return revealedCharCount >= line.text.length
    }

    /**
     * Mengungkapkan seluruh teks secara instan (Instant-Skip saat pemain tap/space).
     */
    fun instantReveal() {
        val line = currentLine ?: return
        revealedCharCount = line.text.length
        pauseTimer = 0f
        if (line.branchOptions.isNotEmpty() && activeBranchReaction == null) {
            isWaitingForChoice = true
        }
    }

    /**
     * Memilih salah satu opsi percabangan respon pemain.
     */
    fun selectBranch(optionIndex: Int, onMoraleBuffGranted: ((MoraleBuffType) -> Unit)? = null): Boolean {
        val line = currentLine ?: return false
        if (!isWaitingForChoice || optionIndex !in line.branchOptions.indices) return false

        val option = line.branchOptions[optionIndex]
        chosenMoraleBuff = option.moraleBuff
        if (option.moraleBuff != MoraleBuffType.NONE) {
            onMoraleBuffGranted?.invoke(option.moraleBuff)
        }

        // Tampilkan reaksi respon NPC
        activeBranchReaction = DialogueLine(
            speaker = option.reactionSpeaker,
            title = option.reactionTitle,
            text = option.reactionText,
            speakerColor = line.speakerColor
        )

        isWaitingForChoice = false
        revealedCharCount = 0
        charTimer = 0f
        pauseTimer = 0f
        return true
    }

    /**
     * Melanjutkan dialog ke baris berikutnya.
     * Mengembalikan true jika masih ada dialog tersisa, false jika seluruh adegan selesai.
     */
    fun advance(): Boolean {
        if (activeBranchReaction != null) {
            activeBranchReaction = null
            currentLineIndex++
            resetTypewriter()
            return currentLineIndex < lines.size
        }

        currentLineIndex++
        resetTypewriter()
        return currentLineIndex < lines.size
    }

    private fun resetTypewriter() {
        revealedCharCount = 0
        charTimer = 0f
        pauseTimer = 0f
        isWaitingForChoice = false
    }

    fun reset() {
        currentLineIndex = 0
        isTriggered = false
        activeBranchReaction = null
        chosenMoraleBuff = MoraleBuffType.NONE
        resetTypewriter()
    }
}

/**
 * Prasasti Batu Hitam (The Lore Tablets) yang dapat dibaca di sudut tersembunyi lantai menara.
 */
class LoreTablet(
    val x: Float,
    val y: Float,
    val tabletId: String,
    val title: String,
    val text: String,
    val width: Float = 1.0f,
    val height: Float = 1.4f
) {
    val bounds = Rectangle(x, y, width, height)
    var isRead: Boolean = false
    private var animTime: Float = 0f

    fun update(delta: Float) {
        animTime += delta
    }

    fun render(shapeRenderer: ShapeRenderer) {
        val centerX = x + width / 2f
        val pulse = (sin(animTime * 3.5f) + 1f) * 0.5f

        // 1. Alas Prasasti Batu Hitam Obsidian
        shapeRenderer.setColor(0.12f, 0.15f, 0.22f, 0.95f)
        shapeRenderer.rect(x - 0.1f, y, width + 0.2f, height)

        // 2. Bingkai Emas Prasasti
        shapeRenderer.setColor(0.85f, 0.70f, 0.25f, 0.85f)
        shapeRenderer.rectLine(x - 0.1f, y + height, x + width + 0.1f, y + height, 0.06f)

        // 3. Simbol Rune Bercahaya di Tengah Prasasti
        shapeRenderer.setColor(0.3f + 0.3f * pulse, 0.7f + 0.3f * pulse, 1f, 0.9f)
        shapeRenderer.circle(centerX, y + height * 0.65f, 0.22f, 12)

        shapeRenderer.color = Color.WHITE
        shapeRenderer.circle(centerX, y + height * 0.65f, 0.10f, 8)

        // Garis Hieroglif Kuno
        shapeRenderer.setColor(0.6f, 0.8f, 1f, 0.7f)
        shapeRenderer.rectLine(centerX - 0.25f, y + 0.45f, centerX + 0.25f, y + 0.45f, 0.04f)
        shapeRenderer.rectLine(centerX - 0.20f, y + 0.30f, centerX + 0.20f, y + 0.30f, 0.04f)
        shapeRenderer.rectLine(centerX - 0.28f, y + 0.15f, centerX + 0.28f, y + 0.15f, 0.04f)
    }
}

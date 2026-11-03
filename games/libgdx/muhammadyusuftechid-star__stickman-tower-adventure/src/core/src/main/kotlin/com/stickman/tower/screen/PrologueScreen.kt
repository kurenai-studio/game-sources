package com.stickman.tower.screen

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.Input.Keys
import com.badlogic.gdx.Screen
import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.GL20
import com.badlogic.gdx.graphics.OrthographicCamera
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
import com.stickman.tower.rpg.SaveManager
import com.stickman.tower.ui.FontManager
import kotlin.math.cos
import kotlin.math.sin

/**
 * PrologueScreen (The Ashen Threshold — Padang Abu Luar Menara):
 * Urutan narasi pembuka sinematik interaktif:
 * - Menjelaskan tragedi The Great Inking & fenomena kutukan The Dissolution.
 * - Memperkenalkan Kaelen The Bladeweaver dan lentera Aria.
 * - Menjelaskan alasan mutlak mengapa ksatria harus mendaki 50 lantai menara.
 * - Momen klimaks tebasan pedang pembuka gerbang menuju Lantai 1.
 */
class PrologueScreen(private val game: StickmanGame) : Screen {

    private data class PrologueDialogue(
        val speaker: String,
        val title: String,
        val text: String,
        val speakerColor: Color
    )

    private val camera = OrthographicCamera()
    private val viewport: Viewport = FitViewport(1280f, 720f, camera)
    private val shapeRenderer = ShapeRenderer()
    private val batch = SpriteBatch()
    private val glyphLayout = GlyphLayout()
    private val touchVec = Vector3()

    private var animTime = 0f
    private var dialogueIndex = 0
    private var charRevealProgress = 0f
    private var isTyping = true
    private var flashAlpha = 1.0f // Mulai dari kegelapan / fade-in
    private var isTransitioning = false
    private var transitionTimer = 0f

    // Partikel debu abu padang pasir
    private val dustCount = 45
    private val dustX = FloatArray(dustCount)
    private val dustY = FloatArray(dustCount)
    private val dustSpeed = FloatArray(dustCount)
    private val dustSize = FloatArray(dustCount)

    private val dialogues = listOf(
        PrologueDialogue(
            speaker = "Aria",
            title = "Sang Gema Warna Terakhir",
            text = "Buka matamu, Ksatria... Kumohon, jangan biarkan lilin jiwamu padam di tanah terkutuk ini.",
            speakerColor = Color(0.35f, 0.85f, 1f, 1f)
        ),
        PrologueDialogue(
            speaker = "Kaelen",
            title = "Kapten Pengawal Kerajaan",
            text = "Di mana... aku? Mengapa tanganku... hanya berupa garis hitam? Di mana warna dunia ini?!",
            speakerColor = Color(0.95f, 0.95f, 1f, 1f)
        ),
        PrologueDialogue(
            speaker = "Aria",
            title = "Sang Gema Warna Terakhir",
            text = "Dunia kita telah mati, Kaelen. Para Penulis Takdir menumpahkan Tinta Pemurnian. Daging kita dikikis, warna kita dirampas. Rekan-rekanmu yang berhenti melangkah telah larut menjadi tinta mati.",
            speakerColor = Color(0.35f, 0.85f, 1f, 1f)
        ),
        PrologueDialogue(
            speaker = "Kaelen",
            title = "Kapten Pengawal Kerajaan",
            text = "Larut menjadi tinta? Tidak. Aku merasakan detak di dadaku. Jiwaku menolak tunduk pada kehampaan ini!",
            speakerColor = Color(0.95f, 0.95f, 1f, 1f)
        ),
        PrologueDialogue(
            speaker = "Aria",
            title = "Sang Gema Warna Terakhir",
            text = "Itu adalah Anima Core—bara api kehendak bebas terakhir di semesta Aethelgard. Tapi kutukan pasak bumi sedang menarikmu ke dasar kepunahan. Lihat ke depanmu!",
            speakerColor = Color(0.35f, 0.85f, 1f, 1f)
        ),
        PrologueDialogue(
            speaker = "Aria",
            title = "Sang Gema Warna Terakhir",
            text = "Itulah The Celestial Chrono-Spire. Lima puluh strata realitas yang memenjarakan seluruh warna dunia kita. Di puncaknya, sang dewa memegang Pena Takdir. Daki menara itu dan tebas setiap keraguan!",
            speakerColor = Color(0.35f, 0.85f, 1f, 1f)
        ),
        PrologueDialogue(
            speaker = "Kaelen",
            title = "Kapten Pengawal Kerajaan",
            text = "Lima puluh lantai... Sekalipun menara ini menusuk surga dan meremukkan tulang bajaku, aku tidak akan berhenti melompat. Bimbing langkahku, Aria. Kita mulai pendakian ini!",
            speakerColor = Color(0.95f, 0.95f, 1f, 1f)
        )
    )

    override fun show() {
        Gdx.input?.setCatchKey(Keys.BACK, true)
        FontManager.init()
        animTime = 0f
        dialogueIndex = 0
        charRevealProgress = 0f
        isTyping = true
        flashAlpha = 1.0f
        isTransitioning = false
        transitionTimer = 0f

        // Inisialisasi partikel debu abu
        for (i in 0 until dustCount) {
            dustX[i] = MathUtils.random(0f, 1280f)
            dustY[i] = MathUtils.random(0f, 720f)
            dustSpeed[i] = MathUtils.random(15f, 45f)
            dustSize[i] = MathUtils.random(1.5f, 3.5f)
        }
        AudioManager.playDodge()
    }

    override fun render(delta: Float) {
        animTime += delta

        // Update debu abu
        for (i in 0 until dustCount) {
            dustX[i] -= dustSpeed[i] * delta * 1.5f
            dustY[i] += sin(animTime * 1.8f + i) * 8f * delta
            if (dustX[i] < -20f) dustX[i] = 1300f
            if (dustY[i] < 0f) dustY[i] = 720f
        }

        // Update typewriter
        if (isTyping && dialogueIndex < dialogues.size) {
            val fullText = dialogues[dialogueIndex].text
            charRevealProgress += delta * 36f
            if (charRevealProgress >= fullText.length) {
                charRevealProgress = fullText.length.toFloat()
                isTyping = false
            }
        }

        // Update transisi fajar putih
        if (isTransitioning) {
            transitionTimer += delta
            flashAlpha = MathUtils.clamp(transitionTimer / 1.2f, 0f, 1f)
            if (transitionTimer >= 1.35f) {
                val save = SaveManager.load()
                save.hasSeenPrologue = true
                SaveManager.save(save)
                game.setScreen(PlayScreen(game, 1, GameMode.STORY))
                return
            }
        } else if (flashAlpha > 0f) {
            flashAlpha = (flashAlpha - delta * 1.5f).coerceAtLeast(0f)
        }

        handleInput()

        ScreenUtils.clear(0.03f, 0.04f, 0.07f, 1f)
        camera.update()
        shapeRenderer.projectionMatrix = camera.combined
        batch.projectionMatrix = camera.combined

        Gdx.gl.glEnable(GL20.GL_BLEND)
        Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)

        // 1. Render Elemen Latar & Karakter Visual
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

        // Latar Belakang: Langit Padang Abu & Gradien Tanah
        shapeRenderer.setColor(0.05f, 0.06f, 0.10f, 1f)
        shapeRenderer.rect(0f, 180f, 1280f, 540f)

        // Permukaan Pasir Abu Hitam (The Ashen Ground)
        shapeRenderer.setColor(0.08f, 0.09f, 0.13f, 1f)
        shapeRenderer.rect(0f, 0f, 1280f, 180f)
        shapeRenderer.setColor(0.18f, 0.20f, 0.28f, 0.7f)
        shapeRenderer.rectLine(0f, 180f, 1280f, 180f, 2.5f)

        // Siluet Menara Monolit 50 Lantai di Latar Belakang Kiri/Tengah
        shapeRenderer.setColor(0.02f, 0.03f, 0.05f, 0.85f)
        shapeRenderer.triangle(540f, 720f, 440f, 180f, 640f, 180f)
        shapeRenderer.rect(480f, 180f, 120f, 400f)

        // Garis Runic Menara Berpendar
        val runePulse = (sin(animTime * 3.5f) + 1f) * 0.5f
        shapeRenderer.setColor(0.35f, 0.85f, 1f, 0.15f + 0.15f * runePulse)
        shapeRenderer.rectLine(540f, 220f, 540f, 580f, 2f)

        // Render Debu Abu
        shapeRenderer.setColor(0.45f, 0.48f, 0.58f, 0.35f)
        for (i in 0 until dustCount) {
            shapeRenderer.circle(dustX[i], dustY[i], dustSize[i], 6)
        }

        // Render Karakter: Kaelen The Bladeweaver di Kiri (x = 360f, y = 180f)
        renderKaelenSilhouette(shapeRenderer, 360f, 180f)

        // Render Karakter: Lentera Aria (Melayang di atas bahu Kaelen: x = 440f, y = 330f)
        renderAriaSprite(shapeRenderer, 440f, 330f + sin(animTime * 4f) * 12f)

        // Gerbang Besi Menara di Kanan (x = 980f, y = 180f)
        renderMonolithGate(shapeRenderer, 980f, 180f)

        // Kotak Dialog Sinematik (Bawah: y = 35f .. 190f)
        renderDialogueBox(shapeRenderer)

        // Tombol Skip di Kanan Atas
        val skipX = 1110f
        val skipY = 660f
        shapeRenderer.setColor(0.12f, 0.15f, 0.22f, 0.85f)
        shapeRenderer.rect(skipX, skipY, 130f, 38f)
        shapeRenderer.setColor(0.6f, 0.7f, 0.85f, 0.6f)
        shapeRenderer.rectLine(skipX, skipY + 38f, skipX + 130f, skipY + 38f, 2f)

        shapeRenderer.end()

        // 2. Render Teks & Tipografi
        batch.begin()
        val titleF = FontManager.titleFont
        val headF = FontManager.headerFont
        val regF = FontManager.regularFont
        val smallF = FontManager.smallFont

        // Header Lokasi Prologue
        smallF.color = Color.GOLD
        smallF.draw(batch, "BABAK PEMBUKA: THE ASHEN THRESHOLD (PADANG ABU)", 70f, 690f)

        // Teks Tombol Skip
        smallF.color = Color(0.8f, 0.85f, 0.95f, 1f)
        glyphLayout.setText(smallF, "LEWATI >>")
        smallF.draw(batch, "LEWATI >>", skipX + (130f - glyphLayout.width) / 2f, skipY + 24f)

        // Teks Dialog Saat Ini
        if (dialogueIndex < dialogues.size) {
            val d = dialogues[dialogueIndex]

            // Nama Pembicara
            headF.color = d.speakerColor
            headF.draw(batch, d.speaker.uppercase(), 95f, 168f)

            // Gelar Pembicara
            smallF.color = Color(0.7f, 0.75f, 0.85f, 1f)
            smallF.draw(batch, "• ${d.title}", 95f + GlyphLayout(headF, d.speaker.uppercase()).width + 16f, 166f)

            // Teks Dialog Typewriter
            regF.color = Color.WHITE
            val visibleLength = charRevealProgress.toInt().coerceIn(0, d.text.length)
            val currentSubstring = d.text.substring(0, visibleLength)
            regF.draw(batch, currentSubstring, 95f, 125f, 1090f, Align.left, true)

            // Prompt Tekan Lanjut
            smallF.setColor(0.35f, 0.85f, 1f, 0.7f + 0.3f * sin(animTime * 6f))
            val promptText = if (dialogueIndex == dialogues.size - 1) "[TAP / SPASI] TEBAS GERBANG & MULAI MENDAKI!" else "[TAP / SPASI] LANJUT..."
            glyphLayout.setText(smallF, promptText)
            smallF.draw(batch, promptText, 1185f - glyphLayout.width, 58f)
        }

        batch.end()

        // 3. Render Flash Layar / Fade Transisi
        if (flashAlpha > 0f) {
            shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)
            if (isTransitioning) {
                // Kilatan Putih Fajar Kemenangan Pembukaan
                shapeRenderer.setColor(1f, 1f, 1f, flashAlpha)
            } else {
                // Fade-in dari Hitam
                shapeRenderer.setColor(0f, 0f, 0f, flashAlpha)
            }
            shapeRenderer.rect(0f, 0f, 1280f, 720f)
            shapeRenderer.end()
        }
    }

    private fun renderKaelenSilhouette(sr: ShapeRenderer, x: Float, y: Float) {
        val breath = sin(animTime * 3.5f) * 2.5f
        val pulseDissolution = 0.85f + 0.15f * sin(animTime * 5f)

        // Siluet Berwarna Hitam Solid dengan Pendar Kutukan Transparan
        sr.setColor(0.08f, 0.08f, 0.12f, pulseDissolution)

        // Kepala
        sr.circle(x, y + 95f + breath, 18f, 18)
        // Mata Bercahaya Tajam Putih
        sr.setColor(1f, 1f, 1f, 1f)
        sr.circle(x + 6f, y + 98f + breath, 3.5f, 8)

        // Badan & Kaki
        sr.setColor(0.08f, 0.08f, 0.12f, pulseDissolution)
        sr.rectLine(x, y + 80f + breath, x, y + 35f, 6f)
        sr.rectLine(x, y + 35f, x - 14f, y, 5f)
        sr.rectLine(x, y + 35f, x + 16f, y, 5f)

        // Lengan & Pedang di Tangan
        sr.rectLine(x, y + 70f + breath, x + 24f, y + 45f + breath, 5f)
        // Pedang Runed Broadsword Berkilau Emas
        sr.setColor(1f, 0.85f, 0.25f, 0.9f)
        sr.rectLine(x + 22f, y + 42f + breath, x + 48f, y + 15f + breath, 3.5f)

        // Anima Core di Dada (Bara Api Jiwa Bercahaya Emas)
        val corePulse = (sin(animTime * 6f) + 1f) * 0.5f
        sr.setColor(1f, 0.75f, 0.2f, 0.4f + 0.5f * corePulse)
        sr.circle(x + 2f, y + 68f + breath, 8f, 14)
        sr.setColor(1f, 0.95f, 0.6f, 1f)
        sr.circle(x + 2f, y + 68f + breath, 3.5f, 8)
    }

    private fun renderAriaSprite(sr: ShapeRenderer, x: Float, y: Float) {
        val pulse = (sin(animTime * 5f) + 1f) * 0.5f

        // Lingkaran Aura Cyan Lembut
        sr.setColor(0.2f, 0.75f, 1f, 0.25f + 0.2f * pulse)
        sr.circle(x, y, 28f + pulse * 6f, 20)

        // Inti Cahaya Pendar
        sr.setColor(0.55f, 0.9f, 1f, 0.85f)
        sr.circle(x, y, 14f, 16)
        sr.setColor(1f, 1f, 1f, 1f)
        sr.circle(x, y, 7f, 12)

        // Ekor Partikel Berputar
        for (idx in 0 until 3) {
            val ang = animTime * 3f + idx * (Math.PI.toFloat() * 2f / 3f)
            val px = x + cos(ang.toDouble()).toFloat() * 18f
            val py = y + sin(ang.toDouble()).toFloat() * 8f
            sr.setColor(1f, 0.9f, 0.4f, 0.75f)
            sr.circle(px, py, 2.5f, 6)
        }
    }

    private fun renderMonolithGate(sr: ShapeRenderer, x: Float, y: Float) {
        // Gerbang Obsidian Raksasa
        sr.setColor(0.06f, 0.08f, 0.12f, 0.95f)
        sr.rect(x - 60f, y, 120f, 280f)
        sr.setColor(0.18f, 0.22f, 0.32f, 0.8f)
        sr.rectLine(x - 60f, y + 280f, x + 60f, y + 280f, 3f)
        sr.rectLine(x, y, x, y + 280f, 2.5f)

        // Rantai Runik Pengikat Gerbang
        sr.setColor(1f, 0.35f, 0.35f, 0.6f + 0.3f * sin(animTime * 4f))
        sr.rectLine(x - 55f, y + 160f, x + 55f, y + 120f, 4f)
        sr.rectLine(x - 55f, y + 120f, x + 55f, y + 160f, 4f)
    }

    private fun renderDialogueBox(sr: ShapeRenderer) {
        val boxX = 70f
        val boxY = 35f
        val boxW = 1140f
        val boxH = 155f

        // Panel Latar Belakang Semi-Transparan
        sr.setColor(0.06f, 0.08f, 0.14f, 0.92f)
        sr.rect(boxX, boxY, boxW, boxH)

        // Border Atas Bercahaya Cyan Emas
        sr.setColor(0.25f, 0.85f, 1f, 0.85f)
        sr.rectLine(boxX, boxY + boxH, boxX + boxW, boxY + boxH, 3f)

        // Garis Pembatas Nama Pembicara
        sr.setColor(0.2f, 0.3f, 0.45f, 0.5f)
        sr.rectLine(boxX + 25f, boxY + boxH - 34f, boxX + boxW - 25f, boxY + boxH - 34f, 1.5f)
    }

    private fun handleInput() {
        if (isTransitioning) return

        if (Gdx.input.isKeyJustPressed(Keys.ESCAPE)) {
            triggerTransition()
            return
        }

        val advanceTriggered = Gdx.input.isKeyJustPressed(Keys.SPACE) ||
            Gdx.input.isKeyJustPressed(Keys.ENTER) ||
            Gdx.input.isKeyJustPressed(Keys.E)

        if (advanceTriggered) {
            advanceDialogue()
            return
        }

        if (Gdx.input.justTouched()) {
            touchVec.set(Gdx.input.x.toFloat(), Gdx.input.y.toFloat(), 0f)
            viewport.unproject(touchVec)

            // Klik Tombol Skip di Kanan Atas
            if (touchVec.x in 1100f..1250f && touchVec.y in 650f..710f) {
                AudioManager.playDodge()
                triggerTransition()
                return
            }

            // Klik Layar Dimana Saja untuk Memajukan Dialog
            advanceDialogue()
        }
    }

    private fun advanceDialogue() {
        if (dialogueIndex >= dialogues.size) return

        val fullText = dialogues[dialogueIndex].text
        // Jika teks masih dalam proses ketikan, selesaikan ketikan seketika
        if (isTyping) {
            charRevealProgress = fullText.length.toFloat()
            isTyping = false
            AudioManager.playVoiceChirp(dialogues[dialogueIndex].speaker)
            return
        }

        // Pindah ke baris dialog berikutnya
        dialogueIndex++
        charRevealProgress = 0f
        isTyping = true

        if (dialogueIndex < dialogues.size) {
            AudioManager.playVoiceChirp(dialogues[dialogueIndex].speaker)
        } else {
            // Momen Tebasan Pedang Pembuka Gerbang Menara
            triggerTransition()
        }
    }

    private fun triggerTransition() {
        if (isTransitioning) return
        isTransitioning = true
        transitionTimer = 0f
        AudioManager.playParry()
        AudioManager.playLevelUp()
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

package com.stickman.tower.narrative

import com.stickman.tower.audio.AudioManager
import com.stickman.tower.world.DialogueBranchOption
import com.stickman.tower.world.DialogueLine
import com.stickman.tower.world.MoraleBuffType
import com.stickman.tower.world.StoryDialogue
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Unit Test Komprehensif untuk Engine Dialog Dinamis, Typewriter,
 * Percabangan Respon Pemain, Buff Moril & Bisikan Menara (Fase 18).
 */
class DialogueEngineTest {

    @Test
    fun testTypewriterCharacterRevealAndPunctuationPause() {
        val dialogue = StoryDialogue(
            triggerX = 2.0f,
            triggerY = 1.0f,
            lines = listOf(
                DialogueLine(
                    speaker = "Aria",
                    title = "Peri Cahaya",
                    text = "Aethelgard! Bangunlah, wahai ksatria."
                )
            )
        )

        assertEquals(0, dialogue.revealedCharCount)
        assertEquals("", dialogue.getDisplayText())
        assertFalse(dialogue.isCurrentLineCompleted())

        // Update typewriter 1 frame (delta kecil 0.05s)
        val revealed = dialogue.updateTypewriter(0.05f)
        assertTrue(revealed, "Karakter baru harus terungkap pada delta 0.05s")
        assertTrue(dialogue.revealedCharCount > 0)
        assertTrue(dialogue.getDisplayText().isNotEmpty())

        // Instant Skip / Instant Reveal
        dialogue.instantReveal()
        assertTrue(dialogue.isCurrentLineCompleted())
        assertEquals("Aethelgard! Bangunlah, wahai ksatria.", dialogue.getDisplayText())
    }

    @Test
    fun testInteractiveBranchingAndMoraleBuffs() {
        val testScene = StoryDialogue(
            triggerX = 10f,
            triggerY = 2f,
            lines = listOf(
                DialogueLine(
                    speaker = "Vulcanus",
                    title = "Sang Penempa",
                    text = "Pilihlah jalanmu!",
                    branchOptions = listOf(
                        DialogueBranchOption(
                            choiceId = "CHOICE_VENGEANCE",
                            promptText = "[1] Pembalasan",
                            reactionSpeaker = "Vulcanus",
                            reactionTitle = "Sang Penempa",
                            reactionText = "Kobaran amarahmu luar biasa!",
                            moraleBuff = MoraleBuffType.KINETIC_SURGE
                        ),
                        DialogueBranchOption(
                            choiceId = "CHOICE_RESTORATION",
                            promptText = "[2] Restorasi",
                            reactionSpeaker = "Vulcanus",
                            reactionTitle = "Sang Penempa",
                            reactionText = "Hati yang damai menuntun langkahmu.",
                            moraleBuff = MoraleBuffType.SPIRITUAL_WARD
                        )
                    )
                ),
                DialogueLine(
                    speaker = "Vulcanus",
                    title = "Sang Penempa",
                    text = "Kini pergilah ke lantai berikutnya."
                )
            )
        )

        // Buka seluruh teks baris 1
        testScene.instantReveal()
        assertTrue(testScene.isWaitingForChoice, "Harus menunggu pilihan setelah baris bercabang terungkap")

        var grantedBuff: MoraleBuffType = MoraleBuffType.NONE
        val success = testScene.selectBranch(0) { buff -> grantedBuff = buff }

        assertTrue(success)
        assertFalse(testScene.isWaitingForChoice)
        assertEquals(MoraleBuffType.KINETIC_SURGE, testScene.chosenMoraleBuff)
        assertEquals(MoraleBuffType.KINETIC_SURGE, grantedBuff)
        assertEquals("Kobaran amarahmu luar biasa!", testScene.currentLine?.text)

        // Selesaikan reaksi lalu advance ke baris dialog berikutnya
        testScene.instantReveal()
        val hasNext = testScene.advance()
        assertTrue(hasNext)
        assertEquals("Kini pergilah ke lantai berikutnya.", testScene.currentLine?.text)

        // Reset
        testScene.reset()
        assertEquals(0, testScene.currentLineIndex)
        assertFalse(testScene.isWaitingForChoice)
        assertEquals(MoraleBuffType.NONE, testScene.chosenMoraleBuff)
        assertNull(testScene.activeBranchReaction)
    }

    @Test
    fun testDialogueRegistryScenesIntegrity() {
        val scene1 = DialogueRegistry.getSceneForFloor(1)
        val scene5 = DialogueRegistry.getSceneForFloor(5)
        val scene6 = DialogueRegistry.getSceneForFloor(6)
        val scene10 = DialogueRegistry.getSceneForFloor(10)
        val scene50 = DialogueRegistry.getSceneForFloor(50)
        val sceneOther = DialogueRegistry.getSceneForFloor(2)

        assertNotNull(scene1)
        assertNotNull(scene5)
        assertNotNull(scene6)
        assertNotNull(scene10)
        assertNotNull(scene50)
        assertNull(sceneOther)

        // Scene 1: Prolog Aria & Kaelen
        assertEquals("Aria", scene1.lines[0].speaker)
        assertEquals("Kaelen", scene1.lines[1].speaker)

        // Scene 4: Vulcanus dengan 2 opsi percabangan
        val vulcanusQuestion = scene6.lines[1]
        assertEquals(2, vulcanusQuestion.branchOptions.size)
        assertEquals(MoraleBuffType.KINETIC_SURGE, vulcanusQuestion.branchOptions[0].moraleBuff)
        assertEquals(MoraleBuffType.SPIRITUAL_WARD, vulcanusQuestion.branchOptions[1].moraleBuff)

        // Scene 5: Lady Vespera di Lantai 10
        assertEquals("Lady Vespera", scene10.lines[0].speaker)
        // Scene 50: The Grand Calligrapher di Lantai 50
        assertEquals("The Grand Calligrapher", scene50.lines[0].speaker)
    }

    @Test
    fun testTowerWhisperManagerIdleTracking() {
        val whisperMgr = TowerWhisperManager()
        assertFalse(whisperMgr.isWhisperActive)
        assertEquals(0f, whisperMgr.idleTimer)

        // Update saat pemain aktif bergerak (idleTimer tetap 0)
        whisperMgr.update(delta = 1.0f, isPlayerIdle = false, actNumber = 1)
        assertEquals(0f, whisperMgr.idleTimer)
        assertFalse(whisperMgr.isWhisperActive)

        // Pemain diam (idle) selama 3.0 detik (kurang dari batas 4.0s)
        whisperMgr.update(delta = 3.0f, isPlayerIdle = true, actNumber = 1)
        assertEquals(3.0f, whisperMgr.idleTimer)
        assertFalse(whisperMgr.isWhisperActive)

        // Pemain diam 1.2 detik lagi (total 4.2s >= IDLE_THRESHOLD 4.0s)
        whisperMgr.update(delta = 1.2f, isPlayerIdle = true, actNumber = 1)
        assertTrue(whisperMgr.isWhisperActive, "Bisikan menara harus aktif setelah 4.0s idle")
        assertNotNull(whisperMgr.currentWhisper)
        assertTrue(whisperMgr.currentWhisper!!.isNotEmpty())

        // Simulasikan pemain bergerak kembali saat bisikan sedang aktif
        whisperMgr.update(delta = 0.5f, isPlayerIdle = false, actNumber = 1)
        // Alpha mulai memudar
        assertTrue(whisperMgr.whisperAlpha < 1.0f)

        // Reset
        whisperMgr.reset()
        assertFalse(whisperMgr.isWhisperActive)
        assertNull(whisperMgr.currentWhisper)
        assertEquals(0f, whisperMgr.idleTimer)
    }

    @Test
    fun testVoiceChirpSpeakerHandlingDoesNotCrash() {
        val speakers = listOf(
            "Aria",
            "Vulcanus",
            "Jenderal Oakhaven",
            "The Amethyst Matron",
            "The Grand Calligrapher",
            "Kaelen",
            "Unknown Shadow"
        )

        for (spk in speakers) {
            // Memastikan pemanggilan sintesis audio aman dan tidak melemparkan exception
            AudioManager.playVoiceChirp(spk)
        }
    }
}

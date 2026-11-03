package com.stickman.tower.audio

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.audio.Sound
import com.badlogic.gdx.math.MathUtils
import java.io.ByteArrayOutputStream
import java.io.DataOutputStream
import kotlin.math.sin

/**
 * Engine Musik Latar Prosedural Dinamis (Procedural Dynamic Ambient BGM Engine).
 * Menghasilkan trek atmosferik berulang secara mulus (seamless looping) per babak cerita (Act I s/d IV & Endless)
 * langsung dari sintesis PCM tanpa membutuhkan unduhan file MP3/OGG besar.
 */
object ProceduralMusicEngine {

    private var isInitialized = false
    private var currentAct: Int = -1
    private var activeSound: Sound? = null
    private var activeSoundId: Long = -1L

    private var soundAct1: Sound? = null
    private var soundAct2: Sound? = null
    private var soundAct3: Sound? = null
    private var soundAct4: Sound? = null
    private var soundEndless: Sound? = null
    private var soundBoss: Sound? = null

    var bgmVolume: Float = 0.65f
        set(value) {
            field = value.coerceIn(0f, 1f)
            updateActiveVolume()
        }

    var isMuted: Boolean = false
        set(value) {
            field = value
            updateActiveVolume()
        }

    fun init() {
        if (isInitialized) return
        isInitialized = true

        try {
            val cacheDir = Gdx.files.local(".audio_cache")
            if (!cacheDir.exists()) cacheDir.mkdirs()

            soundAct1 = createTrack(cacheDir, "bgm_act1_v1.wav") { genAct1Drone(it) }
            soundAct2 = createTrack(cacheDir, "bgm_act2_v1.wav") { genAct2Drone(it) }
            soundAct3 = createTrack(cacheDir, "bgm_act3_v1.wav") { genAct3Drone(it) }
            soundAct4 = createTrack(cacheDir, "bgm_act4_v1.wav") { genAct4Drone(it) }
            soundEndless = createTrack(cacheDir, "bgm_endless_v1.wav") { genEndlessDrone(it) }
            soundBoss = createTrack(cacheDir, "bgm_boss_v1.wav") { genBossDrone(it) }
        } catch (e: Exception) {
            Gdx.app?.error("ProceduralMusicEngine", "Gagal inisialisasi musik latar prosedural: ${e.message}")
        }
    }

    private fun createTrack(cacheDir: com.badlogic.gdx.files.FileHandle, name: String, generator: (Int) -> ShortArray): Sound? {
        val sampleRate = 22050
        val file = cacheDir.child(name)
        if (!file.exists()) {
            val samples = generator(sampleRate)
            val wavBytes = encodeWav(samples, sampleRate)
            file.writeBytes(wavBytes, false)
        }
        return try {
            Gdx.audio?.newSound(file)
        } catch (e: Exception) {
            null
        }
    }

    private fun encodeWav(samples: ShortArray, sampleRate: Int): ByteArray {
        val baos = ByteArrayOutputStream()
        val dos = DataOutputStream(baos)
        val totalDataLen = samples.size * 2
        val totalAudioLen = totalDataLen + 36

        dos.writeBytes("RIFF")
        dos.writeInt(Integer.reverseBytes(totalAudioLen))
        dos.writeBytes("WAVE")

        dos.writeBytes("fmt ")
        dos.writeInt(Integer.reverseBytes(16))
        dos.writeShort(java.lang.Short.reverseBytes(1.toShort()).toInt()) // PCM
        dos.writeShort(java.lang.Short.reverseBytes(1.toShort()).toInt()) // Mono
        dos.writeInt(Integer.reverseBytes(sampleRate))
        dos.writeInt(Integer.reverseBytes(sampleRate * 2))
        dos.writeShort(java.lang.Short.reverseBytes(2.toShort()).toInt())
        dos.writeShort(java.lang.Short.reverseBytes(16.toShort()).toInt())

        dos.writeBytes("data")
        dos.writeInt(Integer.reverseBytes(totalDataLen))
        for (s in samples) {
            dos.writeShort(java.lang.Short.reverseBytes(s).toInt())
        }
        return baos.toByteArray()
    }

    // =========================================================================
    // SINTESIS SINYAL AUDIO AMBIEN (SEAMLESS LOOP PCM)
    // =========================================================================

    /**
     * Act I: Bastion of the Initiate (Lantai 1-3).
     * D-minor ambient drone: 73.4 Hz (D2) + 110.0 Hz (A2) + sub-bass pulse lembut.
     */
    internal fun genAct1Drone(sampleRate: Int): ShortArray {
        val duration = 4.0f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)

        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val lfo = 0.75f + 0.25f * sin(2.0 * Math.PI * 0.25 * t).toFloat()
            val wave = (sin(2.0 * Math.PI * 73.4 * t) * 0.50 +
                    sin(2.0 * Math.PI * 110.0 * t) * 0.35 +
                    sin(2.0 * Math.PI * 146.8 * t) * 0.15) * lfo
            data[i] = (wave * 16000).toInt().coerceIn(-32767, 32767).toShort()
        }
        return data
    }

    /**
     * Act II: Secrets of the Ink & Iron Foundry (Lantai 4-6).
     * F-sharp resonance ambient pad: 92.5 Hz (F#2) + 185.0 Hz (F#3) + 277.2 Hz (C#4).
     */
    internal fun genAct2Drone(sampleRate: Int): ShortArray {
        val duration = 4.0f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)

        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val lfo = 0.70f + 0.30f * sin(2.0 * Math.PI * 0.50 * t).toFloat()
            val wave = (sin(2.0 * Math.PI * 92.5 * t) * 0.45 +
                    sin(2.0 * Math.PI * 185.0 * t) * 0.35 +
                    sin(2.0 * Math.PI * 277.2 * t) * 0.20) * lfo
            data[i] = (wave * 15500).toInt().coerceIn(-32767, 32767).toShort()
        }
        return data
    }

    /**
     * Act III: The Astral Climb (Lantai 7-9).
     * A-minor ethereal chime pad: 110.0 Hz (A2) + 220.0 Hz (A3) + 440.0 Hz (A4 shimmer).
     */
    internal fun genAct3Drone(sampleRate: Int): ShortArray {
        val duration = 4.0f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)

        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val lfo1 = 0.65f + 0.35f * sin(2.0 * Math.PI * 0.33 * t).toFloat()
            val shimmer = 0.85f + 0.15f * sin(2.0 * Math.PI * 2.0 * t).toFloat()
            val wave = (sin(2.0 * Math.PI * 110.0 * t) * 0.40 +
                    sin(2.0 * Math.PI * 220.0 * t) * 0.35 +
                    sin(2.0 * Math.PI * 440.0 * t) * 0.25 * shimmer) * lfo1
            data[i] = (wave * 15000).toInt().coerceIn(-32767, 32767).toShort()
        }
        return data
    }

    /**
     * Act IV: The Primordial Canvas (Lantai 10).
     * E-minor cathedral resonance: 82.4 Hz (E2) + 164.8 Hz (E3) + 246.9 Hz (B3) + 329.6 Hz (E4).
     */
    internal fun genAct4Drone(sampleRate: Int): ShortArray {
        val duration = 4.0f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)

        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val lfo = 0.70f + 0.30f * sin(2.0 * Math.PI * 0.20 * t).toFloat()
            val wave = (sin(2.0 * Math.PI * 82.4 * t) * 0.35 +
                    sin(2.0 * Math.PI * 164.8 * t) * 0.30 +
                    sin(2.0 * Math.PI * 246.9 * t) * 0.20 +
                    sin(2.0 * Math.PI * 329.6 * t) * 0.15) * lfo
            data[i] = (wave * 17000).toInt().coerceIn(-32767, 32767).toShort()
        }
        return data
    }

    /**
     * Endless Spire: The Endless Paradox (Lantai 11 ke atas).
     * Multi-harmonic polyphonic drone: 98.0 Hz (G2) + 146.8 Hz (D3) + 196.0 Hz (G3).
     */
    internal fun genEndlessDrone(sampleRate: Int): ShortArray {
        val duration = 4.0f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)

        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val lfo = 0.75f + 0.25f * sin(2.0 * Math.PI * 0.40 * t).toFloat()
            val wave = (sin(2.0 * Math.PI * 98.0 * t) * 0.45 +
                    sin(2.0 * Math.PI * 146.8 * t) * 0.35 +
                    sin(2.0 * Math.PI * 196.0 * t) * 0.20) * lfo
            data[i] = (wave * 15500).toInt().coerceIn(-32767, 32767).toShort()
        }
        return data
    }

    /**
     * Pertarungan Bos Menara (Boss Battle Tension Drone).
     * Pulsa tensi ritmis 65.4 Hz (C2) + 130.8 Hz (C3) dengan denyut detak drum takdir.
     */
    internal fun genBossDrone(sampleRate: Int): ShortArray {
        val duration = 4.0f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)

        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val beat = (t % 0.5f) / 0.5f // Detak 120 BPM
            val pulse = (1f - beat).let { it * it }
            val wave = (sin(2.0 * Math.PI * 65.4 * t) * 0.50 +
                    sin(2.0 * Math.PI * 130.8 * t) * 0.30 +
                    sin(2.0 * Math.PI * 196.0 * t) * 0.20) * (0.6f + pulse * 0.4f)
            data[i] = (wave * 17500).toInt().coerceIn(-32767, 32767).toShort()
        }
        return data
    }

    // =========================================================================
    // KONTROL PLAYBACK & TRANSISI TREK
    // =========================================================================

    /**
     * Memainkan trek BGM yang sesuai dengan lantai permainan saat ini.
     */
    fun playFloorBgm(floorNumber: Int, isBossFloor: Boolean = false) {
        init()
        val targetAct = when {
            isBossFloor -> 99 // Boss special track
            floorNumber in 1..3 -> 1
            floorNumber in 4..6 -> 2
            floorNumber in 7..9 -> 3
            floorNumber == 10 -> 4
            else -> 5 // Endless Spire
        }

        if (targetAct == currentAct && activeSoundId != -1L) {
            // Sudah memainkan trek yang sama
            return
        }

        // Hentikan trek lama
        stop()

        currentAct = targetAct
        val soundToPlay = when (targetAct) {
            1 -> soundAct1
            2 -> soundAct2
            3 -> soundAct3
            4 -> soundAct4
            99 -> soundBoss
            else -> soundEndless
        }

        activeSound = soundToPlay
        if (soundToPlay != null) {
            val effectiveVol = if (isMuted) 0f else bgmVolume
            activeSoundId = soundToPlay.loop(effectiveVol)
        }
    }

    private fun updateActiveVolume() {
        val sound = activeSound
        val id = activeSoundId
        if (sound != null && id != -1L) {
            val effectiveVol = if (isMuted) 0f else bgmVolume
            sound.setVolume(id, effectiveVol)
        }
    }

    fun pause() {
        val sound = activeSound
        val id = activeSoundId
        if (sound != null && id != -1L) {
            sound.pause(id)
        }
    }

    fun resume() {
        val sound = activeSound
        val id = activeSoundId
        if (sound != null && id != -1L) {
            sound.resume(id)
            updateActiveVolume()
        }
    }

    fun stop() {
        val sound = activeSound
        val id = activeSoundId
        if (sound != null && id != -1L) {
            sound.stop(id)
        }
        activeSound = null
        activeSoundId = -1L
        currentAct = -1
    }

    fun dispose() {
        stop()
        soundAct1?.dispose()
        soundAct2?.dispose()
        soundAct3?.dispose()
        soundAct4?.dispose()
        soundEndless?.dispose()
        soundBoss?.dispose()

        soundAct1 = null
        soundAct2 = null
        soundAct3 = null
        soundAct4 = null
        soundEndless = null
        soundBoss = null
        isInitialized = false
    }
}

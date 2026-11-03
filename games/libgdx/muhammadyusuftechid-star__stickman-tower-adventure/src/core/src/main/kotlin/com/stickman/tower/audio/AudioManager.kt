package com.stickman.tower.audio

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.audio.Sound
import com.badlogic.gdx.math.MathUtils
import java.io.ByteArrayOutputStream
import java.io.DataOutputStream
import kotlin.math.sin

/**
 * Manajer Audio Prosedural:
 * Menghasilkan SFX retro-modern (Jump, Slash, Hit, Dodge, Death, Level Up, Chest)
 * dan BGM ambient aksi secara instan dari sinyal audio PCM sintetis,
 * tanpa membutuhkan unduhan file aset eksternal.
 */
object AudioManager {
    private var isInitialized = false

    private var soundJump: Sound? = null
    private var soundSlashLight: Sound? = null
    private var soundSlashHeavy: Sound? = null
    private var soundHit: Sound? = null
    private var soundDodge: Sound? = null
    private var soundDeath: Sound? = null
    private var soundLevelUp: Sound? = null
    private var soundChest: Sound? = null
    private var soundParry: Sound? = null
    private var soundBossRoar: Sound? = null

    // Voice Chirp Prosedural (Fase 18 Screenplay & Voice Engine)
    private var soundChirpAria: Sound? = null
    private var soundChirpVulcanus: Sound? = null
    private var soundChirpCalligrapher: Sound? = null
    private var soundChirpKaelen: Sound? = null
    private var soundChirpOakhaven: Sound? = null
    private var soundChirpMatron: Sound? = null

    private const val PREF_AUDIO = "stickman_audio_settings"
    private const val KEY_VOLUME = "sfx_volume"
    private const val KEY_BGM_VOLUME = "bgm_volume"
    private const val KEY_MUTED = "is_muted"

    var isMuted: Boolean = false
        set(value) {
            field = value
            ProceduralMusicEngine.isMuted = value
            persistSettings()
        }
    var sfxVolume: Float = 0.85f
        set(value) {
            field = value.coerceIn(0f, 1f)
            persistSettings()
        }

    var bgmVolume: Float
        get() = ProceduralMusicEngine.bgmVolume
        set(value) {
            ProceduralMusicEngine.bgmVolume = value.coerceIn(0f, 1f)
            persistSettings()
        }

    private fun persistSettings() {
        try {
            val prefs = Gdx.app?.getPreferences(PREF_AUDIO)
            if (prefs != null) {
                prefs.putFloat(KEY_VOLUME, sfxVolume)
                prefs.putFloat(KEY_BGM_VOLUME, bgmVolume)
                prefs.putBoolean(KEY_MUTED, isMuted)
                prefs.flush()
            }
        } catch (_: Exception) {}
    }

    fun init() {
        if (isInitialized) return
        isInitialized = true

        try {
            val prefs = Gdx.app?.getPreferences(PREF_AUDIO)
            if (prefs != null) {
                if (prefs.contains(KEY_VOLUME)) sfxVolume = prefs.getFloat(KEY_VOLUME, 0.85f).coerceIn(0f, 1f)
                if (prefs.contains(KEY_BGM_VOLUME)) bgmVolume = prefs.getFloat(KEY_BGM_VOLUME, 0.65f).coerceIn(0f, 1f)
                if (prefs.contains(KEY_MUTED)) isMuted = prefs.getBoolean(KEY_MUTED, false)
            }
            ProceduralMusicEngine.init()
        } catch (_: Exception) {}

        try {
            val cacheDir = Gdx.files.local(".sfx_cache")
            if (!cacheDir.exists()) cacheDir.mkdirs()

            soundJump = createSound(cacheDir, "jump.wav") { genJump(it) }
            soundSlashLight = createSound(cacheDir, "slash_light.wav") { genSlash(it, 0.10f, 600f, 150f) }
            soundSlashHeavy = createSound(cacheDir, "slash_heavy.wav") { genSlash(it, 0.20f, 300f, 60f) }
            soundHit = createSound(cacheDir, "hit.wav") { genHit(it) }
            soundDodge = createSound(cacheDir, "dodge.wav") { genDodge(it) }
            soundDeath = createSound(cacheDir, "death.wav") { genDeath(it) }
            soundLevelUp = createSound(cacheDir, "levelup.wav") { genLevelUp(it) }
            soundChest = createSound(cacheDir, "chest.wav") { genChest(it) }
            soundParry = createSound(cacheDir, "parry.wav") { genParry(it) }
            soundBossRoar = createSound(cacheDir, "boss_roar.wav") { genBossRoar(it) }

            // Voice Chirps untuk Karakter Sinematik (Fase 18)
            soundChirpAria = createSound(cacheDir, "chirp_aria.wav") { genChirpAria(it) }
            soundChirpVulcanus = createSound(cacheDir, "chirp_vulcanus.wav") { genChirpVulcanus(it) }
            soundChirpCalligrapher = createSound(cacheDir, "chirp_calligrapher.wav") { genChirpCalligrapher(it) }
            soundChirpKaelen = createSound(cacheDir, "chirp_kaelen.wav") { genChirpKaelen(it) }
            soundChirpOakhaven = createSound(cacheDir, "chirp_oakhaven.wav") { genChirpOakhaven(it) }
            soundChirpMatron = createSound(cacheDir, "chirp_matron.wav") { genChirpMatron(it) }

            Gdx.app.log("AudioManager", "Procedural SFX synthesis completed successfully.")
        } catch (e: Exception) {
            Gdx.app.error("AudioManager", "Failed to initialize procedural audio: ${e.message}")
        }
    }

    private fun createSound(cacheDir: com.badlogic.gdx.files.FileHandle, name: String, generator: (Int) -> ShortArray): Sound? {
        val sampleRate = 22050
        val file = cacheDir.child(name)
        if (!file.exists()) {
            val samples = generator(sampleRate)
            val wavBytes = encodeWav(samples, sampleRate)
            file.writeBytes(wavBytes, false)
        }
        return try {
            Gdx.audio.newSound(file)
        } catch (e: Exception) {
            null
        }
    }

    private fun encodeWav(samples: ShortArray, sampleRate: Int): ByteArray {
        val baos = ByteArrayOutputStream()
        val dos = DataOutputStream(baos)

        val totalDataLen = samples.size * 2
        val totalAudioLen = totalDataLen + 36

        // RIFF header
        dos.writeBytes("RIFF")
        dos.writeInt(Integer.reverseBytes(totalAudioLen))
        dos.writeBytes("WAVE")

        // fmt chunk
        dos.writeBytes("fmt ")
        dos.writeInt(Integer.reverseBytes(16)) // Subchunk1Size
        dos.writeShort(java.lang.Short.reverseBytes(1.toShort()).toInt()) // PCM = 1
        dos.writeShort(java.lang.Short.reverseBytes(1.toShort()).toInt()) // Mono = 1
        dos.writeInt(Integer.reverseBytes(sampleRate))
        dos.writeInt(Integer.reverseBytes(sampleRate * 2)) // ByteRate
        dos.writeShort(java.lang.Short.reverseBytes(2.toShort()).toInt()) // BlockAlign
        dos.writeShort(java.lang.Short.reverseBytes(16.toShort()).toInt()) // BitsPerSample

        // data chunk
        dos.writeBytes("data")
        dos.writeInt(Integer.reverseBytes(totalDataLen))

        // Audio PCM data
        for (s in samples) {
            dos.writeShort(java.lang.Short.reverseBytes(s).toInt())
        }

        dos.flush()
        return baos.toByteArray()
    }

    // --- Generator Gelombang Suara (DSP Prosedural) ---

    private fun genJump(sampleRate: Int): ShortArray {
        val duration = 0.14f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val progress = t / duration
            val freq = MathUtils.lerp(180f, 520f, progress)
            val env = 1f - progress
            val sample = sin(2.0 * Math.PI * freq * t) * env
            data[i] = (sample * 24000).toInt().toShort()
        }
        return data
    }

    private fun genSlash(sampleRate: Int, duration: Float, startFreq: Float, endFreq: Float): ShortArray {
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val progress = t / duration
            val freq = MathUtils.lerp(startFreq, endFreq, progress)
            val noise = MathUtils.random(-0.35f, 0.35f)
            val tone = sin(2.0 * Math.PI * freq * t) * 0.65f
            val env = (1f - progress) * (1f - progress)
            val sample = (tone + noise) * env
            data[i] = (sample * 22000).toInt().toShort()
        }
        return data
    }

    private fun genHit(sampleRate: Int): ShortArray {
        val duration = 0.11f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val progress = t / duration
            val freq = MathUtils.lerp(140f, 40f, progress)
            val noise = MathUtils.random(-0.4f, 0.4f) * (1f - progress)
            val env = (1f - progress) * (1f - progress)
            val sample = (sin(2.0 * Math.PI * freq * t) * 0.7f + noise) * env
            data[i] = (sample * 28000).toInt().toShort()
        }
        return data
    }

    private fun genDodge(sampleRate: Int): ShortArray {
        val duration = 0.16f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val progress = t / duration
            val noise = MathUtils.random(-0.5f, 0.5f)
            val env = sin(progress * Math.PI.toFloat())
            val sample = noise * env
            data[i] = (sample * 18000).toInt().toShort()
        }
        return data
    }

    private fun genDeath(sampleRate: Int): ShortArray {
        val duration = 0.32f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val progress = t / duration
            val freq = MathUtils.lerp(120f, 25f, progress)
            val noise = MathUtils.random(-0.6f, 0.6f)
            val env = 1f - progress
            val sample = (sin(2.0 * Math.PI * freq * t) * 0.5f + noise * 0.5f) * env
            data[i] = (sample * 26000).toInt().toShort()
        }
        return data
    }

    private fun genLevelUp(sampleRate: Int): ShortArray {
        val duration = 0.42f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)
        val notes = floatArrayOf(261.63f, 329.63f, 392.0f, 523.25f) // C4, E4, G4, C5
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val noteIdx = ((t / duration) * notes.size).toInt().coerceIn(0, notes.size - 1)
            val freq = notes[noteIdx]
            val noteT = (t - (noteIdx.toFloat() / notes.size * duration))
            val env = (1f - (noteT / (duration / notes.size))).coerceIn(0f, 1f)
            val sample = sin(2.0 * Math.PI * freq * t) * env
            data[i] = (sample * 25000).toInt().toShort()
        }
        return data
    }

    private fun genChest(sampleRate: Int): ShortArray {
        val duration = 0.28f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)
        val notes = floatArrayOf(659.25f, 830.61f, 987.77f) // E5, G#5, B5
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val noteIdx = ((t / duration) * notes.size).toInt().coerceIn(0, notes.size - 1)
            val freq = notes[noteIdx]
            val env = 1f - (t / duration)
            val sample = sin(2.0 * Math.PI * freq * t) * env
            data[i] = (sample * 24000).toInt().toShort()
        }
        return data
    }

    private fun genParry(sampleRate: Int): ShortArray {
        val duration = 0.28f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val env = (1f - (t / duration)).let { it * it }
            // Harmoni logam tajam dengan desis burst awal
            val metallic = (sin(2.0 * Math.PI * 1480.0 * t) * 0.45 +
                    sin(2.0 * Math.PI * 2240.0 * t) * 0.35 +
                    sin(2.0 * Math.PI * 3120.0 * t) * 0.20)
            val burst = if (t < 0.015f) MathUtils.random(-0.5f, 0.5f) else 0f
            val sample = (metallic * 0.85 + burst * 0.15) * env
            data[i] = (sample * 28000).toInt().coerceIn(-32768, 32767).toShort()
        }
        return data
    }

    private fun genBossRoar(sampleRate: Int): ShortArray {
        val duration = 0.85f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val env = if (t < 0.15f) (t / 0.15f) else (1f - (t - 0.15f) / 0.70f).coerceIn(0f, 1f)
            val freq = MathUtils.lerp(105f, 60f, t / duration)
            val sub = sin(2.0 * Math.PI * freq * t)
            val noise = MathUtils.random(-0.35f, 0.35f)
            val sample = (sub * 0.65 + noise * 0.35) * env
            data[i] = (sample * 27000).toInt().coerceIn(-32768, 32767).toShort()
        }
        return data
    }

    // --- Voice Chirp Waveform Synthesizers (Fase 18) ---

    private fun genChirpAria(sampleRate: Int): ShortArray {
        val duration = 0.045f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val progress = t / duration
            val freq = MathUtils.lerp(880f, 1046f, progress)
            val env = sin(progress * Math.PI.toFloat())
            val sample = sin(2.0 * Math.PI * freq * t) * env
            data[i] = (sample * 21000).toInt().coerceIn(-32768, 32767).toShort()
        }
        return data
    }

    private fun genChirpVulcanus(sampleRate: Int): ShortArray {
        val duration = 0.055f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val progress = t / duration
            val freq = MathUtils.lerp(140f, 180f, progress)
            val env = 1f - progress
            // Gelombang segitiga nada rendah bergemuruh
            val phase = (t * freq) % 1.0
            val triangle = (kotlin.math.abs(phase * 4.0 - 2.0) - 1.0).toFloat()
            val sample = triangle * env
            data[i] = (sample * 25000).toInt().coerceIn(-32768, 32767).toShort()
        }
        return data
    }

    private fun genChirpCalligrapher(sampleRate: Int): ShortArray {
        val duration = 0.060f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val progress = t / duration
            val env = sin(progress * Math.PI.toFloat())
            // Harmonik ganda mistis: 55Hz (otoritas gaib) + 440Hz (bisikan kosmis)
            val sub = sin(2.0 * Math.PI * 55.0 * t) * 0.60
            val overtone = sin(2.0 * Math.PI * 440.0 * t) * 0.40
            val sample = (sub + overtone).toFloat() * env
            data[i] = (sample * 26000).toInt().coerceIn(-32768, 32767).toShort()
        }
        return data
    }

    private fun genChirpKaelen(sampleRate: Int): ShortArray {
        val duration = 0.042f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val progress = t / duration
            val freq = MathUtils.lerp(240f, 290f, progress)
            val env = (1f - progress)
            val fundamental = sin(2.0 * Math.PI * freq * t) * 0.75
            val harmonic = sin(2.0 * Math.PI * freq * 2.0 * t) * 0.25
            val sample = (fundamental + harmonic).toFloat() * env
            data[i] = (sample * 23000).toInt().coerceIn(-32768, 32767).toShort()
        }
        return data
    }

    private fun genChirpOakhaven(sampleRate: Int): ShortArray {
        val duration = 0.052f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val progress = t / duration
            val freq = MathUtils.lerp(170f, 215f, progress)
            val env = 1f - progress * progress
            val sample = sin(2.0 * Math.PI * freq * t) * env
            data[i] = (sample * 24000).toInt().coerceIn(-32768, 32767).toShort()
        }
        return data
    }

    private fun genChirpMatron(sampleRate: Int): ShortArray {
        val duration = 0.048f
        val numSamples = (sampleRate * duration).toInt()
        val data = ShortArray(numSamples)
        for (i in 0 until numSamples) {
            val t = i.toFloat() / sampleRate
            val progress = t / duration
            val vibrato = sin(2.0 * Math.PI * 28.0 * t).toFloat() * 35f
            val freq = 710f + vibrato
            val env = sin(progress * Math.PI.toFloat())
            val sample = sin(2.0 * Math.PI * freq * t) * env
            data[i] = (sample * 20000).toInt().coerceIn(-32768, 32767).toShort()
        }
        return data
    }

    // --- Public Audio Triggers ---

    fun playJump() {
        if (!isMuted) soundJump?.play(sfxVolume * 0.7f)
    }

    fun playSlashLight() {
        if (!isMuted) soundSlashLight?.play(sfxVolume * 0.8f)
    }

    fun playSlashHeavy() {
        if (!isMuted) soundSlashHeavy?.play(sfxVolume * 1.0f)
    }

    fun playHit() {
        if (!isMuted) soundHit?.play(sfxVolume * 0.9f)
    }

    fun playDodge() {
        if (!isMuted) soundDodge?.play(sfxVolume * 0.75f)
    }

    fun playDeath() {
        if (!isMuted) soundDeath?.play(sfxVolume * 0.9f)
    }

    fun playLevelUp() {
        if (!isMuted) soundLevelUp?.play(sfxVolume * 1.0f)
    }

    fun playChest() {
        if (!isMuted) soundChest?.play(sfxVolume * 0.85f)
    }

    fun playParry() {
        if (!isMuted) soundParry?.play(sfxVolume * 1.0f)
    }

    fun playBossRoar() {
        if (!isMuted) soundBossRoar?.play(sfxVolume * 1.0f)
    }

    /**
     * Memainkan suara kicauan vokal prosedural (Voice Chirp) sesuai persona karakter.
     */
    fun playVoiceChirp(speaker: String) {
        if (isMuted) return
        val pitchVariance = MathUtils.random(0.96f, 1.04f)
        val vol = sfxVolume * 0.65f
        val speakerLower = speaker.lowercase()

        when {
            speakerLower.contains("aria") -> soundChirpAria?.play(vol, pitchVariance, 0f)
            speakerLower.contains("vulcanus") -> soundChirpVulcanus?.play(vol, pitchVariance, 0f)
            speakerLower.contains("calligrapher") || speakerLower.contains("kaligrafer") -> soundChirpCalligrapher?.play(vol, pitchVariance, 0f)
            speakerLower.contains("oakhaven") -> soundChirpOakhaven?.play(vol, pitchVariance, 0f)
            speakerLower.contains("matron") -> soundChirpMatron?.play(vol, pitchVariance, 0f)
            else -> soundChirpKaelen?.play(vol, pitchVariance, 0f)
        }
    }

    fun playFloorBgm(floorNumber: Int, isBossFloor: Boolean = false) {
        ProceduralMusicEngine.playFloorBgm(floorNumber, isBossFloor)
    }

    fun pauseBgm() {
        ProceduralMusicEngine.pause()
    }

    fun resumeBgm() {
        ProceduralMusicEngine.resume()
    }

    fun stopBgm() {
        ProceduralMusicEngine.stop()
    }

    fun toggleMute(): Boolean {
        isMuted = !isMuted
        return isMuted
    }

    fun dispose() {
        soundJump?.dispose()
        soundSlashLight?.dispose()
        soundSlashHeavy?.dispose()
        soundHit?.dispose()
        soundDodge?.dispose()
        soundDeath?.dispose()
        soundLevelUp?.dispose()
        soundChest?.dispose()
        soundParry?.dispose()
        soundBossRoar?.dispose()

        soundChirpAria?.dispose()
        soundChirpVulcanus?.dispose()
        soundChirpCalligrapher?.dispose()
        soundChirpKaelen?.dispose()
        soundChirpOakhaven?.dispose()
        soundChirpMatron?.dispose()

        soundJump = null
        soundSlashLight = null
        soundSlashHeavy = null
        soundHit = null
        soundDodge = null
        soundDeath = null
        soundLevelUp = null
        soundChest = null
        soundParry = null
        soundBossRoar = null

        soundChirpAria = null
        soundChirpVulcanus = null
        soundChirpCalligrapher = null
        soundChirpKaelen = null
        soundChirpOakhaven = null
        soundChirpMatron = null

        ProceduralMusicEngine.dispose()
        isInitialized = false
    }
}

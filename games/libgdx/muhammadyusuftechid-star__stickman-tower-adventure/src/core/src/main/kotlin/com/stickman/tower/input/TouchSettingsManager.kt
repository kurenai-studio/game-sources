package com.stickman.tower.input

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.Preferences

/**
 * Data konfigurasi tata letak dan ergonomi tombol sentuh layar (On-Screen Touch Controls).
 */
data class TouchControlSettings(
    var dpadOffsetX: Float = 0f,
    var dpadOffsetY: Float = 0f,
    var actionOffsetX: Float = 0f,
    var actionOffsetY: Float = 0f,
    var scale: Float = 1.0f,
    var opacity: Float = 0.85f,
    var autoHideOnGamepad: Boolean = true
) {
    fun clamp(): TouchControlSettings {
        dpadOffsetX = dpadOffsetX.coerceIn(-50f, 250f)
        dpadOffsetY = dpadOffsetY.coerceIn(-50f, 250f)
        actionOffsetX = actionOffsetX.coerceIn(-250f, 50f)
        actionOffsetY = actionOffsetY.coerceIn(-50f, 250f)
        scale = scale.coerceIn(0.70f, 1.30f)
        opacity = opacity.coerceIn(0.30f, 1.00f)
        return this
    }
}

/**
 * Manajer penyimpanan preferensi kustomisasi kontrol sentuh ke Gdx.app.getPreferences.
 */
object TouchSettingsManager {
    private const val PREF_NAME = "stickman_touch_controls"
    private const val KEY_DPAD_X = "dpad_offset_x"
    private const val KEY_DPAD_Y = "dpad_offset_y"
    private const val KEY_ACTION_X = "action_offset_x"
    private const val KEY_ACTION_Y = "action_offset_y"
    private const val KEY_SCALE = "scale"
    private const val KEY_OPACITY = "opacity"
    private const val KEY_AUTO_HIDE = "auto_hide_on_gamepad"

    private var cachedSettings: TouchControlSettings? = null

    /**
     * Memuat preferensi kontrol sentuh tersimpan atau mengembalikan default.
     */
    fun load(): TouchControlSettings {
        cachedSettings?.let { return it.copy() }

        val settings = TouchControlSettings()
        try {
            if (Gdx.app != null) {
                val prefs = Gdx.app.getPreferences(PREF_NAME)
                settings.dpadOffsetX = prefs.getFloat(KEY_DPAD_X, 0f)
                settings.dpadOffsetY = prefs.getFloat(KEY_DPAD_Y, 0f)
                settings.actionOffsetX = prefs.getFloat(KEY_ACTION_X, 0f)
                settings.actionOffsetY = prefs.getFloat(KEY_ACTION_Y, 0f)
                settings.scale = prefs.getFloat(KEY_SCALE, 1.0f)
                settings.opacity = prefs.getFloat(KEY_OPACITY, 0.85f)
                settings.autoHideOnGamepad = prefs.getBoolean(KEY_AUTO_HIDE, true)
                settings.clamp()
            }
        } catch (_: Exception) {
            // Fallback ke default jika preferences belum tersedia
        }

        cachedSettings = settings.copy()
        return settings
    }

    /**
     * Menyimpan preferensi kontrol sentuh ke storage lokal.
     */
    fun save(settings: TouchControlSettings) {
        settings.clamp()
        cachedSettings = settings.copy()

        try {
            if (Gdx.app != null) {
                val prefs: Preferences = Gdx.app.getPreferences(PREF_NAME)
                prefs.putFloat(KEY_DPAD_X, settings.dpadOffsetX)
                prefs.putFloat(KEY_DPAD_Y, settings.dpadOffsetY)
                prefs.putFloat(KEY_ACTION_X, settings.actionOffsetX)
                prefs.putFloat(KEY_ACTION_Y, settings.actionOffsetY)
                prefs.putFloat(KEY_SCALE, settings.scale)
                prefs.putFloat(KEY_OPACITY, settings.opacity)
                prefs.putBoolean(KEY_AUTO_HIDE, settings.autoHideOnGamepad)
                prefs.flush()
            }
        } catch (_: Exception) {
        }
    }

    /**
     * Mengatur ulang seluruh konfigurasi ke nilai bawaan (default).
     */
    fun resetToDefault(): TouchControlSettings {
        val def = TouchControlSettings()
        save(def)
        return def
    }
}

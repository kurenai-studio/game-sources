package com.stickman.tower.audio

import com.badlogic.gdx.Application
import com.badlogic.gdx.Gdx

/**
 * Manajer Umpan Balik Getaran Haptic Android:
 * Memberikan getaran mikro haptic untuk aksi pertempuran (Dodge, Hit, Damage, Ultimate)
 * pada perangkat Android yang mendukung motor vibrasi, dengan penanganan defensif zero-overhead.
 */
object HapticManager {
    private const val PREF_SETTINGS = "StickmanSettings"
    private const val KEY_HAPTIC = "haptic_enabled"

    var isEnabled: Boolean = true
        private set

    fun init() {
        try {
            val prefs = Gdx.app?.getPreferences(PREF_SETTINGS)
            if (prefs != null && prefs.contains(KEY_HAPTIC)) {
                isEnabled = prefs.getBoolean(KEY_HAPTIC, true)
            }
        } catch (_: Exception) {}
    }

    fun toggle() {
        isEnabled = !isEnabled
        try {
            val prefs = Gdx.app?.getPreferences(PREF_SETTINGS)
            prefs?.putBoolean(KEY_HAPTIC, isEnabled)
            prefs?.flush()
        } catch (_: Exception) {}

        if (isEnabled) {
            vibrateMedium()
        }
    }

    /**
     * Getaran mikro sangat halus (18ms) untuk manuver cepat seperti Dodge Roll dan pendaratan.
     */
    fun vibrateLight() {
        if (!isEnabled) return
        if (Gdx.app?.type == Application.ApplicationType.Android) {
            runCatching { Gdx.input?.vibrate(18) }
        }
    }

    /**
     * Getaran medium (35ms) saat tebasan kombo mendarat pada musuh atau membuka peti harta.
     */
    fun vibrateMedium() {
        if (!isEnabled) return
        if (Gdx.app?.type == Application.ApplicationType.Android) {
            runCatching { Gdx.input?.vibrate(35) }
        }
    }

    /**
     * Getaran berat berdenyut (70ms) saat pemain terkena serangan musuh atau meledakkan jurus Ultimate.
     */
    fun vibrateHeavy() {
        if (!isEnabled) return
        if (Gdx.app?.type == Application.ApplicationType.Android) {
            runCatching { Gdx.input?.vibrate(70) }
        }
    }
}

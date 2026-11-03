package com.stickman.tower

import com.badlogic.gdx.Game
import com.badlogic.gdx.Screen
import com.stickman.tower.audio.AudioManager
import com.stickman.tower.screen.MainMenuScreen
import com.stickman.tower.ui.FontManager

/**
 * Game root controller untuk Stickman Tower Adventure.
 * Mengelola transisi antar screen menggunakan libGDX Game framework,
 * dengan otomatisasi pembebasan memori native (auto-dispose old screen).
 */
class StickmanGame : Game() {
    private val preservedScreens = mutableSetOf<Screen>()

    override fun create() {
        com.badlogic.gdx.Gdx.input?.setCatchKey(com.badlogic.gdx.Input.Keys.BACK, true)
        FontManager.init()
        AudioManager.init()
        setScreen(MainMenuScreen(this))
    }

    /**
     * Menandai screen agar TIDAK di-dispose saat berpindah sementara ke subscreen
     * (misalnya PlayScreen yang di-pause saat membuka TalentTree atau Blacksmith).
     */
    fun preserveScreen(screen: Screen) {
        preservedScreens.add(screen)
    }

    /**
     * Membebaskan status preservasi screen ketika screen tersebut benar-benar ditutup.
     */
    fun releasePreservedScreen(screen: Screen) {
        preservedScreens.remove(screen)
    }

    override fun setScreen(screen: Screen?) {
        val oldScreen = this.screen
        super.setScreen(screen)
        if (oldScreen != null && oldScreen !== screen) {
            if (oldScreen in preservedScreens) {
                // Jangan dispose screen yang sedang dipreservasi (misal PlayScreen saat subscreen aktif)
            } else {
                val app = com.badlogic.gdx.Gdx.app
                if (app != null) {
                    app.postRunnable {
                        runCatching { oldScreen.dispose() }
                    }
                } else {
                    runCatching { oldScreen.dispose() }
                }
            }
        }
    }

    override fun dispose() {
        super.dispose()
        for (preserved in preservedScreens) {
            runCatching { preserved.dispose() }
        }
        preservedScreens.clear()
        runCatching { screen?.dispose() }
        screen = null
        runCatching { AudioManager.dispose() }
        runCatching { FontManager.dispose() }
    }
}



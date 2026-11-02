package com.darumahq.rainbowclimb

import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration

fun main() {
    val config = Lwjgl3ApplicationConfiguration().apply {
        setTitle("Rainbow Climb")
        setWindowedMode(480, 800) // 2x virtual resolution
        setForegroundFPS(60)
        useVsync(true)
        setResizable(true)
    }

    Lwjgl3Application(RainbowClimbGame(), config)
}

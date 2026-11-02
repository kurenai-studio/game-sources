package com.darumahq.rainbowclimb

import com.badlogic.gdx.Game
import com.badlogic.gdx.Gdx
import com.badlogic.gdx.graphics.g2d.SpriteBatch
import com.darumahq.rainbowclimb.entity.PlayerCharacter
import com.darumahq.rainbowclimb.render.SpriteManager
import com.darumahq.rainbowclimb.screen.MenuScreen

class RainbowClimbGame : Game() {
    lateinit var batch: SpriteBatch
        private set
    lateinit var sprites: SpriteManager
        private set

    // Persistent stats
    var totalGems: Int = 0
        private set
    var selectedCharacter: PlayerCharacter = PlayerCharacter.PINK_MAN

    override fun create() {
        batch = SpriteBatch()
        sprites = SpriteManager()
        sprites.load()

        // Load persistent data
        val prefs = Gdx.app.getPreferences("rainbow-climb")
        totalGems = prefs.getInteger("totalGems", 0)
        val charName = prefs.getString("selectedCharacter", PlayerCharacter.PINK_MAN.name)
        selectedCharacter = try {
            PlayerCharacter.valueOf(charName)
        } catch (e: Exception) {
            PlayerCharacter.PINK_MAN
        }
        // Verify character is still unlocked
        if (!selectedCharacter.isUnlocked(totalGems)) {
            selectedCharacter = PlayerCharacter.PINK_MAN
        }

        setScreen(MenuScreen(this))
    }

    /** Add gems from a completed game run and persist */
    fun addGems(gemsFromRun: Int) {
        totalGems += gemsFromRun
        val prefs = Gdx.app.getPreferences("rainbow-climb")
        prefs.putInteger("totalGems", totalGems)
        prefs.flush()
    }

    fun saveSelectedCharacter() {
        val prefs = Gdx.app.getPreferences("rainbow-climb")
        prefs.putString("selectedCharacter", selectedCharacter.name)
        prefs.flush()
    }

    override fun dispose() {
        batch.dispose()
        sprites.dispose()
        screen?.dispose()
    }
}

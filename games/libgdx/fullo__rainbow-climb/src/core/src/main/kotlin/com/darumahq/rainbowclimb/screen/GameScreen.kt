package com.darumahq.rainbowclimb.screen

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.Input
import com.badlogic.gdx.ScreenAdapter
import com.darumahq.rainbowclimb.RainbowClimbGame
import com.darumahq.rainbowclimb.audio.MusicEngine
import com.darumahq.rainbowclimb.audio.SfxManager
import com.darumahq.rainbowclimb.input.TouchInputHandler
import com.darumahq.rainbowclimb.render.GameRenderer
import com.darumahq.rainbowclimb.util.Constants
import com.darumahq.rainbowclimb.world.World

class GameScreen(private val game: RainbowClimbGame) : ScreenAdapter() {
    private val world = World()
    private val renderer = GameRenderer(game.batch, game.sprites, game.selectedCharacter)
    private val inputHandler = TouchInputHandler()
    private val musicEngine = MusicEngine()
    private val sfx = SfxManager()

    private var lastBiomeIndex = -1
    private var paused = false

    override fun show() {
        world.init()
        Gdx.input.inputProcessor = inputHandler
        Gdx.input.setCatchKey(Input.Keys.BACK, true)
        musicEngine.updateForBiome(world.currentBiome)
        musicEngine.start()

        // Load settings
        val prefs = Gdx.app.getPreferences("rainbow-climb")
        renderer.reducedMotion = prefs.getBoolean("reducedMotion", false)

        // Show tutorial on first ever game
        if (!prefs.getBoolean("tutorialDone", false)) {
            renderer.showTutorial = true
            prefs.putBoolean("tutorialDone", true)
            prefs.flush()
        }
    }

    override fun render(delta: Float) {
        val dt = delta.coerceAtMost(0.033f)

        // Handle input (always, even when paused)
        handleInput()

        if (!paused) {
            // Update world
            world.update(dt)

            // Check biome change
            if (world.currentLevel != lastBiomeIndex) {
                lastBiomeIndex = world.currentLevel
                musicEngine.updateForBiome(world.currentBiome)
            }
        }

        // Render (always, shows pause overlay if paused)
        renderer.render(world)

        // Pause overlay
        if (paused) {
            renderPauseOverlay()
        }

        // Check game over
        if (!world.player.isAlive) {
            sfx.playDeath()
            musicEngine.stop()
            game.addGems(world.gemsCollected)
            game.setScreen(GameOverScreen(game, world.score, world.maxHeight.toInt(), world.currentLevel, world.currentSeed))
        }
    }

    private fun renderPauseOverlay() {
        val font = game.sprites.pixelFont
        val hudCam = com.badlogic.gdx.graphics.OrthographicCamera()
        hudCam.setToOrtho(false, Constants.VIRTUAL_WIDTH, Constants.VIRTUAL_HEIGHT)
        hudCam.update()
        game.batch.projectionMatrix = hudCam.combined
        game.batch.begin()
        font.color = com.badlogic.gdx.graphics.Color.YELLOW
        val text = "PAUSED"
        val layout = com.badlogic.gdx.graphics.g2d.GlyphLayout(font, text)
        font.draw(game.batch, text, (Constants.VIRTUAL_WIDTH - layout.width) / 2f,
            Constants.VIRTUAL_HEIGHT / 2f + 20f)
        font.color = com.badlogic.gdx.graphics.Color.WHITE
        val sub = "Tap or P to resume"
        val subLayout = com.badlogic.gdx.graphics.g2d.GlyphLayout(font, sub)
        font.draw(game.batch, sub, (Constants.VIRTUAL_WIDTH - subLayout.width) / 2f,
            Constants.VIRTUAL_HEIGHT / 2f - 20f)
        game.batch.end()
    }

    private fun handleInput() {
        // Pause toggle — always processed first
        if (Gdx.input.isKeyJustPressed(Input.Keys.P) ||
            (paused && Gdx.input.justTouched())
        ) {
            paused = !paused
            return
        }
        if (paused) return // Block ALL input while paused

        // Movement
        if (Gdx.input.isKeyPressed(Input.Keys.LEFT) || Gdx.input.isKeyPressed(Input.Keys.A)) {
            world.player.moveLeft()
        } else if (Gdx.input.isKeyPressed(Input.Keys.RIGHT) || Gdx.input.isKeyPressed(Input.Keys.D)) {
            world.player.moveRight()
        } else if (inputHandler.moveDirection != 0) {
            if (inputHandler.moveDirection < 0) world.player.moveLeft()
            else world.player.moveRight()
        } else {
            world.player.stopMoving()
        }

        // Jump (UP or W)
        if (Gdx.input.isKeyJustPressed(Input.Keys.UP) ||
            Gdx.input.isKeyJustPressed(Input.Keys.W) ||
            inputHandler.consumeJump()
        ) {
            world.player.jump()
            sfx.playJump()
        }

        // Rainbow bridge (SPACE, Z, or swipe)
        val swipeDir = inputHandler.consumeRainbow()
        if (Gdx.input.isKeyJustPressed(Input.Keys.SPACE) ||
            Gdx.input.isKeyJustPressed(Input.Keys.Z) ||
            swipeDir != -2
        ) {
            val dir = world.player.facing
            world.shootRainbow(dir)
            sfx.playRainbow()
        }

        // Android back button → go to menu
        if (Gdx.input.isKeyJustPressed(Input.Keys.BACK) ||
            Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)
        ) {
            musicEngine.stop()
            game.setScreen(MenuScreen(game))
        }
    }

    override fun resize(width: Int, height: Int) {
        renderer.resize(width, height)
    }

    override fun dispose() {
        renderer.dispose()
        musicEngine.dispose()
    }
}

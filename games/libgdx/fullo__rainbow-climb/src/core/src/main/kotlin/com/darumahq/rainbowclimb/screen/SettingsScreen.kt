package com.darumahq.rainbowclimb.screen

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.Input
import com.badlogic.gdx.ScreenAdapter
import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.GL20
import com.badlogic.gdx.graphics.OrthographicCamera
import com.badlogic.gdx.graphics.g2d.GlyphLayout
import com.darumahq.rainbowclimb.RainbowClimbGame
import com.darumahq.rainbowclimb.util.Constants

class SettingsScreen(private val game: RainbowClimbGame) : ScreenAdapter() {
    private val camera = OrthographicCamera()
    private val font get() = game.sprites.pixelFont
    private val prefs = Gdx.app.getPreferences("rainbow-climb")

    private var musicOn = prefs.getBoolean("musicOn", true)
    private var sfxOn = prefs.getBoolean("sfxOn", true)
    private var vibrationOn = prefs.getBoolean("vibrationOn", true)
    private var reducedMotion = prefs.getBoolean("reducedMotion", false)

    // Simple menu selection
    private var selectedIndex = 0
    private val menuItems = listOf("Music", "SFX", "Vibration", "Reduced Motion", "Back")

    init {
        camera.setToOrtho(false, Constants.VIRTUAL_WIDTH, Constants.VIRTUAL_HEIGHT)
    }

    override fun render(delta: Float) {
        Gdx.gl.glClearColor(0.05f, 0.05f, 0.15f, 1f)
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT)

        handleInput()

        camera.update()
        game.batch.projectionMatrix = camera.combined
        game.batch.begin()

        font.color = Color.WHITE
        drawCentered("SETTINGS", Constants.VIRTUAL_HEIGHT - 60f)

        val startY = Constants.VIRTUAL_HEIGHT - 130f
        val spacing = 30f

        for (i in menuItems.indices) {
            val y = startY - i * spacing
            font.color = if (i == selectedIndex) Color.YELLOW else Color.GRAY

            val label = when (i) {
                0 -> "Music: ${if (musicOn) "ON" else "OFF"}"
                1 -> "SFX: ${if (sfxOn) "ON" else "OFF"}"
                2 -> "Vibration: ${if (vibrationOn) "ON" else "OFF"}"
                3 -> "Reduced Motion: ${if (reducedMotion) "ON" else "OFF"}"
                4 -> "< Back"
                else -> ""
            }
            drawCentered(label, y)
        }

        font.color = Color.DARK_GRAY
        drawCentered("Up/Down to select", 50f)
        drawCentered("Enter/Space to toggle", 35f)

        game.batch.end()
    }

    private fun handleInput() {
        if (Gdx.input.isKeyJustPressed(Input.Keys.UP) || Gdx.input.isKeyJustPressed(Input.Keys.W)) {
            selectedIndex = (selectedIndex - 1 + menuItems.size) % menuItems.size
        }
        if (Gdx.input.isKeyJustPressed(Input.Keys.DOWN) || Gdx.input.isKeyJustPressed(Input.Keys.S)) {
            selectedIndex = (selectedIndex + 1) % menuItems.size
        }

        val confirm = Gdx.input.isKeyJustPressed(Input.Keys.ENTER) ||
            Gdx.input.isKeyJustPressed(Input.Keys.SPACE)

        if (confirm || Gdx.input.justTouched()) {
            // Touch: determine which item was tapped
            if (Gdx.input.justTouched() && !confirm) {
                val touchY = Constants.VIRTUAL_HEIGHT - Gdx.input.y.toFloat() *
                    (Constants.VIRTUAL_HEIGHT / Gdx.graphics.height.toFloat())
                val startY = Constants.VIRTUAL_HEIGHT - 130f
                for (i in menuItems.indices) {
                    val itemY = startY - i * 30f
                    if (touchY > itemY - 15f && touchY < itemY + 15f) {
                        selectedIndex = i
                        break
                    }
                }
            }

            when (selectedIndex) {
                0 -> musicOn = !musicOn
                1 -> sfxOn = !sfxOn
                2 -> vibrationOn = !vibrationOn
                3 -> reducedMotion = !reducedMotion
                4 -> {
                    saveAndReturn()
                    return
                }
            }
        }

        if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE) ||
            Gdx.input.isKeyJustPressed(Input.Keys.BACK)
        ) {
            saveAndReturn()
        }
    }

    private fun saveAndReturn() {
        prefs.putBoolean("musicOn", musicOn)
        prefs.putBoolean("sfxOn", sfxOn)
        prefs.putBoolean("vibrationOn", vibrationOn)
        prefs.putBoolean("reducedMotion", reducedMotion)
        prefs.flush()
        game.setScreen(MenuScreen(game))
    }

    private fun drawCentered(text: String, y: Float) {
        val layout = GlyphLayout(font, text)
        font.draw(game.batch, text, (Constants.VIRTUAL_WIDTH - layout.width) / 2f, y)
    }

    override fun resize(width: Int, height: Int) {
        camera.setToOrtho(false, Constants.VIRTUAL_WIDTH, Constants.VIRTUAL_HEIGHT)
    }

    override fun dispose() {}
}

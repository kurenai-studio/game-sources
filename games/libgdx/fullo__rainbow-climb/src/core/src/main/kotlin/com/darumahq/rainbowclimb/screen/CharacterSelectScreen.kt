package com.darumahq.rainbowclimb.screen

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.Input
import com.badlogic.gdx.ScreenAdapter
import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.GL20
import com.badlogic.gdx.graphics.OrthographicCamera
import com.badlogic.gdx.graphics.g2d.GlyphLayout
import com.darumahq.rainbowclimb.RainbowClimbGame
import com.darumahq.rainbowclimb.entity.PlayerCharacter
import com.darumahq.rainbowclimb.util.Constants

class CharacterSelectScreen(private val game: RainbowClimbGame) : ScreenAdapter() {
    private val camera = OrthographicCamera()
    private val font get() = game.sprites.pixelFont
    private var selectedIndex = PlayerCharacter.entries.indexOf(game.selectedCharacter)
    private var animTimer = 0f

    init {
        camera.setToOrtho(false, Constants.VIRTUAL_WIDTH, Constants.VIRTUAL_HEIGHT)
    }

    override fun render(delta: Float) {
        animTimer += delta

        Gdx.gl.glClearColor(0.05f, 0.05f, 0.15f, 1f)
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT)

        handleInput()

        camera.update()
        game.batch.projectionMatrix = camera.combined
        game.batch.begin()

        // Title
        font.color = Color.WHITE
        drawCentered("SELECT CHARACTER", Constants.VIRTUAL_HEIGHT - 80f)

        // Total gems
        font.color = Color.CYAN
        drawCentered("Total Gems: ${game.totalGems}", Constants.VIRTUAL_HEIGHT - 120f)

        // Character list
        val chars = PlayerCharacter.entries
        val startY = Constants.VIRTUAL_HEIGHT - 200f
        val spacing = 100f

        for (i in chars.indices) {
            val char = chars[i]
            val y = startY - i * spacing
            val unlocked = char.isUnlocked(game.totalGems)
            val isSelected = i == selectedIndex

            // Character preview sprite (idle animation)
            if (unlocked) {
                val anim = game.sprites.getPlayerAnim(char, "idle")
                val frame = anim.getKeyFrame(animTimer, true)
                val previewX = Constants.VIRTUAL_WIDTH / 2f - 80f
                game.batch.setColor(Color.WHITE)
                game.batch.draw(frame, previewX, y - 16f, 32f, 32f)
            }

            // Name and status
            val textX = Constants.VIRTUAL_WIDTH / 2f - 40f

            if (isSelected) {
                font.color = Color.YELLOW
                // Selection indicator
                font.draw(game.batch, ">", textX - 20f, y + 8f)
            }

            if (unlocked) {
                font.color = if (isSelected) Color.YELLOW else Color.WHITE
                font.draw(game.batch, char.displayName, textX, y + 8f)
                if (char == game.selectedCharacter) {
                    font.color = Color.GREEN
                    font.draw(game.batch, "[IN USE]", textX, y - 12f)
                }
            } else {
                font.color = Color.DARK_GRAY
                font.draw(game.batch, char.displayName, textX, y + 8f)
                font.color = Color.RED
                font.draw(game.batch, "${char.gemsRequired} gems", textX, y - 12f)
                // Progress bar
                val progress = (game.totalGems.toFloat() / char.gemsRequired).coerceAtMost(1f)
                val barWidth = 100f
                font.color = Color.DARK_GRAY
                font.draw(game.batch, "[" + "=".repeat((progress * 10).toInt()) +
                    ".".repeat(10 - (progress * 10).toInt()) + "]", textX, y - 28f)
            }
        }

        // Instructions
        font.color = Color.GRAY
        drawCentered("Up/Down to browse", 60f)
        drawCentered("Enter to select, ESC to back", 40f)

        game.batch.end()
    }

    private fun handleInput() {
        val chars = PlayerCharacter.entries

        if (Gdx.input.isKeyJustPressed(Input.Keys.UP) || Gdx.input.isKeyJustPressed(Input.Keys.W)) {
            selectedIndex = (selectedIndex - 1 + chars.size) % chars.size
        }
        if (Gdx.input.isKeyJustPressed(Input.Keys.DOWN) || Gdx.input.isKeyJustPressed(Input.Keys.S)) {
            selectedIndex = (selectedIndex + 1) % chars.size
        }

        if (Gdx.input.isKeyJustPressed(Input.Keys.ENTER) ||
            Gdx.input.isKeyJustPressed(Input.Keys.SPACE)
        ) {
            val char = chars[selectedIndex]
            if (char.isUnlocked(game.totalGems)) {
                game.selectedCharacter = char
                game.saveSelectedCharacter()
                game.setScreen(MenuScreen(game))
            }
        }

        // Touch: tap on character
        if (Gdx.input.justTouched()) {
            val touchY = Constants.VIRTUAL_HEIGHT - Gdx.input.y.toFloat() *
                (Constants.VIRTUAL_HEIGHT / Gdx.graphics.height.toFloat())
            val startY = Constants.VIRTUAL_HEIGHT - 200f
            for (i in chars.indices) {
                val y = startY - i * 100f
                if (touchY > y - 40f && touchY < y + 40f) {
                    if (chars[i].isUnlocked(game.totalGems)) {
                        game.selectedCharacter = chars[i]
                        game.saveSelectedCharacter()
                        game.setScreen(MenuScreen(game))
                    }
                    break
                }
            }
        }

        if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE) ||
            Gdx.input.isKeyJustPressed(Input.Keys.BACK)
        ) {
            game.setScreen(MenuScreen(game))
        }
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

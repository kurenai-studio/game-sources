package io.github.makingthematrix.snakelibgdx

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.graphics.g2d.{Sprite, SpriteBatch}
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import com.badlogic.gdx.graphics.{Color, Texture}
import com.badlogic.gdx.utils.ScreenUtils

import java.nio.file.Paths

object Draw:
  private val SQUARE_SIZE = 80f // Size of each square in pixels
  private val TILE_WIDTH = SQUARE_SIZE // Width of an isometric tile
  private val TILE_HEIGHT = SQUARE_SIZE / 2 // Height of isometric tile (half of width for 2:1 ratio)
  private val coinTexture = new Texture(Paths.get("coins.png").toString)
  private val darkGreen = new Color(0, 0.6f, 0, 1)

  private lazy val graphicsWH: (w: Int, h: Int) = (w = Gdx.graphics.getWidth, h = Gdx.graphics.getHeight)
  private lazy val shapeRenderer: ShapeRenderer = new ShapeRenderer()
  private lazy val batch = new SpriteBatch()

  private lazy val start: (x: Float, y: Float) =
    // Calculate the width and height of the isometric board
    val isoWidth = Main.BOARD_SIZE * TILE_WIDTH
    val isoHeight = Main.BOARD_SIZE * TILE_HEIGHT
    // Calculate the starting position to center the board
    val startX = (graphicsWH.w - isoWidth) / 2f - isoWidth / 16f // Adjust to center horizontally
    val startY = (graphicsWH.h - isoHeight) / 2f // Adjust to center vertically
    (startX, startY)

  def init(): Unit =
    shapeRenderer
    batch
    graphicsWH
    start

  def render(board: Board): Unit =
    // Clear the screen
    ScreenUtils.clear(0.15f, 0.15f, 0.2f, 1f)
    // Begin shape rendering in filled mode
    shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)
    drawBoard(board)
    drawSnake(board.snake)
    shapeRenderer.end()
    // Draw the snake
    batch.begin()
    drawCoins(board.coinsPositions)
    batch.end()

  def dispose(): Unit =
    shapeRenderer.dispose()
    batch.dispose()

  private def drawBoard(board: Board): Unit =
    // First pass: Draw filled tiles (white)
    shapeRenderer.setColor(Color.WHITE)
    for
      row <- 0 until board.size
      col <- 0 until board.size
    do
      // Calculate isometric coordinates
      val isoX = start.x + (col - row) * TILE_WIDTH / 2f + board.size * TILE_WIDTH / 2f
      val isoY = start.y + (col + row) * TILE_HEIGHT / 2f
      // Draw the isometric tile (diamond shape)
      shapeRenderer.triangle(
        isoX, isoY + TILE_HEIGHT / 2f,
        isoX + TILE_WIDTH / 2f, isoY,
        isoX + TILE_WIDTH, isoY + TILE_HEIGHT / 2f
      )
      shapeRenderer.triangle(
        isoX, isoY + TILE_HEIGHT / 2f,
        isoX + TILE_WIDTH, isoY + TILE_HEIGHT / 2f,
        isoX + TILE_WIDTH / 2f, isoY + TILE_HEIGHT
      )

    // End filled rendering and start line rendering for borders
    shapeRenderer.end()
    shapeRenderer.begin(ShapeRenderer.ShapeType.Line)
    shapeRenderer.setColor(Color.BLACK)

    // Second pass: Draw black borders
    for
      row <- 0 until board.size
      col <- 0 until board.size
    do
      // Calculate isometric coordinates
      val isoX = start.x + (col - row) * TILE_WIDTH / 2f + board.size * TILE_WIDTH / 2f
      val isoY = start.y + (col + row) * TILE_HEIGHT / 2f
      // Draw the diamond border (4 lines forming the outline)
      // Top edge
      shapeRenderer.line(isoX, isoY + TILE_HEIGHT / 2f, isoX + TILE_WIDTH / 2f, isoY)
      // Right edge
      shapeRenderer.line(isoX + TILE_WIDTH / 2f, isoY, isoX + TILE_WIDTH, isoY + TILE_HEIGHT / 2f)
      // Bottom edge
      shapeRenderer.line(isoX + TILE_WIDTH, isoY + TILE_HEIGHT / 2f, isoX + TILE_WIDTH / 2f, isoY + TILE_HEIGHT)
      // Left edge
      shapeRenderer.line(isoX + TILE_WIDTH / 2f, isoY + TILE_HEIGHT, isoX, isoY + TILE_HEIGHT / 2f)

    // End line rendering and restart filled rendering for next frame
    shapeRenderer.end()
    shapeRenderer.begin(ShapeRenderer.ShapeType.Filled)

  private def colorTile(pos: (x: Int, y: Int)): Unit =
    val isoX = start.x + (pos.x - pos.y) * TILE_WIDTH / 2f + Main.BOARD_SIZE * TILE_WIDTH / 2f
    val isoY = start.y + (pos.x + pos.y) * TILE_HEIGHT / 2f
    // Draw the isometric tile (diamond shape)
    shapeRenderer.triangle(
      isoX, isoY + TILE_HEIGHT / 2f,
      isoX + TILE_WIDTH / 2f, isoY,
      isoX + TILE_WIDTH, isoY + TILE_HEIGHT / 2f
    )
    shapeRenderer.triangle(
      isoX, isoY + TILE_HEIGHT / 2f,
      isoX + TILE_WIDTH, isoY + TILE_HEIGHT / 2f,
      isoX + TILE_WIDTH / 2f, isoY + TILE_HEIGHT
    )

  private def drawSnake(snake: Snake): Unit =
    val body = snake.body
    if body.nonEmpty then
      shapeRenderer.setColor(darkGreen)
      colorTile(body.head)
      shapeRenderer.setColor(Color.GREEN)
      body.tail.foreach(colorTile)

  private def drawCoins(coinPositions: List[(x: Int, y: Int)]): Unit =
    for coinPos <- coinPositions do
      drawTexture(coinTexture, coinPos)

  private def drawTexture(texture: Texture, pos: (x: Int, y: Int)): Unit =
    // Calculate isometric coordinates for the pawn
    val tokenIsoX = start.x + (pos.x - pos.y) * TILE_WIDTH / 2f + Main.BOARD_SIZE * TILE_WIDTH / 2f
    val tokenIsoY = start.y + (pos.x + pos.y + 1f) * TILE_HEIGHT / 2f
    // Adjust the pawn position to center it on the tile
    val tokenX = tokenIsoX + (1.5f * TILE_WIDTH - SQUARE_SIZE) / 2f
    val tokenY = tokenIsoY - SQUARE_SIZE / 4f// Adjust to position pawn on the tile

    // Wrap the Texture into Sprite and set its size to the size of the square
    val sprite = new Sprite(texture)
    sprite.setSize(SQUARE_SIZE / 2f, SQUARE_SIZE / 2f)
    sprite.setPosition(tokenX, tokenY)

    // Set the origin to the center of the sprite for proper rotation
    sprite.setOrigin(SQUARE_SIZE / 2f, SQUARE_SIZE / 2f)
    sprite.draw(batch)


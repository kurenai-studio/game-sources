package io.github.makingthematrix.snakelibgdx

import com.badlogic.gdx.ApplicationAdapter
import com.badlogic.gdx.Gdx
import com.badlogic.gdx.InputProcessor
import com.badlogic.gdx.InputMultiplexer
import com.badlogic.gdx.scenes.scene2d.Stage
import com.badlogic.gdx.scenes.scene2d.ui.{Dialog, Skin, TextButton, Label}
import com.badlogic.gdx.scenes.scene2d.utils.ClickListener
import com.badlogic.gdx.scenes.scene2d.InputEvent
import com.badlogic.gdx.utils.viewport.ScreenViewport
import io.github.makingthematrix.snakelibgdx.Main.BOARD_SIZE
import scala.util.Random

final class Main extends ApplicationAdapter:
  private lazy val board = Board(
    size = BOARD_SIZE,
    coins = List((6, 3), (5, 2)),
    snake = new Snake(List((3,4), (2, 4), (1, 4)), SnakeDir.Right)
  )

  private var lastUpdateTime: Float = 0f
  private val updateInterval: Float = 0.5f
  private var gameRunning: Boolean = true

  private val newCoinInterval: Float = 5f
  private var lastCoinSpawnTime: Float = 0f

  private lazy val stage: Stage = new Stage(new ScreenViewport())
  private lazy val skin: Skin = new Skin(Gdx.files.internal("ui/uiskin.json"))
  private var showingDialog: Boolean = false

  // Custom InputProcessor for handling game input
  private val gameInputProcessor = new InputProcessor {
    override def keyDown(keycode: Int): Boolean = false

    override def keyUp(keycode: Int): Boolean = {
      import com.badlogic.gdx.Input.Keys.*
      if gameRunning && !showingDialog then
        val currentDirection = board.snake.snakeDir
        keycode match
          case LEFT =>
            board.updateSnakeDirection(currentDirection.rotateCounterClockwise)
            true
          case RIGHT =>
            board.updateSnakeDirection(currentDirection.rotateClockwise)
            true
          case _ => false
      else
        false
    }

    override def keyTyped(character: Char): Boolean = false
    override def touchDown(screenX: Int, screenY: Int, pointer: Int, button: Int): Boolean = false
    override def touchUp(screenX: Int, screenY: Int, pointer: Int, button: Int): Boolean = false
    override def touchCancelled(screenX: Int, screenY: Int, pointer: Int, button: Int): Boolean = false
    override def touchDragged(screenX: Int, screenY: Int, pointer: Int): Boolean = false
    override def mouseMoved(screenX: Int, screenY: Int): Boolean = false
    override def scrolled(amountX: Float, amountY: Float): Boolean = false
  }

  override def create(): Unit =
    Draw.init()

    // Initialize UI components
    stage
    skin

    // Set up input multiplexer to handle both game input and UI input
    val inputMultiplexer = new InputMultiplexer()
    inputMultiplexer.addProcessor(stage) // UI input (dialogs) takes priority
    inputMultiplexer.addProcessor(gameInputProcessor) // Game input (LEFT/RIGHT keys)
    Gdx.input.setInputProcessor(inputMultiplexer)

  override def render(): Unit =
    if gameRunning && !showingDialog then
      // Always render the current board state
      Draw.render(board)

      // Update timing
      val currentTime = Gdx.graphics.getDeltaTime
      lastUpdateTime += currentTime
      lastCoinSpawnTime += currentTime

      // If 1 second has passed, update the board
      if lastUpdateTime >= updateInterval then
        board.update()
        // Check for self-collision after board update
        if board.hasSnakeSelfCollision then
          showScoreDialog()
        lastUpdateTime = 0f

      // If coin spawn interval has passed and we haven't reached MAX_COINS, spawn a new coin
      if lastCoinSpawnTime >= newCoinInterval && board.coinsNumber < Main.MAX_COINS then
        spawnNewCoin()
        lastCoinSpawnTime = 0f

    else if showingDialog then
      // Render the game board in background
      Draw.render(board)

    // Always update and draw the UI stage
    stage.act()
    stage.draw()

  override def dispose(): Unit =
    Draw.dispose()
    stage.dispose()
    skin.dispose()

  private def selectRandomPosition(positions: List[(Int, Int)]): Option[(Int, Int)] =
    if positions.nonEmpty then
      Some(positions(Random.nextInt(positions.length)))
    else
      None

  private def spawnNewCoin(): Unit =
    val emptyPositions = board.getEmptyTilePositions
    selectRandomPosition(emptyPositions) match
      case Some(position) => board.addCoin(position)
      case None => // No empty positions available, do nothing

  private def showScoreDialog(): Unit =
    showingDialog = true
    val score = board.snake.body.size
    val dialog = new Dialog("Game Over", skin)

    // Add score label to dialog
    val scoreLabel = new Label(s"Score: $score", skin)
    dialog.getContentTable.add(scoreLabel).pad(20f)

    // Add OK button
    val okButton = new TextButton("OK", skin)
    okButton.addListener(new ClickListener() {
      override def clicked(event: InputEvent, x: Float, y: Float): Unit = {
        // Exit the application when OK is clicked
        Gdx.app.exit()
      }
    })
    dialog.getButtonTable.add(okButton).pad(10f)

    // Show the dialog
    dialog.show(stage)


object Main:
  val BOARD_SIZE: Int = 8
  private val MAX_COINS: Int = 10

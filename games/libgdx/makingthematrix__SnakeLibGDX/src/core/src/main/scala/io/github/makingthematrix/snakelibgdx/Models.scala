package io.github.makingthematrix.snakelibgdx

enum SnakeDir (val x: Int, val y: Int):
  case Up extends SnakeDir(0, 1)
  case Right extends SnakeDir(1, 0)
  case Down extends SnakeDir(0, -1)
  case Left extends SnakeDir(-1, 0)

  def opposite(other: SnakeDir): Boolean =
    (this, other) match
      case (Up, Down) | (Down, Up) | (Left, Right) | (Right, Left) => true
      case _ => false

  def rotateClockwise: SnakeDir = this match
    case Up => Right
    case Right => Down
    case Down => Left
    case Left => Up

  def rotateCounterClockwise: SnakeDir = this match
    case Up => Left
    case Left => Down
    case Down => Right
    case Right => Up

final class Snake(val body: List[(x: Int, y: Int)], val snakeDir: SnakeDir, val hasCoin: Boolean = false):
  /** Returns true if the snake's head occupies the same position as any part of its body */
  def hasSelfCollision: Boolean = body match
    case head :: tail => tail.contains(head)
    case _ => false

  inline def addCoin: Snake = new Snake(body, snakeDir, true)
  inline def setHasCoin(newHasCoin: Boolean): Snake = new Snake(body, snakeDir, newHasCoin)

  inline def changeDirection(newDir: SnakeDir): Snake = new Snake(body, newDir, hasCoin)

  def crawl: Snake = body match
    case Nil =>
      // Empty body - create new head at (0,0) moved by snakeDir with wrapping
      val newHead = wrapCoordinate(snakeDir.x, snakeDir.y)
      new Snake(List(newHead), snakeDir, false) // hasCoin always false for new snake
    case head :: Nil =>
      // Single element - new head is current head moved by snakeDir with wrapping
      val newHead = wrapCoordinate(head.x + snakeDir.x, head.y + snakeDir.y)
      new Snake(List(newHead), snakeDir, false) // hasCoin always false for single element
    case head :: tail =>
      // Multiple elements - check hasCoin to determine if we grow or move normally
      val newHead = wrapCoordinate(head.x + snakeDir.x, head.y + snakeDir.y)
      if hasCoin then
        // Snake has coin - grow by not removing tail, set hasCoin to false
        val newBody = newHead :: body
        new Snake(newBody, snakeDir, false)
      else
        // Normal movement - remove last, add new head with wrapping
        val newBody = newHead :: body.init // init removes the last element
        new Snake(newBody, snakeDir, false)

  private def wrapCoordinate(x: Int, y: Int): (Int, Int) =
    val wrappedX = if x == -1 then Main.BOARD_SIZE - 1 else if x == Main.BOARD_SIZE then 0 else x
    val wrappedY = if y == -1 then Main.BOARD_SIZE - 1 else if y == Main.BOARD_SIZE then 0 else y
    (wrappedX, wrappedY)

object Snake:
  def apply(): Snake = new Snake(Nil, SnakeDir.Right, false)

  def apply(body: List[(x: Int, y: Int)], snakeDir: SnakeDir = SnakeDir.Right): Option[Snake] =
    if isContinuous(body) then
      // For now, default direction is Right - this could be enhanced to detect direction from body
      Some(new Snake(body, snakeDir, false))
    else
      None

  private def isContinuous(body: List[(x: Int, y: Int)]): Boolean =
    body match
      case Nil => true // Empty list is considered continuous
      case _ :: Nil => true // Single element is continuous
      case _ =>
        body.zip(body.tail).forall { case ((x1, y1), (x2, y2)) =>
          math.abs(x2 - x1) + math.abs(y2 - y1) == 1
        }

final class Board(val size: Int, private var coins: List[(x: Int, y: Int)] = Nil, private var _snake: Snake = Snake()):
  inline def coinsPositions: List[(x: Int, y: Int)] = coins
  inline def snake: Snake = _snake

  inline def coinsNumber: Int = coins.size
  inline def snakeLength: Int = _snake.body.size

  def updateSnake(newSnake: Snake): Unit =
    _snake = newSnake

  def update(): Unit =
    // First crawl the snake to new position
    _snake = _snake.crawl
    // Then check if the new snake head is on a coin position
    _snake.body.headOption.foreach { head =>
      if coins.contains(head) then
        _snake = _snake.addCoin
        coins = coins.filterNot(_ == head)
    }

  def getEmptyTilePositions: List[(Int, Int)] =
    val allPositions = for
      x <- 0 until size
      y <- 0 until size
    yield (x, y)

    val occupiedPositions = _snake.body.toSet ++ coins.toSet
    allPositions.filterNot(occupiedPositions.contains).toList

  def addCoin(position: (Int, Int)): Unit =
    if !coins.contains(position) && !_snake.body.contains(position) then
      coins = position :: coins

  def updateSnakeDirection(newDir: SnakeDir): Boolean =
    if !newDir.opposite(_snake.snakeDir) then
      _snake = _snake.changeDirection(newDir)
      true
    else
      false

  inline def hasSnakeSelfCollision: Boolean = _snake.hasSelfCollision

object Board:
  def apply(size: Int): Board = new Board(size)
  def apply(size: Int, coins: List[(x: Int, y: Int)]): Board = new Board(size, coins)
  def apply(size: Int, coins: List[(x: Int, y: Int)], snake: Snake): Board = new Board(size, coins, snake)


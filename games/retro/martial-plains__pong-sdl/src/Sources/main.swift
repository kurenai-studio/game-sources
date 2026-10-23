//
//  main.swift
//  PongSDL
//
//  Created by Allister Harvey on 6/19/23.
//

import SwiftSDL2
import Foundation

enum Direction: Int32 {
  case Left = -1
  case Right = 1
}

struct Dimension {
  var width, height: Int32
}

struct GameVideo {
  var window: OpaquePointer!
  var renderer: OpaquePointer!
  var dim: Dimension
}

struct Ball {
  var x: Float = 0.0
  var y: Float = 0.0
  var dx: Float = 0.0
  var dy: Float = 0.0
  var within: UnsafePointer<Dimension>! = nil

  static let size: Float = 20
  static let speed: Float = 11 * (Racket.speed / 10)
  static let msSpeed: Float = Float(Racket.speed) / 1000.0

}

struct Racket {
  var y: Float = 0.0
  var dy: Float = 0.0

  static let width: Float = 20
  static let height: Float = Racket.width * 3
  static let speed: Float = 550  // Pixels per second
  static let msSpeed: Float = Float(Racket.speed) / 1000.0
  static let hitbackMaxAngle: Float = 85.0 * Float.pi / 180.0

}

struct Score {
  var player: Int32 = 0
  var enemy: Int32 = 0
}

struct PlayState {
  var player: Racket = Racket()
  var enemy: Racket = Racket()
  var ball: Ball = Ball()
  var lastUpdateMS: UInt32 = 0
  var score: Score = Score()
  var frame: UnsafePointer<Dimension>! = nil
}

struct Game {
  var video: GameVideo
  var play: PlayState = PlayState()
}

struct DigitRenderingContext {
  var xOffset: Int32
  var direction: Direction
  var within: UnsafePointer<Dimension>
}

let maxHitDistance: Float = Float(Racket.height) / 2.0 + Float(Ball.size) / 2.0

enum Midline {
  static let pointWidth: Int32 = 3
  static let pointHeight: Int32 = 2 * Midline.pointWidth
  static let pointMargin: Int32 = 3
  static let padding: Int32 = 20
}

enum Fg {
  static let r: UInt8 = 255
  static let g: UInt8 = 255
  static let b: UInt8 = 255
  static let a: UInt8 = 255
}

enum Bg {
  static let r: UInt8 = 0
  static let g: UInt8 = 0
  static let b: UInt8 = 0
  static let a: UInt8 = 255
}

let enemyWaitTolerance = Racket.height / 5.0

let endScore = 30

struct Digit {
  static let pieceSize: Int32 = 7
  static let height: Int32 = 5  // In pieceSize units
  static let width: Int32 = 5  // In pieceSize units
  static let innerMargin: Int32 = 1  // In pieceSize units
  static let outerMargin: Int32 = 2  // In pieceSize units
}

let scoreDigits: [[[Character]]] = [
  [
    [" ", "*", "*", "*", " "],
    ["*", " ", " ", " ", "*"],
    ["*", " ", " ", " ", "*"],
    ["*", " ", " ", " ", "*"],
    [" ", "*", "*", "*", " "],
  ],
  [
    [" ", " ", " ", "*", " "],
    [" ", " ", " ", "*", " "],
    [" ", " ", " ", "*", " "],
    [" ", " ", " ", "*", " "],
    [" ", " ", " ", "*", " "],
  ],
  [
    ["*", "*", "*", "*", " "],
    [" ", " ", " ", "*", " "],
    ["*", "*", "*", "*", " "],
    ["*", " ", " ", " ", " "],
    ["*", "*", "*", "*", " "],
  ],
  [
    ["*", "*", "*", "*", " "],
    [" ", " ", " ", "*", " "],
    [" ", "*", "*", "*", " "],
    [" ", " ", " ", "*", " "],
    ["*", "*", "*", "*", " "],
  ],
  [
    ["*", " ", " ", "*", " "],
    ["*", " ", " ", "*", " "],
    ["*", "*", "*", "*", " "],
    [" ", " ", " ", "*", " "],
    [" ", " ", " ", "*", " "],
  ],
  [
    ["*", "*", "*", "*", " "],
    ["*", " ", " ", " ", " "],
    ["*", "*", "*", "*", " "],
    [" ", " ", " ", "*", " "],
    ["*", "*", "*", "*", " "],
  ],
  [
    ["*", "*", "*", "*", " "],
    ["*", " ", " ", " ", " "],
    ["*", "*", "*", "*", " "],
    ["*", " ", " ", "*", " "],
    ["*", "*", "*", "*", " "],
  ],
  [
    ["*", "*", "*", "*", " "],
    [" ", " ", " ", "*", " "],
    [" ", " ", " ", "*", " "],
    [" ", " ", " ", "*", " "],
    [" ", " ", " ", "*", " "],
  ],
  [
    ["*", "*", "*", "*", " "],
    ["*", " ", " ", "*", " "],
    ["*", "*", "*", "*", " "],
    ["*", " ", " ", "*", " "],
    ["*", "*", "*", "*", " "],
  ],
  [
    ["*", "*", "*", "*", " "],
    ["*", " ", " ", "*", " "],
    ["*", "*", "*", "*", " "],
    [" ", " ", " ", "*", " "],
    [" ", " ", " ", "*", " "],
  ],
]

var errorFn: UnsafePointer<CChar>? = nil

func initVideo(_ gv: inout GameVideo, title: String) {
  if SDL_Init(SDL_INIT_VIDEO) == 0 {
    gv.window = SDL_CreateWindow(
      title, Int32(SDL_WINDOWPOS_CENTERED_MASK),
      Int32(SDL_WINDOWPOS_CENTERED_MASK), gv.dim.width, gv.dim.height, SDL_WINDOW_SHOWN.rawValue)
    if gv.window != nil {
      gv.renderer = SDL_CreateRenderer(
        gv.window, -1, SDL_RENDERER_ACCELERATED.rawValue | SDL_RENDERER_PRESENTVSYNC.rawValue)
      if gv.renderer != nil {
        return
      }
      SDL_DestroyWindow(gv.window)
    }
    SDL_Quit()
  }
  errorFn = SDL_GetError()
}

func toggleBall(_ ball: inout Ball) {
  let angle =
    Float(Int32.random(in: 0..<RAND_MAX)) * Racket.hitbackMaxAngle * 2.0
    - Racket.hitbackMaxAngle
  ball.dy = sinf(angle)
  ball.dx = ball.dx < 0 ? cosf(angle) : -cosf(angle)
}

func resetPongBall(_ ball: inout Ball) {
  ball.x = Float(ball.within.pointee.width / 2) - Ball.size / 2.0
  ball.y = Float(ball.within.pointee.height / 2) - Ball.size / 2.0
  toggleBall(&ball)
}

func initPlay(_ p: inout PlayState, frame: UnsafePointer<Dimension>) {
  p.frame = frame
  p.enemy.y = Float(frame.pointee.height) / 2.0 - Racket.height / 2.0
  p.player.y = Float(frame.pointee.height) / 2.0 - Racket.height / 2.0
  p.ball.within = frame
  p.ball.dx = 0
  p.ball.dy = 0
  resetPongBall(&p.ball)
  p.score = Score(player: 0, enemy: 0)
}

func quitGame(_ game: inout Game) {
  SDL_DestroyRenderer(game.video.renderer)
  SDL_DestroyWindow(game.video.window)
  SDL_Quit()
}

func handleEvent(_ p: inout PlayState, _ e: inout SDL_Event) {
  if e.type == SDL_KEYDOWN.rawValue {
    switch e.key.keysym.sym {
    case Int32(SDLK_UP.rawValue):
      p.player.dy = -1
      return
    case Int32(SDLK_DOWN.rawValue):
      p.player.dy = 1
      return
    default:
      break
    }
  }
  p.player.dy = 0
}

func fclamp0(_ x: Float, _ max: Float) -> Float {
  return x > max ? max : (x < 0.0 ? 0.0 : x)
}

func moveRacket(_ r: inout Racket, _ deltaMS: UInt32, _ maxY: Float) {
  r.y += Float(deltaMS) * Racket.msSpeed * r.dy
  r.y = fclamp0(r.y, maxY)
}

func movePongBall(_ ball: inout Ball, _ deltaMs: UInt32) {
  ball.x += ball.dx * Float(deltaMs) * Ball.msSpeed
  ball.y += ball.dy * Float(deltaMs) * Ball.msSpeed
  ball.x = fclamp0(ball.x, Float(ball.within.pointee.width))
  ball.y = fclamp0(ball.y, Float(ball.within.pointee.height) - Ball.size)
}

func playMovements(_ p: inout PlayState, _ deltaMS: UInt32) {
  moveRacket(&p.player, deltaMS, Float(p.frame.pointee.height) - Racket.height)
  moveRacket(&p.enemy, deltaMS, Float(p.frame.pointee.height) - Racket.height)
  movePongBall(&p.ball, deltaMS)
}

func playEnemy(_ enemy: inout Racket, ball: inout Ball) {
  let middleY = enemy.y + Racket.height / 2.0
  let pongMiddleY = ball.y + Ball.size / 2.0
  let diff = middleY - pongMiddleY
  let absDiff = fabsf(diff)

  if absDiff <= enemyWaitTolerance {
    enemy.dy = 0
  } else {
    enemy.dy = -diff / absDiff
  }
}

func ballYHitsRacket(_ ball: inout Ball, _ racket: inout Racket) -> Bool {
  let by0 = ball.y
  let by1 = ball.y + Ball.size
  let ry0 = racket.y
  let ry1 = racket.y + Racket.height

  let happened = (ry0 < by0 && by0 < ry1) || (ry0 < by1 && by1 < ry1)
  if !happened {
    return false
  }

  let mby = by0 + Ball.size / 2.0
  let mry = ry0 + Racket.height / 2.0
  let midDistance = mry - mby
  let angle = Racket.hitbackMaxAngle * (midDistance / maxHitDistance)

  ball.dy = -sinf(angle)  // Y increases as you go down, not up.
  ball.dx = ball.dx < 0 ? cosf(angle) : -cosf(angle)

  return true
}

func score(_ ball: inout Ball, _ benefit: inout Int32) {
  benefit += 1
  resetPongBall(&ball)
}

func runCollisions(_ p: inout PlayState, _ deltaMs: UInt32) {
  let ball = p.ball
  var xp: Float
  var yp: Float  // These are x prime and y prime, the next (x,y) for ball.

  xp =
    ball.x + ball.dx
    * Float(
      deltaMs
    ) * Ball.msSpeed
  yp =
    ball.y + ball.dy
    * Float(
      deltaMs
    ) * Ball.msSpeed

  // The ball can collide with the top/bottom walls, in which case its dy changes sign.
  if yp > Float(p.frame.pointee.height) - Ball.size || yp < 0.0 {
    p.ball.dy = -ball.dy
  }

  // If a ball reaches the region before any racket...
  if xp < Racket.width {  // player
    if !ballYHitsRacket(&p.ball, &p.player) {
      score(&p.ball, &p.score.enemy)
    }
  } else if xp > Float(p.frame.pointee.width) - Racket.width - Ball.size {  // enemy
    if !ballYHitsRacket(&p.ball, &p.enemy) {
      score(&p.ball, &p.score.player)
    }
  }
}

func resetGame(_ p: inout PlayState) {
  p.lastUpdateMS = SDL_GetTicks()
  initPlay(&p, frame: p.frame)
}

func play(_ p: inout PlayState, _ nowMs: UInt32) {
  let deltaMS = nowMs - p.lastUpdateMS
  runCollisions(&p, deltaMS)
  playEnemy(&p.enemy, ball: &p.ball)
  playMovements(&p, deltaMS)
  p.lastUpdateMS = nowMs
}

func renderRacket(_ renderer: OpaquePointer?, _ x: Int32, _ y: Int32) {
  var racket = SDL_Rect(x: x, y: y, w: Int32(Racket.width), h: Int32(Racket.height))
  SDL_RenderFillRect(renderer, &racket)
}

func renderPongBall(_ renderer: OpaquePointer?, _ ball: UnsafePointer<Ball>) {
  var ballRect = SDL_Rect(
    x: Int32(ball.pointee.x), y: Int32(ball.pointee.y), w: Int32(Ball.size), h: Int32(Ball.size))
  SDL_RenderFillRect(renderer, &ballRect)
}

func midlineNpoints(_ screen: UnsafePointer<Dimension>) -> Int32 {
  let a = Int32(screen.pointee.height) - Midline.padding * 2 - Midline.pointHeight
  let b = Midline.pointMargin + Midline.pointHeight
  return 1 + a / b
}

func renderMidline(_ renderer: OpaquePointer?, _ screen: UnsafePointer<Dimension>) {
  var npoints = midlineNpoints(screen)
  var mpoint = SDL_Rect(
    x: screen.pointee.width / 2 - Midline.pointWidth / 2, y: Midline.padding, w: Midline.pointWidth,
    h: Midline.pointHeight)
  SDL_RenderFillRect(renderer, &mpoint)

  while npoints > 1 {
    mpoint.y += Midline.pointHeight + Midline.pointMargin
    SDL_RenderFillRect(renderer, &mpoint)
    npoints -= 1
  }
}

func renderDigit(
  _ renderer: OpaquePointer?, _ digit: Int, _ cx: UnsafePointer<DigitRenderingContext>
) {
  let graphic = scoreDigits[digit]
  var digitRect = SDL_Rect()
  var signOffset: Int32
  var accOffset: Int32
  var midlineX: Int32

  digitRect.w = Digit.pieceSize
  digitRect.h = Digit.pieceSize
  signOffset = Int32(cx.pointee.direction == .Left ? 0 : Digit.width * Digit.pieceSize)
  midlineX = Int32(cx.pointee.within.pointee.width) / 2
  accOffset = midlineX + Int32(cx.pointee.xOffset) + signOffset

  for i in 0..<Digit.height {
    for j in 0..<Digit.width {
      if graphic[Int(i)][Int(Digit.width - j) - 1] == "*" {
        digitRect.y = (Digit.outerMargin + i) * Digit.pieceSize
        digitRect.x = Int32(accOffset - (j + 1) * Digit.pieceSize)
        SDL_RenderFillRect(renderer, &digitRect)
      }
    }
  }
}

func is2digits(_ x: Int32) -> Bool {
  return x >= 10
}

func renderSingleScore(_ r: OpaquePointer?, score: Int32, _ cx: inout DigitRenderingContext) {
  var firstOffset: Int32
  var secondOffset: Int32

  assert(score >= 0)
  assert(score <= endScore)

  firstOffset = cx.direction.rawValue * Digit.outerMargin * Digit.pieceSize
  secondOffset =
    cx.direction.rawValue * Digit.pieceSize * (Digit.outerMargin + Digit.innerMargin + Digit.width)

  if is2digits(score) {
    if cx.direction == .Right {
      firstOffset = firstOffset ^ secondOffset
      secondOffset = firstOffset ^ secondOffset
      firstOffset = firstOffset ^ secondOffset
    }

    cx.xOffset = firstOffset
    renderDigit(r, Int(score) % 10, &cx)
    cx.xOffset = secondOffset
    renderDigit(r, Int(score) / 10, &cx)
  } else {
    cx.xOffset = firstOffset
    renderDigit(r, Int(score), &cx)
  }
}

func renderScore(_ r: OpaquePointer?, score: Score, screen: UnsafePointer<Dimension>) {
  var cx = DigitRenderingContext(xOffset: 0, direction: .Left, within: screen)
  renderSingleScore(r, score: score.player, &cx)
  cx.direction = .Right
  renderSingleScore(r, score: score.enemy, &cx)
}

func render(_ r: OpaquePointer?, _ p: inout PlayState) {
  SDL_SetRenderDrawColor(r, Bg.r, Bg.g, Bg.b, Bg.a)
  SDL_RenderClear(r)
  SDL_SetRenderDrawColor(r, Fg.r, Fg.g, Fg.b, Fg.a)
  renderRacket(r, 0, Int32(p.player.y))
  renderRacket(r, Int32(Float(p.frame.pointee.width) - Racket.width), Int32(p.enemy.y))
  renderPongBall(r, &(p.ball))
  renderMidline(r, p.frame)
  renderScore(r, score: p.score, screen: p.frame)
  SDL_RenderPresent(r)
}

func checkFinishRound(_ g: inout Game) {
  let s = g.play.score

  if s.player >= endScore || s.enemy >= endScore {
    SDL_ShowSimpleMessageBox(
      SDL_MESSAGEBOX_INFORMATION.rawValue, "End Round",
      s.player >= endScore
        ? "You won! Go another round."
        : "You lost. Try again.", g.video.window)
    resetGame(&g.play)
  }
}

func gameMain(_ g: inout Game) {
  let fps = 60
  let sec = 1000
  let maxWaitMS = sec / fps

  var e: SDL_Event = SDL_Event()
  var lastMS: UInt32
  var deltaMS: UInt32

  g.play.lastUpdateMS = SDL_GetTicks()

  while true {
    lastMS = SDL_GetTicks()
    while SDL_PollEvent(&e) != 0 {
      if e.type == SDL_QUIT.rawValue {
        return
      }
      handleEvent(&g.play, &e)
    }
    play(&g.play, SDL_GetTicks())
    render(g.video.renderer, &g.play)
    deltaMS = SDL_GetTicks() - lastMS
    if deltaMS < maxWaitMS {
      SDL_Delay(UInt32(maxWaitMS) - deltaMS)
    }
    checkFinishRound(&g)
  }
}

func runGame(_ g: inout Game, title: String) {
  initVideo(&g.video, title: title)
  if errorFn != nil {
    return
  }

  initPlay(&g.play, frame: &g.video.dim)
  gameMain(&g)
  quitGame(&g)
}

let title = "Pong"
var game = Game(video: GameVideo(dim: Dimension(width: 640, height: 480)))

runGame(&game, title: title)

if let error = errorFn {
  print("Error: \(String.init(cString: error))")
}

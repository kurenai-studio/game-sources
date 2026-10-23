# Game loop

The main loop follows the classic **input → update → render** pattern and is
**delta-time driven** (`dt`), so movement and physics are frame-rate
independent.

## Pseudocode

```
love.load():
    Game.init()                      # load paddle, level, UI, effects, sounds
    Game.sm = StateMachine.new(...)  # wire the six state modules
    Game.sm:switch("title")

love.update(dt):
    Game.input.left = love.keyboard.isDown("left", "a")
    Game.input.right = love.keyboard.isDown("right", "d")
    Game.sm:update(dt)               # delegate to the active state

love.draw():
    translate(Game.fx:shakeOffset()) # screen-shake offset only
    Game.sm:draw()                    # render the active state

love.keypressed(key):
    Game.sm:keypressed(key)          # movement stays in update; events go to states
```

## Play-state update

```
play.update(dt):
    paddle:update(dt, input)       # move from input intent
    Game:updateStuckBalls()        # keep the pre-launch ball on the paddle
    for each ball:
        integrate in sub-steps and resolve walls, paddle, and bricks
        remove it when fully below the screen
    if no balls remain:
        lives -= 1
        if lives == 0: state = GAMEOVER
        else: serve another ball in SERVE
    update power-ups, level, and effects
    if level.isComplete():
        load the next layout and SERVE, or switch to VICTORY on the final level
    ui:setHud(score, lives, level)
    # state = PAUSE: nothing advances
```

New games reset score to `0`, lives to `3`, and start at level `1`.

## Design rules

- Rendering (`draw`) never mutates game state; logic lives in `update(dt)`.
- All time-dependent behavior receives `dt` explicitly — no hard-coded
  per-frame values.
- The state machine is consulted at the start of `update` so paused or ended
  games do not advance.
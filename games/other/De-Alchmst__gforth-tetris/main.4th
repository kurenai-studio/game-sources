require random.fs


require raylib.4th
\ some stuff needs to run after rl:init-window \
  720 constant WINDOW-HEIGHT
  1024 constant WINDOW-WIDTH
  WINDOW-WIDTH WINDOW-HEIGHT s" tetris clone in gforth" rl:init-window
  0 value End?
  1e fvalue Max-countdown

require pice-handle.4th
require pices.4th
require field.4th
require game.4th
require pice-choice.4th
require pice-preview.4th
require draw-game.4th
require themes.4th
require name-input.4th
require scores.4th
require menu.4th
require draw-menu.4th
require draw-scores.4th
require save.4th
require io.4th \ <- game-reset is here

\ \ \ \ \ \ \ \ \ \
\ INITIALIZE STUFF \
\ \ \ \ \ \ \ \ \ \ \

: init ( -- )
  KEY-Q rl:set-exit-key
  60 rl:set-target-fps
  scores-init
  save-init
  reset-next-pice
  menu-init
  level-reset
;

\ \ \ \ \ \ \
\ GAME STUFF \
\ \ \ \ \ \ \ \
: handle-play ( r -- r ) \ timer
  \ don't update keys during animation
  Is-Animation? invert if read-keys-play then

  \ count the down
  rl:get-frame-time f+
  fdup Max-countdown f>
  if
    fdrop 0e
    game-update
    if
      \ go to the next pice
      add-current-pice next-pice
      \ if no space for new pice
      collision? if
        GAME-OVER to Game-mode
        register-score
      then
    then
  then

  \ if animation playing
  draw-game if fdrop 0e then
;

: handle-game-over ( r -- 0e ) \ timer
  read-keys-game-over
  draw-game-over

  fdrop 0e \ keep timer at 0
;

: handle-menu ( r -- 0e )
  read-keys-menu
  draw-menu

  fdrop 0e \ keep timer at 0
;

: handle-scores ( r -- 0e )
  read-keys-scores
  draw-scores

  fdrop 0e
;

: handle-pause ( r -- 0e )
  read-keys-pause
  draw-pause
;

: handle-name-input ( -- )
  read-keys-name-input
  name-read
  draw-scores
;

\ \ \ \ \ \ \ \
\ MAIN LOOPING \
\ \ \ \ \ \ \ \ \
: main ( -- )
  0e \ countdown
  begin
    rl:window-should-close End? or
    if save-write bye then

    Game-mode case
      MENU of handle-menu endof
      PLAYING of handle-play endof
      GAME-OVER of handle-game-over endof
      SCORES of handle-scores endof
      PAUSED of handle-pause endof
      NAME-INPUT of handle-name-input endof
    endcase
  again
;

\ \ \ \ \ \ \ \ \ \
\ call upon start \
\ \ \ \ \ \ \ \ \ \

init main

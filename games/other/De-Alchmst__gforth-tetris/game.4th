0 constant LEFT
-1 constant RIGHT

0 constant MENU
1 constant PLAYING
2 constant GAME-OVER
3 constant SCORES
4 constant PAUSED
5 constant NAME-INPUT

0 value Show-next?

1 value Selected-level
1 value Level
10 value To-next-level

0 value Score
0 value Drop-bonus

MENU value Game-mode

: set-max-countdown ( -- )
  1e Level s>f f/ to Max-countdown ;

: to-first-level ( -- )
  Selected-level 10 * to To-next-level ;

: level-reset ( -- )
  Selected-level to Level
  set-max-countdown
  to-first-level
;

: change-level ( f -- ) \ -1 increase
  if 
    Selected-level 1+ 10 mod dup to Selected-level
    0= if 1 to Selected-level then
  else
    Selected-level dup 1 = if drop 10 then 1- to Selected-level
  then

  level-reset
;

: add-row-to-level ( -- )
  Level 9 < if
    To-next-level 1-
    dup to To-next-level
    0= if
      10 to To-next-level
      1 +to Level
      set-max-countdown
    then
  then
;

: wall-collision? ( -- f )
  Pice-X Pice-off-X + 0<
  Pice-X Pice-width + COLS >
  Pice-Y Pice-height + ROWS >
  or or
;

: block-collision? ( -- f )
  16 0 ?do
    Pice-buffer i + c@
    if
      i pice-to-field-ind c@
      if
        -1 unloop exit
      then
    then
  loop
  0
;

: collision? ( -- f )
  wall-collision? block-collision? or ;

: move-pice-sideways ( f -- ) \ direction
  dup if
    1  +to Pice-X
  else
    -1 +to Pice-X
  then

  collision?
  if
    if
      -1 +to Pice-X
    else
      1  +to Pice-X
    then
  else
    drop
  then
;

: rotate-pice ( f -- ) \ direction
  dup if
    rotate-pice-right
  else
    rotate-pice-left
  then
  Pice-rotation pice-set-word execute

  collision?
  if
    if
      rotate-pice-left
    else
      rotate-pice-right
    then
    Pice-rotation pice-set-word execute
  else
    drop
  then
;

: move-pice-down ( -- f )
  1 +to Pice-Y

  collision?
  dup if
    -1 +to Pice-Y
  then
;

: drop-pice ( -- )
  Drop-bonus
  begin
    1+
    move-pice-down invert
  while repeat
  1- to Drop-bonus
;

: count-score ( -- )
  Drop-bonus 1+
  Show-next? if 1+ 2/ then
  Level *
  +to Score

  0 to Drop-bonus
;

: game-update ( -- f )
  move-pice-down
  dup if count-score then
;

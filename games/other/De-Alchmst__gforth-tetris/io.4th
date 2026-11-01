: reset-game ( -- )
  reset-pice-count
  clear-field
  reset-next-pice
  PLAYING to Game-mode
  0 to Score
  level-reset
;

: read-keys-play ( -- )
  begin
    \ read through all qued keys (0 on end)
    rl:get-key-pressed
    dup
  while
    case
      \ pice movement \
      KEY-J of
        LEFT move-pice-sideways
      endof
      KEY-L of
        RIGHT move-pice-sideways
      endof

      \ rotation \
      KEY-K of
        RIGHT rotate-pice
      endof

      \ drop \
      KEY-SPACE of
        drop-pice
      endof

      \ pause \
      KEY-P of
        PAUSED to Game-mode
      endof

      \ debug \
      \ KEY-E of
      \   GAME-OVER to Game-mode
      \ endof
    endcase
  repeat
  drop
;

: read-keys-game-over ( -- )
  begin
    \ read through all qued keys (0 on end)
    rl:get-key-pressed
    dup
  while
    case
      KEY-R of
        reset-game
      endof

      KEY-M of
        reset-game
        MENU to Game-mode
      endof

      KEY-S of
        GAME-OVER to Prev-mode
        SCORES to Game-mode
      endof
    endcase
  repeat
  drop
; 

: read-keys-menu ( -- )
  begin
    \ read through all qued keys (0 on end)
    rl:get-key-pressed
    dup
  while
    case
      \ select \
      dup KEY-ENTER = over KEY-SPACE = or ?of
        drop
        menu-select
      endof

      \ move selection \
      dup KEY-J = over KEY-DOWN = or ?of
        drop
        menu-next
      endof

      dup KEY-K = over KEY-UP = or ?of
        drop
        menu-prev
      endof

      \ select-sideways \
      dup KEY-H = over KEY-LEFT = or ?of
        drop
        LEFT menu-sideways
      endof

      dup KEY-L = over KEY-RIGHT = or ?of
        drop
        RIGHT menu-sideways
      endof
    endcase
  repeat
  drop
;

: read-keys-scores ( -- )
  begin
    \ read through all qued keys (0 on end)
    rl:get-key-pressed
    dup
  while
    Prev-mode to Game-mode
  repeat
  drop
;

: read-keys-pause ( -- )
  begin
    \ read through all qued keys (0 on end)
    rl:get-key-pressed
    dup
  while
    PLAYING to Game-mode
  repeat
  drop
;

: read-keys-name-input ( -- )
  begin
    \ read through all qued keys (0 on end)
    rl:get-key-pressed
    dup
  while
    case
      KEY-BACKSPACE of
        name-backspace
      endof

      KEY-ENTER of
        Name-length 0> if
          GAME-OVER to Game-mode
          0 to Name-length
        then
      endof
    endcase
  repeat
  drop
;

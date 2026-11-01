\ FILE LAYOUT
\  1 byte  : level
\  1 byte  : theme
\  1 byte  : show-next
\  1 byte  : animation-speed
\  4 bytes : reserved for futre use
\ 
\ ( 10 times: )
\  8 bytes : score
\ 24 bytes : player name (null terminated => 23 usable)
\
\ players are sorted from highest score to the lovest

\ \ \ \ \ \ \ \ \ \ \ \ \
\ GET SAVE FILE ADDRESS \
\ \ \ \ \ \ \ \ \ \ \ \ \

\ get dir
sourcefilename dirname 
\ allocate spcae
create SAVE-FILE-NAME dup 8 + allot
dup 8 + constant SAVE-FILE-LENGTH

\ add last part
dup SAVE-FILE-NAME + s" save.dat" rot swap move

\ add dir part
SAVE-FILE-NAME swap move

: save.dat ( -- a u)
  SAVE-FILE-NAME SAVE-FILE-LENGTH ;

\ \ \ \ \ \ \
\ OPARATIONS \
\ \ \ \ \ \ \ \

: save-write ( -- )
  save.dat w/o open-file throw
  Selected-level over emit-file throw
  Selected-theme over emit-file throw
  Show-next? over emit-file throw
  Animation-speed over emit-file throw

  \ reserverd space
  dup s\" \0\0\0\0" rot write-file throw

  \ scores
  10 0 ?do
    \ write score
    dup
    Scores-values i cells + 1 cells rot write-file throw
    \ write name
    dup
    Scores-names i 3 * cells + 3 cells rot write-file throw
  loop

  close-file throw
;

: save-load ( -- )
  save.dat slurp-file drop
  dup     c@ to Selected-level
  dup 1 + c@ to Selected-theme
  dup 2 + c@ to Show-next?
  dup 3 + c@ to Animation-speed

  \ scores
  10 0 ?do
    \ score
    dup i 4 * 1+ cells + @
    Scores-values i cells + !

    \ name
    dup i 4 * 2 + cells +
    Scores-names i 3 * cells +
    3 cells move
  loop

  free throw
;

: save-init ( -- )
  save.dat w/o open-file
  0= if \ file found
    close-file throw save-load
  else \ file not found
    drop
    save.dat w/o create-file throw drop
    save-write
  then
;

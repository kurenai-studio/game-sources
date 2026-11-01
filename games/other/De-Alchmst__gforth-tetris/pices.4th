: set-pice-I ( n -- ) \ rot
  dup UP-ROT = swap DOWN-ROT = or
  if
    \ 0 0 0 0
    \ 1 1 1 1
    \ 0 0 0 0
    \ 0 0 0 0
    0 4 2 pice-size!
    4 5 6 7 1 pice-buffer!
  else
    \ 0 1 0 0
    \ 0 1 0 0
    \ 0 1 0 0
    \ 0 1 0 0
    1 2 4 pice-size!
    1 5 9 13 1 pice-buffer!
  then
;

: set-pice-J ( n -- )
  case
    UP-ROT of
      \ 0 0 0 0
      \ 2 2 2 0
      \ 0 0 2 0
      \ 0 0 0 0
      0 3 3 pice-size!
      4 5 6 10 2 pice-buffer!
    endof

    RIGHT-ROT of
      \ 0 2 2 0
      \ 0 2 0 0
      \ 0 2 0 0
      \ 0 0 0 0
      1 3 3 pice-size!
      1 2 5 9 2 pice-buffer!
    endof

    DOWN-ROT of
      \ 2 0 0 0
      \ 2 2 2 0
      \ 0 0 0 0
      \ 0 0 0 0
      0 3 2 pice-size!
      0 4 5 6 2 pice-buffer!
    endof

    LEFT-ROT of
      \ 0 2 0 0
      \ 0 2 0 0
      \ 2 2 0 0
      \ 0 0 0 0
      0 2 3 pice-size!
      1 5 8 9 2 pice-buffer!
    endof
  endcase
;

: set-pice-L ( n -- )
  case
    UP-ROT of
      \ 0 0 0 0
      \ 3 3 3 0
      \ 3 0 0 0 
      \ 0 0 0 0
      0 3 3 pice-size!
      4 5 6 8 3 pice-buffer!
    endof

    RIGHT-ROT of
      \ 0 3 0 0
      \ 0 3 0 0
      \ 0 3 3 0
      \ 0 0 0 0
      1 3 3 pice-size!
      1 5 9 10 3 pice-buffer!
    endof

    DOWN-ROT of
      \ 0 0 3 0
      \ 3 3 3 0
      \ 0 0 0 0
      \ 0 0 0 0
      0 3 2 pice-size!
      2 4 5 6 3 pice-buffer!
    endof

    LEFT-ROT of
      \ 3 3 0 0
      \ 0 3 0 0
      \ 0 3 0 0
      \ 0 0 0 0
      0 2 3 pice-size!
      0 1 5 9 3 pice-buffer!
    endof
  endcase
;

: set-pice-T ( n -- )
  case
    UP-ROT of
      \ 0 0 0 0
      \ 4 4 4 0
      \ 0 4 0 0
      \ 0 0 0 0
      0 3 3 pice-size!
      4 5 6 9 4 pice-buffer!
    endof

    RIGHT-ROT of
      \ 0 4 0 0
      \ 0 4 4 0
      \ 0 4 0 0
      \ 0 0 0 0
      1 3 3 pice-size!
      1 5 6 9 4 pice-buffer!
    endof

    DOWN-ROT of
      \ 0 4 0 0
      \ 4 4 4 0
      \ 0 0 0 0
      \ 0 0 0 0
      0 3 2 pice-size!
      1 4 5 6 4 pice-buffer!
    endof

    LEFT-ROT of
      \ 0 4 0 0
      \ 4 4 0 0
      \ 0 4 0 0
      \ 0 0 0 0
      0 2 3 pice-size!
      1 4 5 9 4 pice-buffer!
    endof
  endcase
;

: set-pice-O ( n -- )
  drop
  \ 5 5 0 0
  \ 5 5 0 0
  \ 0 0 0 0
  \ 0 0 0 0
  0 2 2 pice-size!
  0 1 4 5 5 pice-buffer!
;

: set-pice-S ( n -- )
  dup UP-ROT = swap DOWN-ROT = or
  if
    \ 0 6 6 0
    \ 6 6 0 0
    \ 0 0 0 0
    \ 0 0 0 0
    0 3 2 pice-size!
    1 2 4 5 6 pice-buffer!
  else
    \ 0 6 0 0
    \ 0 6 6 0
    \ 0 0 6 0
    \ 0 0 0 0
    1 3 3 pice-size!
    1 5 6 10 6 pice-buffer!
  then
;

: set-pice-Z ( n -- )
  dup UP-ROT = swap DOWN-ROT = or
  if
    \ 7 7 0 0
    \ 0 7 7 0
    \ 0 0 0 0
    \ 0 0 0 0
    0 3 2 pice-size!
    0 1 5 6 7 pice-buffer!
  else
    \ 0 7 0 0
    \ 7 7 0 0
    \ 7 0 0 0
    \ 0 0 0 0
    0 2 3 pice-size!
    1 4 5 8 7 pice-buffer!
  then
;

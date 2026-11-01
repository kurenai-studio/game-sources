10 constant COLS
20 constant ROWS

create Game-field COLS ROWS * allot
create Rows-to-break 4 cells allot
0 value Rows-to-break-len

: clear-field ( -- )
  COLS ROWS * 0 ?do
    0 Game-field i + c!
  loop
;

: rows-to-break-push ( n -- )
  \ shift current entries
  0 Rows-to-break-len ?do
    Rows-to-break i 1- cells + @
    Rows-to-break i cells + !
  1 -loop

  Rows-to-break !
  1 +to Rows-to-break-len
;

: rows-to-break-shift ( -- n )
  -1 +to Rows-to-break-len
  Rows-to-break Rows-to-break-len cells + @
;

: rows-to-break-row ( -- n )
  Rows-to-break Rows-to-break-len 1- cells + @
  COLS / 
;

: pice-to-field-ind ( n -- n )
  dup 4 mod Pice-X +
  swap 4 / Pice-Y + COLS * +
  Game-field +
;

: downshift-field ( n -- ) \ index of beginning of removed line
  -1 swap 1- ?do \ don't move last one, will appear on line bellow
    Game-field i + c@
    Game-field i + COLS + c!
  1 -loop

  \ clear top line
  COLS 0 ?do 0 Game-field i + c! loop
;

: remove-lines ( -- )
  \ go through all rows
  ROWS 0 ?do
    i COLS *
    -1 \ mark as full
    COLS 0 ?do
      \ decide otherwise if 0 found
      over i + Game-field + c@
      0= if
        drop 0 leave
      then
    loop

    \ if full, add to queue
    if rows-to-break-push else drop then
      
  loop
;

: add-current-pice ( -- )
  16 0 ?do
    Pice-buffer i + c@

    dup if
      \ transform to position in Game-field
      i pice-to-field-ind c!
    else
      drop
    then
  loop

  remove-lines
;

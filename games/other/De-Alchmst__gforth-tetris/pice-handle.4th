0 value Pice-X
0 value Pice-Y
0 value Pice-width
0 value Pice-height
0 value Pice-off-X

\ word used to set the pice to buffer
0 value Pice-set-word

0 value Pice-rotation
0 constant UP-ROT
1 constant RIGHT-ROT
2 constant DOWN-ROT
3 constant LEFT-ROT

variable Pice-buffer 16 allot \ 4 * 4 chars

: clear-pice-buffer ( -- )
  14 0 ?do
    0 Pice-buffer i + c!
  loop
;

: pice-buffer! ( n n n n cl -- )
  clear-pice-buffer
  4 0 ?do
    dup rot Pice-buffer + c!
  loop
  drop
;

: pice-size! ( offx x y -- )
  to Pice-height
  to Pice-width
  to Pice-off-X
;

: rotate-pice-left ( -- )
  Pice-rotation 1-
  dup 0< if drop 3 then
  to Pice-rotation
;


: rotate-pice-right ( -- )
  Pice-rotation 1+ 4 mod
  to Pice-rotation
;

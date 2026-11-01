0 constant I-PICE
1 constant J-PICE
2 constant L-PICE
3 constant T-PICE
4 constant O-PICE
5 constant S-PICE
6 constant Z-PICE

0 value I-pice-count
0 value J-pice-count
0 value L-pice-count
0 value T-pice-count
0 value O-pice-count
0 value S-pice-count
0 value Z-pice-count

0 value Next-pice-shape

variable Next-pice-buffer 16 allot \ 4 * 4 chars

: reset-pice-count ( -- )
  0 to I-pice-count
  0 to J-pice-count
  0 to L-pice-count
  0 to T-pice-count
  0 to O-pice-count
  0 to S-pice-count
  0 to Z-pice-count
;

: random-next-pice ( -- )
  7 random to Next-pice-shape ;

: next-pice ( -- )
  \ set word to update with
  \ and add co pice counter
  Next-pice-shape case
    I-PICE of
      1 +to I-pice-count
      ['] set-pice-I
    endof
    J-PICE of
      1 +to J-pice-count
      ['] set-pice-J
    endof
    L-PICE of
      1 +to L-pice-count
      ['] set-pice-L
    endof
    T-PICE of
      1 +to T-pice-count
      ['] set-pice-T
    endof
    O-PICE of
      1 +to O-pice-count
      ['] set-pice-O
    endof
    S-PICE of
      1 +to S-pice-count
      ['] set-pice-S
    endof
    Z-PICE of
      1 +to Z-pice-count
      ['] set-pice-Z
    endof
  endcase
  to Pice-set-word

  \ reset variables
  UP-ROT to Pice-rotation
  0 to Pice-Y

  \ to get width and offset
  UP-ROT Pice-set-word execute

  COLS Pice-width - Pice-off-X - 2/ to Pice-X
  
  random-next-pice
;

: reset-next-pice ( -- )
  random-next-pice next-pice ;

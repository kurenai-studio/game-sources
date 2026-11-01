\ \ \ \
\ VARS \
\ \ \ \ \
0 value Prev-mode

create Scores-values 10 cells allot
create Scores-names  30 cells allot

\ adds empty entries to Scores-names
: scores-init ( -- )
  10 0 ?do
    s\" ---NO-ONE---\0"
    Scores-names i 3 cells * + swap move
  loop
;

: shift-scores ( n -- )
  dup 9 = if exit then
  9 ?do
    \ numbers
    Scores-values i 1- cells + @
    Scores-values i cells + !
    \ names
    Scores-names i 1- 3 * cells +
    Scores-names i 3 * cells +
    3 cells move
  1 -loop
;

: add-score ( n n -- ) \ score ind
  cells Scores-values + ! ;

: register-score ( -- )
  Score
  10 0 ?do
    dup Scores-values i cells + @
    > if
      i shift-scores
      i add-score

      Scores-names i 3 * cells + to Name-buffer
      clear-name
      NAME-INPUT to Game-mode
      unloop exit
    then
  loop
  drop
;

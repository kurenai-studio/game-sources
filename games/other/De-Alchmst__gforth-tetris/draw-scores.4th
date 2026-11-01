\ \ \ \ \ \ \
\ VARIABLES \
\ \ \ \ \ \ \
s\" :\0" drop SECONDARY-TEXT-SIZE rl:measure-text
WINDOW-WIDTH swap - 2/ constant COLON-X

30 constant COLON-PADDING
20 constant SCORE-GAPS
WINDOW-HEIGHT
  10 SECONDARY-TEXT-SIZE * -
  9 SCORE-GAPS * -
  2/ constant SCORES-OFFSET

\ \ \ \ \ \
\ DRAWING \
\ \ \ \ \ \

: get-scores-Y ( n -- n )
  SCORES-OFFSET swap SECONDARY-TEXT-SIZE SCORE-GAPS + * + ;

: draw-colon ( n -- )
  s" :" rot COLON-X
  swap get-scores-Y
  SECONDARY-TEXT-SIZE Fg-color rl:draw-text-len
;

: draw-name ( n -- )
  dup 3 * cells Scores-names + \ str
  dup SECONDARY-TEXT-SIZE rl:measure-text 
    WINDOW-WIDTH 2/ swap - COLON-PADDING - \ X
  rot get-scores-Y \ Y
  SECONDARY-TEXT-SIZE Fg-color rl:draw-text
;

: draw-single-score ( n -- )
  dup cells Scores-values + @ s>d <# #s #> \ str
  rot WINDOW-WIDTH 2/ COLON-PADDING + \ X
  swap get-scores-Y \ Y
  SECONDARY-TEXT-SIZE Fg-color rl:draw-text-len
;

: draw-scores ( -- )
  rl:begin-drawing
  draw-bg
  10 0 ?do
    i
    dup draw-colon
    dup draw-name
        draw-single-score
  loop
  rl:end-drawing
;

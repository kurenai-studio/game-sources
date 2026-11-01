3 cells 1- constant MAX-NAME-LENGTH
0 value Name-length

0 value Name-buffer

: clear-name ( -- )
  3 0 ?do 
    0 Name-buffer i cells + !
  loop
;

: name-read ( -- )
  begin
    rl:get-char-pressed
    dup
  while
    dup 32 >= over 126 <= and \ only ascii symbols
    Name-length MAX-NAME-LENGTH < and \ max length
    over 32 <> Name-length 0 > or and \ don't begin with space
    if
      Name-buffer Name-length + c!
      1 +to Name-length
    then
  repeat
  drop
;

: name-backspace ( -- )
  Name-length dup 0> if
    1- to Name-length
    0 Name-buffer Name-length + c!
  else
    drop
  then
;

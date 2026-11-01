\ \ \ \ \ \ \
\ MENU PARTS \
\ \ \ \ \ \ \ \
: draw-options ( -- )
  MENU-LENGTH 0 ?do
    \ text part \
    Menu-texts i cells + @ \ text
    Menu-rects i rectangle% * +
    dup rectangle-y sf@
    rectangle-x sf@
    f>s MENU-RECT-PADDING + f>s MENU-RECT-PADDING + \ X Y
    MAIN-TEXT-SIZE

    \ possible selection \
    i Selected-menu-option <>
    if
      Fg-color rl:draw-text
    else
      Menu-rects i rectangle% * + Fg-color rl:draw-rectangle-rec
      Bg-color rl:draw-text
    then
  loop
;

\ \ \ \ \ \ \ \ \ \ \ \ \
\ PUT ALL STUFF TOGETHER \
\ \ \ \ \ \ \ \ \ \ \ \ \ \
: draw-menu ( -- )
  rl:begin-drawing
  draw-bg
  draw-options
  rl:end-drawing
;

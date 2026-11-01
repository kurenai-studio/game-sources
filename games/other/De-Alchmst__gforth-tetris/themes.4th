0 value Selected-theme
6 constant THEME-LENGTH
create THEME-TEXTS
  s\" < THEME: Light >\0" drop ,
  s\" < THEME: Dark >\0" drop ,
  s\" < THEME: Darker >\0" drop ,
  s\" < THEME: APERTURE >\0" drop ,
  s\" < THEME: H4x0r >\0" drop ,
  s\" < THEME: Kanagawa >\0" drop ,

255 176 0 255 >color constant APERTURE-COLOR

\ kanagawa theme: https://github.com/rebelot/kanagawa.nvim
$1f $1f $28 255 >color constant K-BG
$dc $d7 $ba 255 >color constant K-FG
$c3 $40 $43 255 >color constant K-RED
$98 $bb $6c 255 >color constant K-GREEN
$e6 $c3 $84 255 >color constant K-YELLOW
$d2 $7e $99 255 >color constant K-PINK
$7f $b4 $ca 255 >color constant K-BLUE
$93 $81 $a9 255 >color constant K-MAGENTA
$7a $a8 $9f 255 >color constant K-CYAN
$e8 $24 $24 255 >color constant K-BRIGHT-RED
$e9 $8a $00 255 >color constant K-ORANGE

: beam-color! ( a -- )
  Beam-color
  over color-r c@ over color-r c!
  over color-g c@ over color-g c!
  swap color-b c@ swap color-b c!
;

: default-colors ( -- )
  WHITE to Bg-color
  GRAY to Fg-color

  RED to I-color
  YELLOW to J-color
  PURPLE to L-color
  PINK to T-color
  SKYBLUE to O-color
  GREEN to S-color
  BLUE to Z-color

  DEF-MESSAGE-RECT-COLOR to Message-rect-color
  RED to Message-text-color

  GOLD beam-color!
;

: all-pices-color! ( a -- )
  dup to I-color
  dup to J-color
  dup to L-color
  dup to T-color
  dup to O-color
  dup to S-color
      to Z-color
;

: apply-theme ( -- )
  Selected-theme case
    0 of \ LIGHT
      default-colors
    endof
    1 of \ DARK
      default-colors
      DARKGRAY to Bg-color
      BLACK to Fg-color
    endof
    2 of \ DARKER
      default-colors
      BLACK to Bg-color
      GRAY to Fg-color
    endof
    3 of \ APERTURE
      BLACK to Bg-color
      APERTURE-COLOR to Fg-color
      APERTURE-COLOR all-pices-color!
      BLACK beam-color!
      BLACK to Message-rect-color
      APERTURE-COLOR to Message-text-color
    endof
    4 of \ H4X0R
      BLACK to Bg-color
      DARKGREEN to Fg-color
      GREEN all-pices-color!
      DARKGREEN beam-color!
      DARKGREEN to Message-rect-color
      GREEN to Message-text-color
    endof
    5 of \ KANAGAWA
      K-BG to Bg-color
      K-FG to Fg-color

      K-RED to I-color
      K-YELLOW to J-color
      K-MAGENTA to L-color
      K-PINK to T-color
      K-CYAN to O-color
      K-GREEN to S-color
      K-BLUE to Z-color

      DEF-MESSAGE-RECT-COLOR to Message-rect-color
      K-BRIGHT-RED to Message-text-color

      K-ORANGE beam-color!
    endof
  endcase
;

: change-theme ( f -- ) \ -1 right
  if
    Selected-theme 1+ THEME-LENGTH mod to Selected-theme
  else
    Selected-theme dup 0= if drop THEME-LENGTH then 1- to Selected-theme
  then

  apply-theme
;

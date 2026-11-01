c-library raylib
s" raylib" add-lib

\c #include "raylib.h"

\ \ \ \ \ \ \
\ FUNCTIONS \
\ \ \ \ \ \ \

\ window \
c-function rl:init-window InitWindow n n s -- void ( width height name -- )
c-function rl:close-window CloseWindow -- void
c-function rl:window-should-close WindowShouldClose -- n

\ fps \
c-function rl:set-target-fps SetTargetFPS n -- void
c-function rl:get-frame-time GetFrameTime -- r

\ drawing \
c-function rl:begin-drawing BeginDrawing -- void
c-function rl:end-drawing EndDrawing -- void

c-function rl:clear-background ClearBackground a{*(Color*)} -- void

c-function rl:draw-rectangle-lines-ex DrawRectangleLinesEx a{*(Rectangle*)} r a{*(Color*)} -- void ( rect thickness color -- )
c-function rl:draw-rectangle-rec DrawRectangleRec a{*(Rectangle*)} a{*(Color*)} -- void
c-function rl:draw-rectangle-lines DrawRectangleLines n n n n a{*(Color*)} -- void ( x y w h color )
c-function rl:draw-rectangle DrawRectangle n n n n a{*(Color*)} -- void ( x y w h color )

\ text \
c-function rl:draw-text DrawText a n n n a{*(Color*)} -- void ( str x y size color )
c-function rl:draw-text-len DrawText s n n n a{*(Color*)} -- void ( str x y size color )
c-function rl:measure-text MeasureText a n -- n ( str size -- length )

\ keys \
\ c-function rl:is-key-down IsKeyDown n -- n
\ c-function rl:is-key-down IsKeyUp n -- n
\ c-function rl:is-key-down IsKeyPressed n -- n
\ c-function rl:is-key-down IsKeyReleased n -- n
c-function rl:get-key-pressed GetKeyPressed -- n
c-function rl:get-char-pressed GetCharPressed -- n
c-function rl:set-exit-key SetExitKey n -- void
\ \ \ \ \ \
\ STURCTS \
\ \ \ \ \ \

\ https://github.com/ArnautDaniel/gforth-raylib/blob/master/raylib3.fs

begin-structure color%
  cfield: color-r
  cfield: color-g
  cfield: color-b
  cfield: color-a
end-structure

begin-structure rectangle%
  lfield: rectangle-x
  lfield: rectangle-y
  lfield: rectangle-width
  lfield: rectangle-height
end-structure

\ \ \ \ \
\ COLORS \
\ \ \ \ \ \

\ https://github.com/ArnautDaniel/gforth-raylib/blob/master/raylib3.fs


: >Color ( r g b a -- Color )
    Color% allocate throw { col }
    col Color-a c!
    col Color-b c!
    col Color-g c!
    col Color-r c! col ;


200 200 200 255 >Color Constant LIGHTGRAY
130 130 130 255 >Color Constant GRAY
80 80 80 255	  >Color Constant DARKGRAY
253 249 0 255	  >Color Constant YELLOW
255 203 0 255	  >Color Constant GOLD
255 161 0 255	  >Color Constant ORANGE
255 109 194 255 >Color Constant PINK
230 41 55 255	  >Color Constant RED
190 33 55 255	  >Color Constant MAROON
0 228 48 255	  >Color Constant GREEN
0 158 47 255	  >Color Constant LIME
0 117 44 255	  >Color Constant DARKGREEN
102 191 241 255 >Color Constant SKYBLUE
0 121 241 255	  >Color Constant BLUE
0 82 172 255	  >Color Constant DARKBLUE
200 122 255 255 >Color Constant PURPLE
135 60 190 255	>Color Constant VIOLET
112 31 126 255	>Color Constant DARKPURPLE
211 176 131 255 >Color Constant BEIGE
127 106 79 255	>Color Constant BROWN
76 63 47 255	  >Color Constant DARKBROWN
255 255 255 255 >Color Constant WHITE
0 0 0 255	      >Color Constant BLACK
0 0 0 0		      >Color Constant BLANK
255 0 255 255	  >Color Constant MAGENTA
245 245 245 255 >Color Constant RAYWHITE

\ \ \ \
\ KEYS \
\ \ \ \ \

\ https://github.com/ArnautDaniel/gforth-raylib/blob/master/raylib3.fs

39	constant KEY-APOSTROPHE
44	constant KEY-COMMA
45	constant KEY-MINUS
46	constant KEY-PERIOD
47	constant KEY-SLASH
48	constant KEY-ZERO
49	constant KEY-ONE
50	constant KEY-TWO
51	constant KEY-THREE
52	constant KEY-FOUR
53	constant KEY-FIVE
54	constant KEY-SIX
55	constant KEY-SEVEN
56	constant KEY-EIGHT
57	constant KEY-NINE
59	constant KEY-SEMICOLON
61	constant KEY-EQUAL
65	constant KEY-A
66	constant KEY-B
67	constant KEY-C
68	constant KEY-D
69	constant KEY-E
70	constant KEY-F

71	constant KEY-G
72	constant KEY-H
73	constant KEY-I
74	constant KEY-J
75	constant KEY-K
76	constant KEY-L
77	constant KEY-M
78	constant KEY-N
79	constant KEY-O
80	constant KEY-P
81	constant KEY-Q
82	constant KEY-R
83	constant KEY-S
84	constant KEY-T
85	constant KEY-U
86	constant KEY-V
87	constant KEY-W
88	constant KEY-X
89	constant KEY-Y
90	constant KEY-Z
32	constant KEY-SPACE
256	constant KEY-ESCAPE
257	constant KEY-ENTER
258	constant KEY-TAB
259	constant KEY-BACKSPACE
260	constant KEY-INSERT
261	constant KEY-DELETE
262	constant KEY-RIGHT
263	constant KEY-LEFT
264	constant KEY-DOWN
265	constant KEY-UP
266	constant KEY-PAGE-UP
267	constant KEY-PAGE-DOWN
268	constant KEY-HOME
269	constant KEY-END
280	constant KEY-CAPS-LOCK
281	constant KEY-SCROLL-LOCK
282	constant KEY-NUM-LOCK
283	constant KEY-PRINT-SCREEN
284	constant KEY-PAUSE
290	constant KEY-F1
291	constant KEY-F2
292	constant KEY-F3
293	constant KEY-F4
294	constant KEY-F5
295	constant KEY-F6
296	constant KEY-F7
297	constant KEY-F8
298	constant KEY-F9
299	constant KEY-F10
300	constant KEY-F11
301	constant KEY-F12
340	constant KEY-LEFT-SHIFT
341	constant KEY-LEFT-CONTROL
342	constant KEY-LEFT-ALT
343	constant KEY-LEFT-SUPER
344	constant KEY-RIGHT-SHIFT
345	constant KEY-RIGHT-CONTROL
346	constant KEY-RIGHT-ALT
347	constant KEY-RIGHT-SUPER
348	constant KEY-KB-MENU
91	constant KEY-LEFT-BRACKET
92	constant KEY-BACKSLASH
93	constant KEY-RIGHT-BRACKET
96	constant KEY-GRAVE
320	constant KEY-KP-0
321	constant KEY-KP-1
322	constant KEY-KP-2
323	constant KEY-KP-3
324	constant KEY-KP-4
325	constant KEY-KP-5
326	constant KEY-KP-6
327	constant KEY-KP-7
328	constant KEY-KP-8
329	constant KEY-KP-9
330	constant KEY-KP-DECIMAL
331	constant KEY-KP-DIVIDE
332	constant KEY-KP-MULTIPLY
333	constant KEY-KP-SUBTRACT
334	constant KEY-KP-ADD
335	constant KEY-KP-ENTER
336	constant KEY-KP-EQUAL

end-c-library

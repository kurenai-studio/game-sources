# gforth-tetris
tetris using Gforth and raylib

inspred by [tint](https://github.com/DavidGriffith/tint.git)

# setup
You will need to have 
[raylib](https://www.raylib.com/) (made with vesion 5.5) and 
[Gforth](https://gforth.org/) installed.
Gforth from your package manager should work, but at least for me on
openSUSE Tumbleweed I needed to compile newer version, as the release version
(10 years old, according to
[this github mirror](https://github.com/forthy42/gforth/tree/v0-7-3))
had problems with C interop.

To start the program, simply run `gforth main.4th`.

# score
- upon pice landing, add 1 to score
- add additional 1 for every line dropped
- if show next enabled, divide by two (and add 1 to make up for one lost by
        division rounding)
- multiply by current level

# levels
- there is 9 levels
- block falls each 1/level seconds
- level increses each 10 lines
- first increas takes 10*level lines

# themes used
- [Kanagawa](https://github.com/rebelot/kanagawa.nvim)

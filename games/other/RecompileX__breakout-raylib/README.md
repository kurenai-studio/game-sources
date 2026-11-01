Breakout++

A simple Breakout clone written in C++ with raylib.

Disclaimer

This is an unofficial fan-made project inspired by Atari's Breakout.

I am not affiliated with, endorsed by, sponsored by, or associated with Atari in any way.Atari and Breakout belong to their respective owners.

Requirements

C++ compiler

raylib

Build

Example with MinGW:

g++ main.cpp ball.cpp bricks.cpp paddle.cpp -o breakout++ -lraylib -lopengl32 -lgdi32 -lwinmm

Depending on how raylib is installed on your system, your build command may be different.

Controls

Left Arrow — move paddle left

Right Arrow — move paddle right

Enter — launch the ball

Project files

ball.cpp
ball.h
bricks.cpp
bricks.h
paddle.cpp
paddle.h
main.cpp
.gitignore

Current implementation

1280x800 window

60 FPS target

3 lives

8x5 brick grid

Ball/wall collision

Ball/paddle collision

Ball/brick collision

Bricks disappear when hit

Ball resets after a life is lost

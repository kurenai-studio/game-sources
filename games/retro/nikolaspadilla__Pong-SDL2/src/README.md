# Pong-SDL2

A modern implementation of the classic Pong game using SDL2 and GLM.

## Description

This project is a recreation of the iconic Pong game, built with SDL2 for graphics and input handling, and GLM for mathematics and vector operations. It serves as both a fun game and a demonstration of using these libraries in a game development context.

## Prerequisites

To build and run this project, you'll need:

- C++ compiler with C++20 support
- CMake (version 3.29 or higher)
- SDL2 library
- GLM library

## Building the Project

1. Clone the repository:
   ```
   git clone https://github.com/muddxyii/Pong-SDL2.git
   cd Pong-SDL2
   ```

2. Create a build directory:
   ```
   mkdir build
   cd build
   ```

3. Run CMake:
   ```
   cmake ..
   ```

4. Build the project:
   ```
   cmake --build .
   ```

## Running the Game

After building, you can run the game with:

```
./pong-sdl2
```

## Controls (TO BE IMPLEMENTED)

- Player 1:
  - Up: W
  - Down: S
- Player 2:
  - Up: Up Arrow
  - Down: Down Arrow
- Quit: Esc

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- SDL2 developers
- GLM developers
- The original creators of Pong

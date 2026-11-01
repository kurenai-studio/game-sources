# Minesweeper C++

A modern C++ implementation of the classic Minesweeper game, built with [Raylib](https://www.raylib.com/).

## Features

- **Classic Gameplay**: Identify mines, flag them, and clear the board.
- **Modern C++**: Written in C++17 with a clean resource management approach.
- **Cross-Platform**: Supports Windows, Linux, macOS, and Web (WASM) builds.
- **Efficient Rendering**: Powered by Raylib 5.5.

## Controls

| Key/Action | Function |
|------------|----------|
| **Left Click** | Reveal a cell |
| **Right Click** | Flag/Unflag a cell |
| **R** | Restart the game |

## Building from Source

### Prerequisites

- CMake 3.27 or higher
- C++ Compiler (GCC, Clang, or MSVC) supporting C++17
- Git (for fetching Raylib)

### Desktop Build

1. Clone the repository:
   ```bash
   git clone https://github.com/GKaszewski/minesweeper-cpp
   cd minesweeper-cpp
   ```

2. Create a build directory and compile:
   ```bash
   mkdir build
   cd build
   cmake ..
   cmake --build .
   ```

3. Run the game:
   ```bash
   ./minesweeper
   ```

### Web Build (Emscripten)

1. Ensure [Emscripten](https://emscripten.org/docs/getting_started/downloads.html) is installed and active.

2. Create a web build directory:
   ```bash
   mkdir build-web
   cd build-web
   emcmake cmake ..
   cmake --build .
   ```

3. Run locally:
   ```bash
   python3 -m http.server
   # Open browser at http://localhost:8000/minesweeper.html
   ```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
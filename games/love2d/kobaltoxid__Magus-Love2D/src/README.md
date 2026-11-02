# Magus-Love2D
A simple Love2D top down RPG game about a small magician in a couple of mazes.

## Setup

### Prerequisites
- [Love2D](https://love2d.org/) - Download and install Love2D game engine
- Git (for dependency management)

### Getting Dependencies
This project uses git submodules to manage external libraries. After cloning the repository, run:

```bash
git submodule update --init --recursive
```

This will download the required dependencies:
- **bump.lua** - 2D collision detection library

### Testing Dependencies
To verify that all dependencies are properly set up, you can run the test script:
```bash
lua test_dependencies.lua
```

### Running the Game
1. Make sure Love2D is installed and accessible from your system PATH
2. Navigate to the project directory
3. Run the game with:
   ```bash
   love .
   ```
   Or drag the project folder onto the Love2D executable.

### Dependencies
- [bump.lua](https://github.com/kikito/bump.lua) - 2D collision detection library (managed as git submodule)
- [STI](https://github.com/karai17/Simple-Tiled-Implementation) - Simple Tiled Implementation for Love2D (vendored)

### For New Contributors
When you clone this repository, don't forget to initialize the submodules:
```bash
git clone <repository-url>
cd Magus-Love2D
git submodule update --init --recursive
```

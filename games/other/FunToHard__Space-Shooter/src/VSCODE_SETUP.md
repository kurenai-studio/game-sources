# Space Shooter - VS Code Setup

This directory contains VS Code configuration for developing the Space Shooter game with full IntelliSense, debugging, and task automation.

## Files Overview

- **`tasks.json`** - Build, run, and clean tasks
- **`launch.json`** - Debug configurations  
- **`settings.json`** - Workspace settings for C++
- **`c_cpp_properties.json`** - IntelliSense configuration

## Quick Start

### 1. Open in VS Code
```bash
cd Space-Shooter
code .
```

### 2. Build the Game
- Press `Ctrl+Shift+P` → "Tasks: Run Task" → "Build Debug"
- Or use the shortcut: `Ctrl+Shift+B` (default build task)

### 3. Run the Game
- Press `Ctrl+Shift+P` → "Tasks: Run Task" → "Run Game"
- Or press `F5` to build and debug

### 4. Debug the Game
- Set breakpoints in your code
- Press `F5` to start debugging
- Use `F10` (step over), `F11` (step into), `Shift+F5` (stop)

## Available Tasks

Access via `Ctrl+Shift+P` → "Tasks: Run Task":

### Build Tasks
- **Build Debug** (`Ctrl+Shift+B`) - Default build with debug symbols
- **Build Release** - Optimized release build  
- **Clean** - Remove build artifacts
- **Rebuild Debug** - Clean + Build Debug
- **Rebuild Release** - Clean + Build Release

### Run Tasks
- **Run Game** - Run debug executable
- **Run Game (Release)** - Run release executable
- **Build & Run Debug** - Build debug → run
- **Build & Run Release** - Build release → run

## Debug Configurations

Access via `F5` or Debug panel:

### Debug Space Shooter
- Builds debug version automatically
- Launches with GDB debugger
- Supports breakpoints, variable inspection
- Shows output in integrated terminal

### Run Space Shooter (No Debug)
- Builds release version automatically
- Runs in external console
- Faster execution, no debugging overhead

## IntelliSense Features

The configuration provides full C++ IntelliSense with:

### Include Paths
- ✅ All project source directories (`src/`, `entities/`, `systems/`, `utils/`)
- ✅ raylib headers (`C:/raylib/raylib/src`)
- ✅ External dependencies (`C:/raylib/raylib/src/external`)

### Language Features
-  **Go to Definition** - `F12`
-  **Go to Declaration** - `Ctrl+F12`
-  **Find All References** - `Shift+F12`
-  **Peek Definition** - `Alt+F12`
-  **Symbol Search** - `Ctrl+T`
-  **Rename Symbol** - `F2`
-  **Quick Fix** - `Ctrl+.`
-  **Hover Information** - Mouse hover

### Error Detection
- Real-time syntax checking
- Compiler error highlighting
- Missing include detection
- Type mismatch warnings

## Keyboard Shortcuts

### Essential
- `Ctrl+Shift+B` - Build (default task)
- `F5` - Start debugging
- `Ctrl+F5` - Run without debugging
- `Shift+F5` - Stop debugging
- `F9` - Toggle breakpoint
- `F10` - Step over
- `F11` - Step into
- `Shift+F11` - Step out

### Navigation
- `Ctrl+P` - Quick open file
- `Ctrl+Shift+P` - Command palette
- `Ctrl+G` - Go to line
- `Ctrl+T` - Go to symbol
- `F12` - Go to definition
- `Alt+Left/Right` - Navigate back/forward

### Editing
- `Ctrl+D` - Select next occurrence
- `Ctrl+Shift+L` - Select all occurrences
- `Alt+Up/Down` - Move line up/down
- `Shift+Alt+Up/Down` - Copy line up/down
- `Ctrl+/` - Toggle comment
- `Shift+Alt+F` - Format document

## Troubleshooting

### Build Errors
**"mingw32-make.exe not found"**
- Verify raylib w64devkit installation at `C:/raylib/w64devkit/`
- Update paths in `tasks.json` if installed elsewhere

**"raylib.h not found"** 
- Check raylib installation at `C:/raylib/raylib/`
- Update include paths in `c_cpp_properties.json`

**"Undefined reference errors"**
- Ensure all source files are listed in `tasks.json` OBJS parameter
- Check for missing library links

### IntelliSense Issues
**"Cannot open source file"**
- Reload window: `Ctrl+Shift+P` → "Developer: Reload Window"
- Check include paths in `c_cpp_properties.json`

**"IntelliSense not working"**
- Open Command Palette: `Ctrl+Shift+P`
- Run: "C/C++: Reset IntelliSense Database"
- Run: "C/C++: Log Diagnostics"

### Debugging Issues
**"gdb.exe not found"**
- Verify GDB path in `launch.json`
- Check w64devkit installation

**"Breakpoints not hit"**
- Ensure debug build is used (contains `-g` flag)
- Rebuild with debug configuration

## Extensions

### Recommended Extensions
Install these for the best experience:

**Essential:**
- `ms-vscode.cpptools` - C/C++ IntelliSense and debugging
- `ms-vscode.cpptools-extension-pack` - Complete C++ development


## Configuration Customization

### Custom raylib Path
If raylib is installed elsewhere, update these files:

**`tasks.json`:**
```json
"RAYLIB_PATH=YOUR_PATH_HERE"
```

**`c_cpp_properties.json`:**
```json
"includePath": ["YOUR_PATH_HERE/src"]
```

**`launch.json`:**
```json
"miDebuggerPath": "YOUR_PATH_HERE/bin/gdb.exe"
```

### Custom Compiler
To use a different compiler:

**`tasks.json`:**
```json
"command": "C:/path/to/your/compiler.exe"
```

**`settings.json`:**
```json
"C_Cpp.default.compilerPath": "C:/path/to/your/compiler.exe"
```

## Tips & Best Practices

### Debugging
1. **Set breakpoints early** in `main()` or `Game::Initialize()`
2. **Use conditional breakpoints** for specific conditions
3. **Watch variables** in the Debug panel
4. **Use the Debug Console** for expressions

### Code Navigation
1. **Use breadcrumbs** (top of editor) for quick navigation
2. **Pin important files** with right-click → "Pin Tab"
3. **Use split editor** (`Ctrl+\`) for multiple files
4. **Organize with file explorer** sidebar

### Performance
1. **Disable extensions** you don't need for faster startup
2. **Use workspace settings** instead of global settings
3. **Close unused tabs** to reduce memory usage

This VS Code setup provides a complete development environment for the Space Shooter project! 🚀

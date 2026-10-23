
---

# 🧠 Blind Tracer

**Blind Tracer** is a grid-based memory and pathfinding game being developed with [LÖVE2D](https://love2d.org/). You’re shown a randomly generated maze for a brief moment—then the lights go out. Can you remember the correct path, avoid hidden obstacles, and collect rewards while navigating in the dark?

---

## 🕹️ Gameplay Concept

1. **Preview Phase**: Players are shown a randomly generated maze with walls, obstacles, and rewards for a limited time.
2. **Dark Phase**: The maze goes completely dark. Players must navigate based on memory alone.
3. **Obstacles**: Hidden traps challenge the player’s memory and spatial awareness.
4. **Rewards**: Optional collectibles offer bonus points and incentives.
5. **Objective**: Reach the exit safely and efficiently—before time or lives run out.

---

## 🧩 Planned Features

* Procedurally generated mazes for endless variation
* Progressive difficulty with shorter preview times and larger maps
* Engaging, memory-based navigation gameplay
* Hidden obstacles and optional rewards to add strategic depth
* Audio/visual cues to increase immersion

---

## 🛠️ Development Status

**Blind Tracer** is in active development.
Core gameplay mechanics are being prototyped and refined, with a focus on balancing visibility, challenge, and replayability.

---

## 🔧 Development & Operational Details

Great point! I've updated the section on opening the project workspace in VS Code to include that additional method. Here's the revised section of the README with the improved explanation:

---

### 🧰 Project Setup

This project is developed using **Visual Studio Code (VS Code)** and includes a `.code-workspace` file. To take full advantage of the integrated tasks, debugging, and project settings, you should **open the project using the workspace**.

#### ✅ How to Open the Workspace

You can open the project in workspace mode in several ways:

* **Double-click** the `BlindTracer.code-workspace` file (if your OS is configured to open it with VS Code).
* **From VS Code**, go to **File → Open Workspace from File...**, and select `BlindTracer.code-workspace`.
* **From the file tree in VS Code**:

  1. Locate and click on the `BlindTracer.code-workspace` file.
  2. In the lower right corner of the editor, click the **"Open Workspace"** prompt that appears.

> Opening the workspace ensures all predefined tasks, launch configurations, and settings are applied correctly.

---

### 📦 Required Dependencies

#### VS Code Extensions

When the workspace is opened in VS Code, any **required** or **recommended extensions** will be automatically suggested via a prompt. These include:

* **Required**:

  * `tomblind.local-lua-debugger-vscode` (Local Lua Debugger)
  * `editorconfig.editorconfig` (EditorConfig for consistent code style)
* **Recommended**:

  * `sumneko.lua` (Lua Language Server)

Install these via the **Extensions panel** in VS Code or use the command palette (`Ctrl+Shift+P` → `Extensions: Install Extensions`).

#### Python Packages

You must install the `makelove` Python package to enable project building:

```bash
pip install makelove
```

> **Note**: This is required to use the build task (`Ctrl+Shift+B`).

### 🛠️ VS Code Tasks

This project includes **predefined launch and build tasks**.

#### 📤 Build Task

Use `Ctrl+Shift+B` to run the **build task**. This requires `makelove` to be installed.

#### 🚀 Launch Tasks (F5 Menu)

You can run or debug the game using these **Launch Configurations**:

* **Debug** — Starts the game with debugging support.
* **Release** — Starts the game with optimized settings.
* **Live Profile** — Starts the game with a performance profiler active.

To access:

1. Open the `Run and Debug` sidebar in VS Code.
2. Select a configuration from the dropdown.
3. Click **Start Debugging** or press `F5`.

---

## 📁 Folder Structure

```
BlindTracer/
├── builds/                # Output folder for built distributions
├── game/                  # Main game source folder
│   ├── assets/            # Images, sounds, fonts, etc.
│   ├── lib/               # External Lua libraries
│   ├── src/               # Game source code
│   ├── main.lua           # Entry point for LÖVE2D
│   └── conf.lua           # Game configuration for LÖVE2D
├── resources/             # Non-bundled project resources (profiling, reference data, etc.)
├── tools/                 # Utilities and build config
├── LICENSE
└── README.md
```

---

## 🧠 Planned Additions

* Fog-of-war to dynamically limit visible areas
* Multiplayer or competitive “memory race” modes
* Leaderboards, achievements, and challenge modes
* Maze editor or seed-based sharing for custom layouts

---

## 📜 License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.
See the [LICENSE](./LICENSE) file for full details.

---

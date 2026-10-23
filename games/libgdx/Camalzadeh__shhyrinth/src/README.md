# Shhyrinth — A Magical Labyrinth Adventure

> **Status:** 🚧 In Development — Core gameplay is playable, but some features are still in progress.

---

## 🧙 About the Game

**Shhyrinth** is a 2D magical maze crawler built with **LibGDX**. You play as a spell-wielding mage battling through an enemy-infested labyrinth, surviving with elemental powers and strategic potion use.

Developed by:

* Humbat Jamalov
* Huseyn Pashayev
* Shabnam Nazarli
* Yunis Kangarli

As the final project for the **Object-Oriented Programming course** at **UFAZ**.

---

## 🧠 Technical Overview

* **Engine:** [LibGDX](https://libgdx.com)
* **Build Tool:** Gradle (multi-module: `core`, `desktop`, `html`)
* **Language:** Java 17+
* **Desktop Compatibility:** Windows / macOS / Linux
* **Web Compatibility:** Playable via GWT / HTML5

Project structure supports both `.jar` builds and web-based execution. See `html/` folder for GWT setup.

---

## 🎮 Gameplay Summary

Your mage must escape from a labyrinth across **5 increasing difficulty levels**:

* Each level spawns **more enemies**
* Use **Fire Spell** to burn enemies
* Use **Ice Spell** to freeze them in place
* **Collect at least 5 keys** to unlock the portal and finish the level
* **Open chests** — might be empty, have a key, or a potion

### 🧪 Potion System

* 🧪 **Health Potion** — Restores 50 HP
* 🔮 **Mana Potion** — Restores 70 MP
* 🛡️ **Armor Potion** — Temporarily grants armor (reduces damage)

Potions are selected with **Q/E** and consumed with **F**.

---

## ⚔️ Controls

| Action             | Key                |
| ------------------ | ------------------ |
| Move               | **W A S D**        |
| Normal Attack      | **Left Click**     |
| Special Attack     | **Right Click**    |
| Swap Spell Element | **Spacebar**       |
| Change Potion Type | **Q / E**          |
| Drink Potion       | **F**              |
| Open Chest         | **R**              |
| Zoom In            | **↑ (Arrow Up)**   |
| Zoom Out           | **↓ (Arrow Down)** |

> Future versions may support rebindable controls.

---

## 🕹️ How to Play

### ✅ Desktop (JAR)

1. Make sure you have **Java 17+** installed
2. Navigate to:

```bash
cd desktop/build/lib/
```

3. Run the game:

```bash
java -jar desktop-1.0.jar
```

### 🌐 Web (HTML)

The game is also playable in-browser using the **GWT (Google Web Toolkit)** module:

* HTML build available under `html/`
* Automatically compiles to JavaScript and deploys via `webapp/`

You can host it locally or deploy on services like GitHub Pages or Firebase Hosting.

---

## 🗂️ Project Structure

```
shhyrinth/
├── core/             # Main game logic (entities, spells, map, etc.)
├── desktop/          # Desktop-specific launcher
├── html/             # GWT HTML5 web launcher
├── assets/           # Textures, audio, fonts, etc.
├── gradle/           # Gradle wrapper
└── build.gradle      # Project configuration
```

---

## 🚧 Features in Progress

* 💾 Game saving system
* 🌟 Boss enemies
* 🎵 Dynamic sound effects and soundtrack
* 🎨 Advanced UI animations and settings

---

## 🤝 Contribution

You're welcome to contribute! Ways to help:

* Add new enemies, spells, or levels
* Refactor game mechanics or rendering
* Improve web build performance

> Contact us or open a pull request.
---

> *“The labyrinth bends to no soul... but the right magic might bend it back.”* 🌀

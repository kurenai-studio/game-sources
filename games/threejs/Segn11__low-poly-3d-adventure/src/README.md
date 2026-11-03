# 🎮 Super Star Hopper: 3D Platformer Adventure

<p align="center">
  <img src="public/screenshots/gameplay.png" alt="Super Star Hopper Gameplay" width="850" style="border-radius: 14px; box-shadow: 0 12px 35px rgba(0,0,0,0.35);"/>
</p>

<p align="center">
  <strong>An international AAA-grade 3D Low-Poly Platformer Game built with Three.js, Web Audio API, and Electron.</strong><br>
  <em>Play instantly in your browser or install as a native offline Windows Desktop application!</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Web-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/badge/Gamepad-Xbox%20%7C%20PlayStation%20%7C%20Haptics-107C41?style=for-the-badge&logo=xbox&logoColor=white" alt="Gamepad" />
  <img src="https://img.shields.io/badge/Languages-EN%20%7C%20ES%20%7C%20FR%20%7C%20JA%20%7C%20DE-f39c12?style=for-the-badge" alt="Languages" />
  <img src="https://img.shields.io/badge/3D_Engine-Three.js_r186-black?style=for-the-badge&logo=three.js&logoColor=white" alt="Three.js" />
  <img src="https://img.shields.io/badge/License-MIT-ff4757?style=for-the-badge" alt="License" />
</p>

<p align="center">
  <a href="https://segn11.github.io/low-poly-3d-adventure/">
    <img src="https://img.shields.io/badge/▶_PLAY_LIVE_ONLINE-Browser_Version-2ed573?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Play Live" />
  </a>
  <a href="https://github.com/Segn11/low-poly-3d-adventure/releases">
    <img src="https://img.shields.io/badge/📥_DOWNLOAD_DESKTOP_APP-.exe_Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Download .exe" />
  </a>
</p>

---

## 🌍 Play Online & Desktop Downloads

| Platform | Access Method | Link |
| :--- | :--- | :--- |
| **🌐 Web Browser** | Instant 60 FPS play on PC, Mac, iPhone, Android (No download required) | [**▶️ Play Live on GitHub Pages**](https://segn11.github.io/low-poly-3d-adventure/) |
| **🪟 Windows Setup Installer** | Installs on Windows PC with desktop & start menu shortcuts | [**📥 Download Setup Installer (.exe)**](https://github.com/Segn11/low-poly-3d-adventure/releases) |
| **💼 Windows Portable** | Single standalone `.exe` file (run from USB drive or desktop) | [**📥 Download Portable .exe**](https://github.com/Segn11/low-poly-3d-adventure/releases) |

---

## 🕹️ About The Game

**Super Star Hopper** is an acrobatic 3D low-poly platformer inspired by masterworks like *Super Mario Odyssey*, *A Hat in Time*, and *Fall Guys*. 

Take command of a spirited explorer equipped with a fluttering adventure scarf and spring antenna backpack. Leap across sky islands, wall-jump up towering ruins, belly-dive into recovery rolls, smash wooden crates, trigger expanding ground pound shockwaves, discover secret red coins, and collect all **5 Grand Power Stars** to illuminate the Celestial Summit!

> [!TIP]
> **100% Zero-Dependency Standalone Architecture**: No external 3D models or MP3 files are fetched over the network. The procedural geometry, animated vertex water ripples, and polyphonic Web Audio synthesizer run with zero loading latency and full offline capability.

---

## ✨ Cutting-Edge Game Features

### 🤸 Advanced Acrobatic Moveset
- **Fluid Locomotion**: Instant responsive acceleration, deceleration, and camera-relative directional steering.
- **Double Jump Front-Flip**: Execute high-altitude somersaults with aerial momentum conservation.
- **Wall Slide & Wall Jump**: Slide down sheer cliffs with friction dust, then kick off walls to ascend vertical canyons.
- **Belly Dive & Dive-to-Roll**: Dive forward horizontally in mid-air to clear wide gaps, smoothly rolling into a sprint upon landing.
- **Ground Pound Slam & Shockwave**: Plunge straight down at terminal velocity, emitting a 3D expanding gold shockwave ring that smashes crates and squashes nearby enemies.
- **Spring Antenna & Scarf Physics**: Dynamic secondary cloth flutter and backpack spring animations influenced by player velocity.

### 🏝️ Expansive Multi-Biome World
1. **Emerald Meadow**: Lush starting plateau with low-poly pine trees, mushrooms, breakable crates, and secret red coin paths.
2. **Lagoon & Bouncing Canopy**: Translucent water plane with animated procedural wave ripples, wooden lifts, and super bounce mushrooms.
3. **Clockwork Wind Ruins**: Massive rotating stone cogwheel platforms, wind updraft geysers that launch the player into the sky, and ancient stone arches.
4. **Neon Crystal Chasm**: Floating cloud archipelago, glowing amethyst stalagmites with localized lighting, and high-altitude elevator platforms.
5. **Celestial Summit Shrine**: Golden temple colonnades with rotating planetary orbital rings housing the summit altar.

### ⭐ 5 Grand Power Star Missions & Quest Log (<kbd>Tab</kbd>)
Press <kbd>Tab</kbd> or click 📜 to open the in-game **Mission Quest Log**:
1. ⭐ **Meadow Grove Discovery**: Discover the secret grove tucked behind Meadow Camp.
2. ⭐ **Crimson Constellation**: Track down all 8 hidden Red Coins across daring challenge spots.
3. ⭐ **High-Flying Hop**: Bounce to the sky apex above the giant mushroom.
4. ⭐ **Gears of Antiquity**: Traverse the rotating clockwork ruins to the high stone arch.
5. ⭐ **Celestial Apex Star**: Reach the Temple Altar on the Celestial Summit.

### 🔴 The 8 Red Coins Quest
- Hunt down 8 gleaming ruby Red Coins hidden throughout the world.
- Each collected red coin plays an ascending note on an 8-note musical scale (C5, D5, E5, F5, G5, A5, B5, C6).
- Gathering all 8 summons the **Crimson Constellation Power Star** with victory fanfare!

### 📦 Breakable Wooden Crates
- Wooden crates with metal corner reinforcements scattered across the world.
- Breakable via Ground Pound, Belly Dive, or Shockwave.
- Shatters into 8 physics-tumbling wooden splinter fragments and drops coins, hearts, or secret red coins!

### 👾 Diverse Enemy Combat
- **Standard Slimes ("Blobbies")**: Patrol platforms; squash from above for bonus coins.
- **Winged Bat Slimes ("Batto")**: Hover across aerial gaps; stomping them grants an **aerial jump reset** for acrobatic air chains!
- **Armored Spiky Slimes ("Spikeys")**: Cannot be stomped from above! Defeat them using the Ground Pound Shockwave ring or a Belly Dive smash!

### 🎮 Full Gamepad & Controller Support
- Native Gamepad API support with zero configuration:
  - **Left Stick**: Full 360° analog locomotion.
  - **Right Stick**: Smooth camera orbit and vertical pitch adjustment.
  - **A / Cross**: Jump & Double Jump.
  - **X / Square**: Belly Dive.
  - **B / Circle or Right Trigger**: Ground Pound Slam.
  - **Y / Triangle**: Toggle Mission Quest Log.
  - **Dual-Rumble Vibration Haptics**: Tactile feedback on ground pounds, damage, and star collection.

### 🌐 International Localization & Settings
- Switch between 5 languages in real-time via the ⚙️ Settings menu:
  - 🇬🇧 **English (EN)**
  - 🇪🇸 **Español (ES)**
  - 🇫🇷 **Français (FR)**
  - 🇯🇵 **日本語 (JA)**
  - 🇩🇪 **Deutsch (DE)**
- Customizable volume sliders for Master, SFX, and Music channels.
- Screen Shake toggle with trauma-decay physics camera.

---

## 🎮 Controls Reference

| Action | Keyboard / Mouse | Gamepad (Xbox / PS) | Touch (Mobile) |
| :--- | :--- | :--- | :--- |
| **Move Explorer** | <kbd>W</kbd> <kbd>A</kbd> <kbd>S</kbd> <kbd>D</kbd> | Left Analog Stick | Virtual Thumbstick |
| **Jump / Double Jump** | <kbd>Space</kbd> | <kbd>A</kbd> / <kbd>✕</kbd> | ▲ Button |
| **Belly Dive** | <kbd>F</kbd> or <kbd>Shift</kbd> + <kbd>Space</kbd> | <kbd>X</kbd> / <kbd>▢</kbd> | 🐬 Button |
| **Ground Pound Slam** | <kbd>C</kbd> or <kbd>Ctrl</kbd> | <kbd>B</kbd> / <kbd>○</kbd> or <kbd>RT</kbd> | ⬇ Button |
| **Sprint** | Hold <kbd>Shift</kbd> | Stick Click / Full Tilt | Outer Ring Drag |
| **Wall Jump** | Jump while sliding against wall | <kbd>A</kbd> while sliding | ▲ against wall |
| **Orbit Camera** | Click & Drag Mouse | Right Analog Stick | Touch & Drag Screen |
| **Rotate Camera Snap** | <kbd>Q</kbd> / <kbd>E</kbd> | <kbd>LB</kbd> / <kbd>RB</kbd> | — |
| **Zoom Camera** | Mouse Scroll Wheel | — | Pinch to Zoom |
| **Mission Log** | <kbd>Tab</kbd> or <kbd>M</kbd> | <kbd>Y</kbd> / <kbd>△</kbd> | 📜 Button |
| **Pause / Resume** | <kbd>Escape</kbd> | <kbd>Start</kbd> / <kbd>Options</kbd> | ⏸ Button |
| **Fullscreen** | <kbd>F11</kbd> | — | Browser Fullscreen |

---

## 🛠️ Development & Building

```bash
# Clone the repository
git clone https://github.com/Segn11/low-poly-3d-adventure.git
cd low-poly-3d-adventure

# Install dependencies
npm install

# Run local development server
npm run dev

# Build optimized production bundle
npm run build

# Run native desktop app in development
npm run app:dev

# Build Windows desktop installer & portable .exe
npm run app:build
```

---

## 📄 License
This project is licensed under the [MIT License](LICENSE).

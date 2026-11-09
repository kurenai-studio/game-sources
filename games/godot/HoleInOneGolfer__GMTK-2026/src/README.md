# GMTK-2026: Stardust Stroll

[![Play on Itch.io](https://img.shields.io/badge/Itch.io-Play%20Now-red)](https://holeinonegolfer.itch.io/gmtk-2026)
[![Latest Release](https://img.shields.io/github/v/release/holeinonegolfer/gmtk-2026)](https://github.com/holeinonegolfer/gmtk-2026/releases)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/HoleInOneGolfer/GMTK-2026/deploy.yml)
![License](https://img.shields.io/github/license/holeinonegolfer/gmtk-2026)
![Godot](https://img.shields.io/badge/Godot-4.7.1-blue?logo=godotengine)

---

## 📖 About

A high-speed, top-down game focused on the theme **COUNTDOWN** for the **[2026 Game Makers Toolkit Game Jam](https://itch.io/jam/gmtk-jam-2026)**. Survive against the clock, earn score, and buy upgrades between rounds!

## 🎮 How To Play

- **Move:** WASD (Look and aim with the Mouse)
- **Action:** Mouse Click (Interact with the Shop and buttons)
- **Objective:** Beat the countdown timer, rack up your score, and power up your Speed, Size, and Time in the shop menu!

## 🛠 Tech Stack

- **Engine:** Godot 4.7.1
- **CI/CD:** Automated builds via GitHub Actions & Butler

## 🛠 For Developers

### 🚀 Creating a New Release

I use an automated CI/CD pipeline to streamline my deployment. To push a new release to Itch.io:

1. **Commit** my changes to `main`.
2. **Tag** the commit with a version number:
   ```bash
   git tag v1.0.0
   ```
3. **Push** the tag to GitHub:
   ```bash
   git push origin v1.0.0
   ```

_The GitHub Actions workflow automatically builds, packages, and deploys the new version to the `web` and `windows` channels on Itch.io._

### 🔢 Versioning Strategy

I follow [Semantic Versioning](https://semver.org/) for my releases:

- **Major (v1.0.0):** Major milestones (e.g., core gameplay loop finished, jam submission).
- **Minor (v0.1.0):** Added features or content (e.g., new levels, new mechanics).
- **Patch (v0.0.1):** Bug fixes, balance tweaks, or documentation updates.

### 📦 Local Development

- **Engine:** Godot 4.7.1
- **Testing:** I use `F5` to run the project locally.

## 🤝 Credits

- **Development:** [HoleInOneGolfer](https://holeinonegolfer.itch.io/)
- **Engine:** Powered by the [Godot Engine](https://godotengine.org/) ([License](https://godotengine.org/license/))
- **Assets:**
  - **Art:** Kenney Game Icons, Kenney Space Shooter Remastered, Kenney Puzzle Pack 1
  - **Font:** Kenney Blocks, Kenney Bold, Kenney Thick

---

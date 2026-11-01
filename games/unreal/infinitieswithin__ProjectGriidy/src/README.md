# Griidy — play the ground, not the pawn

<p align="center">
  <img src="🔶Media/hero_pulse_roll.gif" alt="Pulse → Roll hero GIF" width="840">
</p>

<p align="center">
  <a href="https://www.unrealengine.com/"><img alt="UE Version" src="https://img.shields.io/badge/Unreal%20Engine-5.6-1f6feb?logo=unrealengine&logoColor=white"></a>
  <img alt="Status" src="https://img.shields.io/badge/status-Prototype_(WIP)-fb923c">
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-10b981"></a>
  <a href="🔶https://discord.gg/yourinvite"><img alt="Discord" src="https://img.shields.io/badge/Discord-join-5865F2?logo=discord&logoColor=white"></a>
</p>

**A UE5 physics prototype** and an **open-source deformable-terrain system**. You sculpt a modular field to guide a sphere via **indirect control**. The package includes a sample project, docs, and a short tutorial series.

> **Project status:** Prototype (WIP)  
> **Give-back:** Open-source sample + free Fab kit + tutorial series

---

## Table of contents
- [What’s inside](#whats-inside)
- [Quick start](#quick-start)
- [Controls](#controls)
- [System overview](#system-overview)
- [Screenshots](#screenshots)
- [Contributing](#contributing)
- [License](#license)
- [Credits](#credits)

---

## ✨ What’s inside

- **Game Prototype** – fixed-camera sandbox showcasing the core *pulse → roll* loop.  
- **Deformable-Terrain System** – modular tiles driven by:
  - **HISM batching** (efficient rendering for thousands of instances)
  - **WPO deformation** (GPU vertical displacement)
  - **Render-target blending** (*Current → Desired → Render* state loop)
  - **Dynamic collider pooling** (configurable pool that teleports to hotspots; e.g., **~92 on a 128×64 field**)
- **Docs & Assets** – diagrams, parameter guides, and example maps.

---

## 🚀 Quick start

**1) Download**  
Grab the latest release zip from **Releases** → `🔶v0.1-open-sample.zip`

**2) Open in Unreal**  
- Unreal Engine **5.6** (tested on **5.6**)  
- Open `🔶ProjectGriidy/ProjectGriidy.uproject`  
- If prompted, allow it to build a small **C++ helper** module.

**3) Run a demo map**  
- `Content/Griidy/Maps/🔶Lv_Demo.umap`

> **Tip:** First launch may compile shaders; subsequent loads are faster.

---

## 🎮 Controls

| Action                     | Gamepad                              | 
|---------------------------|--------------------------------------|
| Attractor / Influence     | **Right/Left analog sticks**         | 
| Pulse / Raise–lower       | **Right/Left triggers**              | 

> **Readability layer:** the **ring** shows influence; **red lowers**, **yellow raises**; **brightness = height** (brighter = higher).

---

## 🧩 System overview

**Tiles** – capsule-like modules on a grid (e.g., **128 × 64**).  
**Rendering** – **HISM** batches reduce draw calls for large fields.  
**Deformation** – **WPO** pushes vertices in **Z** from GPU textures.  
**State loop** – we blend **Current** ↔ **Desired** into a **Render** state for smooth motion.  
**Physics** – a **collider pool** teleports to active areas so thousands of tiles don’t need individual bodies.

---

## 🤝 Contributing

Issues and PRs are welcome—especially for:
- Docs & diagrams
- Example maps / Blueprint comments
- Performance findings (PC specs + frame timings)

> **Before PRs:** run the demo map, match naming conventions, and keep assets small & tidy.

## 📝 License

MIT — commercial use allowed; see LICENSE
.

## 🙌 Credits

Designed & built by Abdurrahman Furkan BALCI and Büşra Yeliz KARAOĞLU BALCI.
Special thanks to the Unreal Engine community.

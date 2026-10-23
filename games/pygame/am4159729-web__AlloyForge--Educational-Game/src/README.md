

# AlloyForge--Educational-Game(V1.0.0)

A standalone Python and Pygame metallurgy simulation game. Mix elemental metals, calculate density and yield strength in real time, time hammer strikes on a heat-sensitive anvil bar, and quench alloys to fulfill client contracts.

<img width="1073" height="737" alt="Screenshot 2026-10-02 at 12 56 30 PM" src="https://github.com/user-attachments/assets/f0bf43a0-74ee-4841-b33f-ef05124064d9" />
<img width="1077" height="749" alt="Screenshot 2026-10-02 at 12 56 45 PM" src="https://github.com/user-attachments/assets/e74006b7-b99f-4dc3-976a-337d76850a42" />

## Key Features

* It runs entirely on Python 3 and Pygame with zero external asset files—all audio and visual effects are generated procedurally in code.
* The material solver calculates real-time alloy density, yield strength, and unit cost based on custom weight percentages.
* An active temperature and timing system requires you to heat metal above 450°C to hammer and above 650°C to quench.
* Precise hammer timing on the dynamic sweet-spot bar directly increases your alloy's strength multiplier and quality cap.
* An progression loop includes client contracts, a recipe codex for discovered alloys, workshop upgrades, and automatic session saving.
* Includes a custom synthesized audio engine using raw sample arrays so you don't need external `.wav` or `.mp3` files.

## Usage

1. Install Pygame if you haven't already:
   pip3 install pygame
2. Download the file and run it in the terminal: 
   python3 Alloy.py
3. Controls:

  1 / 2: Cycle active elements for Slot 1 and Slot 2

  H: Heat the furnace

  SPACE: Hammer strike (when indicator is over the green zone)

  Q: Quench metal

  S: Submit alloy to client

  C: Toggle Recipe Codex

  ESC: Save and exit

## Limitations in Version 1.0
  The alloy solver uses weighted linear combinations for density, strength, and cost rather than complex non-linear phase diagrams (such as eutectic melting points or true crystal       phase shifts).

  Mixing is currently limited to two active elements at a time.

  Audio generation relies on standard pygame.mixer hardware access; if your system lacks an active sound device, the game safely falls back to silent mode.

  Save data is stored locally as a single JSON file (.alloy_forge_save.json) in your user home directory.

## Testing
  To verify that the physics engine, UI sliders, and state persistence are working correctly:

  Mix 60% Copper and 40% Zinc to discover Brass.

  Press H to heat, time a few SPACE strikes in the green zone, press Q to quench, and click SUBMIT.

  Press ESC to exit, re-launch python3 Alloy.py, and confirm your gold balance and unlocked recipes loaded properly.

## Why I Built This
  I created this game because most crafting systems in RPGs and simulation games rely on arbitrary fantasy recipes—like combining two generic iron ingots to make a sword—without any     connection to actual metallurgy. I wanted to build a project where material properties (like density, yield strength, and composition ratios) actually dictate whether your crafted     item succeeds or fails, wrapped inside an engaging arcade forge loop with zero asset dependencies.

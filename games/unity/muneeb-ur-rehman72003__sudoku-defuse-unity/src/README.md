# Sudoku Defuse

A timed Sudoku bomb-defusal game developed with Unity and C#. Players must solve Sudoku puzzles before the countdown reaches zero while managing limited strikes, hints, and time penalties.

## Game Overview

Sudoku Defuse combines traditional Sudoku gameplay with a bomb-defusal theme. Correct answers provide time bonuses, while incorrect answers reduce the timer and add strikes.

The game contains three difficulty-based missions with different puzzles, timers, and strike limits.

## Features

- Complete 9×9 Sudoku gameplay
- Three difficulty levels
- Countdown timer system
- Strike-based game-over system
- Correct answer time bonuses
- Row, column, and box completion bonuses
- Wrong answer penalties
- Limited hint system
- Mouse and keyboard controls
- Number highlighting
- Level progression and unlocking
- Victory and game-over result screens
- Restart, next-level, and main-menu navigation
- Back confirmation popup
- How-to-play instructions
- Windows desktop build

## Levels

| Level | Mission | Difficulty | Timer | Strikes |
|------:|---------|------------|------:|--------:|
| 1 | Training Mission | Easy | 5 minutes | 3 |
| 2 | Field Operation | Medium | 4 minutes | 3 |
| 3 | Final Defusal | Hard | 3 minutes | 2 |

## Gameplay Rules

- Correct number: **+2 seconds**
- Completed row: **+10 seconds**
- Completed column: **+10 seconds**
- Completed 3×3 box: **+10 seconds**
- Wrong number: **-10 seconds**
- Wrong number also adds one strike
- The mission fails when the timer reaches zero or the strike limit is reached
- Completing the puzzle successfully unlocks the next level

## Controls

| Control | Action |
|---------|--------|
| Mouse Click | Select a Sudoku cell |
| Number Keys 1–9 | Enter a number |
| Numpad 1–9 | Enter a number |
| Arrow Keys | Move between cells |
| Space | Enter or confirm number-selection mode |
| Number Buttons | Enter a number using the interface |
| Hint Button | Reveal a correct number |

## Technology

- Unity 6
- C#
- TextMeshPro
- Unity Input System
- PlayerPrefs for level progression
- Windows 64-bit build

## Project Structure

```text
Assets/
├── Scenes/
│   ├── MainMenu.unity
│   └── GameScene.unity
├── Scripts/
├── Prefabs/
├── Sprites/
├── Fonts/
└── Audio/

Packages/
ProjectSettings/
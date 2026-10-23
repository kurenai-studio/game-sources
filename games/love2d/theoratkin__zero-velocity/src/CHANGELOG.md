# Changelog

[keepachangelog]: http://keepachangelog.com/en/1.0.0/
[semver]: http://semver.org/spec/v2.0.0.html

All notable changes to this project will be documented in this file.

The changelog format is based on [Keep a Changelog][keepachangelog]. \
This project adheres to [Semantic Versioning][semver].

## [3.0.1] - 2022-11-19

### Fixed
- Fix sound volume setting being ignored by new asteroids.


## [3.0] - 2022-05-09

### Added
- 3 new ships with different statistics!
- Explosion particle effects.
- Endless mode that is available on game completion.
- Configurable post-processing effects (bloom, pixelate, scan lines, and CRT).
- Implement UI with the following elements:
  - Title screen
  - Main menu
  - Ship select screen
  - Options
  - Credits
  - Pause menu
  - Game over screen
  - Winning screen
- Music volume is now configurable and is at 50% by default.
- Sound volume is now configurable and is at 100% by default.
- Data-driven input mappings, which enables custom mappings in the future.
- Persistent config.
- Russian translation (can be changed in options).

### Changed
- Completely remade asteroid rendering, they are now randomly generated and
  drawn using lines.
- Asteroids amount is now determined by an easing function (slow start but
  then they multiply rapidly).
- Hyperdrive charge indicator is now shown in place of fuel.
- Reset ship rotation on start.
- Disable asteroids on the winning screen.
- Ship can now be precisely rotated with a joystick.
- Each laser is now its own physical body
- Laser width now can be changed per ship
- Laser damage now stacks (so if 2 lasers are hitting an asteroid at the same
  time damage is multiplied by 2)

## Fixed
- Game now scales properly and is not affected by current resolution
- Not being able to play multiple asteroid explosion sounds simultaneously
- Improve collision detection
- Improve font rendering.
- Wrong ship collision bounds
- Final animation can't be played more than once


## [2.0.0] - 2020-04-28

### Added
- Asteroids now have health.
- Color feedback for laser heat and asteroids's health.
- AppImage builds.
- An option to toggle FPS display with F2.

### Changed
- Laser's damage is now proportional to its heat.
- Move all HUD to the center of the screen.
- Make the HUD transparent so it doesn't get in the way too much.
- Change heat percentage color to red on overheating.

### Fixed
- Heat being negative sometimes.
- Time counter increases when the game is not active.


## [1.0.0] - 2020-04-16

Game release.

<!--
vim: tw=78 ts=2 sw=2 sts=2 et nonu
-->

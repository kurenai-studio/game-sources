<!-- markdownlint-configure-file {"MD024": { "siblings_only": true } } -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.1/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.1] - 2026-05-08

### Added

- Initial release of tetris-efi, a Tetris clone that runs as a UEFI application.
- Graphics Output Protocol rendering with a double-buffered `Blt` path for flicker-free output.
- Coloured tetrominoes (I, O, T, S, Z, J, L) with a dimmed ghost-piece preview of the hard-drop
  landing position.
- Hold (store/recall) action allowing the current piece to be swapped with a held piece once per
  drop.
- In-game user interface with score, version, project URL, and on-screen control hints rendered
  with a built-in 5x5 bitmap font.
- Game-over overlay with a "GAME OVER" title and prompts for starting a new game (`N`) and
  quitting to firmware (`Q`).
- Minimal UEFI-bootable `tetris.iso` produced alongside `tetris.efi` and a `run-qemu` CMake target
  that boots the ISO under OVMF.
- cmocka-based host tests for piece and game logic, gated behind `-DBUILD_TESTS=ON`.

[unreleased]: https://github.com/Tatsh/tetris-efi/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/Tatsh/tetris-efi/releases/tag/v0.0.1

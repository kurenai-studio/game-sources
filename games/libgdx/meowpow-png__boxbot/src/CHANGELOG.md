# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/2.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-08-22

### Added

- Warehouse simulation with a robot that paths automatically to its destination
- Click-to-select controls for choosing a package and its destination
- Ability to queue additional moves while the robot is busy
- Red, green, and blue packages, with orders that request a specific color
- Battery system that drains as the robot moves, with a charging station to recharge it
- Scheduled truck deliveries for dropping off and picking up packages
- Manual option to dispatch the truck early
- Delivery timers on orders, with a failure limit that ends the run once exceeded
- Pause menu that can be accessed with `Esc`

[Unreleased]: https://github.com/meowpow-png/boxbot/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/meowpow-png/boxbot/releases/tag/v0.1.0

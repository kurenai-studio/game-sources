# Horse Racing

A free, open-source desktop horse-racing game for one to eight local players. SD mode combines a mechanical-style track, whole-credit combination bets, virtual players, race announcers, photo finishes, and saved games. Live Track and Off Track themes remain planned and are dimmed in Settings.

## Download and play

Download the package for your computer from [Releases](https://github.com/jimmyhtz/horse-racing-sd/releases). You do not need a GitHub account or the development tools to play.

| Computer | Package | Installation |
| --- | --- | --- |
| Windows 10/11, 64-bit Intel or AMD | Windows Setup.exe | Run the installer. It installs for your account and creates a Start menu shortcut. |
| Windows portable | Windows-x86_64.zip | Extract the entire folder, then run Horse Racing.exe. Keep the adjacent PCK file. |
| macOS, Intel or Apple Silicon | macOS-universal.zip | Extract and move Horse Racing.app to Applications. This early build is not Apple-notarized. |
| Linux, Intel or AMD | Linux-x86_64.tar.gz | Extract, run ./horse-racing or ./install.sh for a user-menu shortcut. |
| Linux, ARM64 | Linux-arm64.tar.gz | Same steps on an ARM64 Linux desktop. |

The first public version is a prerelease. Windows is the primary locally tested platform. The native CI checks cover parsing, help, and packaged startup where a runner is available. A complete interactive and audio test on macOS and Linux still needs community testing. The Windows installer is unsigned. Operating systems may show an unidentified-publisher prompt. Do not disable system protections. Read the release notes and use only downloads from this repository.

Start with the [online Quick Start](https://jimmyhtz.github.io/horse-racing-sd/QUICK_START.html), or press **F1** in the game. Each Settings page and setting has context-sensitive help. The [full manual](https://jimmyhtz.github.io/horse-racing-sd/USER_MANUAL.html) and quick start are also available offline beside the installed game.

## What is included

- One real player is active initially. Select another player to join, or cycle V mode for virtual opponents.
- Two announcers use installed system voices. Windows stages a local speech worker to produce measured speech clips. macOS and Linux use system speech; available voices differ by computer. Linux speech may require Speech Dispatcher and a compatible voice package.
- Settings apply immediately. Profiles save presentation preferences; saved games include the game state and its settings. Revert returns to the settings from when that visit began.
- Race Control changes the race presentation while preserving the modeled finish order and chances. Replay travel and duration do not decide whether a close second/third finish qualifies.
- Credits are game counters. This is entertainment software, not a certified real-money gambling system.

This is an independent project. It is not affiliated with or endorsed by the makers or owners of Sigma Derby. No original cabinet logo or proprietary game software is included. Historical payout-card data is a fan transcription with provenance and may contain errors.

## Privacy and saved games

Play is local. Diagnostic records remain on your computer until you explicitly export and share them. Optional support links open PayPal in your browser. The installer and uninstaller do not remove saved games. Do not attach a saved game or a raw diagnostic archive to a public issue without reviewing it for personal information.

## Source and license

Copyright 2026 Jim Holtz. Original project code and assets are licensed under **GNU GPL version 3.0 only**. Distributed modifications must meet that license's source-distribution terms. See [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the engine, recording, data provenance, and other included notices.

The source for each released package is tagged beside its download. See [BUILDING.md](BUILDING.md) for reproducible build steps and [CONTRIBUTING.md](CONTRIBUTING.md) for contributions and bug reports.

Optional support for hosting and development costs: [PayPal](https://www.paypal.com/paypalme/SuperpuppySD). There is no payment requirement and no paid feature unlock.

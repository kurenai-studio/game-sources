# Contributing

Use GitHub Issues to describe a bug, your operating system, the release version, and the shortest steps that reproduce it. Export Log in Settings can help diagnose race, sound and frame-rate problems. Review an archive before sharing it publicly; do not post PINs, private player images or saved games.

Changes to race probability, whole-credit payouts, card rotation, entropy, or movement need mathematical and regression evidence. Presentation work should leave those systems unchanged. Work with isolated user-data storage and never test against a player's saved game in place.

Help content lives in docs/help_topics.json. After changing it, run python tools/build_help.py and the help tests. Update planned/active status when a setting becomes operational. Announcer phrases and card data have separate data files so corrections do not require rewriting the interface.

Submit changes as a pull request with the problem, resulting behavior and checks performed. Contributions are provided under GPL-3.0-only. Preserve attribution and provenance for third-party material.

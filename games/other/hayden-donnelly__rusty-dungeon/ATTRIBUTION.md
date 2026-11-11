# Attribution — rusty-dungeon

- **Authors / upstream owner:** [Hayden Donnelly](https://github.com/hayden-donnelly)
- **Upstream:** https://github.com/hayden-donnelly/rusty-dungeon
- **License:** MIT (see `LICENSE`) — copyright 2025 Hayden Donnelly (git blob `c6a53d427920eaa1507e53f0ede154142457c84e`)
- **Pinned commit:** `55b0c66ec4916eda5d19b46cbb6deb839ac5705e` (default branch `main`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference.

**Third-party notes:**
- Engine / platform: Linux x86-64 terminal (Rust + inline assembly, `no_std`, no C runtime). Gameplay source is `src/main.rs` (md5 `c752103ae94ec882e800b2508ff0cd01`).
- This is a complete playable ASCII dungeon: arrow keys move, space dismisses on-screen messages, Q quits. The player must find a key.
- No bundled TTF/OTF, no images or audio, no EXE, no DLL, no Git LFS, and no third-party game assets.
- `src/flake.nix` and `src/flake.lock` describe a Nix dev shell for rustc 1.89.0-nightly (fenix). The flake sets `allowUnfree` on nixpkgs but does not add unfree packages; build inputs are only the rustc/cargo toolchain.
- Build: `rustc -C panic=abort -C link-arg=-nostartfiles main.rs`, then run `./main` on x86-64 Linux.

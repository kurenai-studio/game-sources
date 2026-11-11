# Attribution — Wolf-80

- **Authors / upstream owner:** [Wojciech Graj](https://github.com/wojciech-graj)
- **Upstream:** https://github.com/wojciech-graj/Wolf-80
- **License:** MIT (see `LICENSE`) — copyright 2021 Wojciech Graj (git blob `3fa19ac2b7121c12aeaaaaf9377eb7e927ce66b0`)
- **Pinned commit:** `db7d3f00f1be87a32df0fc90dd48096bd2ed6818` (default branch `master`)
- **Collected by:** bot e
- **Collected at:** 2026-11-11 (Asia/Shanghai)

This directory is a redistributable source snapshot of the upstream repository at the pinned commit, for internal reference.

**Third-party notes:**
- Engine / platform: TIC-80 (retro fantasy console). The playable cartridge is `src/wolf-80.tic` (md5 `39bed0f878c8e12546524ea175d67b56`). Gameplay source is `src/game.lua` (md5 `8e4aec38f9d6c6803f933da9e2658abd`); the raycast renderer is `src/raycast.lua` (md5 `14ef4d4e9d711e33233f4f848410dc01`).
- The game is inspired by Wolfenstein 3D but uses original TIC-80 pixel art and code by Wojciech Graj, not official Wolf3D assets or id Software files. No bundled TTF/OTF, no EXE, no DLL, no Git LFS.
- The README lists music and SFX as planned features that were not added; the snapshot contains no music bank.
- Author screenshots and original texture/HUD reference images under `src/screenshots/` are retained, including `scr1.png` (md5 `089945d51103d0aa1ace851d965c963b`), `scr2.png` (`9567736faf0cd760a05fa0fe7f89fbce`), `scr3.png` (`d504f93886dea53cb090963c2c2faf0e`), plus `textures.png`, `hud.png`, `enemy.png`, and `half-height.png`.
- Omitted three non-redistributable Lode Vandevenne raycasting-tutorial diagrams (`src/screenshots/raycasthit.png` md5 `2d6379a582efd67c10be8fb5f97bd14c`, `raycastdelta.png` md5 `1671411281843d0b739039a301d11173`, `raycastperpwalldist.png` md5 `68582889051f583fdef90e3d6848461e`). They are Copyright (c) 2004–2007 Lode Vandevenne, All rights reserved, and may not be copied without permission (https://lodev.org/cgtutor/legal.html). The README may still link to the original tutorial text.
- The upstream repository is archived; this snapshot is the default-branch tip. Playable online: https://tic80.com/play?cart=2333

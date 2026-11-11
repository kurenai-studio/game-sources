# Attribution / 归属说明

## English
- **Game**: IA — jeu de dames (TIPE-Jeux-De-Dames)
- **Author**: Loris Sogliuzzo
- **Upstream**: https://github.com/SogliuzzoL/TIPE-Jeux-De-Dames
- **License**: MIT (see `LICENSE`; Copyright 2026 Loris Sogliuzzo)
- **Engine**: pygame
- **Snapshot commit**: `b0075f7d0eb833865300eb3dbe23d116d70b0855`
- **Collected by**: bot b
- **Collected at**: 2026-11-10T19:24:35-08:00 (America/Los_Angeles)
- **Claim issue**: #4123
- **Notes**: Complete international draughts (10×10 board, 20 pieces per side) with a Pygame interface, forced captures, promotion to king, and a draw after 25 moves without a capture. Supports human-vs-bot and bot-vs-bot, with on-screen win/draw counts. Default `src/config.json` is human vs the trained evolutionary agent (`bot_used` = 2). UI uses system fonts only (`pygame.font.SysFont`); no bundled TTF/OTF, audio, EXE, DLL, or LFS. Upstream README notes that the minimax bot is a stub and that `reconnaissance_image.py` is an exploratory script whose input image is not shipped; neither is required for the default playable path. CLEAN. Claim #4123.

## 中文
- **游戏**: IA — jeu de dames（TIPE-Jeux-De-Dames）
- **作者**: Loris Sogliuzzo
- **上游仓库**: https://github.com/SogliuzzoL/TIPE-Jeux-De-Dames
- **许可证**: MIT（见 `LICENSE`；Copyright 2026 Loris Sogliuzzo）
- **引擎**: pygame
- **快照提交**: `b0075f7d0eb833865300eb3dbe23d116d70b0855`
- **收集者**: bot b
- **收集时间**: 2026-11-10T19:24:35-08:00（America/Los_Angeles）
- **认领 Issue**: #4123
- **备注**: 完整的国际跳棋（10×10 棋盘，每方 20 枚棋子），带 Pygame 界面、强制吃子、升变为后，以及 25 步无吃子则和棋。支持人机与机机对弈，并在界面统计胜负和棋。默认 `src/config.json` 为人机对弈，对手为已训练的演化智能体（`bot_used` = 2）。界面仅用系统字体（`pygame.font.SysFont`）；无捆绑 TTF/OTF、音频、EXE、DLL 或 LFS。上游 README 说明 minimax 机器人为草稿，且 `reconnaissance_image.py` 为缺少输入图的探索脚本；默认可玩路径不依赖这两者。CLEAN。认领 #4123。

本目录为上游源码快照，仅供内部查阅与研究；版权归原作者所有，再分发请遵循 MIT。

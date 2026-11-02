# Maze Runner 🧩

一款基于 [Phaser 3](https://phaser.io/) 的随机迷宫游戏。每一关都是程序实时生成的全新迷宫：找到出口、收集金币、争取用最少的步数和最短的时间通关。

纯前端实现，**零依赖、零构建、零素材**：所有贴图由代码绘制，音效由 WebAudio 实时合成。

## ✨ 特性

- **无限关卡**：递归回溯算法生成迷宫，关卡越往后迷宫越大
- **三种难度**
  - 简单：迷宫较小、无迷雾、5 次提示
  - 普通：迷雾视野、出口可见、3 次提示
  - 困难：大型迷宫、狭窄视野、出口隐藏、1 次提示
- **迷雾探索**：走过的区域会留下记忆，未探索区域保持黑暗
- **路线提示**：按 H 用 BFS 算出到出口的最短路线（扣 50 分）
- **计分系统**：金币 + 通关奖励 + 路线效率 + 速度奖励 + 剩余提示奖励
- **最高纪录**：按难度保存在浏览器本地
- **手机适配**：滑动屏幕即可操作，角色会沿通道自动前进，遇到岔路自动停下
- **8-bit 音效**：可随时静音

## 🎮 操作

| 按键 | 功能 |
| --- | --- |
| 方向键 / WASD | 移动 |
| H | 显示最短路线提示 |
| P / Esc | 暂停 / 继续 |
| R | 重新开始本关 |
| M | 静音开关 |
| Enter / 空格 | 通关后进入下一关 |
| 滑动屏幕（手机） | 沿通道自动前进 |

## 🚀 运行

不需要安装任何东西：

```bash
git clone https://github.com/chenzy1183/phaser-maze-runner.git
cd phaser-maze-runner

# 方式一：直接双击 index.html 用浏览器打开

# 方式二：起一个本地静态服务器（推荐）
python3 -m http.server 8080
# 然后访问 http://localhost:8080
```

### 部署到 GitHub Pages

仓库 **Settings → Pages → Build and deployment**，Source 选 `Deploy from a branch`，分支选 `main`、目录选 `/ (root)`，保存后等一两分钟即可通过 `https://chenzy1183.github.io/phaser-maze-runner/` 在线游玩。

## 📁 项目结构

```
phaser-maze-runner/
├── index.html              # 入口页面（通过 CDN 加载 Phaser 3.80）
├── style.css
└── src/
    ├── config.js           # 画布尺寸、配色、难度参数、本地存储
    ├── maze.js             # 迷宫生成（递归回溯 + braid 环路）与 BFS 寻路
    ├── sfx.js              # WebAudio 合成音效
    ├── ui.js               # 按钮组件
    ├── main.js             # Phaser 游戏配置与启动
    └── scenes/
        ├── BootScene.js    # 程序化生成贴图
        ├── MenuScene.js    # 主菜单 / 难度选择
        └── GameScene.js    # 游戏主逻辑：移动、迷雾、金币、提示、结算
```

## 🔧 自定义

难度参数都在 `src/config.js` 的 `DIFFICULTIES` 中，可以调整：

- `baseCols` / `baseRows`：第一关迷宫大小
- `growth`：每关增长幅度
- `braid`：环路比例（越大岔路越多、越容易）
- `fogRadius`：迷雾视野半径
- `exitVisible`：迷雾中是否显示出口
- `hints`：每关提示次数

## 📄 License

[MIT](LICENSE)

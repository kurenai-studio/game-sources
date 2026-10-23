# 深渊幸存者（Abyss Survivors）

幸存者割草（Survivors-like）单机网页游戏（Phaser 3，零依赖单文件可玩）。

## 内容一览

| 模块 | 内容 |
|------|------|
| 经典关卡模式 | **10 个主线关**（逐关解锁，每关 4 分钟；关底 Boss 登场后停止小波增援，Boss 战是 DPS 检验——Boss 自身的召唤仍会继续）+ **3 个趣味关**（无限火力 / 疯狂成长 / 怪物潮，独立解锁不占主线进度）；第 7 关地面有**熔岩池**、第 8 关有**游荡幽魂**两类环境危害，`levels.json` 的 `hazard` 字段可继续扩展 |
| 无尽模式 | 45 秒一档阶梯刷怪（15 档打完后按轮次继续加密）、精英周期登场、Boss 每 210 秒轮番且血量递增；**属性硬上限每生存 2 分钟放开 12%（最多翻倍），仅无尽模式生效**；按难度独立记录最长生存时间 |
| 进化模式 | 土豆兄弟式 20 波竞技场：全屏角斗场、波次军备商店（白/绿/蓝/紫/红 5 阶道具、4 商品位、锁定、刷新）、武器合成与 3/6 件同名羁绊；终幕第 20 波必须全歼双首领才判登顶 |
| 难度 | 普通 / 困难 / 噩梦三档（角色属性递减，怪物生命/伤害/移速/密度递增，金币经验加成），各难度关卡进度与纪录相互独立 |
| 武器 | **12 把武器，全部可进化**（满级 + 持有对应被动 → 进化词条）；三选一按权重无放回抽取（已持有武器升级与进化权重更高，鼓励聚焦构筑，不会产生重复卡面） |
| 角色 | **10 个出战角色**，初始武器与专属机制各异，金币解锁 |
| 局外 | 金币商店 12 项永久强化、11 条成就、暂停/结算/音量与音乐开关，进度存 localStorage |
| 音频 | WebAudio 实时合成，零音频素材：音效 + 四和弦慢速铺底 BGM（固定低增益、可关闭、切到后台自动静音） |

数值与系统一律以 `data/*.json` 与 `src/` 为准；早期设计文档与素材源目录（`assets1/`）仅在本地保留，未随仓库发布。

## 素材授权

- `assets/ui/icon-weapon-{boomerang,spore,laser,frost}.png` 来自 [game-icons.net](https://game-icons.net/)（Boomerang / Poison cloud / Laser blast / Snowflake 1），授权 [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/)，作者 Lorc、Delapouite 及 contributors。分发游戏时请保留本署名。

## 运行

需要任意静态服务器（ES Module 不能用 file:// 直接打开）：

```bash
# 方式一：Python
python -m http.server 8137

# 方式二：Node
npx serve .
```

然后浏览器打开 <http://localhost:8137/>。

## 操作

- **WASD / 方向键** 移动；手机/触屏**按住屏幕左半边**拖动（虚拟摇杆）
- 攻击、瞄准、拾取全部自动，玩家只负责走位
- **X** 切换瞄准模式（全自动索敌 ↔ 鼠标光标精准指向，仅键鼠）
- 升级时点击卡片，或按 **1 / 2 / 3** 直接选择；卡片下方的重掷按钮花费局内金币
- **P** 暂停（含音量调节、结束本局、返回主菜单），**M** 静音
- 进化模式波次间歇自动弹出军备商店：3 选 1 免费属性加点 + 4 个商品位（可锁定/刷新/变卖武器/同名合成）
- 死亡或通关后点击画面、按 **R** 重开

## 打包单文件版（分享给其他电脑）

```
node build-singlefile.js
```

生成 **`深渊幸存者.html`**（约 1.6 MB，56 张贴图 base64 内嵌）：引擎、全部代码、素材全部打进一个文件。把它拷到任何电脑（U盘/微信均可），**双击用 Chrome/Edge 打开即玩**——目标电脑无需安装任何东西，也不需要联网。

> 已构建好的版本不必自己打包，直接到 [Releases](https://github.com/qjngbac/abyss-survivors/releases) 下载 `abyss-survivors.html` 即可（内容就是本脚本生成的单文件版，下载后双击即玩）。

- 产物内置看门狗：个别会冻结后台标签的环境里也能自动代打帧完成启动，前台正常游玩时自动休眠
- 任一启动异常会在屏幕左下角显示错误横幅，不会静默黑屏
- 关卡解锁/金币/成就进度存浏览器 localStorage；`file://` 下与 localhost 的进度相互独立

> 约定：改动 `src/` 或 `data/` 后必须重跑 `node build-singlefile.js` 刷新 `深渊幸存者.html`。

## 调试

浏览器控制台可用 `window.__game` 访问游戏实例、`window.__meta` 访问局外进度，例如：

```js
// 直接触发一次升级
__game.scene.getScene('GameScene').onLevelUp();
// 查看当前索敌上限 / 拾取半径
const gs = __game.scene.getScene('GameScene'); [gs.aimDist, gs.player.pickupRadius];
```

## 代码结构

```
index.html            开发入口（Phaser 3 CDN，需配合静态服务器）
build-singlefile.js   单文件打包脚本
data/*.json           所有数值（武器/怪物/关卡/角色/商店/成就/平衡参数），调手感只改这里
src/scenes/           Boot(素材+动画) / Menu / LevelSelect / Character / Shop / Achievements
                      Game(核心战斗+进化模式波次) / UI(HUD+暂停+三选一+结算) / WaveShopOverlay(波次军备商店)
src/entities/         Player(属性与上限/护甲/闪避/复活) / Enemy(6 种 AI 行为) / Pickup(4 种拾取)
src/weapons/          WeaponBase + 12 把武器（魔杖/飞刀/圣光鞭/旋转斧/护体环/圣水/闪电/吸血指环/回旋镖/毒孢子/激光/冰霜新星）
src/systems/          XP / 三选一(含进化与诅咒·加权无放回抽取) / 波次导演(关卡·无尽·进化) / 环境危害(熔岩池·游荡幽魂)
src/difficulty.js     三档难度的数值表（游戏结算与主菜单说明共用同一份数据）
src/fx/Particles.js   粒子特效
src/audio.js          WebAudio 合成音效（零素材）
assets/               56 张实际引用的素材（sprites 32 / ui 20 / tiles 4）
```

内嵌浏览器测试注意：面板切后台会暂停 RAF 导致游戏冻结，可用 `g.loop.step(t)` 手动泵帧推进；先设 `g.loop.smoothStep = false`，再每帧把时间戳 +50ms，实测 2000 帧 ≈ 1.7 秒真实时间即可模拟完 100 秒战斗（Phaser 3.87 的 `Game` 上没有 `render` 方法，绘制在 `TimeStep.step` 内部）。

## 许可证

本项目代码以 [MIT License](LICENSE) 授权，Copyright (c) 2026 qjngbac。

第三方资源：

- 引擎 [Phaser 3](https://phaser.io/)（MIT License），开发入口通过 CDN 引入，单文件版内嵌其发行版。
- `assets/ui/icon-weapon-{boomerang,spore,laser,frost}.png` 来自 [game-icons.net](https://game-icons.net/)（CC BY 3.0），作者 Lorc、Delapouite 及 contributors，详见上方"素材授权"。
- 其余美术素材为本项目自行生成。

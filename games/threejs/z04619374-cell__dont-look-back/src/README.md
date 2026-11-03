# 回头 · Don't Look Back

单人、双视角、左右分屏的 3D 白盒恐怖游戏 demo。照顾身后的人，守住前方的路。

**纯白盒，无美术资源。** 所有角色、手臂、怪物和场景由长方体组成。无模型和贴图；环境音由 Web Audio 合成，拍肩播放打包的女声“Hey!”。Three.js 固定为 0.180.0，随项目附带，运行不依赖外部 CDN、账号或 API 密钥。

## 运行

安装 Node.js 22 或更新版本，在项目目录运行：

```sh
node scripts/serve.mjs
```

打开打印出的地址（默认 `http://127.0.0.1:4173`）。无需 npm install 或构建。也可以直接用任意静态服务器托管 `dist/`。请通过 HTTP/HTTPS 访问，双击 HTML 的 file:// 模式不支持 JS 模块。

## 操作与规则

| 输入 | 行为 |
|---|---|
| 移动鼠标 | 观察 A 视角，抵抗拍肩造成的回头 |
| 左键单击 | B 拍肩，恢复 B 视角面积；同时推动 A 回头 |
| 短按 A | 短暂防御前方攻击 |
| 持续按住 A | 2 秒后锁定强制转身，随后必然失败，鼠标无法抵消 |
| Esc / 切换窗口 | 暂停，冻结计时，清除按键状态 |

左侧是 A，右侧是 B。角色沿道路自动前进，视线转动不会改变行走方向。忽视 B 4 秒后右侧开始缩窄，12 秒没有有效拍肩则消失并失败。拍肩冷却 1.2 秒；冷却期间点击无效。A 完全回头（接近 180°持续 0.2 秒）同样失败。怪物每次攻击仅造成 3/100 伤害，伴有红色边缘、镜头震动和音效；面向前方并处于防御窗口时可以阻挡。

存活 90 秒通关。设置提供灵敏度、音量及减少震动。鼠标锁定不可用时显示说明并支持左键拖动观察。游戏面向电脑鼠标键盘，不提供手机触屏操作；窄屏与触屏设备显示电脑试玩提示。

## 测试与检查

```sh
node --test tests/*.test.mjs
node scripts/check.mjs
```

服务器集成测试会短暂监听随机本地端口，需要允许本地回环连接。纯规则测试可独立运行 `node --test tests/model.test.mjs`。浏览器测试结果与环境限制见 `docs/verification.md`。

## 修改参数

编辑 `dist/js/config.js`：怪物伤害、防御窗口、拍肩力度、联系消退、长按阈值和关卡长度均集中于此。规则位于 `model.js`；渲染位于 `world.js` / `splitView.js`，可以更换表现而不改规则。

## 项目结构

```text
dist/                   可直接部署的完整游戏
  js/config.js          玩法参数
  js/model.js           与浏览器无关的规则与游戏状态
  js/world.js           白盒场景与人物动作
  js/splitView.js       双相机与动态分屏
  js/input.js           鼠标锁定、键盘、失焦处理
  js/ui.js              HUD、开始/暂停/失败/通关
  js/sound.js           合成音效与拍肩女声
  js/main.js            连接、游戏循环与错误处理
  vendor/               固定版本 Three.js 及其许可
tests/                  Node 内置测试
scripts/                本地服务、语法检查、发布打包
docs/                   设计、实现计划和验证记录
.github/workflows/      GitHub Pages 发布流程
```

## 开源与发布

原创代码采用 MIT，Three.js 许可保留于 `dist/vendor/THREE-LICENSE.txt`。引用出处见 `THIRD_PARTY_NOTICES.md`。

这是一个可发布的源码项目；尚未创建公开 GitHub 仓库。将源码包上传到你选定的仓库后，在仓库 Settings → Pages → Source 选择 GitHub Actions，运行附带的 Pages 工作流即可部署。也可使用 Netlify、Cloudflare Pages 等静态托管，将发布目录设为 `dist`，无需构建命令。

```sh
node scripts/package.mjs
```

会在 `output/` 生成公开源码 ZIP 与文件校验清单；自动排除 Git 元数据、私有 Sites 标识、本地输出和未使用的概念图。Sites 的托管配置保存在 `.openai/hosting.json`，不含令牌，但不会进入公开源码包。

## English

A single-player, dual-camera whitebox horror prototype. Left: A's forward view and incoming monsters. Right: B's view of A's back and B's hands. Click to tap A's shoulder and restore B's shrinking viewport, then counter the resulting turn with the mouse. Tap A to guard; holding it for two seconds irreversibly turns A around and ends the run. Monster damage is low, feedback is prominent. Survive 90 seconds.

Run `node scripts/serve.mjs`, open the printed local URL. No installation or build required. Desktop mouse/keyboard and WebGL are required. All geometry is procedural; a bundled female “Hey!” accompanies shoulder taps. MIT source with vendored Three.js MIT notices. See the commands above for tests and GitHub Pages deployment.

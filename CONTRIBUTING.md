# 共创规则（game-sources）

面向协调 bot（master）与执行 bot（a–e）。强度高于原无限画布项目：持续搜、认领、开 PR，协调节奏约 **每 1 小时**。

## 目标

把 GitHub 上可再分发的**完整游戏**（或可独立游玩的 demake / jam 作品）源码复制进本库 `games/`，便于内部查阅与二次研究。不是星标列表，是带归因的源码快照。

## 许可证白名单（必须满足其一）

允许：`MIT`、`Apache-2.0`、`BSD-2-Clause`、`BSD-3-Clause`、`ISC`、`Zlib`、`Unlicense`、`CC0-1.0`、`MPL-2.0`、`GPL-2.0`、`GPL-3.0`、`AGPL-3.0`、`LGPL-2.1`、`LGPL-3.0`、`Artistic-2.0`、明确写明可再分发的自定义 OSS。

拒绝：无 LICENSE、仅 README 写 “all rights reserved”、专有引擎示例未开源资源、Steam/商业资源包、明确禁止再分发的条款。

不确定时：**跳过**，在 PR 描述里说明原因，不要硬塞。

## 收录标准

- 主体是**游戏**（可玩），不是纯引擎 / 纯框架 / 纯素材包（引擎 demo 若本身是完整小游戏可收）。
- 源仓库公开，且默认分支有可检出的源码。
- 单仓体积尽量 < 200MB（不含大型二进制资源时优先；过大则只收源码目录并在 `SOURCE.json` 注明 omit）。
- 同一上游只收一次；fork 仅当有实质改动且许可证仍合规。

## SOURCE.json 字段（必填）

```json
{
  "upstream": "https://github.com/OWNER/REPO",
  "owner": "OWNER",
  "repo": "REPO",
  "default_branch": "main",
  "commit": "<full sha of snapshot>",
  "license_spdx": "MIT",
  "engine_or_genre": "godot",
  "collected_by": "a",
  "collected_at": "2026-10-23T00:00:00-07:00",
  "notes": ""
}
```

路径：`games/<engine_or_genre>/<owner>__<repo>/`

## 认领与防撞车

1. 开 Issue：标题 `claim: OWNER/REPO`，标签 `status:claimed` + `bot:<letter>`。
2. 认领后 2 小时内应开出 PR，否则其他 bot 可接手（在原 Issue 评论 `steal` 并改标签）。
3. 推送前检查 `catalog/claimed.json` 与已有 `games/**/SOURCE.json` 的 `upstream`，禁止重复。
4. 每人同时最多 **2** 个进行中认领（比画布项目更高强度，但仍要控并行）。

## PR 规范

- 分支：`bot/<letter>/<owner>-<repo>`
- 标题：`add: OWNER/REPO (license)`
- 内容：仅新增该游戏目录 + 必要时更新 `catalog/INDEX.md` / `claimed.json`
- 描述必须含：上游链接、许可证、commit SHA、体积粗估
- squash-merge；master **只 COMMENT 审查，不 APPROVE**（与画布项目一致时可沿用）
- CI：无强制构建；审查重点是许可证与归因完整性

## 执行约束（全员）

- **只在本机（box）跑**：`gh` / `git` / 脚本。禁止 CloudAgent、禁止消耗额外云编码额度。
- 不要对上游提 PR、不要 star 轰炸、不要批量 fork 污染。
- 用 shallow clone / sparse checkout 拉快照，再去掉 `.git` 后提交快照。
- 中文向 master / 群里汇报进度即可。

## 引擎/类型标签（engine_or_genre）

优先：`godot` `unity` `unreal` `love2d` `pygame` `phaser` `threejs` `libgdx` `monogame` `defold` `rpgmaker` `browser` `retro` `other`

## 强度

相对无限画布（约 4 小时一轮）：本项目协调约 **1 小时**一轮；各 bot 空闲即继续搜下一目标，无需等下一轮闹钟。

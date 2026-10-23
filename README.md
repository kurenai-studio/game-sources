# game-sources

Kurenai Studio 的开源游戏源码汇总库：从 GitHub 收集可再分发的游戏源码，集中镜像到本仓库，并保留许可证与归因。

## 目录结构

```
games/
  <engine-or-genre>/          # 如 godot / unity / love2d / pygame / browser / other
    <owner>__<repo>/          # 源仓库 owner/repo，斜杠改成 __
      SOURCE.json             # 必填元数据（见 CONTRIBUTING.md）
      LICENSE                 # 上游许可证全文（或指向）
      ATTRIBUTION.md          # 作者、链接、许可证摘要、收录日期
      src/                    # 上游源码快照（不含 .git）
catalog/
  INDEX.md                    # 总目录（自动或手工维护）
  claimed.json                # 认领锁，避免重复
```

## 硬性约束

1. **只收录允许再分发的开源游戏源码**（见 `CONTRIBUTING.md` 许可证白名单）。
2. **禁止**闭源、未授权、仅“查看不可再分发”、或许可证不明的仓库。
3. 每条收录必须带 `SOURCE.json` + `ATTRIBUTION.md` + 上游 `LICENSE`。
4. 所有工作在协调 bot 的电脑上完成；**禁止使用 CloudAgent / 云编码额度**。

## 协作

共创规则与认领流程见 [CONTRIBUTING.md](./CONTRIBUTING.md)。Issue/PR 标签约定见同文件。

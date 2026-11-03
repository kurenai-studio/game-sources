---
name: update-issues
description: 在本機手動依時事更新今日群島的 data/issues.json，照每日例行任務同一份守則，最後開 PR。Use when 使用者說「更新議題」「手動跑一次議題更新」「補幾則新聞議題」「這則新聞加進島上」，或輸入 /update-issues。
---

# 手動更新議題

這是每日雲端例行任務的本機版。規則照 `docs/routine-prompt.md` 和 `docs/update-guide.md`，這裡只寫本機不同的地方。

## 步驟

1. 讀上面兩份文件。
2. `git fetch origin`，從 `origin/main` 開分支 `issues/<台北今天日期>`（日期取法見 routine-prompt 步驟 1）。
   - `git ls-remote --heads origin issues/<日期>` 有結果時，改用 `issues/<日期>-manual`。
3. 使用者有指定新聞或議題，就從那則開始；沒有指定，照 routine-prompt 步驟 4 逐島搜尋。
4. 新來源照 routine-prompt 步驟 6 用 WebFetch 讀內文。本機網路沒被擋，可以再用 `curl -A 'Mozilla/5.0'` 確認回 200。
5. 照 routine-prompt 步驟 7 驗證。
6. **commit 前先把改動表給使用者看**，格式用 update-guide 的改動表格式，使用者確認後才 commit。
7. 收尾：沒有更新、或驗證修兩輪仍失敗時，不提交。通過時只 commit `data/issues.json`，push 分支並開 PR 到 main，內文用改動表格式。**不要推 main，也不要合併**：手動更新由使用者自己審，不照例行任務直接推 main 的做法。

## 回報

- 改了哪幾則。
- PR 連結。
- 有哪些候選議題沒收，為什麼不收。

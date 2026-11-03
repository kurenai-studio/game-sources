---
name: preview
description: 把今日群島目前的工作目錄 build 好、驗證後上傳成 Cloudflare 預覽版並回報網址，不影響正式站。Use when 使用者說「給我預覽」「上傳預覽版」「我想先看看效果」「部署到測試」，或輸入 /preview。
---

# 上傳預覽版

任何一步失敗（含上傳時未登入或沒有 token）就停下來回報，不往下做。

1. 跑 `AGENTS.md`「指令」裡的測試、`sh build.sh` 和語法檢查。
2. 上傳：用 `AGENTS.md`「Git 與部署」寫的 wrangler 版本跑 `versions upload --message "<分支名或說明>"`，從輸出取得 `Version Preview URL`。
3. 用 curl 確認預覽網址回 200，而且內容是這次的版本。比對一段這次改動才有的字串。
4. 回報：
   - 預覽網址。
   - 這次包含哪些改動，用 `git log origin/main..HEAD --oneline` 加上未 commit 的檔案。
   - 正式站沒有變動。

## 不要做

- 不要跑 `wrangler deploy` 或 `wrangler versions deploy`。那兩個會更新正式站，正式站只能透過合併到 main 由 GitHub Action 部署。

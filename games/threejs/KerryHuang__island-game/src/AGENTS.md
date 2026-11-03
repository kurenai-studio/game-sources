# 今日群島：給 coding agent 的專案說明

一座虛構城市的 3D 議題地圖：12 座六角形島是議題分類，島上的建物是取材自台灣新聞的議題。單一 HTML 檔，Three.js 0.160.0 從 jsDelivr 載入，沒有建置工具或框架。

- 線上版：https://island-game.kh-lab.workers.dev
- 使用者文件：`README.md`、`docs/introduction.md`、`docs/manual.md`
- 開發細節：`docs/development.md`
- 議題怎麼寫：`docs/update-guide.md`

## 回覆與文件

- 一律用繁體中文，技術名詞保留英文，中英文之間留半形空格。
- 改了行為就同步改對應文件。介面與操作改 `docs/manual.md`，資料格式改 `docs/development.md`，議題規則改 `docs/update-guide.md`。

## 結構

- `parts/`：原始碼片段。`build.sh` 依檔名順序串成一個 `<script type="module">`，所以檔案之間共用同一個 module scope。
- `data/issues.json`：議題，是唯一會隨時事變動的檔案。build 時會嵌成 `const ISSUES = …;`，放在 `parts/10-data.js` 前面。
- `scripts/validate.mjs`：驗證 `issues.json`。`build.sh` 會先跑它，不通過就不 build。
- `tests/*.test.mjs`：`node:test` 測試。
- `.github/workflows/`：`check.yml` 在 PR 時跑測試加 build，`deploy.yml` 在 main 有新提交時部署到 Cloudflare Workers。

## 指令

```sh
node --test tests/*.test.mjs     # 測試（Node 22 不接受目錄參數）
node scripts/validate.mjs        # 驗證議題，通過時印 ok N issues
sh build.sh                      # 產生 index.html / preview.html / dist/index.html（皆不進版控）
python3 -m http.server 8765      # 本機預覽 http://localhost:8765/preview.html
```

語法檢查：

```sh
sed -n '/<script type="module">/,/<\/script>/p' index.html | sed '1d;$d' > /tmp/check.mjs && node --check /tmp/check.mjs
```

## Git 與部署

- **main 一有新提交就會自動部署到正式站。** 不要直接推 main，一律開分支、發 PR，等 PR 檢查通過。唯一例外是每日議題更新例行任務，見下方。
- 用 `git status --short` 確認要加的檔案，逐檔指名 `git add`，不要用 `git add -A` 或 `git add .`。
- 不要合併 PR，除非使用者明確說可以。
- 部署到正式站、刪除遠端分支，都要先問使用者。
- 要給使用者看效果，用 `npx -y wrangler@4.155.0 versions upload` 上傳預覽版。這不會影響正式站。

## 每日議題更新

- `/schedule` 雲端例行任務每天台北 07:00 執行，指示在 `docs/routine-prompt.md`。它只改 `data/issues.json`，驗證通過後直接推 main 並自動部署，不經 PR 與人工審。
- 推不上 main（保護規則、衝突）時，它會改推分支 `issues/YYYY-MM-DD` 並開 PR。
- 手動更新議題（`/update-issues`）仍然走 PR。
- 雲端執行環境會擋掉 curl 連新聞網站，來源有沒有效以 WebFetch 讀不讀得到內文為準。

## 容易踩的坑

- THREE 是在 boot 時用動態 `import()` 載入的。任何用到 THREE 的東西都不能在 module 頂層建立，例如 `new THREE.Vector3()` 或 `Color`，要延後到初始化之後。
- 所有隨機數都來自固定種子 `mulberry32(20261029)`。在建模或配置時多呼叫或少呼叫一次 `rand()`，後面整座城市的細節都會跟著變。
- `index.html` 也會發布成 claude.ai artifact：
  - 檔案從 `<title>` 開始，不加 doctype。
  - 外部 script 只能來自 cdnjs、jsDelivr、unpkg。
  - 頁面只收得到 `#hash`，所以語言切換用 `#en`。
- 議題文字會嵌進 `<script>`，`build.sh` 會把 `</` 跳脫成 `<\/`。來源連結只對 https 網址輸出 `<a>`。
- 細項依 heat 由高到低、再依 `updated` 由新到舊排序。排第一的佔島中央的主位，所以 JSON 裡的順序沒有意義。
- 時段高亮（`dayCycle.lit`）寫的是模型種類，不是議題 id。

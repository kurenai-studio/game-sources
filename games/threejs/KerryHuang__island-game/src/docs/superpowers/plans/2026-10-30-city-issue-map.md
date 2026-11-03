# 城市議題地圖 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把今日群島從「政見書」改成「虛構城市＋真實議題」的議題地圖，附上真實新聞來源的首版內容，在分支上開 PR 給 Kerry 審。

**Architecture:**
- 細項搬到 `data/issues.json`，由 `build.sh` 嵌成 `const ISSUES = …;` 放在 `10-data.js` 前面，維持單一 HTML。
- `scripts/validate.mjs` 用純 Node 驗證 JSON，以 `node:test` 測試。
- 前端改的地方：卡片、清單、時段高亮（改依模型種類）、熱度旗。

**Tech Stack:**
- Three.js 0.160.0（既有）。
- Node 內建 `node:test` 與 `node:assert`，不引入套件。
- `sh build.sh`。

**Spec:** `docs/superpowers/specs/2026-10-30-city-issue-map-design.md`

**範圍外：**
- `/schedule` 例行任務。
- GitHub Action 自動部署。

這兩件等 Kerry 審過首版再做。

## Global Constraints

- 12 座島的 id、名稱、q/r、ground、tree、band 都不改。
- 細項欄位固定為：`id, name, en, model, status, heat, what, why, views, sources, updated`。
  - 移除 `phase`、`desc`、`facts`，不留相容層。
- 欄位值的限制：
  - `status` 只能是 `new` / `debating` / `progress` / `settled`。
  - `heat` 是 0 到 3 的整數；heat 3 全城不超過 6 則。
  - 每島 3 到 8 則。
  - `views` 2 到 3 筆，`who` 只能寫角色，不能寫人名。
  - `sources` 1 到 3 筆，皆為 https。至少一筆的 `date` 落在 `updated` 之前 14 天內。
  - id 格式：`<島縮寫>-<YYYY-MM>-<slug>`。
  - `model` 必須是現有 15 種之一。
- 卡片不放任何數字磚。文字裡出現的數字，必須能在來源中找到，並寫成「報導指出…」。
- 介面文字一律繁中，並附 `tr()` 英文對照。細項的 `what`、`why`、`views` 不翻英文。
- git：逐檔指名 `git add`，不用 `-A`；在分支 `feature/issue-map` 上工作，不推 main。
- commit 訊息結尾加 `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`。

## Review Focus

1. **heat 全為 0 或沒有 heat 3**：「本週熱門」區塊要隱藏，不能顯示空標題。測試放在 Task 3 的瀏覽器檢查。
2. **sources 的 url 或 title 含 `<`、`"`**：必須經過 `esc()`，連結要 `rel="noopener"`、`target="_blank"`。測試放在 Task 1 的驗證（url 必須是 https 開頭）與 Task 3 的程式檢查。
3. **某時段 `lit` 的模型種類在全城都沒有對應細項**：該時段不亮任何東西，但不能報錯。測試放在 Task 3。
4. **`#en` 模式下**：狀態、熱度、來源等標籤要有英文。議題內文維持中文，不能出現 `undefined`。測試放在 Task 3。
5. **手機版**：卡片變長，加上來源列表後，34% 高的 sheet 要能捲動，「回到某某島」按鈕要能點到。測試放在 Task 5 的手機模擬截圖。

---

### Task 1：驗證腳本

**Files:**
- Create: `scripts/validate.mjs`
- Create: `data/blocked-names.txt`：一行一個名字，先放新聞常見的台灣政治人物姓名約 20 個，Kerry 可以再補。
- Test: `tests/validate.test.mjs`

**Interfaces:**
- Produces：`export function validate(issues, { islandIds, today, blocked }) -> { errors: string[], warnings: string[] }`
- 以 CLI 執行時：`node scripts/validate.mjs [data/issues.json]` 會從 `parts/10-data.js` 用 regex `/id: '(\w+)', no: '\d\d'/g` 讀出 12 個島 id，`today` 取執行當日。有錯誤就印出並 exit 1，否則印出 `ok N issues` 並 exit 0。

- [ ] **Step 1：寫失敗測試。** 測試在 `tests/validate.test.mjs`，先用一個 `good()` 產生合法的 12 島、每島 3 則的資料。測試案例與斷言如下：
  - `合法資料沒有錯誤`：`errors.length === 0`。
  - `島數不對`：少一個島 id 時，errors 含 `missing island`。
  - `每島 3 到 8 則`：2 則與 9 則都報 `count`。
  - `status 列舉`：值為 `'done'` 時報 `status`。
  - `heat 範圍`：4、-1、1.5 都報錯。
  - `heat 3 超過 6 則`：7 則時報 `heat3`。
  - `views 數量`：1 筆與 4 筆都報錯。
  - `who 是黑名單人名`：報 `who`。
  - `sources 數量與 https`：0 筆報錯，`http://` 報錯。
  - `來源太舊`：updated 為 2026-10-30，唯一來源為 2026-10-10，報 `stale`。
  - `id 格式與重複`：`tr1` 報 `id`，兩則同 id 報 `duplicate`。
  - `model 不在 15 種`：報 `model`。
  - `含舊欄位 facts`：報 `legacy`。
- [ ] **Step 2：** 執行 `node --test tests/`，預期 FAIL，原因是找不到 `scripts/validate.mjs`。
- [ ] **Step 3：實作 `validate()` 與 CLI。** 15 種模型清單寫在檔案內：`house hall booth classroom clinic busstop bikes court farm river stage book coin clock globe`。每則錯誤訊息的格式是 `<島id>/<議題id>: <代碼> <說明>`，代碼就用上面的英文字。
- [ ] **Step 4：** 執行 `node --test tests/`，預期全部 PASS。
- [ ] **Step 5：** 在分支 `feature/issue-map` 上 commit 這三個檔。

### Task 2：首版議題內容（真實來源）

**Files:**
- Create: `data/issues.json`
- Create: `docs/update-guide.md`：更新守則。內容包括設計文件裡的反目標、欄位規則、每島的新聞分類、中立用字、「沒把握就不改」原則，以及 PR 內文格式。

**Interfaces:**
- Consumes：Task 1 的 CLI。
- Produces：`data/issues.json`，key 是 12 個島 id，value 是議題陣列。

- [ ] **Step 1：先寫 `docs/update-guide.md`。** 每座島的新聞分類，例如交通是大眾運輸、道路安全、停車。這份守則也是給 Step 2 研究員看的指示。
- [ ] **Step 2：研究。** 平行派 4 個 subagent，每個負責 3 座島。
  - 每座島找 3 到 4 則台灣近 14 天的真實議題，基準日是 2026-10-30。
  - 只用 WebSearch 實際找到的報導，每則附 1 到 3 個來源，寫明標題、媒體、url、日期。
  - 依守則寫好 `what`、`why`、`views`，`model` 從 15 種裡挑最貼切的。
  - 以 JSON 交回。
- [ ] **Step 3：合併成 `data/issues.json`，評定熱度。** heat 3 全城最多 6 則，依報導量評定。
- [ ] **Step 4：檢查來源連結。** 用 curl 逐一確認所有 url 回應 200（`curl -s -o /dev/null -w '%{http_code}' -L`）。不是 200 的來源就移除；移除後沒有合格來源的議題整則拿掉，再視需要補研究。
- [ ] **Step 5：** 執行 `node scripts/validate.mjs`，預期輸出 `ok N issues`，N 介於 36 到 60。
- [ ] **Step 6：自己抽查。** 抽 6 則，打開來源核對 `what` 和其中的數字有沒有出處。發現錯誤就修正，修完再跑一次 Step 5。
- [ ] **Step 7：** commit `data/issues.json` 與 `docs/update-guide.md`。

### Task 3：資料接線與 UI 改版

**Files:**
- Modify: `build.sh`：在 `parts/08-*` 與 `parts/10-*` 之間，插入 `printf 'const ISSUES = '; cat data/issues.json; printf ';\n'`。
- Modify: `parts/10-data.js`
  - 島資料移除 `items`，每座島的 `summary`、`summaryEn` 改寫成議題分類的描述。
  - `flows` 的 label 依新議題重寫。`evidence` 欄位值不變，語意改為「直接牽動／間接相關／有人提出」。
  - `dayCycle.lit` 改成模型種類陣列，例如上學通勤是 `['busstop','bikes','classroom']`。
  - 檔尾加上：`DATA.islands.forEach((d) => { d.items = sortIssues(ISSUES[d.id] || []); });`
- Modify: `parts/50-ui.js`：改 `PHASES`、`EVIDENCE`、`islandCard`、`itemCard`、`bigNumbers`（刪除）、搜尋、清單，以及 3 處 `lit` 判斷。
- Modify: `parts/05-ui.html`：卡片新段落的樣式，含狀態標籤、熱度、看法列表、來源列表。

**Interfaces:**
- Produces（`10-data.js`）：
  - `sortIssues(list)`：依 heat 由高到低排，同 heat 再依 `updated` 由新到舊，回傳新陣列。
- Produces（`50-ui.js`）：
  - `STATUS = { new: ['剛冒出來','New'], debating: ['討論中','Debating'], progress: ['有進展','Moving'], settled: ['已定案','Settled'] }`
  - `isLit(rec) -> boolean`：`!!S.period && S.period.lit.includes(rec.data.model)`
  - `heatDots(h) -> string`：回傳 h 個實心圓點加上 3−h 個空心圓點，附 `aria-label`。
  - `latestUpdate() -> string`：所有細項 `updated` 的最大值。
- `EVIDENCE` 的文字改為：`official: ['直接牽動','Direct']`、`thematic: ['間接相關','Related']`、`pending: ['有人提出','Proposed']`。

- [ ] **Step 1：** 改 `build.sh` 與 `10-data.js`，然後跑 `sh build.sh`，再對抽出的 module 跑 `node --check`（指令見 `docs/development.md`），預期沒有輸出。
- [ ] **Step 2：改 UI。**
  - `itemCard` 依序呈現：
    1. eyebrow：島名、①、`isLit` 時加註「此時段亮起」。
    2. 標題、縮圖。
    3. 狀態標籤與 `heatDots`。
    4. 「發生什麼」`what`。
    5. 「為什麼跟你有關」`why`。
    6. 「各方怎麼看」：每筆 `<b>who</b> says`。
    7. 「取材來源」：每筆 `outlet · date · <a href target=_blank rel=noopener>title</a>`。
    8. 「更新於 updated」。
    9. 「回到」chip。
  - `islandCard`：eyebrow 改成「議題分類」，列表右側小字改成狀態。
  - 側欄：細項照 `sortIssues` 的順序列出。最上方加「本週熱門」區塊，列出所有 heat 3 的細項，沒有就整塊隱藏。搜尋範圍加上 `what`、`why`、`views[].says`。
- [ ] **Step 3：瀏覽器檢查。** 用 Chrome DevTools 開 `http://localhost:8765/preview.html`，逐項確認：
  - console 沒有錯誤。
  - 點一則議題，卡片的 9 段都在，來源連結可以點。
  - 時間跳到 07:30（上學通勤），所有公車站、單車架、教室類的細項都亮黃色。
  - 在 console 把某時段的 `lit` 改成 `['nonexistent']`，然後重新選取，不能報錯。
  - 在 console 把所有 heat 設成 1 並重繪清單，「本週熱門」要隱藏。
  - 開 `#en`，卡片的標籤是英文，沒有出現 `undefined`。
- [ ] **Step 4：** commit 這次改到的檔案。

### Task 4：熱度旗

**Files:**
- Modify: `parts/45-models.js`：`layoutIsland` 的迴圈裡，heat ≥ 2 的細項在模型右後角加旗子。

**Interfaces:**
- 只用現有的 `kit.local(frame, kind, p, s, c, rot)` 與現有幾何，不新增 kind：
  - 旗桿：`cylinder` 細長，顏色 `PAL.stone`。
  - 旗面：`box`，顏色取島的 `band`。
  - 旗頂：heat 3 用 `glowsphere`，夜晚會亮；heat 2 用 `sphere`。
- 旗桿高度：heat 3 約 1.5，heat 2 約 1.1（模型單位）。位置約 `[.42, 0, -.42]`。實作者可以微調，但不能擋住模型正面，也不能和旁邊的格子重疊。

- [ ] **Step 1：** 實作，然後 `sh build.sh`、跑 `node --check`。
- [ ] **Step 2：** 在瀏覽器分別截白天全景與夜晚 21:00 的圖。白天看得到旗子，夜晚 heat 3 的旗頂會亮；點旗子會選到該細項，因為 owner 是同一個 rec。
- [ ] **Step 3：** commit。

### Task 5：品牌卡、說明視窗、文件、README、預覽版

**Files:**
- Modify: `parts/00-head.html`：
  - 眉標改成「虛構城市 · 議題取材自新聞」，英文 `FICTIONAL CITY · ISSUES FROM THE NEWS`。
  - 新增 `<span id="updatedAt">`，啟動時由 `latestUpdate()` 填入「資料更新於 YYYY-MM-DD」。
  - 載入畫面文字改成「正在整理今天的議題」。
- Modify: `parts/07-finish.html`：說明視窗三步驟改寫成議題地圖的讀法：看熱門旗子 → 點議題看各方看法 → 看來源。
- Modify: `README.md`：
  - 在線上版那一行下面加一行：`**製作過程**：[一份流傳的 prompt 怎麼變成這座 3D 城市](https://kerry-notes.kh-lab.workers.dev/posts/island-policy-city/)`
  - 虛構聲明改成：「城市、角色都是虛構的；議題取材自近期台灣新聞，每則都附來源。」
  - 特色段落照實改寫。
- Modify: `docs/introduction.md`、`docs/manual.md`、`docs/development.md`：照新資料格式和卡片照實改寫。development 要新增：
  - `data/issues.json` 的欄位說明。
  - `node --test tests/` 與 `node scripts/validate.mjs` 的用法。
  - 指向 `docs/update-guide.md`。
- Modify: `NOTES.md`：記下這次的決定，以及驗證過和沒驗證的項目。
- Replace: `docs/images/*.png`：四張截圖重拍，原本的構圖照舊。

- [ ] **Step 1：** 完成上述修改，然後跑 `sh build.sh`、`node --check`、`node --test tests/`、`node scripts/validate.mjs`，四個都要通過。
- [ ] **Step 2：手機模擬。** 開 390×844 的手機模擬，打開一張來源最多的議題卡。sheet 要能捲到底、點得到「回到」chip，然後截圖存成 `docs/images/mobile.png`。
- [ ] **Step 3：預覽版。** 執行 `npx -y wrangler@4.155.0 versions upload`，取得預覽網址。這一步不 promote，正式站不變。如果指令不支援，就在 PR 裡說明改用本機預覽，並標記「未驗證」。
- [ ] **Step 4：** commit，推分支，用 `gh pr create` 開 PR。PR 內文包括：
  - 改動摘要。
  - 預覽網址。
  - 議題數與各島數量。
  - 抽查了哪 6 則。
  - 未驗證項目。
  - 結尾加上 `🤖 Generated with [Claude Code](https://claude.com/claude-code)`。
- [ ] **Step 5：回報 blog session。** 用 SendMessage 傳給 `uds:/tmp/cc-socks/99699.sock`，內容是簡短清單：新名稱與網址、新增或拿掉的功能、還沒寫進文件的決定。

## 收尾

整個分支由一個新的 reviewer 做 code review。合併與正式部署要等 Kerry 審完 PR 再做。

# 開發指南

## 檔案結構

成品是單一 HTML 檔。為了方便編輯，原始碼拆成 `parts/` 底下的片段，由 `build.sh` 依檔名順序串起來：

```
parts/
  00-head.html        <title>、基本樣式、載入畫面、品牌卡
  05-ui.html          工具列、卡片、側欄、HUD 的樣式與 HTML
  06-walk.html        城市日誌、協作線圖例的樣式與 HTML
  07-finish.html      說明視窗、手機版樣式
  08-script-open.html importmap 與 <script type="module"> 開頭
  10-data.js          DATA：城市、島、議題牽連、時段；議題本身在 data/issues.json
  20-core.js          常數、工具函式、渲染器、相機、飛行
  25-env.js           天空、光線、水面、日夜 keyframes
  30-islands.js       程序貼圖、六角島、橋、路網與 Dijkstra、島名標籤
  40-kit.js           零件庫：所有靜態物件走 InstancedMesh
  45-models.js        15 種模型、島內配置、熱度旗
  47-furniture.js     路燈、盆栽、長椅、島上大樹、夜晚光池
  48-world.js         盆地地形、背景樹、遠山、雲、海上小島與帆船
  50-ui.js            選取、高亮、卡片、側欄、HUD、標籤避讓
  60-walkers.js       小人、協作線、badge、城市日誌
  70-finish.js        手機 bottom sheet、說明、reduced-motion、語言切換
  90-main.js          啟動流程、render loop、錯誤畫面
```

```
data/
  issues.json         議題：唯一會隨時事變動的檔案
  blocked-names.txt   views.who 不能出現的人名
scripts/validate.mjs  驗證 issues.json
tests/                validate.mjs 的測試（node:test）
```

`build.sh` 會把 `data/issues.json` 嵌成 `const ISSUES = …;`，放在 `10-data.js` 前面，所以成品仍是單一 HTML 檔。

`build.sh` 產出三個檔案，都不進版控：

- `index.html`：發布成 claude.ai artifact 用。平台會自動包上 `<!doctype>` 與 charset，所以檔案從 `<title>` 開始。
- `preview.html`：補上 doctype 與 charset，給本機瀏覽器預覽。
- `dist/index.html`：內容同 `preview.html`，部署到 Cloudflare 用。

## 本機預覽

```sh
sh build.sh
python3 -m http.server 8765
```

打開 http://localhost:8765/preview.html 。不要直接用 `file://` 開：ES Modules 和 importmap 需要透過 http 載入。

改完程式碼後，可以先用 Node 檢查語法，再進瀏覽器：

```sh
sed -n '/<script type="module">/,/<\/script>/p' index.html | sed '1d;$d' > /tmp/check.mjs
node --check /tmp/check.mjs
node --test tests/*.test.mjs              # 驗證腳本的測試
node scripts/validate.mjs       # 驗證 data/issues.json，通過時輸出 ok N issues
```

## 換內容

### 議題：data/issues.json

議題依島分組，key 是島的 `id`：

```json
{ "traffic": [ { "id": "tr-2026-10-mrt-peak", "name": "捷運尖峰加班車", "en": "Extra peak trains",
    "model": "busstop", "status": "debating", "heat": 3,
    "what": "…", "why": "…",
    "views": [ { "who": "通勤族", "says": "…" }, { "who": "營運單位", "says": "…" } ],
    "sources": [ { "title": "…", "outlet": "…", "url": "https://…", "date": "2026-10-28" } ],
    "updated": "2026-10-30" } ],
  "care": [ … ] }
```

欄位規則、寫法與每座島收哪類新聞，都在[更新守則](update-guide.md)。重點：

- 每座島 3 到 8 則；heat 3 全城最多 6 則。
- 載入時依 heat 由高到低、再依 `updated` 由新到舊排序。排第一的佔島中央的主位，編號 ①②… 也照這個順序。JSON 裡的順序沒有意義。
- heat 3 的議題會在建物右後角插旗，旗頂夜晚發光。
- 改完一定要跑 `node scripts/validate.mjs`。

### 城市與島

```js
city: { name: '今日', en: 'Today', subtitle: '群島', subtitleEn: 'Isles' }
```

注意：`DATA.city` 目前沒有被程式讀取。品牌卡、載入畫面和 `<title>` 上的名稱直接寫在 `parts/00-head.html` 裡。

```js
{ id: 'traffic', no: '01', name: '交通', en: 'Transit', q: 0, r: 0,
  ground: 'stripe', tree: 'round', band: '#db6a41', summary: '…', summaryEn: '…' }
```

- `q`、`r`：六角格的 axial 座標。島和島要彼此相鄰（axial 距離為 1），橋才會自動接上。
- `ground`：地面花紋，可用 `brick`、`speckle`、`stripe`。
- `tree`：島上大樹的樹種，可用 `cone`、`cherry`、`fruit`、`palm`、`willow`、`round`。
- `band`：島緣圖案帶的顏色，也用在清單、卡片和熱度旗上。
- `model`（在議題裡）：可用 `house`、`hall`、`booth`、`classroom`、`clinic`、`busstop`、`bikes`、`court`、`farm`、`river`、`stage`、`book`、`coin`、`clock`、`globe`。寫錯時會退回 `house`，但驗證會擋下。

### 議題牽連

```js
{ id: 'f4', from: 'elder', to: 'traffic', cargo: 'medkit', role: 'elder',
  evidence: 'official', label: '高齡者怎麼出門', en: 'Getting around in old age', count: 7 }
```

- `from`、`to`：島的 `id`。路線會從兩座島前側的步道出發，用 Dijkstra 沿路網和橋算出來。
- `cargo`：搬運物，決定小人手上方塊的顏色和頭上的圖示。可用 `book`、`meal`、`sapling`、`medkit`、`laptop`、`ticket`、`ball`、`letter`。
- `role`：走路的角色，決定配件。可用 `civil`、`researcher`、`elder`、`student`、`parent`、`commuter`、`farmer`、`worker`、`tourist`。`commuter` 會騎腳踏車，速度比較快。
- `evidence`：`official` 是直接牽動（實線），`thematic` 是間接相關（虛線），`pending` 是有人提出（點線）。
- `count`：小人數量，會限制在 4 到 14 之間。

### 一天的時段

```js
{ start: 450, name: '上學通勤', en: 'Morning rush', lit: ['busstop', 'bikes', 'classroom'] }
```

- `start`：從 0 點起算的分鐘數。
- `lit`：這個時段要亮起黃色的**模型種類**。用模型種類而不是議題 id，議題每次更新都會換，時段高亮也不會失效。

## 加一種新模型

在 `parts/45-models.js` 的 `MODELS` 裡加一個函式。模型在單位空間設計：底面 ±0.5、高 0 到 1.5，正面朝 +z。

```js
fountain(L) {
  L('rbox', [0, .03, 0], [.96, .06, .96], '#e8ddcc');           // 底座
  L('cylinder', [0, .1, 0], [.7, .1, .7], PAL.stone);          // 水池
  L('cylinder', [0, .14, 0], [.6, .02, .6], PAL.pastel[1]);    // 水面
  L('glowsphere', [0, .4, 0], .12, PAL.cream);                 // 夜晚會發光
},
```

`L(幾何, 位置, 縮放, 顏色, 旋轉)` 會把零件推進零件庫。幾何可用 `box`、`rbox`、`cylinder`、`cone`、`sphere`、`ico`、`dome`、`torus`、`prism`、`hip`（四坡屋頂），以及夜晚會發光的 `glowbox`、`glowsphere`。所有零件最後依幾何合併成 InstancedMesh，不會增加 draw call。

加完後，在 `scripts/validate.mjs` 的 `MODELS` 清單補上新名稱，議題的 `model` 才能用它。

## 部署

### Cloudflare（公開網站）

設定在 `wrangler.jsonc`，把 `dist/` 當靜態檔案發布到 Cloudflare Workers：

```sh
sh build.sh && npx -y wrangler@4.155.0 deploy
```

網址：https://island-game.kh-lab.workers.dev

新版 wrangler 已把 Cloudflare Pages 併進 Workers，`wrangler pages project create` 在沒有設定檔時會失敗，所以這裡直接用 Workers 靜態網站。

### 自動部署與每日議題更新

- `.github/workflows/check.yml`：每個 PR 會跑測試與 build。
- `.github/workflows/deploy.yml`：main 有新提交就部署到 Cloudflare。需要 repo secrets `CLOUDFLARE_API_TOKEN` 與 `CLOUDFLARE_ACCOUNT_ID`。也可以在 Actions 頁面手動觸發。
- 每日議題更新：`/schedule` 雲端例行任務每天台北 07:00 執行，指示在 [`docs/routine-prompt.md`](routine-prompt.md)。它只改 `data/issues.json`，在任務內跑完 validate、測試與 build 後直接推 main，由 `deploy.yml` 部署，不經 PR。推不上 main 時才改開 PR。

### claude.ai artifact（私人分享）

`index.html` 也發布成了 claude.ai artifact，預設是私人的，要從頁面的 Share 選單分享。artifact 是另一份副本，要在 Claude Code 裡重新發布才會更新，不會跟著 Cloudflare 一起更新。

artifact 的網址只會把 `#名稱` 這種 hash 傳進頁面，query string 傳不進去，所以語言切換用 `#en`，不用 `?lang=en`。

## 設計上的取捨

- **固定種子**：`mulberry32(20261029)` 供應所有隨機，包含 SimplexNoise。調整建模或配置程式時，只要呼叫 `rand()` 的次數變了，後面所有隨機結果都會跟著變，整座城市的細節會換一個樣子。
- **只在需要時渲染**：平常小人和水面一直在動，每一幀都會畫，按「暫停」只會停住時鐘。開啟 reduced-motion 時，畫面只在有互動時才重畫。
- **只有太陽投影**：背景樹、小人都不投影。小人腳下是一張半透明圓形假影子。
- **LOD**：盆栽、灌木、串燈、長椅在鏡頭距離 26 以上時隱藏。
- **標籤避讓**：每次渲染後檢查島名標籤是否和介面面板或其他標籤重疊。重疊時先只留號碼，還是重疊就隱藏，並留 8px 緩衝避免閃爍。

跟原始規格不同的地方，以及驗證過哪些項目，都記在 [`NOTES.md`](../NOTES.md)。改版後的完整規格寫成了提示詞，放在 [`spec-prompt.md`](spec-prompt.md)，可以直接交給 coding agent。

## 已知限制

- 英文版的議題內容、各方看法與來源還是中文。
- `DATA.city` 沒有接上程式，城市名稱要改 `00-head.html`。
- 只有 `validate.mjs` 有自動化測試，畫面的驗證方式是語法檢查加上瀏覽器實測。
- 只在 Chrome 測過，Safari 和 Firefox 都還沒測。

# 規格提示詞

今日群島的完整規格，寫成可以直接交給 coding agent 的提示詞。用途：

- 大改版或重建某個部分時，當作「現在應該長什麼樣」的基準。
- 開新 session 時貼給 agent，讓它不用讀完整個 repo 就知道全貌。

最早的版本是「{示範市}政策島」：虛構政見、數字磚、時程軸。2026-10-30 改成城市議題地圖，這份是改版後的版本。數值都對過 `parts/` 的程式碼；程式碼改了，這份也要跟著改。

---

你是資深 WebGL／Three.js 創意前端工程師兼互動設計師，在 `island-game` repo 裡工作。這個專案叫「今日群島」：一座由 12 座六角形小島拼成的虛構城市，島是議題分類，島上的建物是取材自近期台灣新聞的議題。風格是溫暖的黏土玩具模型城市（微縮模型感）。它是中立的議題地圖，不是任何人的競選文宣。

開工前先讀 `AGENTS.md`，裡面有指令、Git 規則和容易踩的坑。

## 0. 基本約束

- 成品是單一 HTML 檔，原生 ES Modules，不用框架、不用 bundler。
- 原始碼拆在 `parts/`，`build.sh` 依檔名順序串成一個 `<script type="module">`，所有檔案共用同一個 module scope。新檔的編號要排在它依賴的檔案之後，不要改 `10-data.js` 的編號。
- Three.js 固定 0.160.0，importmap 指向 jsDelivr：
  - `"three": "https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.module.js"`
  - `"three/addons/": "https://cdn.jsdelivr.net/npm/three@0.160.0/examples/jsm/"`
  - 只用 OrbitControls、CSS2DRenderer、RoundedBoxGeometry、BufferGeometryUtils、SimplexNoise。
- THREE 在 boot 時用動態 `import()` 載入。用到 THREE 的東西（`new THREE.Vector3()`、`Color`）都不能放在 module 頂層，要延後到初始化之後。
- 不載入任何圖片、3D 模型、字型檔。幾何全用程式產生，貼圖用 canvas 即時畫。字型用系統字 `"Noto Sans TC","PingFang TC","Microsoft JhengHei",sans-serif`。
- 所有隨機都來自 `mulberry32(20261029)`，包含 SimplexNoise 的 random。多呼叫或少呼叫一次 `rand()`，後面整座城市的細節都會變；`kit.add` 內部也會呼叫 `rand()`。
- 初始化整段包 try/catch：WebGL 或 CDN 載入失敗時，在載入畫面顯示錯誤訊息，不要白畫面。localStorage 讀寫走 `parts/20-core.js` 的包裝，一律包 try/catch。
- `index.html` 也會發布成 claude.ai artifact：
  - 檔案從 `<title>` 開始，不加 doctype。`build.sh` 另外產生補上 doctype 的 `preview.html` 與 `dist/index.html`。
  - 外部 script 只能來自 cdnjs、jsDelivr、unpkg。
  - 頁面只收得到 `#hash`，所以語言切換用 `#en`，不用 query string。
- 插入 `innerHTML` 的字串一律包 `esc()`。來源連結只對 https 網址輸出 `<a target="_blank" rel="noopener">`。

## 1. 內容與資料

資料分兩處，程式完全由資料驅動，模型種類由每則議題的 `model` 欄位決定，不寫死在程式裡。

### 議題：`data/issues.json`

唯一會隨時事變動的檔案。`build.sh` 先跑 `scripts/validate.mjs`，通過後把它嵌成 `const ISSUES = …;` 放在 `parts/10-data.js` 前面，並把 `</` 跳脫成 `<\/`。

- 以島 id 分組：`{ "traffic": [ …議題… ], "care": [ … ] }`。每座島 3 到 8 則。
- 欄位：`id`、`name`、`en`、`model`、`status`（`new`／`debating`／`progress`／`settled`）、`heat`（0–3，全城 heat 3 最多 6 則）、`what`、`why`、`views`（2–3 筆 `{ who, says }`）、`sources`（1–3 筆 `{ title, outlet, url, date }`）、`updated`。
- 載入時依 heat 由高到低、再依 `updated` 由新到舊排序；排第一的佔島中央的主位，編號 ①②… 照這個順序。JSON 裡的順序沒有意義。
- 寫法與中立性規則（不寫真實人名與政黨名、各方看法對等、數字要出自來源）在 `docs/update-guide.md`，這份不重複。

### 城市、島、牽連線、時段：`parts/10-data.js` 的 `DATA`

- 12 座島固定不動：`traffic` 交通、`care` 托育、`edu` 教育、`elder` 長照、`sport` 運動、`green` 綠地、`culture` 文化、`youth` 青年、`digital` 數位、`safety` 安全、`eco` 環保、`tour` 觀光。每座島有 `no`、`name`、`en`、`q`、`r`、`ground`（brick／speckle／stripe）、`tree`（cone／cherry／fruit／palm／willow／round）、`band`（圖案帶顏色）、`summary`、`summaryEn`。
- 9 條「議題牽連」（`flows`）：`from`／`to` 島 id、`cargo`（book、meal、sapling、medkit、laptop、ticket、ball、letter）、`role`（civil、researcher、elder、student、parent、commuter、farmer、worker、tourist）、`evidence`（official 直接牽動／thematic 間接相關／pending 有人提出）、`label`、`en`、`count`（限制在 4–14）。
- 7 個時段（`dayCycle`）：`start` 分鐘、`name`、`en`、`lit`。`lit` 寫的是**模型種類**，不是議題 id，議題每天換也不會失效。
- `DATA.city` 目前沒接上程式，城市名稱直接寫在 `parts/00-head.html`。

## 2. 世界佈局

- pointy-top 六角形（頂點朝 ±z）：外接半徑 R=2.02、格距 SPACING=2.28、島面高 TOP=0.65、水面 WATER_Y=-0.18。
- axial→world：x = √3·SPACING·(q + r/2)，z = 1.5·SPACING·r。島與島之間留約 0.45 寬的水道。12 島拼成不規則但彼此相連的輪廓，相鄰（axial 距離 1）的島才會自動接橋。
- 島面：CircleGeometry(R-0.05, 6).rotateZ(π/6).rotateX(-π/2)，MeshStandard roughness .92，貼 256² canvas 程序地面貼圖（磚紋／斑點／條紋），UV 用世界座標 ÷2.2，花紋跨島連續。
- 每島：半徑 1.8 的步道環（寬約 0.28、淺磚色）、外緣路緣 #e4d6c3、頂緣一圈高 0.16 的彩色圖案帶、外圈淺水環（R+0.7）與白色泡沫環（R+0.16，opacity .55）。側壁用和水面相同的 shader，看起來像浮在淺海上。用 polygonOffset 避免 z-fighting。
- 相鄰島之間各一座小拱橋（9 片甲板，sin 拱高 .04–.1），連接兩島步道環的邊中點。
- 行人路網：每島 12 個節點（步道六角形的 6 頂點 + 6 邊中點）連成環，橋連接相鄰島，用 Dijkstra 尋路。
- 島內配置：主位放在 (0, −0.58)、尺寸約 1.15；其餘議題用交錯格子放在內切半徑 1.36 以內，格子大小依數量從 0.62 自動縮到 0.46。
- heat 3 的議題在建物右後角插熱度旗，旗面用島的 `band` 色，旗頂夜晚發光。

## 3. 渲染與相機

- WebGLRenderer：antialias、alpha、PCFSoftShadowMap、SRGBColorSpace、ACESFilmicToneMapping（exposure 1）、pixelRatio = min(devicePixelRatio, 1.75)，手機 1.4。頁面背景 radial-gradient(#fffdf9 → #edddcf)。
- PerspectiveCamera：fov 32、near .3、far 320。
- OrbitControls：damping .07、禁止平移、polar 25°–70°、距離 3–70。
- 全景：方向 normalize(.24, .33, .87)，距離依長寬比：> 1.3 為 28.5、> .8 為 38、其餘 56。
- 選取時飛行 800ms easeInOutCubic，同時插值 position 與 target。使用者一按下指標就取消飛行。
  - 島 offset (3.7, 7.15, 8.4)：原規格 (2.75, 5.3, 6.2) 放大 1.35 倍，讓整座島和周邊都入鏡。
  - 建物、小人 offset (1.6, 2.5, 3.2)。
  - 牽連線：飛到兩島中點，offset (2.75, 5.3, 6.2) 乘上 (1 + 兩島距離/8)。
  - 桌面版左側有卡片時，目標往右偏 1.5，近距離時依 offset 長度 ÷ 8.6 等比縮小。
  - 手機開卡片時 offset 再放大 1.3 倍，目標往鏡頭方向移 offset 長度的 .14，讓物件落在 bottom sheet 上方。
- 鳥瞰模式：camera = target + (0.01, 42, 6)。

## 4. 環境、光線與日夜

- 天空：SphereGeometry(170)，BackSide 的 ShaderMaterial（depthWrite false、fog false），uniforms uTop、uHorizon、uSunDir、uSun、uNight。顏色 = mix(horizon, top, smoothstep(-.02, .55, dir.y))，加太陽光暈 pow(dot, 18)·.35，夜晚加星星（floor(dir·180) 做 hash，大於 .9965 才亮）。
- 霧：Fog(0xf4eee3, 42, 150)，顏色永遠等於當下的 horizon。
- 光：HemisphereLight(0xeef6fa, 0x8f8270, 1.3)；太陽 DirectionalLight(0xfff1de, 2.8)，castShadow、map 2048、shadow camera ±20／±22、near 1、far 90、bias −.0006、normalBias .045、radius 3；補光 DirectionalLight(0xbfd6ff, .35)。只有太陽投影。
- 水：CircleGeometry(160, 64) 的 ShaderMaterial，淺色 #a4d4da、深色 #6fa9b8，兩組交疊正弦波做色彩漂移，離城市越遠越深，加微小閃光，支援 fog。
- 日夜 keyframes（`parts/25-env.js`），欄位依序為分鐘、skyTop、horizon、sunColor、sunI、hemiSky、hemiGround、hemiI、night、water，之間線性插值：
  - 0: 1e2c58, 3f4f80, b4c2ff, 1.15, 94a2d8, 64566a, 1.85, 1, 5a88b2
  - 300: 26365f, 4c5688, b8c4ff, 1.0, 96a4da, 66586c, 1.85, 1, 5c8ab4
  - 360: 7f8fc4, f6c3a6, ffb48a, 1.3, f3c6b5, 6b5a5a, 1.1, .55, 8fb7c4
  - 450: a9d1ea, fbe6d3, ffe2c4, 2.4, eaf2f6, 8a7a68, 1.25, 0, 9fcfd6
  - 720: 9fd0ec, f4eee3, fff1de, 2.9, eef6fa, 8f8270, 1.35, 0, a9d8db
  - 960: a6cfe6, f8e7d2, ffe3c0, 2.5, f1efe8, 8a7a66, 1.25, 0, 9fcbd2
  - 1065: 8b8fc4, f7b98f, ff9f6a, 1.8, f6d2bc, 7d6660, 1.2, .3, 93a9bd
  - 1140: 5a5e9e, d99aa6, ff9a7a, 1.3, c0b2e0, 655868, 1.35, .75, 6a7cab
  - 1260: 22325f, 445488, c0ccff, 1.2, 98a8dc, 685a6e, 1.9, 1, 5a88b2
  - 1440: 與 0 相同
- 太陽方位：時間先量化到 10 分鐘。t = clamp((min−360)/720, 0, 1)；az = π(.15+.7t)；el = .35 + sin(tπ)·.75；dir = normalize(cos az·cos el, sin el, .55·cos el + .35)；sun.position = 城市中心 + dir·40。
- 夜晚：窗戶與燈的 emissive（#ffc777）強度 = night × 3.2；路燈光池、島緣串燈、窗光溢出都乘上 night。
- 時鐘：從 10:00 開始，每秒走 10 分鐘（一天 144 秒）。HUD 有清晨 06、白天 12、黃昏 18、夜晚 21 四顆按鈕。
- 遠景：
  - 盆地地形：170² PlaneGeometry（細分 160），中心低，環狀山用 smoothstep 隆起，疊 fbm 噪聲與梯田量化，鏡頭那一側壓低。依高度上頂點色：河床 8fb3ad → 沙 d9c9a3 → 田 aec493 → 草 a3b986 → 林 6f8a62 → 岩 b2a38d，flatShading。山比原規格矮、往外推。
  - 背景樹：InstancedMesh，針葉 = 3 個 cone merge，闊葉 = 4 顆抖動過的 ico merge，flatShading、不投影、偏灰的綠，近處稀疏。手機再減量。
  - 三圈遠山剪影帶（MeshBasic，顏色往 horizon 混）、12 團雲沿 +x 漂移並繞回、海上幾座小島、燈塔、帆船。

## 5. 建物零件庫

- `parts/40-kit.js`：建模函式只把 {kind, matrix, color} 推進陣列，最後每種幾何建一個 InstancedMesh，用 setColorAt 上色。所有靜態物件合計約 20–30 個 draw call。模型和家具不要自己 `new THREE.Mesh`；島體、天空、水面這類單一物件不在此限。
- 幾何：box、rbox（RoundedBoxGeometry(1,1,1,2,0.12)）、cylinder（14 段）、cone、sphere、ico（detail 1）、dome、torus、prism、hip（四坡屋頂），發光的 glowbox、glowsphere。
- 材質：solid 是 MeshStandard roughness .78、metalness 0，前景不 flatShading；glow 加 emissive #ffc777。每個 instance 的縮放乘上 1 ± 0.0072 抖動，防 z-fighting。
- 15 種模型（`parts/45-models.js` 的 `MODELS`），在單位空間設計（底面 ±0.5、高 0–1.5、正面朝 +z）：`house`、`hall`、`booth`、`classroom`、`clinic`、`busstop`、`bikes`、`court`、`farm`、`river`、`stage`、`book`、`coin`、`clock`、`globe`。新增模型要同步補進 `scripts/validate.mjs` 的 `MODELS`。
- 每島外圈：頂點放路燈、邊上放盆栽、灌木、花；外圈 4–6 棵大樹，樹種依島的 `tree`；島內散布長椅。盆栽、灌木、串燈、長椅在鏡頭距離 ≥ 26 時隱藏。
- 色票：coral #db6a41、ink #211d1d、cream #fff8f4、yellow #fcea8b、stone #c5b5a7、green #71806a；glass #86a8a6、wood #b48560、teal #3e7c8c；植物 #9cc27a、#8db86f、#728f5f；粉彩 #f2b5c6、#58a6a6、#6f7fb5。

## 6. 小人與牽連線

- 小人：大頭 chibi，高約 0.35，頭占 40%。腿、手臂、Capsule 身體、球形頭、半球髮殼、眼睛各一個 InstancedMesh（DynamicDrawUsage），腳下圓形假影子（opacity .22）。角色配件依 `role`：公務員背心加識別證、研究員白袍、長者拐杖、學童黃帽、家長推嬰兒車、通勤族騎腳踏車、農夫斗笠、工人安全帽、旅客行李箱。
- 行走：每條牽連線的兩端固定在兩座島前側的步道頂點，用 Dijkstra 沿路網和橋算路線，配 `count` 個人來回走。速度 .32–.40，腳踏車 .62–.70；到端點停 1.4 秒交接再折返。動畫 ph = time·9 + phase·20，腿擺 ±.55、手擺 ±.45、上下起伏 |sin ph|·.012。鏡頭拉遠時縮放乘上 clamp(d/20, 1, 1.45)。
- 頭上 badge：128² canvas Sprite，白圓加 coral 外環，中間是搬運物的 ink 線條圖示。鏡頭距離 < 16 且「搬運」開啟時才顯示。
- 牽連線：沿路網折線做 TubeGeometry（半徑 .035），ShaderMaterial 的 u = vUv.x·長度·5 − time·1.4。official 實線；thematic 虛線（fract(u) > .6 時 discard）；pending 點線（fract(u) > .3 時 discard）。coral 色、opacity .82、圖樣流動。預設隱藏；選到相關的島、線或小人，或打開「牽連線」開關時才顯示，同時出現圖例。

## 7. 標籤

- CSS2DRenderer，每島在前側崖邊掛 pill 標籤，例如「01 交通」。選取的島標籤變 ink 底，其他島變淡。
- 選島後，每則議題上方出現 ①②③ pin，用 coral 細線（depthTest false）連到模型頂端。
- 「名牌」開關打開時，近距離（< 14）的小人頭上顯示「正在搬 X」氣泡。
- 每次渲染後做標籤避讓：和介面面板或其他標籤重疊時先只留號碼，還是重疊就隱藏，留 8px 緩衝防閃爍。

## 8. 互動與介面

- 點擊：pointerup 且指標移動 ≤ 6px 才 raycast，依命中物件呼叫 selectIsland、selectItem、selectWalker、selectFlow。四者走同一流程：高亮 → 顯示相關牽連線 → 飛行 → 開卡片。點旗子或 pin 也算選到該議題。
- 高亮：setColorAt 把該建物所有零件往 coral 混 22%；當前時段 `lit` 的模型種類往 yellow 混 22%。
- 桌面版面：
  - 左上品牌卡：毛玻璃、圓角 18，「今日群島」，右上角 EN／中文切換。
  - 左側卡片：寬 340px、圓角 22、多層柔和陰影、內部可捲動。三種：
    - 島卡：摘要、議題列表（編號、名稱、狀態）、牽連 chips。
    - 議題卡：160² 離屏渲染的模型縮圖、狀態標籤加熱度點（●●○）、「發生什麼」「為什麼跟你有關」「各方怎麼看」「取材來源」四段、更新日期、「回到某某島」按鈕。不放數字磚與時程軸。
    - 牽連卡：from → to、牽連程度（直接牽動／間接相關／有人提出）、搬運物。
  - 右側清單側欄：寬 318px，半透明加 backdrop-filter blur 16px。搜尋框（比對名稱、內容與各方看法）；「本週熱門」列出全城 heat 3，搜尋時或沒有 heat 3 時隱藏；「議題分類／議題牽連」兩個 tab，分類用 details 展開議題 ①②…，附「看整座島」。
  - HUD pill 工具列：目前時間與時段名、四顆時間按鈕，以及名牌、搬運（預設開）、牽連線、暫停、鳥瞰、日誌六個開關（icon 在上、字在下）。
  - 右上「城市日誌」：小人到站時產生 depart／arrive／handoff 事件，有 LIVE 綠點，可依牽連線篩選。
  - 左上工具列：全景、清單、說明。
- 元件樣式：按鈕最小高度 44px、圓角 9px，hover 黃底、pressed ink 底、focus 3px coral outline；chip 999px 全圓角、白或奶油底、陰影 0 2px 8px #4a2a1414；眉標 ui-monospace 700 10px、字距 2px；大字用 Georgia 斜體。
- 載入畫面：「今日群島」加「正在整理今天的議題…」。第一次進入顯示三步驟說明（先找插旗的建物／點開看各方看法／看來源，自己判斷），看過後用 localStorage 記住。
- 手機版（≤ 800px）：工具列移到右上改直排；側欄與卡片變 bottom sheet，預設高度 52% 與 34%，拖曳把手往上撐滿、往下回原高、再往下關閉；開卡片時清單自動收起；HUD 收進「時間」按鈕。
- 鍵盤：方向鍵旋轉鏡頭（左右繞轉、上下改俯角），Esc 關閉卡片。
- prefers-reduced-motion：相機瞬移、時鐘與小人凍結、牽連線改靜態虛線；監聽 change 事件即時切換。
- 雙語：預設中文，`#en` 或品牌卡按鈕切英文。JS 內用 `tr('中文', 'English')`；HTML 用 `data-en`，placeholder 用 `data-en-ph`，aria-label 用 `data-en-label`。英文只翻介面、島名與摘要、議題名稱，議題內容、各方看法與來源維持中文。

## 9. 效能

- 小人和水面持續在動，平常每一幀都畫；reduced-motion 時只在有互動時重畫。dt 上限 .08。「暫停」只停時鐘。
- 只有太陽投影，背景樹和小人不投影，小物件依距離做 LOD。
- 用 ResizeObserver 處理尺寸變化。

## 10. 驗收與交付

每項改動都要過：

```sh
node --test tests/*.test.mjs     # validate、build、ui 測試
node scripts/validate.mjs        # 印 ok N issues
sh build.sh
sed -n '/<script type="module">/,/<\/script>/p' index.html | sed '1d;$d' > /tmp/check.mjs && node --check /tmp/check.mjs
python3 -m http.server 8765      # 開 http://localhost:8765/preview.html，看畫面與 console
```

- 介面有改：桌面與手機（390×844 觸控模擬）都實測，也看 `#en` 有沒有出現 undefined。
- 改了行為就同步改文件：介面與操作改 `docs/manual.md`，資料格式改 `docs/development.md`，議題規則改 `docs/update-guide.md`，規格數值改這份。
- main 一有新提交就自動部署。一律開分支、發 PR，等檢查通過；不要自己合併。要給人看效果，用 `npx -y wrangler@4.155.0 versions upload` 上傳預覽版。
- 大改版分階段做，每個階段結束時頁面都要能完整執行：場景骨架 → 零件庫與模型 → 介面與資料 → 小人與牽連線 → 手機、reduced-motion、說明、雙語、效能。

---
paths:
  - "parts/**"
  - "build.sh"
---

# 改 parts/ 或 build.sh 時

驗證指令見 `AGENTS.md`「指令」；介面有改的話，再用瀏覽器開 `preview.html` 實測並看 console。

- `build.sh` 只依 `parts/*` 的檔名排序串接，並在 `parts/10-*` 前面注入 `const ISSUES`。新檔編號要避開既有編號、排在它依賴的檔案之後；不要改 `10-data.js` 的編號。
- 插入 `innerHTML` 的字串一律包 `esc()`（`parts/50-ui.js`）。
- 介面文字兩種語言都要有：JS 內用 `tr('中文', 'English')`；`parts/*.html` 用 `data-en`，placeholder 用 `data-en-ph`，aria-label 用 `data-en-label`。
- 模型與家具零件走 `kit.local`（模型座標系，`parts/45-models.js`）或 `kit.add`，它們會排進 InstancedMesh；不要在模型裡自己 `new THREE.Mesh`。島體、天空、水面這類單一物件不在此限。
- `kit.add` 內部會呼叫 `rand()`，增減零件會改變後面整座城市的隨機細節，改完要實際看畫面。

# 變更紀錄 (Changelog)

本專案遵循語意化版本紀錄與規格演進紀錄。所有重大修改均對應各階段代碼審查工單與產品決策。

---

## [1.2.0] - 2026-10-18 (第四版修改工單 v4.0)

### 新增 (Added)
- **純邏輯能力模組 (`src/logic/abilities.js`)**：抽離 `detonatePollen` 與 `buzzardStrike`，達成與 Phaser 完全解耦的純函式架構，直接為遊戲本體與測試共用。
- **靜態防禦守門測試 (`tests/regression.test.js`)**：新增代碼靜態守門斷言，強制防止 `GameScene.js` 倒退回內嵌 `takeDamage` 迭代或裸 `new Set()`。
- **動態核爆配置 (`src/config.js:POLLEN`)**：新增 `POLLEN.MINION_DAMAGE: 120` 與 `POLLEN.BOSS_DAMAGE: 200` 配置。

### 變更 (Changed)
- **可靠 Web Fonts 載入 (`src/main.js`) (T12)**：由不具保證的 `document.fonts.ready` 改為使用 `document.fonts.load` 明確載入 `Noto Sans TC` 與 `Press Start 2P`，並附帶 3 秒 Promise.race 逾時保護。
- **蜂鷹距離配置化 (T9)**：蜂鷹判定半徑 95px 抽離為 `GAME_CONFIG.EASTER.RANGE`。

### 安全與規則 (Rules & Security)
- **工蜂進場免疫與子彈穿透 (D4, D5, T11)**：
  - 工蜂處於 `ENTERING`（平滑進場歸隊）狀態時，對子彈、核爆、蜂鷹與玩家碰撞全面免疫。
  - 玩家非穿透子彈遇到 `ENTERING` 工蜂直接穿透而不被消耗，避免「剛生成就被擊殺」的不良體驗。
  - `Hornet.takeDamage` 加入最後防禦性守門。

---

## [1.1.0] - 2026-10-18 (第三版修改工單 v3.0)

### 新增 (Added)
- **Gamepad 搖桿與手把支援 (D2, T1)**：
  - 完整支援 Standard Gamepad / XInput 協定。
  - 左類比搖桿支援 ±0.2 死區濾波與 D-Pad 十字鍵。
  - 手把 A 鍵支援連射，B / X 鍵支援全屏核爆單發邊緣偵測。
  - 選單與結算畫面支援 A / Start 鍵確認。
- **原生單元與回歸測試套件 (T6)**：引入 `node:test`，在 zero-dependency 下驗證範圍傷害快照、難度公式與單次命中邏輯。
- **CI 自動化測試閘門 (T6)**：GitHub Actions 部署前先執行 `npm test`，失敗時自動阻擋 Pages 部署。
- **中文字型渲染強化 (T3)**：導入 Google Fonts `Noto Sans TC`，提升中文排版與微光字體辨識度。
- **工蜂平滑進場狀態 (T4)**：新增 `ENTERING` 狀態與 650ms EaseOut Tween，消滅俯衝超界後瞬間瞬移歸隊的視覺瑕疵。
- **蜂鷹數值配置化 (T5)**：將蜂鷹傷害集中至 `config.js:EASTER`。
- **護衛計數型別隔離 (T7, N1)**：透過 `isBossMinion` 與 `shouldSummonMinions` 限定只計算女王蜂召喚之活躍護衛。

---

## [1.0.1] - 2026-10-18 (第一、二版修復 v1.0 & v2.0)

### 修復 (Fixed)
- **F1 範圍傷害迭代修正**：核爆與蜂鷹改採 `.getChildren().slice().forEach()` 快照迭代，徹底解決原 Phaser 3 Live Array 在迭代中銷毀物件觸發 `splice` 導致漏殺約 50% 敵機的重大缺陷。
- **F2 蜂鷹單次傷害守門**：引入 `onceHitTracker`，解決原 Tween `onUpdate` 逐幀扣血導致 Boss 依螢幕刷新率 (60/120/144Hz) 被秒殺的物理問題。
- **F4 結算畫面防誤觸**：GameOverScene 加入 1.2 秒輸入冷卻時間。
- **F5 模組快取防衝突**：`_headers` 將 `/src/*` 與 `/css/*` 設為 `no-cache, must-revalidate`，避免 ESM 模組部署後新舊混用。
- **F6 安全性補強**：Phaser CDN 補齊 SRI (SHA-384) 雜湊與 `crossorigin`，配置嚴格 Content-Security-Policy (CSP)。
- **F7.2 難度敵彈倍率**：`bulletSpeedMultiplier`（每波 +8%）正式於工蜂尾針生效。
- **N2 CSP 強化**：自 `_headers` 的 CSP `style-src` 中移除 `'unsafe-inline'`。
- **F6.3 & F6.4 工作流安全性**：Actions 鎖定為完整 commit SHA，建立 `_site` 獨立打包目錄隔離非網頁檔案。

---

## [1.0.0] - 2026-10-18 (初始開源發布)
- 復古 8-Bit 像素街機彈幕射擊遊戲基礎核心架構。
- 4 階重武器進階系統、花粉天譴核爆、東方蜂鷹天降神援彩蛋。
- 100% 程式化像素紋理、Web Audio 晶片合成音效引擎。

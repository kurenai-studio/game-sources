# 每日議題更新：例行任務指示

這份是 `/schedule` 雲端例行任務每天執行時讀的指示。要改例行任務的行為，就改這個檔案並走 PR（改這份文件本身仍要走 PR）。

## 你的工作

你在 `KerryHuang/island-game` 的 checkout 裡。依時事更新 `data/issues.json`，驗證通過後直接 commit 並推到 main。**main 一有新提交就會自動部署到正式站，沒有人工審，所以守則與驗證都要嚴格做完才能推。** 推 main 只限 `data/issues.json` 這一個檔案的改動。

## 步驟

0. 看有沒有還開著的 `issues/*` PR。有的話，代表之前推不上 main 而改開 PR，在最後回報裡列出它的編號。不要去改它，今天照常從 main 出發。
1. 取得台北今天的日期：`node -e "import('./scripts/validate.mjs').then(m=>console.log(m.taipeiToday()))"`。下面的 `TODAY` 都指這個日期。
2. 完整讀 `docs/update-guide.md`，嚴格照它的規則寫。重點如下：
   - 中立。
   - 不寫真實人名與政黨名。
   - 數字要出自來源，寫成「報導指出…」。
   - 沒把握就不改。
3. 讀 `data/issues.json`。
4. **搜尋，兩項都要做完，才能下「沒有更新」的結論：**
   - **12 座島逐一搜。** 依守則裡「每座島收哪類新聞」，每座島至少搜一次。關鍵字要帶日期，例如「2026年10月」或「10月28日」，並優先限定主要媒體（`site:cna.com.tw`、`site:udn.com`、`site:ltn.com.tw`、`site:pts.org.tw`）。搜到的如果是舊報導，就換關鍵字再搜一次。
   - **heat 2 以上的既有議題逐一搜。** 用議題名稱搜一次，確認近 7 天有沒有新報導。
5. 決定改動：
   - **新增**：新出現且有不同立場的議題，`id` 用 `<島縮寫>-<YYYY-MM>-<slug>`。
   - **更新**：既有議題有新報導，就更新 `status`、`heat`、`views`、`sources`。
   - **降溫**：近 7 天沒有新報導的議題，heat 減 1，最低到 0。這條規則不管 heat 是誰設的、哪天設的都要照做。
   - **移除**：heat 已經是 0 的議題。但每座島移除後不能少於 3 則。
   - 每次最多改 8 則。heat 3 全城最多 6 則。每座島 3 到 8 則。
   - 有改動的議題，`updated` 設為 `TODAY`。沒改的不要動。
6. 每個新加的來源都要用 WebFetch 讀到內文，才能收。讀得到內文就代表連結有效。讀不到，例如 403、要登入、只有標題，就不收。
   - 執行環境的網路政策可能會擋掉 curl，所以不要用 curl 檢查來源。
7. 驗證：`node scripts/validate.mjs`、`node --test tests/*.test.mjs`、`sh build.sh` 都要通過。失敗就修，最多修兩輪。
8. 收尾。依情況擇一：
   - **沒有值得改的**：不 commit，最後回報「今天沒有更新」。
   - **驗證通過**：
     1. 確認 `git status --short` 只有 `data/issues.json` 有改動。有其他檔案改動就不推 main，改走下面第 5 點。
     2. **只 commit `data/issues.json`**，commit 訊息第一行「議題更新 TODAY」，空一行後放守則裡的「改動表格式」，結尾加一行 `Co-Authored-By: Claude <noreply@anthropic.com>`。
     3. `git pull --rebase origin main` 後 `git push origin main`。rebase 有衝突就 `git rebase --abort`，改走第 5 點。
     4. 推成功後，最後回報附上 commit 連結 `https://github.com/KerryHuang/island-game/commit/<sha>`。
     5. 推不上 main（被保護規則擋下、衝突、或第 1 點不符）：把 commit 推到分支 `issues/TODAY`，開 PR 到 main，標題「議題更新 TODAY」，內文用「改動表格式」，並在回報裡寫明推不上的原因。不要用 force push。
   - **修兩輪還是失敗**：不 commit。開一個 GitHub issue，標題「議題更新失敗 TODAY」，內文貼錯誤訊息。開不了 issue 就在最後回報裡寫明。

## 不能做的事

- 不改 `data/issues.json` 以外的任何檔案。
- 推到 main 的 commit 只能改 `data/issues.json`。
- 不 force push，不改寫 main 的歷史，不刪分支。
- 不合併、不關閉、不修改任何 PR。
- 不放沒有讀過內文的來源，也不寫來源裡沒有的事。

## 最後回報

用繁體中文，列出：
- 搜尋紀錄：12 座島各用了什麼關鍵字、找到幾則近 7 天的報導；heat 2 以上的既有議題各有沒有新報導。
- 新增、更新、降溫、移除各幾則，各是哪幾則。
- 推上 main 的 commit 連結；推不上時附 PR 連結與原因。
- 還開著的舊 `issues/*` PR。
- 哪些候選議題沒收，為什麼。

-- 建立模組表格
-- 這個檔案最後會 return M，
-- 讓其他 Lua 檔可透過 require(...) 使用 M.load_all()、M.get()、M.count()
local M = {}


-- 關卡 JSON 檔案在 Defold 專案中的資源路徑。
-- sys.load_resource() 會用這個路徑讀取檔案內容。
local RESOURCE_PATH = "/assets/file/levels.json"


-- 關卡快取
--
-- 第一次呼叫 load_all() 時會從 JSON 載入與解析所有關卡，
-- 後續呼叫直接回傳這份資料，避免重複讀檔與重複 json.decode()
--
-- nil：尚未載入
-- table：已載入並標準化後的關卡陣列
local cached_levels = nil


-- 將格子座標轉換成字串 key
--
-- 例如：
-- wall_key(3, 5) --> "3,5"
--
-- 這種格式可作為 Lua table 的 key，
-- 用來快速判斷指定座標是否為牆壁。
local function wall_key(x, y)
    return x .. "," .. y
end


-- 將 JSON 中的一筆原始關卡資料轉成遊戲執行時使用的資料格式
--
-- level 是從 JSON decode 後取得的 table，例如：
-- {
--     id = "level_1",
--     width = 8,
--     height = 6,
--     player = { x = 2, y = 2 },
--     boxes = { { x = 3, y = 2 } },
--     targets = { { x = 6, y = 4 } },
--     walls = { { x = 1, y = 1 }, { x = 2, y = 1 } }
-- }
local function normalize_level(level)

    -- 建立牆壁查詢 table
    --
    -- 最終格式會是：
    -- {
    --     ["1,1"] = true,
    --     ["2,1"] = true,
    -- }
    --
    -- 這比逐一掃描 walls 陣列更適合頻繁碰撞檢查
    local walls = {}


    -- 將 JSON 的 walls 陣列轉換成 key-value table
    --
    -- level.walls or {}：
    -- 若 JSON 中沒有 walls 欄位，則使用空陣列，避免 ipairs(nil) 出錯
    for _, wall in ipairs(level.walls or {}) do
        walls[wall_key(wall.x, wall.y)] = true
    end


    -- 驗證關卡資料是否合理
    --
    -- 推箱子遊戲中，通常箱子的數量必須與目標點數量一致；
    -- 否則可能無法完成關卡
    --
    -- assert(條件, 錯誤訊息)：
    -- 若條件為 false 或 nil，程式會停止並顯示指定錯誤
    assert(#(level.boxes or {}) == #(level.targets or {}), "Level '" .. level.id .. "' must have the same number of boxes and targets")


    -- 回傳整理後的關卡資料
    return {
        -- 關卡識別名稱，例如 "level_1"
        id = level.id,

        -- 地圖的格子寬度與高度
        width = level.width,
        height = level.height,


        -- 玩家初始格子座標
        -- 重新建立 table，可避免直接共用原始 JSON 物件
        player = {
            x = level.player.x,
            y = level.player.y,
        },


        -- 箱子的初始格子座標陣列
        -- 沒有 boxes 時，改用空陣列
        boxes = level.boxes or {},

        -- 目標點的格子座標陣列
        -- 沒有 targets 時，改用空陣列
        targets = level.targets or {},


        -- 牆壁的查詢 table
        --
        -- JSON 原始格式通常是陣列：
        -- walls = {
        --     { x = 1, y = 1 },
        --     { x = 2, y = 1 },
        -- }
        --
        -- 遊戲執行時改成：
        -- walls = {
        --     ["1,1"] = true,
        --     ["2,1"] = true,
        -- }
        --
        -- 因此後續可快速查詢：
        -- level.walls["1,1"] == true
        walls = walls,
    }
end


-- 載入並回傳全部關卡
function M.load_all()

    -- 如果已經載入過關卡，直接回傳快取
    -- 這樣不需要每次呼叫都重新讀取 JSON 檔與解析資料
    if cached_levels then
        return cached_levels
    end


    -- 從 Defold bundle 資源讀取 JSON 檔
    --
    -- 成功時：
    -- raw_json 是 JSON 文字字串
    -- error_message 通常是 nil
    --
    -- 失敗時：
    -- raw_json 是 nil
    -- error_message 包含失敗原因
    local raw_json, error_message = sys.load_resource(RESOURCE_PATH)


    -- 確認 JSON 檔案成功讀取
    -- 若 raw_json 是 nil，停止程式並顯示錯誤原因
    assert(raw_json, "Cannot load level JSON: " .. tostring(error_message))


    -- 將 JSON 字串解析成 Lua table
    --
    -- 例如 JSON：
    -- { "levels": [ ... ] }
    --
    -- 解析後：
    -- decoded = {
    --     levels = {
    --         { id = "level_1", ... },
    --         { id = "level_2", ... },
    --     }
    -- }
    local decoded = json.decode(raw_json)


    -- 驗證 JSON 結構
    -- 必須成功解析，並且根節點需要有 levels 欄位
    assert(
        decoded and decoded.levels,
        "Invalid levels JSON: missing 'levels'"
    )


    -- 初始化快取陣列，準備存放整理後的所有關卡
    cached_levels = {}


    -- 逐一處理 JSON 中的每個關卡
    for _, level in ipairs(decoded.levels) do

        -- 將原始關卡資料轉成遊戲適用格式，
        -- 再加入 cached_levels 陣列
        table.insert(cached_levels, normalize_level(level))
    end


    -- 回傳所有已載入且完成格式化的關卡
    return cached_levels
end


-- 依照關卡索引取得單一關卡
--
-- 例如：
-- M.get(1)  --> 第一關
-- M.get(2)  --> 第二關
function M.get(index)

    -- 確保關卡已載入後，再從 Lua 陣列中取出指定索引
    return M.load_all()[index]
end


-- 取得關卡總數量
--
-- #table 是 Lua 取得陣列長度的運算子
function M.count()

    -- 先確保關卡已載入，再回傳關卡陣列的元素數量
    return #M.load_all()
end


-- 回傳模組公開介面
return M
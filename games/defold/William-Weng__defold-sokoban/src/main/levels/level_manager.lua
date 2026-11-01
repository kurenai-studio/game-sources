-- 載入關卡資料模組
local levels = require "main.levels.level_data"

-- MARK: 建立模組表格 M
local M = {}

-- 常數設定
M.TIME_INTERVAL = 0.25                     -- 移動動畫時間（秒）
M.TILE_SIZE = 64                           -- 每個格子的像素大小
M.MAP_ORIGIN = vmath.vector3(32, 32, 0)    -- 地圖原點偏移（讓格子對齊）

-- MRAK: 遊戲狀態
M.current_index = 1           -- 當前關卡索引
M.current = nil               -- 當前關卡資料（從 levels 載入）

M.player = nil                -- 玩家邏輯位置 {x, y}
M.player_id = nil             -- 玩家遊戲物件 ID
M.is_moving = false           -- 玩家是否正在移動 (動畫未完成)

M.boxes = {}                  -- 所有箱子的列表 {id, x, y}
M.targets = {}                -- 所有目標點的列表 {id, x, y}

-- MARK: 移動邏輯
-- 播放移動動畫
local function move_animation(id, position) 

    -- 標記角色正在移動中
    -- 動畫尚未完成前，可以在 on_input() 中忽略新的按鍵
    M.is_moving = true

    -- 將 Game Object 的 position 動畫化到目標座標
    go.animate(id, "position", go.PLAYBACK_ONCE_FORWARD, position, go.EASING_OUTQUAD, M.TIME_INTERVAL, 0, 
    function ()
        M.is_moving = false
    end)
end

-- MARK: 工具函式
-- 將網格座標轉成字串 key，用於 walls 表格的快速查詢
function M.key(x, y)
    return x .. "," .. y
end

-- 取得所有關卡的總數量
function M.level_count()
    return levels.count()
end

-- 將網格座標 (x, y, z) 轉換成世界座標
-- x, y 從 1 開始，z 預設為 1（玩家/箱子層），目標點在 0.5
function M.grid_to_world(x, y, z)
    
    local real_x = (x - 1) * M.TILE_SIZE
    local real_y = (y - 1) * M.TILE_SIZE
    local real_z = z or 1
        
    return M.MAP_ORIGIN + vmath.vector3(real_x, real_y, real_z)
end

-- 檢查 (x, y) 是否在當前關卡範圍內
function M.is_inside_map(x, y)
    
    if x < 1 then return false end
    if y < 1 then return false end
    if x > M.current.width then return false end
    if y > M.current.height then return false end
    
    return true
end

-- 檢查 (x, y) 是否是牆壁
-- 超出地圖範圍也視為牆壁
function M.is_wall(x, y)
    if not M.is_inside_map(x, y) then return true end
    return M.current.walls[M.key(x, y)] == true
end

-- 檢查 (x, y) 是否有箱子，有則回傳箱子物件
function M.box_at(x, y)
    
    for _, box in ipairs(M.boxes) do
        if box.x == x and box.y == y then return box end
    end

    return nil
end

-- 檢查 (x, y) 是否是目標點
function M.is_target(x, y)
    
    for _, target in ipairs(M.targets) do
        if target.x == x and target.y == y then return true end
    end

    return false
end

-- 檢查關卡是否完成：所有箱子都在目標點上
function M.is_complete()
    
    -- 箱子數量必須等於目標點數量
    if #M.boxes ~= #M.targets then
        return false
    end

    -- 每個箱子都必須在目標點上
    for _, box in ipairs(M.boxes) do
        if not M.is_target(box.x, box.y) then return false end
    end

    return true
end

-- MARK: 關卡管理
-- 清除當前關卡的所有遊戲物件
function M.clear()
    
    -- 刪除玩家物件
    if M.player_id then
        go.delete(M.player_id)
        M.player_id = nil
    end

    -- 刪除所有箱子物件
    for _, box in ipairs(M.boxes) do
        go.delete(box.id)
    end

    -- 刪除所有目標點物件
    for _, target in ipairs(M.targets) do
        go.delete(target.id)
    end

    -- 重置狀態
    M.boxes = {}
    M.targets = {}
    M.player = nil
end

-- 載入指定索引的關卡
-- factories: {player, box, target} 對應的 factory 路徑
function M.load(index, factories)
    
    -- 先清除舊關卡
    M.clear()

    -- 設定當前關卡索引並載入關卡資料
    M.current_index = index
    M.current = assert(levels.get(index), "Missing level at index: " .. index)

    -- 初始化玩家位置
    M.player = { x = M.current.player.x, y = M.current.player.y }

    -- 建立玩家遊戲物件
    M.player_id = factory.create(factories.player, M.grid_to_world(M.player.x, M.player.y, 1))

    -- 建立所有目標點物件
    for _, data in ipairs(M.current.targets) do
        local id = factory.create(factories.target, M.grid_to_world(data.x, data.y, 0.5))
        local target_info = { id = id, x = data.x, y = data.y }
        table.insert(M.targets, target_info)
    end
    
    -- 建立所有箱子物件
    for _, data in ipairs(M.current.boxes) do
        local id = factory.create(factories.box, M.grid_to_world(data.x, data.y, 1))
        local box_info = { id = id, x = data.x, y = data.y }
        table.insert(M.boxes, box_info)
    end
end

-- 嘗試移動玩家 (dx, dy) 是方向增量
function M.try_move(dx, dy)

    if M.is_moving == true then 
        return 
    end
    
    -- 計算下一步位置
    local next_x = M.player.x + dx
    local next_y = M.player.y + dy

    -- 如果下一步是牆壁，不能移動
    if M.is_wall(next_x, next_y) then
        return false
    end

    -- 檢查下一步是否有箱子
    local box = M.box_at(next_x, next_y)

    -- 沒有箱子：直接移動玩家
    if not box then
        
        M.player.x = next_x
        M.player.y = next_y
        
        move_animation(M.player_id, M.grid_to_world(M.player.x, M.player.y, 1))
                
        return true
    end

    -- 有箱子：嘗試推動箱子
    local box_next_x = box.x + dx
    local box_next_y = box.y + dy

    -- 箱子下一步是牆壁，不能推
    if M.is_wall(box_next_x, box_next_y) then
        return false
    end

    -- 箱子下一步有其他箱子，不能推
    if M.box_at(box_next_x, box_next_y) then
        return false
    end

    -- 可以推：更新箱子和玩家位置
    box.x = box_next_x
    box.y = box_next_y

    M.player.x = next_x
    M.player.y = next_y

    -- 播放箱子和玩家的移動動畫
    move_animation(box.id, M.grid_to_world(box.x, box.y, 1))
    move_animation(M.player_id, M.grid_to_world(M.player.x, M.player.y, 1))
    
    return true
end

-- 回傳模組
return M
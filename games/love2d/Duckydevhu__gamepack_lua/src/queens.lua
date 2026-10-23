-- ==============================================================================
-- queens.lua
-- Téma: Procedurális generálás, Backtracking algoritmus, Állapotgépek és UI logika
-- ==============================================================================
local game = {} -- A modul saját névtere (Encapsulation)

-- ==============================================================================
-- KONSTANSOK ÉS ÁLLAPOTVÁLTOZÓK
-- ==============================================================================
-- "Magic number"-ök elkerülése: A fix értékeket konstansként (csupa nagybetűvel) 
-- definiáljuk a fájl elején, így később könnyen módosítható a játék mérete.
local BOARD_SIZE = 8
local CELL_SIZE = 60
local OFFSET_X = (800 - (BOARD_SIZE * CELL_SIZE)) / 2 -- Középre igazítás X tengelyen
local OFFSET_Y = (600 - (BOARD_SIZE * CELL_SIZE)) / 2 -- Középre igazítás Y tengelyen

-- Játékállapotot tároló változók
local grid = {}            -- A játékos táblája (0: üres, 1: Q, 2: X)
local regions = {}         -- A generált régiókat tároló 2D tömb (1-8 közötti azonosítók)
local currentSolution = {} -- A "titkos" helyes megoldás a Hint funkcióhoz
local dragAction = nil     -- "Action Lock" minta: megjegyzi, hogy épp festünk vagy radírozunk
local gameTimer = 0        -- A játékidőt méri másodpercben (Delta Time alapú)
local isWon = false        -- Győzelmi állapot flag-je (Boolean)

-- UI Elemek (Gombok) - Egyszerű AABB (tengelypárhuzamos befoglaló doboz) adatok
local hintButton = { x = 630, y = 15, w = 150, h = 40, text = "Segítség (Hint)" }
local nextLevelButton = { x = 300, y = 300, w = 200, h = 50, text = "Következő pálya" }

-- Színpaletta a régiókhoz (RGB formátum 0.0 - 1.0 között)
local regionColors = {
    {0.7, 0.5, 0.9}, {1.0, 0.7, 0.4}, {0.5, 0.7, 1.0}, {0.6, 0.8, 0.5},
    {0.9, 0.9, 0.9}, {0.7, 0.7, 0.6}, {1.0, 0.4, 0.4}, {0.9, 1.0, 0.5}
}

-- ==============================================================================
-- ALGORITMUSOK ÉS VALIDÁCIÓ
-- ==============================================================================

-- Fisher-Yates keverő algoritmus: Egy tömb elemeit keveri össze véletlenszerűen.
-- O(n) időkomplexitással dolgozik, ami a leghatékonyabb módja a keverésnek.
local function shuffleTable(t)
    for i = #t, 2, -1 do
        local j = love.math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

-- Ellenőrzi, hogy egy adott (row, col) pozícióra rakhatunk-e Királynőt a szabályok szerint.
local function isValidStar(queens, row, col)
    for r = 1, row - 1 do
        local c = queens[r]
        if c == col then return false end -- Azonos oszlopban már van
        -- Átlós vagy szomszédos érintkezés vizsgálata (Chebyshev távolság)
        if math.abs(row - r) <= 1 and math.abs(col - c) <= 1 then return false end
    end
    return true
end

-- BACKTRACKING ALGORITMUS: Visszalépéses kereséssel legenerál egy érvényes megoldást.
local function generateValidQueens()
    local queens = {}
    -- Ez egy rekurzív (önmagát hívó) függvény
    local function placeQueens(row)
        if row > BOARD_SIZE then return true end -- Bázisfeltétel: Sikerült az összeset lerakni
        
        local cols = {1, 2, 3, 4, 5, 6, 7, 8}
        shuffleTable(cols) -- Keverés miatt minden indításkor más lesz a megoldás
        
        for _, col in ipairs(cols) do
            if isValidStar(queens, row, col) then
                queens[row] = col -- Próbáljuk meg letenni ide
                -- Ha a következő sorokban is le tudjuk tenni (rekurzió), akkor ez a lépés jó volt
                if placeQueens(row + 1) then return true end
            end
        end
        return false -- Zsákutca (Dead end): Nincs hova tenni, visszalépés történik
    end
    placeQueens(1) -- Indítás az 1. sorból
    return queens
end

-- FLOOD FILL (Régió növesztés): A lerakott királynők köré építi a régiókat.
local function generateRegions(queens)
    local newRegions = {}
    for r = 1, BOARD_SIZE do
        newRegions[r] = {}
        for c = 1, BOARD_SIZE do newRegions[r][c] = 0 end
    end

    local activeRegions = {1, 2, 3, 4, 5, 6, 7, 8}
    -- 1. Magok (Seeds) elültetése: Minden Királynő a saját régiójának kezdőpontja
    for i = 1, BOARD_SIZE do
        newRegions[i][queens[i]] = i
    end

    local emptyCount = (BOARD_SIZE * BOARD_SIZE) - BOARD_SIZE
    -- 2. Növekedési ciklus: Addig megyünk, amíg van üres cella
    while emptyCount > 0 do
        shuffleTable(activeRegions)
        for _, regionId in ipairs(activeRegions) do
            local candidates = {}
            -- Megkeressük a régióhoz ortogonálisan (fel/le/jobbra/balra) érintkező üres cellákat
            for r = 1, BOARD_SIZE do
                for c = 1, BOARD_SIZE do
                    if newRegions[r][c] == 0 then
                        if (r > 1 and newRegions[r-1][c] == regionId) or
                           (r < BOARD_SIZE and newRegions[r+1][c] == regionId) or
                           (c > 1 and newRegions[r][c-1] == regionId) or
                           (c < BOARD_SIZE and newRegions[r][c+1] == regionId) then
                            table.insert(candidates, {r = r, c = c})
                        end
                    end
                end
            end
            -- Ha találtunk szomszédos üres cellát, bekebelezzük
            if #candidates > 0 then
                local pick = candidates[love.math.random(#candidates)]
                newRegions[pick.r][pick.c] = regionId
                emptyCount = emptyCount - 1
            end
        end
    end
    return newRegions
end

-- Segítség (Hint) funkció: Összeveti a játékos tábláját a titkos megoldással
local function giveHint()
    for r = 1, BOARD_SIZE do
        local correctCol = currentSolution[r]
        -- Ha találunk egy sort, ahol a játékos még nem tette jó helyre a Királynőt
        if grid[r][correctCol] ~= 1 then
            -- Töröljük a rossz próbálkozásokat abból a sorból
            for c = 1, BOARD_SIZE do
                if grid[r][c] == 1 then grid[r][c] = 0 end
            end
            -- Lerakjuk a helyeset
            grid[r][correctCol] = 1
            return -- Kilépünk, hogy egyszerre csak egy segítséget adjunk
        end
    end
end

-- GYŐZELEM ELLENŐRZÉSE: Játékszabályok érvényesítése
local function checkWin()
    local queenCount = 0
    local rowCount = {0,0,0,0,0,0,0,0}
    local colCount = {0,0,0,0,0,0,0,0}
    local regCount = {0,0,0,0,0,0,0,0}
    local queenPositions = {}

    -- 1. Elemek kigyűjtése és számlálása
    for r = 1, BOARD_SIZE do
        for c = 1, BOARD_SIZE do
            if grid[r][c] == 1 then
                queenCount = queenCount + 1
                rowCount[r] = rowCount[r] + 1
                colCount[c] = colCount[c] + 1
                regCount[regions[r][c]] = regCount[regions[r][c]] + 1
                table.insert(queenPositions, {r = r, c = c})
            end
        end
    end

    -- Pontosan 8 Királynő kell
    if queenCount ~= BOARD_SIZE then return false end

    -- Minden sorban, oszlopban és régióban pontosan 1 darab lehet
    for i = 1, BOARD_SIZE do
        if rowCount[i] ~= 1 or colCount[i] ~= 1 or regCount[i] ~= 1 then
            return false
        end
    end

    -- 2. Térbeli távolság (érintkezés) vizsgálata
    for i = 1, #queenPositions do
        for j = i + 1, #queenPositions do
            local q1 = queenPositions[i]
            local q2 = queenPositions[j]
            if math.abs(q1.r - q2.r) <= 1 and math.abs(q1.c - q2.c) <= 1 then
                return false
            end
        end
    end

    return true -- Ha minden teszten átment, a játékos nyert!
end

-- Új pálya generálása és az állapotok nullázása
local function startNewLevel()
    currentSolution = generateValidQueens()
    regions = generateRegions(currentSolution)
    for row = 1, BOARD_SIZE do
        grid[row] = {}
        for col = 1, BOARD_SIZE do
            grid[row][col] = 0
        end
    end
    dragAction = nil
    gameTimer = 0
    isWon = false
end

-- ==============================================================================
-- MOTOR HORGOK (Engine Callbacks)
-- ==============================================================================

function game.load()
    -- Véletlenszám-generátor inicializálása a rendszeridő alapján (Seed)
    love.math.setRandomSeed(os.time())
    startNewLevel()
end

function game.update(dt)
    -- Amíg a játék fut, pörgetjük az időzítőt és másodpercenként 60-szor ellenőrizzük a győzelmet
    if not isWon then
        gameTimer = gameTimer + dt
        if checkWin() then
            isWon = true -- Állapotváltás: a játék megnyerve
        end
    end
end

function game.draw()
    love.graphics.clear(0.95, 0.95, 0.95)
    local font = love.graphics.getFont()

    -- 1. RÉTEG: Régiók színezése (Háttér)
    for row = 1, BOARD_SIZE do
        for col = 1, BOARD_SIZE do
            local regionId = regions[row][col]
            love.graphics.setColor(regionColors[regionId] or {1,1,1})
            local x = OFFSET_X + (col - 1) * CELL_SIZE
            local y = OFFSET_Y + (row - 1) * CELL_SIZE
            love.graphics.rectangle("fill", x, y, CELL_SIZE, CELL_SIZE)
        end
    end

    -- 2. RÉTEG: Határvonalak rajzolása ("Okos" keretek)
    for row = 1, BOARD_SIZE do
        for col = 1, BOARD_SIZE do
            local x = OFFSET_X + (col - 1) * CELL_SIZE
            local y = OFFSET_Y + (row - 1) * CELL_SIZE
            
            -- Halvány, vékony belső rács
            love.graphics.setLineWidth(1)
            love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
            love.graphics.rectangle("line", x, y, CELL_SIZE, CELL_SIZE)
            
            -- Vastag vonalak a régiók határain
            love.graphics.setLineWidth(4)
            love.graphics.setColor(0, 0, 0)
            local currentRegion = regions[row][col]
            
            -- Csak ott húzunk vastag vonalat, ahol a szomszéd cella már más régióba tartozik
            if row == 1 or regions[row - 1][col] ~= currentRegion then love.graphics.line(x, y, x + CELL_SIZE, y) end
            if row == BOARD_SIZE or regions[row + 1][col] ~= currentRegion then love.graphics.line(x, y + CELL_SIZE, x + CELL_SIZE, y + CELL_SIZE) end
            if col == 1 or regions[row][col - 1] ~= currentRegion then love.graphics.line(x, y, x, y + CELL_SIZE) end
            if col == BOARD_SIZE or regions[row][col + 1] ~= currentRegion then love.graphics.line(x + CELL_SIZE, y, x + CELL_SIZE, y + CELL_SIZE) end
        end
    end

    -- 3. RÉTEG: Játékos lépéseinek rajzolása
    love.graphics.setLineWidth(3)
    for row = 1, BOARD_SIZE do
        for col = 1, BOARD_SIZE do
            local state = grid[row][col]
            local x = OFFSET_X + (col - 1) * CELL_SIZE
            local y = OFFSET_Y + (row - 1) * CELL_SIZE
            
            if state == 1 then -- Királynő (Q)
                love.graphics.setColor(0, 0, 0)
                local text = "Q"
                -- Középre igazítás matekja: pozíció + (cella méret - szöveg méret) / 2
                love.graphics.print(text, x + (CELL_SIZE - font:getWidth(text))/2, y + (CELL_SIZE - font:getHeight())/2)
            elseif state == 2 then -- X jelzés
                love.graphics.setColor(0.3, 0.3, 0.3)
                local pad = 15 -- "Padding": ne érjen teljesen a cella széléig az X
                love.graphics.line(x + pad, y + pad, x + CELL_SIZE - pad, y + CELL_SIZE - pad)
                love.graphics.line(x + CELL_SIZE - pad, y + pad, x + pad, y + CELL_SIZE - pad)
            end
        end
    end

    -- 4. RÉTEG: Szövegek és HUD (Heads-Up Display)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Queens Puzzle", 10, 10)
    
    -- Időzítő formázása MM:SS alakba (pl. 01:05)
    local mins = math.floor(gameTimer / 60)
    local secs = math.floor(gameTimer % 60)
    love.graphics.print(string.format("Idő: %02d:%02d", mins, secs), 10, 40)

    -- Hint gomb rajzolása (csak játék közben)
    if not isWon then
        love.graphics.setColor(0.2, 0.6, 0.8)
        love.graphics.rectangle("fill", hintButton.x, hintButton.y, hintButton.w, hintButton.h, 4, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(hintButton.text, hintButton.x + (hintButton.w - font:getWidth(hintButton.text))/2, hintButton.y + (hintButton.h - font:getHeight())/2)
    end

    -- 5. RÉTEG: Győzelmi képernyő (Overlay)
    if isWon then
        -- Félátlátszó fekete réteg (Alpha csatorna = 0.7)
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
        
        love.graphics.setColor(1, 0.8, 0) 
        local winText = "NYERTÉL!"
        love.graphics.print(winText, 400 - (font:getWidth(winText)*2)/2, 200, 0, 2, 2)
        
        love.graphics.setColor(1, 1, 1)
        local timeText = string.format("Megoldottad ennyi idő alatt: %02d:%02d", mins, secs)
        love.graphics.print(timeText, 400 - font:getWidth(timeText)/2, 260)

        -- Következő pálya gomb
        love.graphics.setColor(0.2, 0.8, 0.3)
        love.graphics.rectangle("fill", nextLevelButton.x, nextLevelButton.y, nextLevelButton.w, nextLevelButton.h, 5, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(nextLevelButton.text, nextLevelButton.x + (nextLevelButton.w - font:getWidth(nextLevelButton.text))/2, nextLevelButton.y + (nextLevelButton.h - font:getHeight())/2)
    end
end

-- ==============================================================================
-- BEMENET KEZELÉSE ÉS LOGIKA
-- ==============================================================================

-- Képernyő koordináták (pixel) átalakítása rács indexekké (sor, oszlop)
local function getGridIndices(x, y)
    local col = math.floor((x - OFFSET_X) / CELL_SIZE) + 1
    local row = math.floor((y - OFFSET_Y) / CELL_SIZE) + 1
    -- "Bounds check": Csak akkor adunk vissza érvényes indexet, ha a táblán belül kattintott
    if col >= 1 and col <= BOARD_SIZE and row >= 1 and row <= BOARD_SIZE then
        return row, col
    end
    return nil, nil
end

function game.mousepressed(x, y, button)
    -- UI: Ha nyert a játékos, letiltjuk a tábla interakcióit (Early Return minta)
    if isWon then
        if button == 1 then
            if x >= nextLevelButton.x and x <= nextLevelButton.x + nextLevelButton.w and 
               y >= nextLevelButton.y and y <= nextLevelButton.y + nextLevelButton.h then
                startNewLevel()
            end
        end
        return -- Nem engedjük tovább a futást a tábla-logikára
    end

    -- UI: Hint gomb figyelése AABB ütközésvizsgálattal
    if button == 1 then
        if x >= hintButton.x and x <= hintButton.x + hintButton.w and y >= hintButton.y and y <= hintButton.y + hintButton.h then
            giveHint()
            return
        end
    end

    -- Játék logika: Táblára kattintás kezelése
    local row, col = getGridIndices(x, y)
    if not row then return end -- Ha a táblán kívül kattintott, kilépünk

    if button == 1 then
        -- Bal klikk (Toggle): Ha 1 volt, 0 lesz. Ha bármi más, 1 lesz.
        grid[row][col] = grid[row][col] == 1 and 0 or 1
    elseif button == 2 then
        -- Jobb klikk és "Action Lock" inicializálása
        if grid[row][col] == 2 then
            grid[row][col] = 0
            dragAction = "erase" -- X-en kezdtük a húzást, tehát radírozni fogunk
        else
            if grid[row][col] == 0 then
                grid[row][col] = 2
            end
            dragAction = "paint" -- Üresen kezdtük, tehát festeni fogunk
        end
    end
end

function game.mousemoved(x, y, dx, dy, istouch)
    if isWon then return end 

    -- Ha a jobb egérgomb le van nyomva tartva (Drag)
    if love.mouse.isDown(2) then
        local row, col = getGridIndices(x, y)
        if row then
            -- "Action Lock" alkalmazása: Csak azt csináljuk, amivel a húzás indult
            if dragAction == "paint" and grid[row][col] == 0 then
                grid[row][col] = 2
            elseif dragAction == "erase" and grid[row][col] == 2 then
                grid[row][col] = 0
            end
        end
    else
        -- Ha felengedtük a gombot, töröljük a lock-ot
        dragAction = nil
    end
end

return game
-- ==============================================================================
-- main.lua
-- Téma: Állapotgépek (State Machine), Esemény-delegálás és UI alapok
-- ==============================================================================

-- 1. MODULOK BETÖLTÉSE (Dependency Injection / Imports)
-- A 'require' függvény a Lua beépített modulkezelője. Megkeresi az adott nevű .lua fájlt,
-- lefuttatja, és az ott lévő 'return' által visszaadott értéket (esetünkben egy táblát) 
-- betölti a lokális változóba. Így a main.lua hozzáfér a játékok belső függvényeihez,
-- de a fájl maga tiszta és átlátható marad.
local ballGame = require("ball")
local queensGame = require("queens")

-- 2. ÁLLAPOTTÉR (State Machine)
-- A 'currentState' egy rendkívül fontos változó: ez határozza meg, hogy a program
-- éppen melyik képernyőt vagy játékot futtatja. Ez egy véges állapotgép (FSM) alapja.
local currentState = "menu" 
local menuButtons = {} -- A menü gombjainak adatait tároló lista (tömb)

-- ==============================================================================
-- MOTOR HORGOK (Engine Callbacks)
-- ==============================================================================

function love.load()
    -- Ablak és betűtípus globális konfigurálása
    love.window.setTitle("Lua Game Pack")
    love.window.setMode(800, 600)
    love.graphics.setNewFont(18)

    -- Menügombok definiálása táblázatokkal (Table)
    -- Minden gomb egy objektum, ami tartalmazza a pozícióját (x,y), méretét (w,h),
    -- a megjelenő szöveget, és egy egyedi azonosítót (id), amivel később hivatkozunk rá.
    table.insert(menuButtons, {x = 250, y = 200, w = 300, h = 50, text = "Pattogó Labda", id = "game_ball"})
    table.insert(menuButtons, {x = 250, y = 270, w = 300, h = 50, text = "Queens (Logika)", id = "game_queens"})
    table.insert(menuButtons, {x = 250, y = 340, w = 300, h = 50, text = "Kilépés", id = "exit"})
end

function love.update(dt)
    -- DELEGÁLÁS: A main.lua nem tartalmaz saját játéklogikát. 
    -- Csak megnézi, mi az aktuális állapot, és "továbbdobja" a frissítés feladatát
    -- a megfelelő modul .update() függvényének.
    if currentState == "game_ball" then
        ballGame.update(dt)
    elseif currentState == "game_queens" then
        queensGame.update(dt)
    end
end

function love.draw()
    -- DELEGÁLÁS a renderelésnél is.
    -- Csak az a modul rajzolhat a képernyőre, amelyik éppen az aktív állapot.
    if currentState == "menu" then
        drawMenu() -- Helyi függvény hívása
    elseif currentState == "game_ball" then
        ballGame.draw()
    elseif currentState == "game_queens" then
        queensGame.draw()
    end
end

-- ==============================================================================
-- BEMENET KEZELÉSE (Input Routing)
-- ==============================================================================

function love.mousepressed(x, y, button)
    if currentState == "menu" then
        -- Gombnyomás ellenőrzése a főmenüben (Csak bal klikk)
        if button == 1 then
            -- Végigiterálunk az összes gombon az 'ipairs' (indexelt párok) segítségével
            for _, btn in ipairs(menuButtons) do
                -- AABB (Axis-Aligned Bounding Box) matematikai ütközésvizsgálat
                -- Ellenőrzi, hogy az egér (x,y) koordinátája beleesik-e a gomb téglalapjába.
                if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                    
                    -- Állapotváltások (State Transitions)
                    if btn.id == "game_ball" then
                        ballGame.load() -- Inicializáljuk a játékot, mielőtt átváltunk rá!
                        currentState = "game_ball"
                    elseif btn.id == "game_queens" then
                        queensGame.load()
                        currentState = "game_queens"
                    elseif btn.id == "exit" then
                        love.event.quit() -- Biztonságos kilépés a programból
                    end
                    
                end
            end
        end
    elseif currentState == "game_ball" then
        -- Ha a labdás játék fut, oda irányítjuk a kattintást
        ballGame.mousepressed(x, y, button)
    elseif currentState == "game_queens" then
        -- Ha a queens fut, oda irányítjuk
        queensGame.mousepressed(x, y, button)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    -- Ezt az eseményt csak a Queens játék használja (a húzásos festéshez), 
    -- ezért csak akkor delegáljuk, ha az az aktív állapot.
    if currentState == "game_queens" and queensGame.mousemoved then
        queensGame.mousemoved(x, y, dx, dy, istouch)
    end
end

function love.keypressed(key)
    -- Globális "Vissza/Kilépés" mechanika az ESC billentyűvel
    if key == "escape" then
        if currentState ~= "menu" then
            currentState = "menu" -- Ha játékban vagyunk, visszalépünk a menübe
        else
            love.event.quit() -- Ha már a menüben vagyunk, kilépünk az egész programból
        end
    end
end

-- ==============================================================================
-- SEGÉDFÜGGVÉNYEK
-- ==============================================================================

-- Ezt a függvényt csak a main.lua használja, ezért ide került.
function drawMenu()
    -- Sötétkék háttér
    love.graphics.clear(0.15, 0.15, 0.2)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("GAME PACK", 330, 80)

    -- Dinamikus UI renderelés: A tömb alapján rajzoljuk ki a gombokat.
    -- Ha hozzáadunk egy új elemet a menuButtons-hoz a load() fv-ben, az itt 
    -- automatikusan kirajzolódik, extra kódolás nélkül.
    for _, btn in ipairs(menuButtons) do
        -- Gomb háttere
        love.graphics.setColor(0.3, 0.3, 0.4)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 5, 5) -- 5,5 a kerekített sarkokhoz
        
        -- Szöveg tökéletes középre igazítása (Matematika)
        love.graphics.setColor(1, 1, 1)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(btn.text)
        local textHeight = font:getHeight()
        -- Pozíció = Gomb széle + (Gomb mérete - Szöveg mérete) / 2
        love.graphics.print(btn.text, btn.x + (btn.w - textWidth) / 2, btn.y + (btn.h - textHeight) / 2)
    end
end
-- ==============================================================================
-- ball.lua
-- Téma: Moduláris felépítés, állapotkezelés, 2D fizika és kör-kattintás detektálás
-- ==============================================================================

-- 1. MODUL INICIALIZÁLÁSA
-- Létrehozunk egy üres táblát (table). A Lua-ban nincsenek hagyományos osztályok,
-- ehelyett táblákba gyűjtjük a modulhoz (vagy objektumhoz) tartozó adatokat és függvényeket.
-- A 'local' kulcsszó kritikus: megakadályozza, hogy a 'game' bekerüljön a globális 
-- névtérbe, elkerülve ezzel a lehetséges névütközéseket más fájlokkal.
local game = {}

-- ==============================================================================
-- ÁLLAPOTTÉR (State)
-- ==============================================================================

-- A játék belső állapota, amely a pontszámot tárolja.
local state = { score = 0 }

-- A labda fizikai és vizuális tulajdonságait összefoglaló tábla.
-- X és Y a pozíció, radius a sugár, speedX és speedY a másodpercenkénti elmozdulás pixelben.
local ball = { 
    x = 400, 
    y = 300, 
    radius = 30, 
    speedX = 200, 
    speedY = 150, 
    color = {0.2, 0.6, 1.0} -- Szín megadása RGB formátumban (0.0 és 1.0 közötti értékekkel)
}

-- ==============================================================================
-- JÁTÉK CIKLUS (Game Loop) FÜGGVÉNYEI
-- ==============================================================================

-- game.load()
-- Cél: A játék kiinduló állapotának beállítása.
-- Miért fontos? Mivel ezt a modult a főmenüből többször is elindíthatjuk, 
-- garantálnunk kell, hogy korábbi játékok állapota (pl. hatalmas sebesség) ne ragadjon bent.
function game.load()
    state.score = 0
    ball.x = 400
    ball.y = 300
    ball.speedX = 200
    ball.speedY = 150
    ball.color = {0.2, 0.6, 1.0}
end

-- game.update(dt)
-- Cél: Az üzleti logika és a fizika frissítése. Minden egyes képkocka (frame) kirajzolása előtt lefut.
-- A 'dt' (Delta Time) az előző képkocka óta eltelt idő másodpercben (pl. 0.016s egy 60 FPS-es játéknál).
function game.update(dt)
    -- Mozgás kiszámítása: Új pozíció = Jelenlegi pozíció + (Sebesség * Idő)
    -- A 'dt'-vel való szorzás garantálja, hogy a labda ugyanannyit mozduljon el
    -- 1 másodperc alatt egy gyors (144 FPS) és egy lassú (30 FPS) gépen is.
    ball.x = ball.x + ball.speedX * dt
    ball.y = ball.y + ball.speedY * dt

    -- Ütközésvizsgálat a vízszintes (X) tengelyen (képernyő bal és jobb széle)
    -- A labda pozíciója (x) a közepét jelenti, ezért ki kell vonni/hozzá kell adni a sugarat,
    -- hogy a labda széle pattanjon vissza, ne a közepe menjen ki a képernyőről.
    if ball.x - ball.radius < 0 or ball.x + ball.radius > love.graphics.getWidth() then
        ball.speedX = -ball.speedX -- Az irány megfordítása (pozitívból negatív, negatívból pozitív)
    end
    
    -- Ütközésvizsgálat a függőleges (Y) tengelyen (képernyő teteje és alja)
    if ball.y - ball.radius < 0 or ball.y + ball.radius > love.graphics.getHeight() then
        ball.speedY = -ball.speedY
    end
end

-- game.draw()
-- Cél: A képernyő tartalmának renderelése. Ide tilos üzleti logikát (pl. változók módosítását) írni!
function game.draw()
    -- Képernyő törlése egy sötét szürkéskék színnel (RGB: 10%, 10%, 12%)
    love.graphics.clear(0.1, 0.1, 0.12)
    
    -- LÖVE2D Állapotgép (State Machine) logika: 
    -- Először beállítjuk az "ecset" színét, majd utána rajzolunk vele.
    love.graphics.setColor(ball.color)
    love.graphics.circle("fill", ball.x, ball.y, ball.radius)
    
    -- Szín visszaállítása fehérre a szöveg kirajzolása előtt
    love.graphics.setColor(1, 1, 1)
    
    -- Szöveg összefűzése (konkatenáció) a Lua-ban a '..' operátorral történik
    love.graphics.print("Pontszám: " .. state.score .. " | Vissza a menübe: ESC", 10, 10)
end

-- ==============================================================================
-- FELHASZNÁLÓI BEMENET (Input)
-- ==============================================================================

-- game.mousepressed(x, y, button)
-- Cél: Reagálás az egérkattintásokra.
function game.mousepressed(x, y, button)
    -- Csak a bal egérgomb (1) lenyomását figyeljük
    if button == 1 then
        -- 2D-s távolságszámítás a kattintás (x, y) és a labda közepe (ball.x, ball.y) között.
        local dx = x - ball.x -- Távolság az X tengelyen
        local dy = y - ball.y -- Távolság az Y tengelyen
        
        -- Pitagorasz-tétel (a^2 + b^2 = c^2) alkalmazása a pontos távolság (c) megállapítására
        local distance = math.sqrt(dx * dx + dy * dy)

        -- Ha a kiszámolt távolság kisebb vagy egyenlő a labda sugarával, akkor a kattintás a labdán belül történt.
        if distance <= ball.radius then
            -- Játékmenet frissítése: Pontszám növelése
            state.score = state.score + 1
            
            -- Nehezítés: A sebesség növelése 10%-kal (1.1-es szorzó)
            ball.speedX = ball.speedX * 1.1
            ball.speedY = ball.speedY * 1.1
            
            -- Vizuális visszajelzés: Új, teljesen véletlenszerű szín generálása
            ball.color = {math.random(), math.random(), math.random()}
        end
    end
end

-- 2. MODUL EXPORTÁLÁSA
-- A require("ball") hívásakor a főprogram ezt a 'game' táblát kapja meg,
-- benne az összes fent definiált függvénnyel.
return game
-- Fondos de cada nivel: capas lejanas que se mueven más lento que el terreno.
-- Usan pocos píxeles para que las balas se sigan viendo bien.

local D = require("datos")
local Logica = require("logica")
local F = {}

local ANCHO, ALTO, TECHO = D.ANCHO, D.ALTO, D.TECHO

local function pixel(x, y)
	love.graphics.rectangle("fill", math.floor(x), math.floor(y), 1, 1)
end

-- número "al azar" pero siempre igual para la misma entrada
local function azar_fijo(n)
	local v = math.sin(n * 12.9898 + 78.233) * 43758.5453
	return v - math.floor(v)
end

-- posición que se repite cada `largo` píxeles, para capas que dan la vuelta
local function envolver(x, largo, margen)
	return (x % largo) - margen
end

local function circulo(cx, cy, r)
	local pasos = math.max(16, r * 8)
	for i = 0, pasos - 1 do
		local a = i / pasos * math.pi * 2
		pixel(math.floor(cx + math.cos(a) * r + 0.5), math.floor(cy + math.sin(a) * r + 0.5))
	end
end

local function estrellas(s)
	for _, st in ipairs(s.estrellas) do
		pixel(st.x, st.y)
	end
end

-- nivel 2: cordillera lejana: silueta con cumbres y ladera punteada
local function montes(s, r)
	estrellas(s)
	local desplazar = math.floor(r * 0.3)
	local antes
	for x = 0, ANCHO - 1 do
		local w = x + desplazar
		local h = 7 + 4 * math.sin(w * 0.09) + 3 * math.sin(w * 0.21 + 1) + 2 * math.sin(w * 0.04)
		local y = math.floor(ALTO - 4 - h)
		local desde, hasta = y, y
		if antes then desde, hasta = math.min(y, antes), math.max(y, antes) end
		-- se une con la columna anterior para que la silueta no tenga huecos
		love.graphics.rectangle("fill", x, desde, 1, math.max(1, hasta - desde))
		-- ladera: puntos sueltos que dan volumen sin tapar las balas
		for yy = y + 2, ALTO - 1, 2 do
			if (w + yy) % 4 == 0 then pixel(x, yy) end
		end
		antes = y
	end
end

-- nivel 3: ruinas lejanas (contorno punteado) y una luna con cráteres
local function ruinas(s, r)
	estrellas(s)
	circulo(70, 13, 4)
	pixel(69, 12); pixel(71, 15); pixel(72, 12)
	local desplazar = math.floor(r * 0.25)
	local base = ALTO - 2
	for x = 0, ANCHO - 1 do
		local w = x + desplazar
		local bloque = math.floor(w / 9)
		local dentro = w % 9
		if dentro < 7 then
			local alto = 4 + math.floor(azar_fijo(bloque) * 8)
			-- algunos edificios están rotos: el techo baja en escalón
			if azar_fijo(bloque + 50) < 0.4 and dentro > 3 then alto = alto - 3 end
			local techo = base - alto
			if dentro == 0 or dentro == 6 then
				for y = techo, base, 2 do pixel(x, y) end
			else
				if dentro % 2 == 0 then pixel(x, techo) end
				-- ventanas encendidas
				if dentro == 3 then
					for y = techo + 2, base - 2, 3 do
						if azar_fijo(bloque * 31 + y) < 0.4 then pixel(x, y) end
					end
				end
			end
		end
	end
end

-- nivel 4: vetas y grietas en la roca del fondo
local grietas = {}
for i = 1, 16 do
	grietas[i] = { x = azar_fijo(i) * 130, y = TECHO + 4 + azar_fijo(i + 100) * (ALTO - TECHO - 10), forma = math.floor(azar_fijo(i + 200) * 3) }
end
local function roca(s, r)
	for _, g in ipairs(grietas) do
		local x = envolver(g.x - r * 0.5, 130, 20)
		if g.forma == 0 then
			pixel(x, g.y); pixel(x + 1, g.y + 1); pixel(x + 2, g.y + 1); pixel(x + 3, g.y + 2)
		elseif g.forma == 1 then
			pixel(x, g.y); pixel(x + 2, g.y); pixel(x + 1, g.y + 1)
		else
			pixel(x, g.y + 2); pixel(x + 1, g.y + 1); pixel(x + 2, g.y + 1); pixel(x + 3, g.y)
		end
	end
end

-- nivel 5: cinturón de asteroides en dos capas
local piedras = {}
for i = 1, 14 do
	piedras[i] = {
		x = azar_fijo(i + 300) * 140, y = TECHO + 2 + azar_fijo(i + 400) * (ALTO - TECHO - 6),
		lenta = i % 2 == 0, grande = azar_fijo(i + 500) < 0.4,
	}
end
local function asteroides(s, r)
	estrellas(s)
	for _, p in ipairs(piedras) do
		local x = envolver(p.x - r * (p.lenta and 0.2 or 0.45), 140, 20)
		if p.grande then
			pixel(x + 1, p.y); pixel(x + 2, p.y)
			pixel(x, p.y + 1); pixel(x + 3, p.y + 1)
			pixel(x + 1, p.y + 2); pixel(x + 2, p.y + 2)
		else
			pixel(x + 1, p.y); pixel(x, p.y + 1); pixel(x + 2, p.y + 1); pixel(x + 1, p.y + 2)
		end
	end
end

-- nivel 6: tuberías de una base con luces que parpadean
local function tuberias(s, r, reloj)
	local desplazar = math.floor(r * 0.5)
	for _, y in ipairs({ 13, 34 }) do
		for x = 0, ANCHO - 1 do
			local w = x + desplazar
			if w % 3 == 0 then
				pixel(x, y); pixel(x, y + 2)
			end
			-- uniones cada 28 píxeles, con una luz que se prende y apaga
			local junta = w % 28
			if junta == 0 or junta == 4 then
				love.graphics.rectangle("fill", x, y - 1, 1, 5)
			elseif junta == 2 and math.floor(reloj * 2 + w / 28) % 2 == 0 then
				pixel(x, y + 1)
			end
		end
	end
end

-- nivel 7: mar de noche, luna con su reflejo y destellos bajo el agua
local function mar(s, r, reloj)
	local a = D.niveles[s.nivel].agua or 34
	for _, st in ipairs(s.estrellas) do
		if st.y < a - 2 then pixel(st.x, st.y) end
	end
	circulo(70, 14, 4)
	pixel(69, 13); pixel(71, 15)
	local brillo = math.floor(reloj * 3)
	for k, y in ipairs({ a + 3, a + 6, a + 9 }) do
		for x = 66 + (brillo + k) % 2, 74, 2 do pixel(x, y) end
	end
	local desplazar = math.floor(r * 0.6)
	for y = a + 3, ALTO - 1, 3 do
		for x = 0, ANCHO - 1 do
			if ((x + desplazar) * 7 + y * 5) % 13 < 2 and (x < 64 or x > 76) then pixel(x, y) end
		end
	end
end

-- nivel 8: bajo el agua; superficie lejana, rayos de luz, algas, burbujas
-- y uno de los Avenger del Vuelo 19 hundido en el fondo
local AVENGER = {
	"......#.........",
	"..############..",
	"######++++######",
	"......####......",
}
local function abismo(s, r, reloj)
	-- superficie vista desde abajo
	local ola = math.floor(reloj * 4)
	for x = 0, ANCHO - 1 do
		if (x + ola) % 4 < 2 then pixel(x, TECHO + 1) end
	end
	-- rayos de luz inclinados que se desplazan lento
	local desplazar = math.floor(r * 0.15)
	for k = 0, 4 do
		local x0 = envolver(k * 22 - desplazar, 110, 12)
		for j = 0, 15, 2 do
			pixel(x0 + j / 2, TECHO + 3 + j)
		end
	end
	-- el avión hundido pasa muy despacio
	local ax = envolver(ANCHO + 10 - r * 0.25, 170, 20)
	for j, fila in ipairs(AVENGER) do
		for i = 1, #fila do
			if fila:sub(i, i) ~= "." then pixel(ax + i - 1, ALTO - 15 + j) end
		end
	end
	-- algas que se mecen
	local mover = math.floor(r * 0.4)
	for k = 0, 6 do
		local x0 = envolver(k * 17 + 5 - mover, 120, 10)
		for j = 0, 7 do
			pixel(x0 + math.floor(math.sin(reloj * 2 + j * 0.7 + k) + 0.5), ALTO - 6 - j)
		end
	end
	-- burbujas que suben
	for k = 1, 6 do
		local x = math.floor(azar_fijo(k + 700) * ANCHO)
		local y = ALTO - 4 - ((reloj * (6 + k) + k * 9) % (ALTO - TECHO - 6))
		pixel(x + math.floor(math.sin(reloj * 3 + k) + 0.5), y)
	end
end

-- nivel 9: lago Baikal helado; nieve que cae, montes de Siberia y agua bajo el hielo
local function lago(s, r, reloj)
	local a = D.niveles[s.nivel].agua or 37
	for i = 1, 22 do
		local alto = a - TECHO - 2
		local x = (azar_fijo(i) * ANCHO * 2 - r * 0.3 + math.sin(reloj * 1.3 + i) * 2) % ANCHO
		local y = TECHO + (azar_fijo(i + 50) * alto + reloj * (4 + (i % 3) * 2)) % alto
		pixel(x, y)
	end
	local desplazar = math.floor(r * 0.2)
	for x = 0, ANCHO - 1 do
		local w = x + desplazar
		local h = 6 + 3 * math.sin(w * 0.11) + 2 * math.sin(w * 0.29 + 1)
		local y = math.floor(a - 3 - h)
		pixel(x, y)
		if w % 3 == 0 then pixel(x, y + 2) end
	end
	for y = a + 6, ALTO - 1, 3 do
		for x = 0, ANCHO - 1 do
			if ((x + math.floor(r * 0.5)) * 5 + y * 3) % 11 == 0 then pixel(x, y) end
		end
	end
end


-- tono suave: mezcla del fondo con la tinta, para que lo lejano no compita con el juego
local function tono_suave(p, cuanto)
	return {
		p.fondo[1] + (p.tinta[1] - p.fondo[1]) * cuanto,
		p.fondo[2] + (p.tinta[2] - p.fondo[2]) * cuanto,
		p.fondo[3] + (p.tinta[3] - p.fondo[3]) * cuanto,
	}
end

F.tono = tono_suave

-- nivel 10: Golfo Nuevo de noche (la pantalla va invertida). Dos buques de la Armada en el
-- horizonte barren el agua con sus reflectores; el haz y los destellos de las cargas se ven
-- un poco más claros que el resto del fondo
local BUQUE = {
	"......#.........",
	"......##........",
	"....######......",
	"..###########...",
	"################",
}
local function golfo(s, r, reloj, p)
	local a = D.niveles[s.nivel].agua or 31
	love.graphics.setColor(tono_suave(p, 0.32))
	for _, haz in ipairs(s.reflectores or {}) do
		if haz.encendido and haz.dx then
			for y = a - 3, ALTO - 1 do
				local desde, hasta = Logica.tramo_haz(haz, a, y)
				local x0, x1 = math.floor(desde + 0.5), math.floor(hasta + 0.5)
				if x1 >= x0 then love.graphics.rectangle("fill", x0, y, x1 - x0 + 1, 1) end
			end
		end
	end
	for _, d in ipairs(s.destellos or {}) do
		local radio = d.r * math.min(1, d.t / 0.35)
		for y = math.floor(d.y - radio), math.floor(d.y + radio) do
			local ancho = math.sqrt(math.max(0, radio * radio - (y - d.y) ^ 2))
			love.graphics.rectangle("fill", math.floor(d.x - ancho), y, math.floor(ancho * 2) + 1, 1)
		end
	end
	love.graphics.setColor(tono_suave(p, 0.22))
	for _, st in ipairs(s.estrellas) do
		if st.y < a - 7 then pixel(st.x, st.y) end
	end
	for _, haz in ipairs(s.reflectores or {}) do
		for fy, fila in ipairs(BUQUE) do
			for fx = 1, #fila do
				if fila:sub(fx, fx) == "#" then pixel(haz.ox - 8 + fx, a - 6 + fy) end
			end
		end
	end
	-- olas bajo la superficie que avanzan despacio
	local desplazar = math.floor(r * 0.5)
	for y = a + 4, ALTO - 1, 4 do
		for x = 0, ANCHO - 1 do
			if ((x + desplazar) * 5 + y * 3) % 17 == 0 then pixel(x, y) end
		end
	end
end

-- ======================================================== fondos completos de cada nivel
-- Cada uno suma a la capa de arriba una capa muy lejana en tono 0.12 y un detalle del caso
-- (cometa, F-16, la V de Phoenix, el mapa de Betty Hill...). Las luces van en 0.32.
local function lejos(p) love.graphics.setColor(tono_suave(p, 0.12)) end
local function cerca(p) love.graphics.setColor(tono_suave(p, 0.22)) end
local function luz(p) love.graphics.setColor(tono_suave(p, 0.32)) end

-- cosas que pasan cada tanto, contadas con el tiempo del nivel: devuelve cuánto lleva
-- (de 0 a `dura`) o nil si ahora no toca
local function ciclo(s, periodo, dura, desfase)
	local t = ((s.tiempo_nivel or 0) + (desfase or 0)) % periodo
	if t < dura then return t end
end

local function dibujo(filas, x, y)
	for j, fila in ipairs(filas) do
		for i = 1, #fila do
			if fila:sub(i, i) ~= "." then pixel(x + i - 1, y + j - 1) end
		end
	end
end

-- estrellas muy lejanas que casi no se mueven
local lejanas = {}
for i = 1, 26 do
	lejanas[i] = { x = azar_fijo(i + 900) * 168, y = TECHO + 1 + azar_fijo(i + 950) * (ALTO - TECHO - 2) }
end
local function estrellas_lejanas(r, hasta_y)
	for _, e in ipairs(lejanas) do
		if not hasta_y or e.y < hasta_y then pixel((e.x - r * 0.06) % 168, e.y) end
	end
end

-- 1 Roswell: nebulosa lejana, estrellas en dos velocidades y un cometa lento
local NEBULOSA = {}
do
	local manchas = { { 50, 24, 24, 8 }, { 150, 14, 18, 6 }, { 178, 36, 14, 5 } }
	for x = 0, 219 do
		for y = TECHO + 1, ALTO - 1 do
			local d = 0
			for _, m in ipairs(manchas) do
				d = d + math.exp(-((x - m[1]) / m[3]) ^ 2 - ((y - m[2]) / m[4]) ^ 2)
			end
			d = d * (0.75 + 0.25 * math.sin(x * 0.35 + y * 0.6))
			if (d > 0.55 and (x + y) % 2 == 0) or (d > 0.22 and (x * 3 + y * 5) % 7 == 0) then
				NEBULOSA[#NEBULOSA + 1] = { x, y }
			end
		end
	end
end
-- Saturno: disco con franjas y lado de noche, anillo inclinado con la división de Cassini
-- (el de atrás lo tapa el planeta, el de adelante pasa por encima) y Titán dando vueltas.
-- '#' = tono 0.32, '+' = 0.22, '-' = 0.12; el centro del planeta está en la columna 20, fila 8.
local SATURNO_DIBUJO = {
	"..................+++..................",
	"................+++++++................",
	"..............+++++++++++--------+++...",
	"..............+#########+++++++++----+.",
	"..........+--+###########++++++++++.-+.",
	".......+--++++++++++++++-+.....++++.-+.",
	"....+--+++++++++++++++++--+....++##--+.",
	"..+--+++++..+###########+++..+++##--+..",
	".+--++++....+##########+++++++##--+....",
	".+-.#+++.....++++++++++++++##--+.......",
	".+-.###++++++++++++++++###--+..........",
	".+----##############----+..............",
	"...+++-----------++++++++..............",
	"................+++++++................",
	"..................+++..................",
}
local SATURNO = { lejos = {}, cerca = {}, luz = {} }
-- silueta de cada fila (de dónde a dónde ocupa), para que la nebulosa no se le meta adentro
local SATURNO_SILUETA = {}
for fy, fila in ipairs(SATURNO_DIBUJO) do
	local desde, hasta = fila:find("[^%.]"), #fila - (fila:reverse():find("[^%.]") or 1) + 1
	SATURNO_SILUETA[fy - 8] = { (desde or 1) - 21, hasta - 19 }
	for fx = 1, #fila do
		local capa = ({ ["#"] = "luz", ["+"] = "cerca", ["-"] = "lejos" })[fila:sub(fx, fx)]
		if capa then
			local l = SATURNO[capa]
			l[#l + 1] = fx - 20
			l[#l + 1] = fy - 8
		end
	end
end
local function saturno(p, cx, cy, reloj)
	for _, nombre in ipairs({ "lejos", "cerca", "luz" }) do
		love.graphics.setColor(tono_suave(p, nombre == "lejos" and 0.12 or (nombre == "cerca" and 0.22 or 0.32)))
		local l = SATURNO[nombre]
		for k = 1, #l, 2 do pixel(cx + l[k], cy + l[k + 1]) end
	end
	-- Titán da la vuelta despacio: pasa por delante y por detrás
	local a = reloj * 0.35
	local tx, ty = cx + math.cos(a) * 23, cy + math.sin(a) * 4 - math.cos(a) * 2
	if math.sin(a) > 0 or math.abs(tx - cx) > 9 then
		love.graphics.setColor(tono_suave(p, 0.32))
		pixel(tx, ty); pixel(tx + 1, ty); pixel(tx, ty + 1); pixel(tx + 1, ty + 1)
	end
end

local function espacio_nuevo(s, r, reloj, p)
	lejos(p)
	local sx, sy = math.floor(envolver(ANCHO + 24 - r * 0.12, ANCHO + 72, 24)), 24
	local desplazar = r * 0.04
	for _, q in ipairs(NEBULOSA) do
		local x = (q[1] - desplazar) % 220
		if x < ANCHO then
			local fila = SATURNO_SILUETA[q[2] - sy]
			local dx = math.floor(x) - sx
			if not (fila and dx >= fila[1] and dx <= fila[2]) then pixel(x, q[2]) end
		end
	end
	estrellas_lejanas(r)
	cerca(p)
	estrellas(s)
	saturno(p, sx, sy, reloj)
	-- estrella fugaz cada 7 segundos
	cerca(p)
	local fase = reloj % 7
	if fase < 0.5 then
		local x, y = 70 - fase * 120, 9 + fase * 30
		for k = 0, 3 do pixel(x + k, y - k * 0.5) end
	end
	local t = ciclo(s, 13, 5, 3)
	if t then
		local x, y = 92 - t * 22, 9 + t * 2.5
		pixel(x, y); pixel(x + 1, y); pixel(x, y + 1)
		lejos(p)
		for k = 1, 9 do pixel(x + 1 + k, y - k * 0.3) end
	end
end

-- 2 Bélgica: cordillera lejana, luces de Eupen al pie y dos F-16 que cruzan
local F16 = { "....#", "#####", "...#." }
local function montes_nuevo(s, r, reloj, p)
	lejos(p)
	local desplazar = math.floor(r * 0.12)
	for x = 0, ANCHO - 1 do
		local w = x + desplazar
		local y = math.floor(ALTO - 12 - 5 * math.sin(w * 0.05) - 3 * math.sin(w * 0.13 + 2))
		pixel(x, y)
		for yy = y + 3, ALTO - 1, 3 do
			if (w * 2 + yy) % 5 == 0 then pixel(x, yy) end
		end
	end
	estrellas_lejanas(r, ALTO - 20)
	cerca(p)
	montes(s, r)
	-- el pueblo: ventanas que se prenden y apagan
	luz(p)
	local pueblo = math.floor(r * 0.3)
	for x = 0, ANCHO - 1 do
		local w = x + pueblo
		if w % 70 < 16 and w % 2 == 0 then
			local y = ALTO - 2 - (math.floor(w / 2) % 3)
			if azar_fijo(w + math.floor(reloj * 0.5 + w)) < 0.7 then pixel(x, y) end
		end
	end
	-- los F-16 de la Fuerza Aérea Belga que salieron a buscar el triángulo
	local t = ciclo(s, 17, 3.5, 6)
	if t then
		cerca(p)
		local x = 90 - t * 34
		dibujo(F16, x, 10)
		dibujo(F16, x + 9, 13)
		if math.floor(reloj * 6) % 2 == 0 then luz(p); pixel(x + 5, 11); pixel(x + 14, 14) end
	end
end

-- 3 Phoenix: ciudad lejana y la V de luces cruzando el cielo
local function ruinas_nuevo(s, r, reloj, p)
	lejos(p)
	local desplazar = math.floor(r * 0.1)
	for x = 0, ANCHO - 1 do
		local w = x + desplazar
		local bloque = math.floor(w / 6)
		local alto = 8 + math.floor(azar_fijo(bloque + 800) * 10)
		local techo = ALTO - 2 - alto
		if w % 6 == 5 then
			-- calle entre edificios
		elseif w % 6 == 0 or w % 6 == 4 then
			for y = techo, ALTO - 1, 2 do pixel(x, y) end
		else
			pixel(x, techo)
			if w % 2 == 0 then
				for y = techo + 2, ALTO - 1, 3 do
					if azar_fijo(bloque * 17 + y) < 0.35 then pixel(x, y) end
				end
			end
		end
	end
	cerca(p)
	ruinas(s, r)
	-- las luces de Phoenix: una V enorme y silenciosa que avanza muy despacio
	luz(p)
	local cx = 100 - ((s.tiempo_nivel or 0) * 3) % 150
	for k = 0, 4 do
		if (math.floor(reloj * 1.5) + k) % 7 ~= 0 then
			pixel(cx + k * 3, 14 - k * 1.5)
			if k > 0 then pixel(cx + k * 3, 14 + k * 1.5) end
		end
	end
end

-- 4 Los Hill: estalactitas que gotean y el mapa estelar de Betty Hill grabado en la roca
local MAPA_ESTELAR = { { 0, 8, true }, { 3, 10, true }, { 11, 3 }, { 13, 10 }, { 9, 15 }, { 19, 6 }, { 21, 12 }, { 27, 2 }, { 29, 9 }, { 26, 15 }, { 16, 0 } }
local LINEAS_MAPA = { { 1, 3 }, { 1, 4 }, { 2, 5 }, { 2, 4 }, { 3, 6 }, { 4, 7 }, { 6, 8 }, { 7, 9 }, { 7, 10 }, { 3, 11 }, { 6, 7 } }
local function roca_nuevo(s, r, reloj, p)
	local mx = envolver(60 - r * 0.3, 170, 40)
	local my = 18
	lejos(p)
	for _, l in ipairs(LINEAS_MAPA) do
		local a, b = MAPA_ESTELAR[l[1]], MAPA_ESTELAR[l[2]]
		local pasos = math.floor(math.max(math.abs(b[1] - a[1]), math.abs(b[2] - a[2])))
		for i = 1, pasos - 1, 2 do
			pixel(mx + a[1] + (b[1] - a[1]) * i / pasos, my + a[2] + (b[2] - a[2]) * i / pasos)
		end
	end
	cerca(p)
	for _, e in ipairs(MAPA_ESTELAR) do
		pixel(mx + e[1], my + e[2])
		if e[3] then pixel(mx + e[1] - 1, my + e[2]); pixel(mx + e[1] + 1, my + e[2]); pixel(mx + e[1], my + e[2] - 1); pixel(mx + e[1], my + e[2] + 1) end
	end
	roca(s, r)
	-- estalactitas pegadas al techo de la cueva, y gotas que caen de algunas
	local col = s.columna or 0
	for x = 0, ANCHO - 1 do
		local w = x + col
		local g = math.floor(w / 9)
		if azar_fijo(g + 600) < 0.7 then
			local largo = 2 + math.floor(azar_fijo(g + 650) * 4)
			local d = w % 9
			local cuanto = d == 4 and largo or ((d == 3 or d == 5) and math.floor(largo / 2) or 0)
			local y0 = TECHO + (s.arriba[x] or 0)
			for k = 0, cuanto - 1 do pixel(x, y0 + k) end
			if d == 4 and azar_fijo(g + 700) < 0.5 then
				local suelo = ALTO - (s.abajo[x] or 0)
				local caida = suelo - y0 - largo
				if caida > 3 then pixel(x, y0 + largo + (reloj * 18 + g * 7) % caida) end
			end
		end
	end
end

-- 5 Lubbock: banda de polvo, un asteroide grande muy lejos y el arco de luces de 1951
local function asteroides_nuevo(s, r, reloj, p)
	lejos(p)
	local desplazar = math.floor(r * 0.08)
	for x = 0, ANCHO - 1 do
		local w = x + desplazar
		local centro = 16 + x * 0.25 + 4 * math.sin(w * 0.05)
		for y = math.floor(centro - 5), math.floor(centro + 5) do
			if (w + y * 3) % 5 == 0 or (math.abs(y - centro) < 2 and (w + y) % 2 == 0) then pixel(x, y) end
		end
	end
	local gx = envolver(70 - r * 0.05, 130, 12)
	circulo(gx, 34, 5)
	pixel(gx - 2, 33); pixel(gx + 1, 35); pixel(gx + 2, 32)
	cerca(p)
	asteroides(s, r)
	-- las luces de Lubbock: un arco de puntos que cruza el cielo rápido y en silencio
	local t = ciclo(s, 15, 4, 4.5)
	if t then
		luz(p)
		local cx = 100 - t * 32
		for k = -7, 7 do
			pixel(cx + k * 2, 12 + 0.12 * k * k)
		end
	end
end

-- 6 Hangar 18: paneles con remaches, luces de alarma y un tanque con un cuerpo adentro
local GRIS = { ".###.", "#.#.#", ".###.", "..#..", ".###.", "#.#.#", "..#..", ".#.#.", ".#.#." }
local function tuberias_nuevo(s, r, reloj, p)
	lejos(p)
	local desplazar = math.floor(r * 0.25)
	for x = 0, ANCHO - 1 do
		local w = x + desplazar
		if w % 16 == 0 then
			for y = TECHO + 1, ALTO - 1, 2 do pixel(x, y) end
		end
		if w % 4 == 0 then pixel(x, 23) end
		if w % 16 == 2 or w % 16 == 14 then pixel(x, 17); pixel(x, 29) end
	end
	cerca(p)
	tuberias(s, r, reloj)
	-- el tanque, en la misma capa que las tuberías
	local mover = math.floor(r * 0.5)
	local tx = envolver(70 - mover, 112, 12)
	for y = 17, 31 do
		pixel(tx, y); pixel(tx + 8, y)
	end
	for x = tx + 1, tx + 7 do pixel(x, 16); pixel(x, 32) end
	for x = tx - 1, tx + 9 do pixel(x, 33) end
	dibujo(GRIS, tx + 2, 20)
	lejos(p)
	for y = 18, 31 do
		for x = tx + 1, tx + 7 do
			if (x + y) % 3 == 0 then pixel(x, y) end
		end
	end
	for k = 0, 2 do pixel(tx + 2 + k * 2, 31 - (reloj * 5 + k * 4) % 13) end
	-- luces de alarma que giran: el destello va de un lado al otro
	for k = 0, 1 do
		local ax = envolver(30 + k * 56 - mover, 112, 12)
		cerca(p)
		pixel(ax, 18); pixel(ax + 1, 18); pixel(ax, 19); pixel(ax + 1, 19)
		local giro = math.sin(reloj * 4 + k)
		if giro > 0.3 then
			luz(p)
			for d = 2, 5 do pixel(ax - d, 18 + d * 0.3) end
		elseif giro < -0.3 then
			luz(p)
			for d = 2, 5 do pixel(ax + 1 + d, 18 + d * 0.3) end
		end
	end
end

-- 7 Shag Harbour: costa de Nueva Escocia con su faro y botes pesqueros en el horizonte
local BOTE = { "..#..", "..##.", "#####", ".###." }
local function mar_nuevo(s, r, reloj, p)
	local a = D.niveles[s.nivel].agua or 34
	cerca(p)
	mar(s, r, reloj)
	lejos(p)
	local desplazar = math.floor(r * 0.08)
	for x = 0, ANCHO - 1 do
		local w = x + desplazar
		local h = math.max(0, math.floor(2 + 3 * math.sin(w * 0.04) + 1.5 * math.sin(w * 0.17)))
		for y = a - 1 - h, a - 1 do
			if y == a - 1 - h or (x + y) % 2 == 0 then pixel(x, y) end
		end
	end
	-- el faro y su haz que da vueltas
	local fx = envolver(40 - r * 0.08, 150, 30)
	cerca(p)
	for y = a - 8, a - 2 do pixel(fx, y); pixel(fx + 1, y) end
	pixel(fx - 1, a - 9); pixel(fx + 2, a - 9)
	local giro = math.cos(reloj * 1.3)
	luz(p)
	pixel(fx, a - 9); pixel(fx + 1, a - 9)
	if math.abs(giro) > 0.15 then
		local largo = math.floor(22 * math.abs(giro))
		local lado = giro > 0 and 1 or -1
		for d = 2, largo, 2 do pixel(fx + (lado > 0 and 1 or 0) + d * lado, a - 9 - d * 0.08) end
	end
	-- botes
	cerca(p)
	for k = 0, 1 do
		local bx = envolver(20 + k * 55 - r * 0.2, 120, 10)
		dibujo(BOTE, bx, a - 4)
		if math.floor(reloj * 1.5 + k) % 2 == 0 then luz(p); pixel(bx + 2, a - 5); cerca(p) end
	end
end

-- 8 Bermudas: haces de sol anchos, cardúmenes que pasan y el Avenger hundido
local function abismo_nuevo(s, r, reloj, p)
	lejos(p)
	local desplazar = math.floor(r * 0.1)
	for k = 0, 3 do
		local x0 = envolver(k * 30 + 8 - desplazar, 120, 16)
		local fuerza = 0.5 + 0.5 * math.sin(reloj * 0.7 + k * 1.7)
		if fuerza > 0.25 then
			for y = TECHO + 2, ALTO - 1 do
				local x = x0 + (y - TECHO) * 0.45
				for i = 0, 3 do
					if (y + i) % 2 == 0 and (y < ALTO - 14 or (x + y) % 3 == 0) then pixel(x + i, y) end
				end
			end
		end
	end
	cerca(p)
	abismo(s, r, reloj)
	-- dos cardúmenes que nadan juntos y se ondulan
	for c = 0, 1 do
		local cx = envolver(90 - reloj * (8 + c * 3) - r * 0.4 + c * 60, 140, 20)
		local cy = 18 + c * 12
		for k = 0, 8 do
			local fx = cx + (k % 3) * 4 + math.floor(k / 3) * 2
			local fy = cy + math.floor(k / 3) * 2 + math.sin(reloj * 3 + k) * 0.8
			pixel(fx, fy); pixel(fx + 1, fy)
		end
	end
end

-- 9 Baikal: aurora, montes lejanos, taiga y nevada en dos capas
local function lago_nuevo(s, r, reloj, p)
	local a = D.niveles[s.nivel].agua or 37
	lejos(p)
	for x = 0, ANCHO - 1, 2 do
		local yc = TECHO + 5 + 3 * math.sin(x * 0.08 + reloj * 0.6) + 1.5 * math.sin(x * 0.21 - reloj * 0.9)
		local largo = math.floor(3 + 3 * (0.5 + 0.5 * math.sin(x * 0.3 + reloj * 1.1)))
		for k = 0, largo - 1, 1 do pixel(x, yc + k) end
	end
	local lejano = math.floor(r * 0.08)
	for x = 0, ANCHO - 1 do
		local w = x + lejano
		local y = math.floor(a - 14 - 3 * math.sin(w * 0.06) - 2 * math.sin(w * 0.15 + 1))
		pixel(x, y)
		if (w + y) % 3 == 0 then pixel(x, y + 2) end
	end
	for i = 1, 14 do
		local alto = a - TECHO - 2
		local x = (azar_fijo(i + 77) * ANCHO * 2 - r * 0.1) % ANCHO
		local y = TECHO + (azar_fijo(i + 88) * alto + reloj * 2) % alto
		pixel(x, y)
	end
	cerca(p)
	lago(s, r, reloj)
	-- pinos de la taiga sobre la línea de los montes cercanos
	local desplazar = math.floor(r * 0.2)
	for x = 0, ANCHO - 1 do
		local w = x + desplazar
		if w % 7 == 0 and azar_fijo(math.floor(w / 7) + 40) < 0.7 then
			local h = 6 + 3 * math.sin(w * 0.11) + 2 * math.sin(w * 0.29 + 1)
			local y = math.floor(a - 3 - h)
			for k = 1, 4 do pixel(x, y - k) end
			pixel(x - 1, y - 2); pixel(x + 1, y - 2); pixel(x - 1, y - 1); pixel(x + 1, y - 1)
		end
	end
end

-- 10 Golfo Nuevo: acantilados de Península Valdés y ballenas francas soplando
local function golfo_nuevo(s, r, reloj, p)
	local a = D.niveles[s.nivel].agua or 31
	lejos(p)
	local desplazar = math.floor(r * 0.06)
	for x = 0, ANCHO - 1 do
		local w = (x + desplazar) % 150
		-- meseta plana que cae a pique al mar
		local h = 0
		if w < 70 then
			local borde = math.min(w, 70 - w) * 2
			h = math.min(borde, math.floor(5 + 1.5 * math.sin(w * 0.23) + math.sin(w * 0.61)))
		end
		if h > 0 then
			local tope = a - 1 - h
			pixel(x, tope)
			for y = tope + 2, a - 1, 2 do
				if (x + y) % 2 == 0 then pixel(x, y) end
			end
		end
	end
	golfo(s, r, reloj, p)
	-- las ballenas: el lomo asoma y sale el soplo en V
	cerca(p)
	for k = 0, 1 do
		local t = ciclo(s, 11, 2.5, k == 0 and 0.5 or 10)
		if t then
			local vez = math.floor(((s.tiempo_nivel or 0) + k * 4) / 11)
			local bx = envolver(30 + k * 37 + vez * 23 - r * 0.2, ANCHO + 20, 10)
			pixel(bx + 1, a - 1); pixel(bx + 2, a - 1); pixel(bx + 3, a - 1)
			local sube = math.min(4, math.floor(t * 4))
			for d = 1, sube do
				pixel(bx + 2 - d * 0.5, a - 2 - d); pixel(bx + 2 + d * 0.5, a - 2 - d)
			end
		end
	end
end

local CAPAS = {
	espacio = espacio_nuevo, montes = montes_nuevo, ruinas = ruinas_nuevo, roca = roca_nuevo,
	asteroides = asteroides_nuevo, tuberias = tuberias_nuevo, mar = mar_nuevo, abismo = abismo_nuevo,
	lago = lago_nuevo, golfo = golfo_nuevo,
}

-- dibuja el fondo del nivel en tono suave; deja la tinta puesta al terminar
function F.dibujar(s, p)
	love.graphics.setColor(tono_suave(p, 0.22))
	local datos = D.niveles[s.nivel]
	local capa = CAPAS[datos.fondo or "espacio"]
	capa(s, s.recorrido or 0, love.timer.getTime(), p)
	love.graphics.setColor(p.tinta)
end

-- hielo del lago: una placa brillante que flota sobre el agua. Borde de arriba en
-- tinta, fila de brillo, cuerpo en tono medio con destellos en diagonal, borde de
-- abajo mellado y carámbanos. Los agujeros tienen bordes rotos y trozos flotando.
local function hielo(s, p, a)
	local reloj = love.timer.getTime()
	local ag = s.jefe and s.jefe.agujero
	local function hueco(x)
		if x < 0 or x >= ANCHO then return false end
		return s.abajo[x] == 0 or (ag and x >= math.floor(ag.x) and x < ag.x + ag.w)
	end
	local mundo = s.columna or 0
	local medio = tono_suave(p, 0.45)
	-- cuerpo en tono medio, con fila de brillo a trozos y destellos sin pintar
	love.graphics.setColor(medio)
	for x = 0, ANCHO - 1 do
		local w = mundo + x
		if hueco(x) then
			-- agua que se mueve y trozos de hielo que suben y bajan
			if (x + math.floor(reloj * 4)) % 2 == 0 then pixel(x, a + 2) end
		else
			if math.floor(w / 6) % 3 == 2 then pixel(x, a + 1) end
			local d = w % 26
			for y = a + 2, a + 4 do
				-- destello: rayita en diagonal de tres píxeles
				local k = a + 4 - y
				if not (d == 5 + k) then pixel(x, y) end
			end
			-- carámbanos
			if (w * 7) % 11 == 0 then
				pixel(x, a + 6); pixel(x, a + 7)
			elseif (w * 3) % 7 == 0 then
				pixel(x, a + 6)
			end
		end
	end
	love.graphics.setColor(p.tinta)
	for x = 0, ANCHO - 1 do
		local w = mundo + x
		if hueco(x) then
			local sube = math.floor(reloj * 2 + w) % 2
			if w % 6 == 1 or w % 6 == 2 then pixel(x, a + 1 + sube) end
		else
			pixel(x, a)
			-- borde de abajo mellado
			pixel(x, (w * 7) % 5 == 0 and a + 4 or a + 5)
			-- bordes rotos del agujero
			if hueco(x - 1) or hueco(x + 1) then
				love.graphics.rectangle("fill", x, a, 1, 6)
			end
		end
	end
	-- chispas que titilan sobre el hielo
	for x = 0, ANCHO - 1 do
		local w = mundo + x
		if w % 37 == 0 and not hueco(x) and math.floor(reloj * 2 + w / 37) % 4 == 0 then
			pixel(x + 1, a - 4); pixel(x, a - 3); pixel(x + 2, a - 3); pixel(x + 1, a - 2)
		end
	end
	local function grieta(gx, ancho)
		gx = math.floor(gx)
		pixel(gx - 1, a - 1); pixel(gx + 1, a - 1); pixel(gx + 2, a - 2)
		for k = 1, math.floor(ancho / 2) do
			pixel(gx - k, a + k % 5); pixel(gx + k, a + (k + 2) % 5)
		end
	end
	for _, g in ipairs(s.grietas or {}) do
		-- titila más rápido cuando está por abrirse
		if g.t < 0.7 or math.floor(g.t * 12) % 2 == 0 then grieta(g.x, g.ancho) end
	end
	local gj = s.jefe and s.jefe.grieta
	if gj and math.floor(reloj * 8) % 2 == 0 then
		for k = 0, gj.w - 1, 6 do grieta(gj.x + k + 2, 6) end
	end
end

-- reflejo de un dibujo sobre el hielo: dado vuelta y a cuadros, en el color del fondo
function F.reflejo(s, p, filas, x, y)
	local a = D.niveles[s.nivel].agua
	local alejado = math.max(0, math.floor(a - (y + #filas) + 0.5))
	love.graphics.setColor(p.fondo)
	for j = 0, #filas - 1 do
		local fy = a + 1 + alejado + j
		if fy > a + 4 then break end
		local fila = filas[#filas - j]
		for i = 1, #fila do
			local fx = math.floor(x + 0.5) + i - 1
			if fila:sub(i, i) ~= "." and (i + j) % 2 == 0 and fx >= 0 and fx < ANCHO and s.abajo[fx] > 0 then
				pixel(fx, fy)
			end
		end
	end
	love.graphics.setColor(p.tinta)
end

-- terreno: relleno liso en tono medio y borde con la tinta (el borde es lo que choca)
function F.terreno(s, p)
	local datos = D.niveles[s.nivel]
	if datos.hielo then
		return hielo(s, p, datos.agua)
	end
	love.graphics.setColor(tono_suave(p, 0.4))
	for x = 0, ANCHO - 1 do
		local abajo, arriba = s.abajo[x], s.arriba[x]
		if abajo > 1 then love.graphics.rectangle("fill", x, ALTO - abajo + 1, 1, abajo - 1) end
		if arriba > 1 then love.graphics.rectangle("fill", x, TECHO, 1, arriba - 1) end
	end
	love.graphics.setColor(p.tinta)
	for x = 0, ANCHO - 1 do
		local abajo, arriba = s.abajo[x], s.arriba[x]
		if abajo > 0 then
			-- el borde se une con la columna vecina para que se vea como una línea continua
			local y = ALTO - abajo
			local vecino = x > 0 and s.abajo[x - 1] > 0 and ALTO - s.abajo[x - 1] or y
			love.graphics.rectangle("fill", x, math.min(y, vecino), 1, math.abs(y - vecino) + 1)
		end
		if arriba > 0 then
			local y = TECHO + arriba - 1
			local vecino = x > 0 and s.arriba[x - 1] > 0 and TECHO + s.arriba[x - 1] - 1 or y
			love.graphics.rectangle("fill", x, math.min(y, vecino), 1, math.abs(y - vecino) + 1)
		end
	end
	-- superficie del mar en tinta, con crestas que avanzan
	local a = D.niveles[s.nivel].agua
	if a then
		local ola = math.floor((s.recorrido or 0) * 0.8)
		love.graphics.rectangle("fill", 0, a, ANCHO, 1)
		for x = 0, ANCHO - 1 do
			local k = (x + ola) % 9
			if k == 3 or k == 4 then love.graphics.rectangle("fill", x, a - 1, 1, 1) end
		end
	end
end

return F

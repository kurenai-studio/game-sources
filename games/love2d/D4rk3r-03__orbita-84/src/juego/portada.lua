-- Portada dinámica: escenas que se turnan cada pocos segundos.
-- Abducción, recreativa, radar, un expediente de enemigo y la tabla de mejores.

local D = require("datos")
local P = {}

local ANCHO = D.ANCHO
local DURACION = 6

-- api: dibujar(nombre, x, y, escala), texto(cad, x, y), centrado(cad, y),
--      tinta, medio, suave (colores ya calculados para la paleta)
local api

local function tono(c)
	love.graphics.setColor(c)
end

local function pixel(x, y)
	love.graphics.rectangle("fill", math.floor(x), math.floor(y), 1, 1)
end

local function marco(x, y, w, h)
	love.graphics.rectangle("fill", x, y, w, 1)
	love.graphics.rectangle("fill", x, y + h - 1, w, 1)
	love.graphics.rectangle("fill", x, y, 1, h)
	love.graphics.rectangle("fill", x + w - 1, y, 1, h)
end

-- letras gordas con sombra en tono medio
local function gordo(cadena, x, y, escala)
	escala = escala or 1
	local paso = 7 * escala
	for capa = 1, 2 do
		tono(capa == 1 and api.medio or api.tinta)
		local d = capa == 1 and 1 or 0
		for i = 1, #cadena do
			local filas = D.gordas[cadena:sub(i, i)]
			if filas then
				for fy, fila in ipairs(filas) do
					for fx = 1, #fila do
						if fila:sub(fx, fx) == "#" then
							love.graphics.rectangle("fill", x + (i - 1) * paso + (fx - 1) * escala + d,
								y + (fy - 1) * escala + d, escala, escala)
						end
					end
				end
			end
		end
	end
	tono(api.tinta)
end

local function ancho_gordo(cadena, escala)
	return #cadena * 7 * (escala or 1) - (escala or 1)
end

local function estrellas(s)
	tono(api.suave)
	for _, st in ipairs(s.estrellas) do
		pixel(st.x, st.y)
	end
	tono(api.tinta)
end

-- la firma del autor: cada cinco segundos ocupa el lugar de PULSA START un momento
local function toca_firma(s)
	return s.t % 5 > 3.5
end

local function pulsa_start(s, y)
	if toca_firma(s) then
		tono(api.medio)
		api.centrado("POR D4RK3R", y)
		tono(api.tinta)
	elseif math.floor(s.t * 2) % 2 == 0 then
		api.centrado("PULSA START", y)
	end
end

-- A: un platillo se lleva una vaca con su rayo tractor
local function abduccion(s, t)
	estrellas(s)
	gordo("ORBITA", math.floor((ANCHO - ancho_gordo("ORBITA")) / 2), 2)
	gordo("84", math.floor((ANCHO - ancho_gordo("84", 2)) / 2) - 6, 11, 2)
	local py = 11 + math.floor(math.sin(t * 2) + 0.5)
	-- rayo tractor en tono suave, con franjas que suben
	tono(api.suave)
	for y = py + 4, 40 do
		local a = math.floor((y - py - 4) / 4)
		if (y + math.floor(t * 12)) % 3 ~= 0 then
			love.graphics.rectangle("fill", 75 - a, y, a * 2 + 1, 1)
		end
	end
	tono(api.tinta)
	-- segundo cuadro cuatro veces por segundo, como los enemigos
	local b = math.floor(t * 4) % 2 == 1 and "_b" or ""
	api.dibujar("platillo" .. b, 72, py)
	-- la vaca sube durante la escena
	local subida = math.min(1, t / (DURACION - 1))
	api.dibujar("vaca" .. b, 73, math.floor(37 - subida * 20))
	api.dibujar(api.nave, 4, 30 + math.floor(math.sin(t * 3) * 1.5))
	pulsa_start(s, 42)
end

-- B: cartel de recreativa con luces que corren y una persecución
local function recreativa(s, t)
	local corre = math.floor(t * 8) % 2
	for x = 0, ANCHO - 1 do
		tono(((x + corre) % 2 == 0) and api.tinta or api.medio)
		pixel(x, 0)
		tono(((x + corre) % 2 == 1) and api.tinta or api.medio)
		pixel(x, 47)
	end
	for y = 0, 47 do
		tono(((y + corre) % 2 == 0) and api.tinta or api.medio)
		pixel(0, y)
		tono(((y + corre) % 2 == 1) and api.tinta or api.medio)
		pixel(ANCHO - 1, y)
	end
	tono(api.tinta)
	gordo("ORBITA 84", 11, 4)
	tono(api.medio)
	love.graphics.rectangle("fill", 8, 14, 68, 1)
	tono(api.tinta)
	-- el platillo de Roswell huye y tu nave lo sigue disparando
	local px = 50 + math.floor(math.sin(t * 1.3) * 6)
	local py = 18 + math.floor(math.sin(t * 2.1) * 2)
	api.dibujar(({ "jefe", "jefe_b", "jefe_c", "jefe_d" })[math.floor(t * 4) % 4 + 1], px, py)
	api.dibujar(api.nave, 10 + math.floor(math.sin(t * 1.3 - 0.6) * 4), py + 4)
	for k = 0, 3 do
		local bx = 22 + ((t * 40 + k * 7) % 28)
		if bx < px - 2 then
			love.graphics.rectangle("fill", math.floor(bx), py + 6, 3, 1)
		end
	end
	pulsa_start(s, 32)
	local mejor = s.tabla[1]
	if mejor then
		tono(api.medio)
		api.centrado("MEJOR " .. mejor.nombre .. " " .. mejor.puntos, 40)
		tono(api.tinta)
	end
end

-- C: radar con ecos que se encienden cuando pasa el barrido
local ecos = { { 0.6, 10 }, { 2.3, 7 }, { 3.9, 13 }, { 5.2, 4 } }
local function radar(s, t)
	local cx, cy = 62, 24
	tono(api.suave)
	for _, r in ipairs({ 6, 11, 16 }) do
		for k = 0, r * 8 - 1 do
			local a = k / (r * 8) * math.pi * 2
			pixel(math.floor(cx + math.cos(a) * r + 0.5), math.floor(cy + math.sin(a) * r + 0.5))
		end
	end
	love.graphics.rectangle("fill", cx - 16, cy, 33, 1)
	love.graphics.rectangle("fill", cx, cy - 16, 1, 33)
	local barrido = (t * 1.8) % (math.pi * 2)
	tono(api.medio)
	for k = 1, 16 do
		pixel(math.floor(cx + math.cos(barrido) * k + 0.5), math.floor(cy + math.sin(barrido) * k + 0.5))
	end
	-- cada eco se ve fuerte justo después del barrido y se apaga de a poco
	for _, eco in ipairs(ecos) do
		local atras = (barrido - eco[1]) % (math.pi * 2)
		if atras < 2.5 then
			tono(atras < 1 and api.tinta or api.medio)
			local ex = math.floor(cx + math.cos(eco[1]) * eco[2] + 0.5)
			local ey = math.floor(cy + math.sin(eco[1]) * eco[2] + 0.5)
			love.graphics.rectangle("fill", ex - 1, ey, 3, 1)
			pixel(ex, ey - 1)
		end
	end
	tono(api.tinta)
	gordo("ORBITA", 2, 5)
	gordo("84", 2, 15, 2)
	marco(0, 36, 47, 9)
	if toca_firma(s) then
		tono(api.medio)
		api.texto("POR D4RK3R", 2, 38)
		tono(api.tinta)
	elseif math.floor(s.t * 2) % 2 == 0 then
		api.texto("CLASIFICADO", 2, 38)
	else
		api.texto("PULSA START", 2, 38)
	end
end

-- D: ficha de un enemigo con su caso
local function expediente(s, t, vuelta)
	local lista = D.expedientes
	local cual = lista[(vuelta * 2 + math.floor(t / (DURACION / 2))) % #lista + 1]
	tono(api.medio)
	api.centrado("EXPEDIENTE", 2)
	tono(api.tinta)
	marco(26, 9, 32, 20)
	local d = D.dibujos[cual[1]]
	local escala = (#d[1] > 14 or #d > 9) and 1 or 2
	api.dibujar(cual[1], math.floor(42 - #d[1] * escala / 2), math.floor(19 - #d * escala / 2), escala)
	api.centrado(cual[2], 31)
	tono(api.medio)
	api.centrado(cual[3], 37)
	tono(api.tinta)
	pulsa_start(s, 43)
end

-- E: los mejores puntajes
local function mejores(s)
	api.centrado("MEJORES", 2)
	tono(api.medio)
	love.graphics.rectangle("fill", 14, 8, 56, 1)
	tono(api.tinta)
	for i, f in ipairs(s.tabla) do
		api.texto(("%d %s %6d"):format(i, f.nombre, f.puntos), 14, 6 + i * 7)
	end
end

function P.dibujar(s, la_api)
	api = la_api
	local escenas = { abduccion, recreativa, radar, expediente }
	if #s.tabla > 0 then
		escenas[#escenas + 1] = mejores
	end
	local forzada = tonumber(os.getenv("ORBITA_PORTADA") or "")
	local numero = math.floor(s.t / DURACION)
	local indice = forzada or (numero % #escenas + 1)
	local t = s.t % DURACION
	local vuelta = math.floor(numero / #escenas)
	escenas[math.min(indice, #escenas)](s, t, vuelta)
end

return P

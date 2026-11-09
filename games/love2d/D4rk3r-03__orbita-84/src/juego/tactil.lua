-- Controles táctiles dibujados dentro del juego, para teléfonos.
-- Aparecen con el primer toque. En horizontal la pantalla va al centro con la
-- cruceta a la izquierda y los botones a la derecha; en vertical, la pantalla
-- arriba y los controles abajo. ORBITA_TACTIL=1 los deja puestos y hace que el
-- ratón sirva de dedo (para probarlos en el PC).

local T = {}

local ANCHO, ALTO = 84, 48
T.forzado = os.getenv("ORBITA_TACTIL") ~= nil
T.activo = T.forzado
local toques = {} -- id -> { x, y, control, soltado }
local d -- disposición calculada para el tamaño actual de la ventana
local d_w, d_h

-- ---------- disposición

local function calcular(w, h)
	local r = {}
	if w >= h then
		-- horizontal: deja columnas a los lados para los pulgares
		local lado = math.min(h * 0.34, w * 0.2)
		r.escala = math.max(1, math.floor(math.min((w - 2 * lado) / ANCHO, h / ALTO)))
		r.ox = math.floor((w - ANCHO * r.escala) / 2)
		r.oy = math.floor((h - ALTO * r.escala) / 2)
		local m = r.ox -- ancho real de cada columna
		local radio = math.min(m * 0.4, h * 0.22)
		r.cruceta = { x = m / 2, y = h * 0.62, r = radio }
		r.acciones = { x = w - m / 2, y = h * 0.62, r = radio }
		local bw, bh = math.min(m * 0.7, radio * 1.6), math.max(28, radio * 0.42)
		r.select = { x = m / 2 - bw / 2, y = h * 0.1, w = bw, h = bh, nombre = "SELECT" }
		r.start = { x = w - m / 2 - bw / 2, y = h * 0.1, w = bw, h = bh, nombre = "START" }
	else
		-- vertical: pantalla arriba (dejando sitio a la muesca) y controles abajo
		r.escala = math.max(1, math.floor(math.min(w / ANCHO, h * 0.5 / ALTO)))
		r.ox = math.floor((w - ANCHO * r.escala) / 2)
		r.oy = math.floor(math.max(h * 0.06, r.ox))
		local y0 = r.oy + ALTO * r.escala
		local alto = h - y0
		local radio = math.min(w * 0.19, alto * 0.28)
		r.cruceta = { x = w * 0.26, y = y0 + alto * 0.58, r = radio }
		r.acciones = { x = w * 0.74, y = y0 + alto * 0.58, r = radio }
		local bw, bh = w * 0.24, math.max(28, radio * 0.4)
		local by = y0 + alto * 0.14
		r.select = { x = w * 0.5 - bw - w * 0.03, y = by, w = bw, h = bh, nombre = "SELECT" }
		r.start = { x = w * 0.5 + w * 0.03, y = by, w = bw, h = bh, nombre = "START" }
	end
	-- los tres botones de acción como en un mando: A grande a la derecha, Y arriba y B abajo
	local a, c = r.acciones, r.acciones.r
	r.botones = {
		{ nombre = "a", letra = "A", rotulo = "DISPARO", x = a.x + c * 0.5, y = a.y, r = c * 0.52 },
		{ nombre = "poder", letra = "Y", rotulo = "PODER", x = a.x - c * 0.55, y = a.y - c * 0.6, r = c * 0.38 },
		{ nombre = "b", letra = "B", rotulo = "RAYO", x = a.x - c * 0.55, y = a.y + c * 0.62, r = c * 0.38 },
	}
	return r
end

local function disposicion()
	local w, h = love.graphics.getDimensions()
	if w ~= d_w or h ~= d_h then
		d, d_w, d_h = calcular(w, h), w, h
	end
	return d
end

-- dónde se dibuja la pantalla del juego: escala, x, y
function T.pantalla()
	local r = disposicion()
	return r.escala, r.ox, r.oy
end

-- ---------- toques

local function dentro(caja, x, y, holgura)
	return x >= caja.x - holgura and x <= caja.x + caja.w + holgura
		and y >= caja.y - holgura and y <= caja.y + caja.h + holgura
end

-- qué control toma un dedo según dónde se apoya
local function elegir(x, y)
	local r = disposicion()
	local w = love.graphics.getDimensions()
	local holgura = r.start.h * 0.4
	if dentro(r.start, x, y, holgura) then return "start" end
	if dentro(r.select, x, y, holgura) then return "select" end
	local cx, cy = r.cruceta.x, r.cruceta.y
	if (x - cx) ^ 2 + (y - cy) ^ 2 <= (r.cruceta.r * 1.6) ^ 2 then return "cruceta" end
	local ax, ay = r.acciones.x, r.acciones.y
	if (x - ax) ^ 2 + (y - ay) ^ 2 <= (r.acciones.r * 1.6) ^ 2 then return "acciones" end
	-- sobre la pantalla del juego vale como A (confirma en los menús)
	local e, ox, oy = r.escala, r.ox, r.oy
	if x >= ox and x <= ox + ANCHO * e and y >= oy and y <= oy + ALTO * e then return "a" end
	-- fuera de todo: el lado izquierdo mueve y el derecho dispara
	return x < w / 2 and "cruceta" or "acciones"
end

function T.presionar(id, x, y)
	T.activo = true
	toques[id] = { x = x, y = y, control = elegir(x, y) }
end

function T.mover(id, x, y)
	local t = toques[id]
	if t then t.x, t.y = x, y end
end

function T.soltar(id)
	-- se borra después de leerlo una vez, para que un toque muy corto también cuente
	if toques[id] then toques[id].soltado = true end
end

-- con teclado o mando de verdad, los controles se esconden
function T.esconder()
	if not T.forzado then
		T.activo = false
		toques = {}
	end
end

-- botón de acción más cercano al dedo (deja deslizar de uno a otro)
local function boton_cercano(x, y)
	local mejor, distancia
	for _, b in ipairs(disposicion().botones) do
		local dd = ((x - b.x) ^ 2 + (y - b.y) ^ 2) / b.r ^ 2
		if not distancia or dd < distancia then mejor, distancia = b, dd end
	end
	return mejor
end

-- devuelve qué botones están apretados ahora, con los mismos nombres de leer_entrada
function T.leer()
	local e = {}
	if not T.activo then return e end
	local r = disposicion()
	for id, t in pairs(toques) do
		if t.control == "cruceta" then
			-- ocho direcciones; en diagonal se aprietan dos a la vez
			local dx, dy = t.x - r.cruceta.x, t.y - r.cruceta.y
			local muerta = r.cruceta.r * 0.22
			if math.abs(dx) > muerta and math.abs(dx) > math.abs(dy) * 0.45 then
				e[dx > 0 and "derecha" or "izquierda"] = true
			end
			if math.abs(dy) > muerta and math.abs(dy) > math.abs(dx) * 0.45 then
				e[dy > 0 and "abajo" or "arriba"] = true
			end
		elseif t.control == "acciones" then
			e[boton_cercano(t.x, t.y).nombre] = true
		else
			e[t.control] = true
		end
		if t.soltado then toques[id] = nil end
	end
	return e
end

-- ---------- dibujo

-- p = paleta; e = entrada de este cuadro (se iluminan también con teclado);
-- escribir(cadena, x_centro, y_arriba, escala) dibuja con las letras del juego
function T.dibujar(p, e, escribir)
	if not T.activo then return end
	local r = disposicion()
	local g = love.graphics
	local function tinta(c, alfa) g.setColor(c[1], c[2], c[3], alfa or 1) end
	-- colores sólidos (sin transparencia, para que no se manchen al superponerse)
	local function mezcla(a, b, t) return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t } end
	local reposo, apretado = mezcla(p.marco, p.tinta, 0.55), mezcla(p.marco, p.fondo, 0.9)
	local rotulo = mezcla(p.marco, p.fondo, 0.6)

	-- cruceta: una cruz con un brazo por dirección
	local c = r.cruceta
	local brazo = c.r * 0.62
	local function brazo_cruz(dx, dy, nombre)
		local x = c.x + dx * c.r * 0.5 - (dx ~= 0 and c.r * 0.5 or brazo / 2)
		local y = c.y + dy * c.r * 0.5 - (dy ~= 0 and c.r * 0.5 or brazo / 2)
		local bw, bh = dx ~= 0 and c.r or brazo, dy ~= 0 and c.r or brazo
		tinta(e[nombre] and apretado or reposo)
		g.rectangle("fill", x, y, bw, bh, brazo * 0.18)
		-- flecha
		local fx, fy, t = c.x + dx * c.r * 0.68, c.y + dy * c.r * 0.68, brazo * 0.26
		tinta(e[nombre] and p.marco or rotulo)
		if dx ~= 0 then
			g.polygon("fill", fx + dx * t, fy, fx - dx * t, fy - t, fx - dx * t, fy + t)
		else
			g.polygon("fill", fx, fy + dy * t, fx - t, fy - dy * t, fx + t, fy - dy * t)
		end
	end
	brazo_cruz(0, -1, "arriba")
	brazo_cruz(0, 1, "abajo")
	brazo_cruz(-1, 0, "izquierda")
	brazo_cruz(1, 0, "derecha")
	-- el centro tapa las esquinas redondeadas donde se juntan los brazos
	tinta(reposo)
	g.rectangle("fill", c.x - brazo / 2, c.y - brazo / 2, brazo, brazo)

	-- botones redondos con su letra y lo que hacen debajo
	for _, b in ipairs(r.botones) do
		local on = e[b.nombre]
		tinta(on and apretado or reposo)
		g.circle("fill", b.x, b.y, b.r)
		local k = math.max(1, math.floor(b.r / 6))
		tinta(on and p.marco or p.fondo)
		escribir(b.letra, b.x, b.y - k * 2.5, k)
		local kr = math.max(1, math.floor(b.r / 14))
		tinta(rotulo)
		escribir(b.rotulo, b.x, b.y + b.r + kr * 2, kr)
	end

	-- START y SELECT
	for _, caja in ipairs({ r.select, r.start }) do
		local on = e[caja.nombre:lower()]
		tinta(on and apretado or reposo)
		g.rectangle("fill", caja.x, caja.y, caja.w, caja.h, caja.h / 2)
		local k = math.max(1, math.floor(math.min(caja.h / 9, caja.w / (#caja.nombre * 4 + 4))))
		tinta(on and p.marco or p.fondo)
		escribir(caja.nombre, caja.x + caja.w / 2, caja.y + caja.h / 2 - k * 2.5, k)
	end
end

return T

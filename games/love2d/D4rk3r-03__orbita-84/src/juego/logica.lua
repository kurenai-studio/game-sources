-- Lógica del juego, sin gráficos ni sonido: así se puede probar fuera de LÖVE.
-- El estado vive en una tabla; main.lua la dibuja y reproduce s.sonidos.

local D = require("datos")
local L = {}

local ANCHO, ALTO, TECHO = D.ANCHO, D.ALTO, D.TECHO

local function tam(nombre)
	local d = D.dibujos[nombre]
	return #d[1], #d
end

local function choca(ax, ay, aw, ah, bx, by, bw, bh)
	return ax < bx + bw and bx < ax + aw and ay < by + bh and by < ay + ah
end

local function sonar(s, nombre)
	s.sonidos[#s.sonidos + 1] = nombre
end

local function cambiar(s, estado)
	s.estado = estado
	s.t = 0
end

-- ---------- creación

-- tabla: los 10 mejores, lista de { nombre = "ABC", puntos = n, nave, nivel, ciclo }, de mayor a menor
-- (nave, nivel y ciclo faltan en los récords de versiones viejas)
L.PUESTOS = 10
L.ABECEDARIO = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

function L.nuevo(tabla, azar)
	tabla = tabla or {}
	local s = {
		estado = "titulo", t = 0, tabla = tabla, record = tabla[1] and tabla[1].puntos or 0, azar = azar or math.random,
		sonidos = {}, estrellas = {},
	}
	for i = 1, 14 do
		s.estrellas[i] = { x = s.azar() * ANCHO, y = TECHO + s.azar() * (ALTO - TECHO), v = (i % 2 == 0) and 6 or 12 }
	end
	return s
end

local function terreno_vacio(s)
	s.arriba, s.abajo = {}, {}
	for x = 0, ANCHO do
		s.arriba[x], s.abajo[x] = 0, 0
	end
	s.terreno_rumbo_arriba, s.terreno_rumbo_abajo = 0, 0
end

local function empezar_nivel(s)
	s.enemigos, s.balas, s.balas_enemigas, s.mejoras, s.explosiones = {}, {}, {}, {}, {}
	s.jefe = nil
	s.tiempo_nivel, s.oleada = 0, 1.5
	s.guion, s.reloj_mejora = {}, 0
	s.desplazamiento = 0
	-- distancia recorrida y columnas de terreno creadas (para los fondos)
	s.recorrido, s.columna = 0, 0
	s.nave = { x = 4, y = 24, enfriar = 0 }
	s.transformada = false
	s.cartel = nil
	s.rayo_activo, s.rayo_golpe = 0, 0
	s.pulso = nil
	-- poderes con tiempo: tiempo perdido, sonda y abducción
	s.lento, s.abduccion = 0, 0
	s.sonda, s.abducidas = nil, 0
	s.gotas = {}
	s.grietas = {}
	-- Golfo Nuevo: reflectores de los dos buques, cargas de profundidad y sus destellos
	s.cargas, s.destellos, s.reflectores = {}, {}, {}
	s.luz_t, s.carga_reloj = 0, 6
	if D.niveles[s.nivel].reflectores then
		s.reflectores = {
			{ ox = 16, base = 30, amplitud = 22, rapidez = 0.55, fase = 0, ancho = 4, encendido = true },
			{ ox = 62, base = 50, amplitud = 24, rapidez = 0.4, fase = 2, ancho = 4, encendido = true },
		}
	end
	s.hielo_falta, s.hielo_abierto = 30, 0
	terreno_vacio(s)
	local terreno = D.niveles[s.nivel].terreno
	if terreno == "llano" or terreno == "lecho" or terreno == "hielo" then
		local alto = ({ llano = 2, lecho = 4, hielo = ALTO - (D.niveles[s.nivel].agua or 37) })[terreno]
		for x = 0, ANCHO do s.abajo[x] = alto end
	end
	cambiar(s, "inicio_nivel")
	sonar(s, "inicio")
end

function L.empezar_partida(s)
	s.nivel, s.ciclo = s.prueba and s.prueba.nivel or 1, s.prueba and s.prueba.vuelta or 1
	s.puntos, s.vidas, s.rayos = 0, 3, 2
	s.escudo, s.triple, s.invencible = 0, 0, 0
	s.poder, s.aprendidos = nil, {}
	s.record_nuevo = false
	s.puesto = nil
	s.victoria = nil
	s.mejor_tramo, s.continuaciones = 0, 0
	empezar_nivel(s)
	-- una partida de verdad empieza con el prólogo (el modo de prueba va directo al nivel)
	if not s.prueba then
		s.pagina = 1
		cambiar(s, "prologo")
	end
end

-- pantallas de la historia: cada página dura un rato y se puede pasar con A o START
L.PAGINA, L.PAGINA_MAPA = 4, 4.5
local function pasar_pagina(s, e, dura)
	return s.t > dura or (s.t > 0.6 and (e.a_pulsado or e.start_pulsado))
end

-- continuar como en las recreativas: se sigue ahí mismo (el jefe conserva el daño recibido)
-- con tres vidas y el puntaje en cero; para los récords cuenta el mejor tramo sin continuar
L.CUENTA_CONTINUAR = 10
function L.continuar(s)
	s.mejor_tramo = math.max(s.mejor_tramo or 0, s.puntos)
	s.continuaciones = (s.continuaciones or 0) + 1
	s.puntos, s.vidas, s.rayos = 0, 3, math.max(s.rayos, 2)
	s.escudo, s.triple = 0, 0
	s.balas_enemigas = {}
	local n = s.nave
	n.oculta, n.entrando = 1.0, nil
	s.invencible, s.rayo_activo = 4, 0
	cambiar(s, "jugando")
	sonar(s, "mejora")
end

local function datos_nivel(s)
	return D.niveles[s.nivel]
end

local function en_tierra(s)
	return datos_nivel(s).modo == "tierra"
end

local function submarino(s)
	return datos_nivel(s).modo == "submarino"
end

-- en el lago helado la oruga resbala y el hielo se rompe
local function hielo(s)
	return datos_nivel(s).hielo
end

-- en los niveles de mar, altura de la línea del agua (nil en los demás)
local function agua(s)
	return datos_nivel(s).agua
end

-- ---------- Golfo Nuevo: lo que alumbran los reflectores (o el destello de una carga) se puede tocar

-- un haz sale de la cubierta del buque (ox, agua - 3) y llega al fondo en dx, abriéndose;
-- devuelve el tramo [desde, hasta] que ilumina en la fila y
function L.tramo_haz(r, a, y)
	local oy = a - 3
	if y < oy or y > ALTO then return nil end
	local tt = (y - oy) / (ALTO - oy)
	local cx = r.ox + (r.dx - r.ox) * tt
	local medio = 0.5 + r.ancho * tt
	return cx - medio, cx + medio
end

function L.alumbrado(s, x, y, w, h)
	local a = agua(s)
	if not a then return false end
	for _, r in ipairs(s.reflectores or {}) do
		if r.encendido and r.dx then
			for _, fy in ipairs({ y, y + h / 2, y + h }) do
				local desde, hasta = L.tramo_haz(r, a, fy)
				if desde and desde < x + w and hasta > x then return true end
			end
		end
	end
	for _, d in ipairs(s.destellos or {}) do
		local cx, cy = math.max(x, math.min(d.x, x + w)), math.max(y, math.min(d.y, y + h))
		if (cx - d.x) ^ 2 + (cy - d.y) ^ 2 <= d.r ^ 2 then return true end
	end
	return false
end

-- gotas que saltan al cruzar la superficie (solo se dibujan)
local function salpicar(s, x, y)
	for k = 1, 4 do
		s.gotas[#s.gotas + 1] = { x = x + k - 2.5, y = y - 1, vx = (k - 2.5) * 9, vy = -(22 + s.azar() * 14), t = 0 }
	end
end

-- naves que se pueden elegir en la portada (todas de 7x5)
-- cada una con su disparo y su poder especial (botón B)
L.NAVES = {
	{ dibujo = "nave", nombre = "CABINA", arma = "simple", especial = "rayo", detalle = "DISPARO + RAYO" },
	{ dibujo = "nave_interceptor", nombre = "INTERCEPTOR", arma = "doble", especial = "pulso", detalle = "DOBLE + PULSO" },
}

function L.nave_actual(s)
	return L.NAVES[s.nave_elegida or 1]
end

-- qué dibujo usa la nave: en tierra se vuelve oruga y bajo el agua batiscafo
function L.forma_nave(s)
	if s.nivel and s.estado ~= "titulo" and not (s.estado == "inicio_nivel" and s.t < 1.4) then
		if en_tierra(s) then return "oruga" end
		if submarino(s) then return "batiscafo" end
	end
	return L.NAVES[s.nave_elegida or 1].dibujo
end

-- multiplicador de dificultad por cada vuelta completa a los niveles
local function dificultad(s)
	return 1 + 0.25 * (s.ciclo - 1)
end

-- ---------- terreno

local function nueva_columna(s)
	local tipo = datos_nivel(s).terreno
	local function paso(alto, rumbo, minimo, maximo)
		if s.azar() < 0.15 then
			rumbo = math.floor(s.azar() * 3) - 1
		end
		alto = math.max(minimo, math.min(maximo, alto + rumbo))
		return alto, rumbo
	end
	local arriba, abajo = s.arriba[ANCHO], s.abajo[ANCHO]
	-- durante el jefe el terreno se aplana para dejarle sitio
	if s.jefe then
		-- en tierra queda un suelo bajo para que la oruga siga rodando
		local piso = (tipo == "llano" and 2) or (tipo == "lecho" and 3) or (tipo == "hielo" and ALTO - datos_nivel(s).agua) or 0
		arriba, abajo = math.max(0, arriba - 1), math.max(piso, abajo - 1)
	elseif tipo == "suelo" then
		abajo, s.terreno_rumbo_abajo = paso(abajo, s.terreno_rumbo_abajo, 1, 9)
	elseif tipo == "llano" then
		-- lomas suaves para que la oruga pueda avanzar
		if s.azar() < 0.5 then
			abajo, s.terreno_rumbo_abajo = paso(abajo, s.terreno_rumbo_abajo, 2, 6)
		end
	elseif tipo == "hielo" then
		-- hielo parejo con agujeros de vez en cuando (siempre se pueden saltar)
		s.hielo_falta = s.hielo_falta - 1
		abajo = ALTO - datos_nivel(s).agua
		if s.hielo_abierto > 0 then
			s.hielo_abierto, abajo = s.hielo_abierto - 1, 0
		elseif s.hielo_falta <= 0 then
			s.hielo_abierto = 5 + math.floor(s.azar() * 3)
			s.hielo_falta = 45 + math.floor(s.azar() * 40)
			abajo = 0
		end
	elseif tipo == "lecho" then
		-- fondo del mar: dunas que suben y bajan despacio
		if s.azar() < 0.5 then
			abajo, s.terreno_rumbo_abajo = paso(abajo, s.terreno_rumbo_abajo, 3, 9)
		end
	elseif tipo == "cueva" then
		abajo, s.terreno_rumbo_abajo = paso(abajo, s.terreno_rumbo_abajo, 1, 8)
		arriba, s.terreno_rumbo_arriba = paso(arriba, s.terreno_rumbo_arriba, 0, 6)
	end
	for x = 0, ANCHO - 1 do
		s.arriba[x], s.abajo[x] = s.arriba[x + 1], s.abajo[x + 1]
	end
	s.arriba[ANCHO], s.abajo[ANCHO] = arriba, abajo
	s.columna = (s.columna or 0) + 1
end

local function choca_terreno(s, x, y, w, h)
	for cx = math.max(0, math.floor(x)), math.min(ANCHO, math.floor(x + w - 1)) do
		if y + h > ALTO - s.abajo[cx] or y < TECHO + s.arriba[cx] then
			return true
		end
	end
	return false
end

-- empuja algo de w x h fuera del suelo y del techo de la cueva (los enemigos vuelan por encima)
local function respetar_terreno(s, o, w, h)
	local arriba, abajo = 0, 0
	for cx = math.max(0, math.floor(o.x)), math.min(ANCHO, math.floor(o.x + w - 1)) do
		arriba, abajo = math.max(arriba, s.arriba[cx]), math.max(abajo, s.abajo[cx])
	end
	local antes = o.y
	o.y = math.min(o.y, ALTO - abajo - h)
	o.y = math.max(o.y, TECHO + arriba)
	if o.base_y then
		o.base_y = o.base_y + (o.y - antes)
	end
end

-- altura de suelo más alta bajo algo que va de x a x + w - 1
local function suelo_bajo(s, x, w)
	local abajo = 0
	for cx = math.max(0, math.floor(x)), math.min(ANCHO, math.floor(x + w - 1)) do
		abajo = math.max(abajo, s.abajo[cx])
	end
	return abajo
end

-- abre un agujero en el hielo centrado en cx
local function abrir_agujero(s, cx, ancho)
	local desde = math.floor(cx - ancho / 2 + 0.5)
	for x = math.max(0, desde), math.min(ANCHO, desde + ancho - 1) do
		s.abajo[x] = 0
	end
end

-- grieta en el hielo: avisa y al rato se vuelve agujero
local function rajar(s, x, ancho)
	s.grietas[#s.grietas + 1] = { x = x, t = 0, ancho = ancho or 7 }
end

-- ---------- enemigos

local function hueco_vertical(s, h)
	-- zona libre de terreno donde puede aparecer algo de alto h
	local arriba, abajo = 0, 0
	for x = ANCHO - 12, ANCHO do
		arriba, abajo = math.max(arriba, s.arriba[x]), math.max(abajo, s.abajo[x])
	end
	local minimo, maximo = TECHO + arriba + 1, ALTO - abajo - h - 1
	-- sobre el mar, lo que vuela aparece por encima del agua
	if agua(s) then
		maximo = math.min(maximo, agua(s) - h - 2)
	end
	if maximo < minimo then
		maximo = minimo
	end
	return minimo, maximo
end

-- los enemigos (no los jefes) se ponen más bravos en cada expediente: 0,9 en el nivel 1
-- hasta 1,17 en el 10, encima de lo que sube cada vuelta
local function dificultad_enemigos(s)
	return dificultad(s) * (0.9 + 0.03 * ((s.nivel or 1) - 1))
end
L.dificultad_enemigos = dificultad_enemigos

-- enemigos que de por sí no disparan pero que, desde el nivel 3, pueden venir "armados":
-- avisan con un marco que titila y sueltan una bala apuntada
L.ARMABLES = { chispa = true, medusa = true, espora = true, lazo = true, rodante = true, saltarin = true, orbe = true }
L.AVISO_ARMADO = 0.45
-- de cada tantos, cuántos vienen armados según el nivel (nada en el 1 y el 2, la mitad desde el 8)
function L.prob_armado(nivel)
	return math.max(0, math.min(0.5, 0.08 * (nivel - 2)))
end
-- vida extra: +1 desde el nivel 5 y +2 desde el 9 (no para los muy duros ni los especiales)
local SIN_EXTRA = { mina = true, esporita = true, gemelo = true }
function L.vida_extra(nivel, tipo)
	local t = D.enemigos[tipo]
	if t.invulnerable or SIN_EXTRA[tipo] or t.vida >= 5 then return 0 end
	return math.floor((nivel - 1) / 4)
end

local function crear_enemigo(s, tipo, x, y, fase)
	local t = D.enemigos[tipo]
	local w, h = tam(tipo)
	local nivel = s.nivel or 1
	local e = {
		tipo = tipo, x = x, y = y, base_y = y, w = w, h = h, vida = t.vida + L.vida_extra(nivel, tipo), t = 0, fase = fase or 0,
		golpe = 0, disparo = 1 + s.azar(),
	}
	if L.ARMABLES[tipo] and s.azar() < L.prob_armado(nivel) then
		e.armado = 1.2 + s.azar() * 1.2
	end
	s.enemigos[#s.enemigos + 1] = e
end

-- ritmo de las oleadas según lo avanzado del nivel: 1.2 al empezar, 0.6 justo antes del jefe
-- (multiplica el tiempo entre una oleada y la siguiente)
function L.ritmo_oleadas(progreso)
	return 1.2 - 0.6 * math.max(0, math.min(1, progreso))
end

local oleada
-- una oleada y, pasado el primer tercio del nivel, a veces una escolta de otro tipo que
-- entra un poco más atrás: así se mezclan los enemigos del expediente
function L.lanzar_oleada(s, progreso)
	local antes = #s.enemigos
	oleada(s)
	local lista = datos_nivel(s).enemigos
	if progreso > 0.3 and #s.enemigos < 9 and s.azar() < 0.2 + 0.5 * progreso then
		local principal = s.enemigos[antes + 1] and s.enemigos[antes + 1].tipo
		local otro
		for _ = 1, 4 do
			otro = lista[math.floor(s.azar() * #lista) + 1]
			if otro ~= principal then break end
		end
		local desde = #s.enemigos
		oleada(s, otro)
		for k = desde + 1, #s.enemigos do
			local en = s.enemigos[k]
			if en.x > ANCHO then en.x = en.x + 14 end
		end
	end
end

oleada = function(s, tipo)
	local lista = datos_nivel(s).enemigos
	tipo = tipo or lista[math.floor(s.azar() * #lista) + 1]
	local _, h = tam(tipo)
	local minimo, maximo = hueco_vertical(s, h)
	local y = minimo + math.floor(s.azar() * (maximo - minimo + 1))
	if tipo == "chispa" then
		for i = 0, 2 + math.floor(s.azar() * 3) do
			crear_enemigo(s, tipo, ANCHO + 2 + i * 8, y)
		end
	elseif tipo == "medusa" then
		local centro = math.max(minimo + 6, math.min(maximo - 6, y))
		for i = 0, 2 do
			crear_enemigo(s, tipo, ANCHO + 2 + i * 9, centro, i * 0.9)
		end
	elseif tipo == "dardo" then
		for i = 0, math.floor(s.azar() * 2) do
			local _, yy = 0, minimo + math.floor(s.azar() * (maximo - minimo + 1))
			crear_enemigo(s, tipo, ANCHO + 2 + i * 14, yy)
		end
	elseif tipo == "roca" then
		-- caen en diagonal desde arriba
		for i = 0, 1 + math.floor(s.azar() * 3) do
			crear_enemigo(s, tipo, 40 + s.azar() * 50 + i * 10, TECHO - 3 - i * 6)
		end
	elseif tipo == "espora" then
		local centro = math.max(minimo + 6, math.min(maximo - 6, y))
		for i = 0, 1 do
			crear_enemigo(s, tipo, ANCHO + 2 + i * 12, centro, i * 1.5)
		end
	elseif tipo == "torreta" or tipo == "pincho" or tipo == "rodante" then
		local _, alto = tam(tipo)
		crear_enemigo(s, tipo, ANCHO + 2, ALTO - alto - suelo_bajo(s, ANCHO - 6, 6))
		if tipo == "rodante" and s.azar() < 0.5 then
			crear_enemigo(s, tipo, ANCHO + 10, ALTO - alto - suelo_bajo(s, ANCHO - 6, 6))
		end
	elseif tipo == "lazo" then
		-- fila de cuatro con espacio para la vuelta
		local centro = math.max(minimo + 9, math.min(maximo - 1, y))
		for i = 0, 3 do
			crear_enemigo(s, tipo, ANCHO + 2 + i * 8, centro)
		end
	elseif tipo == "avispa" then
		for i = 0, 1 do
			crear_enemigo(s, tipo, ANCHO + 2 + i * 10, minimo + math.floor(s.azar() * (maximo - minimo + 1)), i == 0 and 1 or -1)
		end
	elseif tipo == "saltarin" then
		local _, alto = tam(tipo)
		crear_enemigo(s, tipo, ANCHO + 2, ALTO - alto - suelo_bajo(s, ANCHO - 6, 6))
	elseif tipo == "orbe" or tipo == "buzo" then
		-- nacen bajo el agua: primero se ve su sombra
		local _, alto = tam(tipo)
		crear_enemigo(s, tipo, ANCHO + 2, ALTO - alto - 2)
		if tipo == "orbe" and s.azar() < 0.5 then
			crear_enemigo(s, tipo, ANCHO + 14, ALTO - alto - 2)
		end
	elseif tipo == "plateado" then
		-- nace bajo el hielo; elige dónde romperlo
		local _, alto = tam(tipo)
		crear_enemigo(s, tipo, ANCHO + 2, ALTO - alto)
		s.enemigos[#s.enemigos].meta = 22 + s.azar() * 44
	elseif tipo == "luz" then
		-- sale del hielo más adelante, delante de la nave
		local _, alto = tam(tipo)
		crear_enemigo(s, tipo, 30 + math.floor(s.azar() * 46), ALTO - alto)
	elseif tipo == "torbellino" then
		crear_enemigo(s, tipo, ANCHO + 2, agua(s))
	elseif tipo == "cilindro" and agua(s) then
		-- en el golfo cruzan hundidos, a distintas profundidades: a unos se los espera y a otros se los busca
		local _, alto = tam(tipo)
		local a = agua(s)
		crear_enemigo(s, tipo, ANCHO + 2, a + 3 + math.floor(s.azar() * (ALTO - a - alto - 5)))
	elseif tipo == "planeador" then
		for i = 0, math.floor(s.azar() * 2) do
			crear_enemigo(s, tipo, ANCHO + 2 + i * 12, TECHO + 2 + math.floor(s.azar() * 9))
		end
	else
		crear_enemigo(s, tipo, ANCHO + 2, y)
	end
end

local function disparo_enemigo(s, x, y, vx, vy)
	s.balas_enemigas[#s.balas_enemigas + 1] = { x = x, y = y, vx = vx, vy = vy }
end

local function apuntar(s, x, y, velocidad)
	local dx, dy = s.nave.x + 3 - x, s.nave.y + 2 - y
	local largo = math.sqrt(dx * dx + dy * dy)
	if largo < 1 then
		largo = 1
	end
	return dx / largo * velocidad, dy / largo * velocidad
end

local function mover_enemigo(s, e, dt)
	local t = D.enemigos[e.tipo]
	local v = t.velocidad * dificultad_enemigos(s)
	e.t = e.t + dt
	if t.movimiento == "recto" then
		e.x = e.x - v * dt
		-- la chispa, ya dentro de la pantalla, va buscando tu altura poco a poco
		if e.tipo == "chispa" and e.x < ANCHO - 8 then
			e.y = e.y + math.max(-10 * dt, math.min(10 * dt, s.nave.y + 1 - e.y))
		end
	elseif t.movimiento == "onda" then
		e.x = e.x - v * dt
		e.y = e.base_y + math.sin(e.t * 3 + e.fase) * 6
		-- la medusa suelta una sola bala lenta hacia la nave
		if e.tipo == "medusa" and not e.disparo_hecho and e.x < 60 and e.x > s.nave.x + 10 then
			e.disparo_hecho = true
			local vx, vy = apuntar(s, e.x, e.y + 2, 18 * dificultad_enemigos(s))
			disparo_enemigo(s, e.x, e.y + 2, vx, vy)
		end
	elseif t.movimiento == "embestida" then
		if e.t < 0.7 then
			e.x = e.x - 10 * dt
			-- se alinea con la nave antes de lanzarse
			e.y = e.y + math.max(-20 * dt, math.min(20 * dt, s.nave.y + 1 - e.y))
		else
			e.x = e.x - v * dt
		end
	elseif t.movimiento == "tirador" then
		if e.x > 62 or e.t > 7 then
			e.x = e.x - (e.t > 7 and v * 2 or v) * dt
		end
		e.y = e.base_y + math.sin(e.t * 2) * 3
		e.disparo = e.disparo - dt
		if e.disparo <= 0 and e.x < ANCHO - 4 then
			e.disparo = 1.6 / dificultad_enemigos(s)
			local vx, vy = apuntar(s, e.x, e.y + 2, 28 * dificultad_enemigos(s))
			disparo_enemigo(s, e.x, e.y + 2, vx, vy)
		end
	end
	if t.movimiento == "caida" then
		e.x = e.x - v * dt
		e.y = e.y + v * 0.55 * dt
		if e.y >= ALTO - e.h - 0.5 then
			-- se estrella contra el fondo
			e.muerto = true
			s.explosiones[#s.explosiones + 1] = { x = e.x, y = e.y - 1, t = 0 }
		end
	elseif t.movimiento == "dispersa" then
		e.x = e.x - v * dt
		e.y = e.y + e.fase * 18 * dt
	elseif t.movimiento == "suelo" then
		-- pegada al suelo, avanza con el paisaje y dispara hacia la nave
		e.x = e.x - v * dt
		local abajo = 0
		for cx = math.max(0, math.floor(e.x)), math.min(ANCHO, math.floor(e.x + e.w - 1)) do
			abajo = math.max(abajo, s.abajo[cx])
		end
		e.y = ALTO - abajo - e.h
		e.disparo = e.disparo - dt
		if e.disparo <= 0 and e.x < ANCHO - 4 and e.x > s.nave.x + 6 then
			e.disparo = 2 / dificultad_enemigos(s)
			local vx, vy = apuntar(s, e.x, e.y, 26 * dificultad_enemigos(s))
			disparo_enemigo(s, e.x, e.y, vx, vy)
		end
	elseif t.movimiento == "rodar" then
		-- rueda pegado al suelo hacia la nave; el rodante va tomando impulso
		local impulso = e.tipo == "rodante" and math.min(1.8, 0.6 + e.t * 0.4) or 1
		e.x = e.x - v * impulso * dt
		e.y = ALTO - suelo_bajo(s, e.x, e.w) - e.h
	elseif t.movimiento == "zigzag" then
		e.x = e.x - v * dt
		e.y = e.y + (e.fase >= 0 and 1 or -1) * 22 * dificultad_enemigos(s) * dt
		local arriba = 0
		for cx = math.max(0, math.floor(e.x)), math.min(ANCHO, math.floor(e.x + e.w - 1)) do
			arriba = math.max(arriba, s.arriba[cx])
		end
		if e.y <= TECHO + arriba + 1 then
			e.fase = 1
		elseif e.y >= ALTO - suelo_bajo(s, e.x, e.w) - e.h - 1 then
			e.fase = -1
		end
		e.disparo = e.disparo - dt
		if e.disparo <= 0 and e.x < ANCHO - 4 then
			e.disparo = 1.8 / dificultad_enemigos(s)
			disparo_enemigo(s, e.x, e.y + 1, -30 * dificultad_enemigos(s), -5)
			disparo_enemigo(s, e.x, e.y + 3, -30 * dificultad_enemigos(s), 5)
		end
	elseif t.movimiento == "lazo" then
		if not e.giro and e.x < 52 then
			e.giro, e.cx, e.cy = 0, e.x, e.y - 7
		end
		if e.giro and e.giro < math.pi * 2 then
			-- una vuelta completa en sentido contrario al reloj
			e.giro = e.giro + 4 * dificultad_enemigos(s) * dt
			e.x = e.cx - math.sin(e.giro) * 7
			e.y = e.cy + math.cos(e.giro) * 7
			-- al cerrar la vuelta dispara hacia la nave
			if e.giro >= math.pi * 2 and e.x > s.nave.x + 6 then
				local vx, vy = apuntar(s, e.x, e.y + 2, 30 * dificultad_enemigos(s))
				disparo_enemigo(s, e.x, e.y + 2, vx, vy)
			end
		else
			e.x = e.x - v * dt
		end
	elseif t.movimiento == "orbita" then
		e.destino = e.destino or (50 + s.azar() * 16)
		if not e.cx then
			e.x = e.x - v * dt
			if e.x <= e.destino then
				e.cx, e.cy, e.giro, e.rafagas = e.x, e.y, 0, 0
			end
		elseif e.giro < 3.2 then
			e.giro = e.giro + dt
			e.x = e.cx + math.sin(e.giro * 3) * 5
			e.y = e.cy + math.cos(e.giro * 3) * 5 - 5
			-- rueda de 8 balas a mitad de la vuelta y al final
			if (e.rafagas == 0 and e.giro > 1.4) or (e.rafagas == 1 and e.giro > 3) then
				e.rafagas = e.rafagas + 1
				for k = 0, 7 do
					local a = k * math.pi / 4 + e.rafagas * 0.4
					disparo_enemigo(s, e.x + 3, e.y + 3, math.cos(a) * 20 * dificultad_enemigos(s), math.sin(a) * 20 * dificultad_enemigos(s))
				end
			end
		else
			e.x = e.x - v * 2 * dt
		end
	elseif t.movimiento == "minador" then
		e.x = e.x - v * dt
		e.disparo = e.disparo - dt
		if e.disparo <= 0 and e.x < ANCHO - 10 then
			e.disparo = 1.6 / dificultad_enemigos(s)
			crear_enemigo(s, "mina", e.x + 3, e.y + e.h)
		end
	elseif t.movimiento == "mina" then
		e.x = e.x - v * dt
		if e.t > 1.8 then
			-- revienta en cuatro balas en diagonal
			e.muerto = true
			s.explosiones[#s.explosiones + 1] = { x = e.x - 1, y = e.y - 1, t = 0 }
			for _, d in ipairs({ { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } }) do
				disparo_enemigo(s, e.x + 1, e.y + 1, d[1] * 18 * dificultad_enemigos(s), d[2] * 18 * dificultad_enemigos(s))
			end
		end
	elseif t.movimiento == "francotirador" then
		if (e.tiros or 0) >= 3 then
			e.apuntando = nil
			e.x = e.x - v * 2 * dt
		elseif e.x > 74 then
			e.x = e.x - v * dt
		else
			e.disparo = e.disparo - dt
			if e.apuntando then
				-- sigue la altura de la nave mientras apunta, luego dispara
				e.y = e.y + math.max(-16 * dt, math.min(16 * dt, s.nave.y - e.y))
				if e.disparo <= 0 then
					e.apuntando = nil
					e.tiros = (e.tiros or 0) + 1
					e.disparo = 1.1 / dificultad_enemigos(s)
					disparo_enemigo(s, e.x - 2, e.y + 2, -70 * dificultad_enemigos(s), 0)
					sonar(s, "rebote")
				end
			elseif e.disparo <= 0 then
				e.apuntando = true
				e.disparo = 0.8
			end
		end
	elseif t.movimiento == "salto" then
		e.x = e.x - v * dt
		local piso = ALTO - suelo_bajo(s, e.x, e.w) - e.h
		e.vy = (e.vy or 0) + 140 * dt
		e.y = e.y + e.vy * dt
		if e.y >= piso then
			e.y, e.vy = piso, 0
			e.disparo = e.disparo - dt
			if e.disparo <= 0 then
				e.disparo = 0.5 + s.azar() * 0.6
				e.vy = -(40 + s.azar() * 20)
			end
		end
	elseif t.movimiento == "planeo" then
		-- vuela alto y suelta bombas cuando pasa por encima de la oruga
		e.x = e.x - v * dt
		e.y = e.base_y + math.sin(e.t * 2 + e.fase) * 2
		e.disparo = e.disparo - dt
		if e.disparo <= 0 and math.abs(e.x - s.nave.x - 2) < 14 then
			e.disparo = 1.4 / dificultad_enemigos(s)
			disparo_enemigo(s, e.x + 3, e.y + e.h, -6, 26 * dificultad_enemigos(s))
		end
	elseif t.movimiento == "brinco" then
		-- nada al fondo y de a ratos salta fuera del agua en arco
		e.x = e.x - v * dt
		local fondo = ALTO - e.h - 2
		if not e.saltando then
			e.y = math.min(fondo, e.y + 20 * dt)
			e.espera = (e.espera or (0.3 + s.azar() * 1.2)) - dt
			if e.espera <= 0 and e.x < ANCHO - 6 then
				e.saltando, e.vy = true, -(56 + s.azar() * 14)
			end
		else
			e.vy = e.vy + 80 * dt
			e.y = e.y + e.vy * dt
			if e.vy > 0 and e.y >= fondo then
				e.y, e.saltando, e.espera = fondo, false, 1 + s.azar()
			end
		end
	elseif t.movimiento == "asomar" then
		-- nada hundido, asoma la cabeza dos veces, dispara burbujas y se vuelve a hundir
		e.x = e.x - v * dt
		local hundido, asomado = ALTO - e.h - 2, agua(s) - 3
		e.asomos = e.asomos or 0
		e.fase_buzo = e.fase_buzo or "nada"
		if e.fase_buzo == "nada" then
			e.y = math.min(hundido, e.y + 18 * dt)
			if e.asomos < 2 and e.x < 70 - e.asomos * 28 then
				e.fase_buzo = "sube"
			end
		elseif e.fase_buzo == "sube" then
			e.y = e.y - 18 * dt
			if e.y <= asomado then
				e.y, e.fase_buzo, e.reloj, e.disparo = asomado, "arriba", 1.3, 0.3
			end
		elseif e.fase_buzo == "arriba" then
			e.reloj = e.reloj - dt
			e.disparo = e.disparo - dt
			if e.disparo <= 0 then
				e.disparo = 0.6 / dificultad_enemigos(s)
				local vx, vy = apuntar(s, e.x + 2, e.y, 24 * dificultad_enemigos(s))
				disparo_enemigo(s, e.x + 2, e.y, vx, vy)
			end
			if e.reloj <= 0 then
				e.fase_buzo, e.asomos = "baja", e.asomos + 1
			end
		else
			e.y = e.y + 18 * dt
			if e.y >= hundido then
				e.y, e.fase_buzo = hundido, "nada"
			end
		end
	elseif t.movimiento == "cruce" then
		-- cruza rápido ondulando apenas y dispara hacia arriba y hacia abajo
		e.x = e.x - v * dt
		e.y = e.base_y + math.sin(e.t * 4) * 1.5
		e.disparo = e.disparo - dt
		if e.disparo <= 0 and e.x < ANCHO - 6 and e.x > 4 then
			e.disparo = 1.1 / dificultad_enemigos(s)
			disparo_enemigo(s, e.x + 4, e.y - 1, -8, -24 * dificultad_enemigos(s))
			disparo_enemigo(s, e.x + 4, e.y + e.h, -8, 24 * dificultad_enemigos(s))
		end
	elseif t.movimiento == "romper" then
		-- nada bajo el hielo, lo raja, lo rompe, asoma, dispara y se vuelve a hundir
		local hundido, asomado = ALTO - e.h, agua(s) - 4
		e.fase_p = e.fase_p or "nada"
		if e.fase_p == "nada" then
			e.x = e.x - v * dt
			e.y = math.min(hundido, e.y + 18 * dt)
			if e.meta and e.x <= e.meta then
				e.meta, e.fase_p, e.reloj = nil, "raja", 1.25
				rajar(s, e.x + e.w / 2, 7)
			end
		elseif e.fase_p == "raja" then
			-- espera bajo la grieta (que se mueve con el paisaje)
			e.x = e.x - 14 * dt
			e.reloj = e.reloj - dt
			if e.reloj <= 0 then
				e.fase_p = "sube"
			end
		elseif e.fase_p == "sube" then
			e.x = e.x - 14 * dt
			e.y = e.y - 22 * dt
			if e.y <= asomado then
				e.y, e.fase_p, e.reloj, e.disparo = asomado, "arriba", 1.5, 0.3
			end
		elseif e.fase_p == "arriba" then
			e.x = e.x - 14 * dt
			e.reloj = e.reloj - dt
			e.disparo = e.disparo - dt
			if e.disparo <= 0 then
				e.disparo = 0.55 / dificultad_enemigos(s)
				local vx, vy = apuntar(s, e.x + 2, e.y, 26 * dificultad_enemigos(s))
				disparo_enemigo(s, e.x + 2, e.y, vx, vy)
			end
			if e.reloj <= 0 then
				e.fase_p = "baja"
			end
		else
			e.x = e.x - 14 * dt
			e.y = e.y + 20 * dt
			if e.y >= hundido then
				e.y, e.fase_p = hundido, "nada"
			end
		end
	elseif t.movimiento == "subir" then
		-- raja el hielo, lo atraviesa y sube recto hasta perderse arriba
		if not e.rajado then
			e.rajado = true
			rajar(s, e.x + e.w / 2, 5)
		end
		e.x = e.x - 14 * dt
		if e.t > 1.3 then
			e.y = e.y - v * dt
			e.x = e.x + math.sin(e.t * 5) * 6 * dt
			if e.y < TECHO - e.h then
				e.muerto = true
			end
		end
	elseif t.movimiento == "gemelo" then
		-- lo mueve el jefe; al pasar a la fase 3 se va por la derecha
		if e.retira then
			e.x = e.x + 22 * dt
			if e.x > ANCHO + 4 then e.muerto = true end
		end
	elseif t.movimiento == "remolino" then
		-- flota en la superficie y arrastra la nave hacia su centro y hacia abajo
		e.x = e.x - v * dt
		e.y = agua(s)
		local n = s.nave
		if not n.oculta and not n.entrando then
			local dx = e.x + e.w / 2 - (n.x + 3)
			if math.abs(dx) < 16 and n.y > agua(s) - 18 then
				-- sin sacarla de la pantalla
				n.x = math.max(0, math.min(ANCHO - 7, n.x + (dx > 0 and 1 or -1) * 10 * dt))
				n.y = n.y + 14 * dt
			end
		end
	end
	-- armado: ya dentro de la pantalla, avisa (marco que titila) y dispara apuntado
	if e.armado and not e.bajo_agua and e.x < ANCHO - 6 and e.x > 10 then
		e.armado = e.armado - dt
		e.avisando = e.armado < L.AVISO_ARMADO
		if e.armado <= 0 then
			local vx, vy = apuntar(s, e.x, e.y + e.h / 2, 24 * dificultad_enemigos(s))
			disparo_enemigo(s, e.x, e.y + e.h / 2, vx, vy)
			e.armado, e.avisando = (2.6 + s.azar()) / dificultad_enemigos(s), false
		end
	else
		e.avisando = false
	end
	if e.tipo == "caparazon" then
		e.disparo = e.disparo - dt
		if e.disparo <= 0 and e.x < ANCHO - 4 then
			e.disparo = 2.2 / dificultad_enemigos(s)
			-- alterna disparo recto y abanico de tres
			e.abanico = not e.abanico
			if e.abanico then
				for _, vy in ipairs({ -10, 0, 10 }) do
					disparo_enemigo(s, e.x, e.y + 2, -28 * dificultad_enemigos(s), vy)
				end
			else
				disparo_enemigo(s, e.x, e.y + 2, -34 * dificultad_enemigos(s), 0)
			end
		end
	end
	-- los que nadan bajo el hielo no se empujan fuera del suelo
	local bajo_hielo = t.movimiento == "romper" or t.movimiento == "subir"
	if (t.movimiento ~= "caida" or e.y > TECHO) and not bajo_hielo then
		respetar_terreno(s, e, e.w, e.h)
	end
	-- sobre el mar: lo que queda entero bajo el agua no toca ni se puede tocar
	local a = agua(s)
	if a then
		e.alumbrado = datos_nivel(s).reflectores and L.alumbrado(s, e.x, e.y, e.w, e.h)
		e.bajo_agua = e.y >= a + 1 and not e.alumbrado
		local fuera = e.y + e.h / 2 < a
		if e.fuera ~= nil and e.fuera ~= fuera then
			salpicar(s, e.x + e.w / 2, a)
		end
		e.fuera = fuera
	end
	e.golpe = math.max(0, e.golpe - dt)
end

-- ---------- jefe

-- cada nivel tiene su jefe: dibujo y velocidad al subir y bajar
local JEFES = {
	coloso = { dibujo = "jefe", velocidad = 0, y = 19 },
	tenaza = { dibujo = "tenaza", velocidad = 20 },
	ojo = { dibujo = "ojo_abierto", velocidad = 0 },
	serpiente = { dibujo = "serpiente_cabeza", velocidad = 0, casa_x = 58 },
	nucleo = { dibujo = "nucleo", velocidad = 9 },
	nodriza = { dibujo = "nodriza", velocidad = 0, y = TECHO + 1 },
	shag = { dibujo = "shag", velocidad = 0, y = 28 },
	piramide = { dibujo = "piramide", velocidad = 0, y = ALTO - 3 - 11 },
	gigante = { dibujo = "gigante", velocidad = 0, y = 39 },
	fantasma = { dibujo = "fantasma", velocidad = 0, y = ALTO - 8 - 2 },
}

local function crear_jefe(s)
	local tipo = datos_nivel(s).jefe or "coloso"
	local w, h = tam(JEFES[tipo].dibujo)
	local vida = math.floor(datos_nivel(s).jefe_vida * (1 + 0.3 * (s.ciclo - 1)))
	s.jefe = {
		tipo = tipo, dibujo = JEFES[tipo].dibujo, x = ANCHO + 2, y = JEFES[tipo].y or 20, w = w, h = h,
		casa_x = JEFES[tipo].casa_x or (ANCHO - w - 3), rastro = {}, bloques = {},
		vida = vida, maximo = vida, t = 0, rumbo = 1, golpe = 0,
		ataque = 1.5, invocar = 3, embestida = 3, parpado = 2.5,
		-- el fantasma llega hundido: no toca ni se le puede pegar hasta que lo alumbren
		sumergido = tipo == "fantasma" or nil,
	}
	sonar(s, "jefe")
end

-- ---------- jefes por fases: ataques fijos que se aprenden, con aviso antes de cada uno

-- en qué fase va el jefe según la vida que le queda (1 llena, 3 en el último tercio)
local function fase_por_vida(j)
	local resto = j.vida / j.maximo
	return resto > 2 / 3 and 1 or resto > 1 / 3 and 2 or 3
end

-- al cambiar de fase el jefe se sacude, se cubre con un escudo (un marco, como el de la nave)
-- y se queda quieto un momento; el escudo titila justo antes de volver a pelear
L.CAMBIO_FASE, L.SACUDIDA, L.ESCUDO_AVISO = 2.2, 0.6, 0.6
local function revisar_fase(s, j)
	local f = fase_por_vida(j)
	j.fase_n = j.fase_n or 1
	if f > j.fase_n then
		j.fase_n, j.cambio, j.paso, j.ataque = f, L.CAMBIO_FASE, 0, 1.0
		j.avisos = {}
		j.chispazo = 0
		-- las balas no se esfuman: se deshacen en chispas y dan 5 puntos cada una
		for _, b in ipairs(s.balas_enemigas) do
			s.gotas[#s.gotas + 1] = { x = b.x, y = b.y, vx = (s.azar() - 0.5) * 24, vy = -(14 + s.azar() * 16), t = 0 }
			if not s.prueba then s.puntos = s.puntos + 5 end
		end
		s.balas_enemigas = {}
		s.cartel = { texto = "FASE " .. f, t = 1.6 }
		sonar(s, "embestida")
	end
end

-- bala que sale, se frena, espera quieta y luego sale disparada hacia la nave
local function bala_frenada(s, x, y, vx, vy, espera, rapidez)
	s.balas_enemigas[#s.balas_enemigas + 1] = { x = x, y = y, vx = vx, vy = vy, vx0 = vx, vy0 = vy, frena = 0.45, espera = espera, rapidez = rapidez }
end

-- abanico hacia la izquierda: cada ángulo se mide desde el frente (0 = recto)
local function abanico(s, x, y, angulos, vel)
	for _, a in ipairs(angulos) do
		disparo_enemigo(s, x, y, -math.cos(a) * vel, math.sin(a) * vel)
	end
end
local ABANICO_5 = { -0.5, -0.25, 0, 0.25, 0.5 }
local ABANICO_4 = { -0.375, -0.125, 0.125, 0.375 }

-- muro de balas con un hueco: con avisar, solo pone su silueta en los avisos
local function muro(s, j, x, hueco, vel, avisar)
	for y = TECHO + 1, ALTO - 2, 3 do
		if math.abs(y + 1 - hueco) > 5 and not choca_terreno(s, x, y, 2, 2) then
			if avisar then
				j.avisos[#j.avisos + 1] = { x = x, y = y, w = 1, h = 2 }
			else
				disparo_enemigo(s, x, y, -vel, 0)
			end
		end
	end
end

-- espiral: un brazo que gira; solo dispara los tramos que van hacia la izquierda
local function espiral(s, j, x, y, paso_angulo, vel, clave)
	clave = clave or "angulo"
	j[clave] = (j[clave] or 0) + paso_angulo
	local a = j[clave]
	if math.cos(a) < 0.3 then
		disparo_enemigo(s, x, y, math.cos(a) * vel - 6, math.sin(a) * vel)
	end
end

-- reloj de ataque: devuelve true cuando toca disparar y lo recarga
local function toca(j, clave, dt, cada)
	j[clave] = (j[clave] or cada) - dt
	if j[clave] <= 0 then
		j[clave] = j[clave] + cada
		return true
	end
	return false
end

-- huecos de los muros de la fase 2, siempre en el mismo orden (centro del hueco)
local HUECOS_COLOSO = { 14, 36, 25, 11, 39, 25 }

-- el platillo de Roswell.
-- Fase 1: abanicos alternos de 5 y 4 balas; el hueco de uno es la bala del otro.
-- Fase 2: se queda al centro y suelta muros de balas con un hueco; la silueta
--         del muro aparece antes en tono medio.
-- Fase 3: espiral hacia adelante y, cada tanto, cuatro balas que se frenan y apuntan.
local function coloso(s, j, dt)
	local dif = dificultad(s)
	j.avisos = {}
	j.paso = j.paso or 0
	-- el piloto de Roswell en su cúpula; las luces del borde corren
	j.dibujo = ({ "jefe", "jefe_b", "jefe_c", "jefe_d" })[math.floor(j.t * 4) % 4 + 1]
	local cx, cy = j.x - 1, j.y + 7
	j.ataque = j.ataque - dt
	if j.fase_n == 1 then
		j.giro = (j.giro or 0) + dt
		j.y = 19 + math.sin(j.giro * 0.9) * 10
		-- la cúpula titila un momento antes de cada abanico
		if j.ataque < 0.3 then j.avisos[1] = { x = cx - 2, y = cy - 1, w = 2, h = 2 } end
		if j.ataque <= 0 then
			j.ataque = 1.4 / dif
			j.paso = j.paso + 1
			abanico(s, cx, cy, j.paso % 2 == 1 and ABANICO_5 or ABANICO_4, 26 * dif)
		end
	elseif j.fase_n == 2 then
		j.y = j.y + math.max(-20 * dt, math.min(20 * dt, 19 - j.y))
		local hueco = HUECOS_COLOSO[j.paso % #HUECOS_COLOSO + 1]
		if j.ataque < 0.7 then muro(s, j, j.x - 2, hueco, 0, true) end
		if j.ataque <= 0 then
			j.ataque = 2.2 / dif
			j.paso = j.paso + 1
			muro(s, j, j.x - 2, hueco, 22 * dif)
			sonar(s, "pulso")
		end
	else
		j.giro = (j.giro or 0) + dt
		j.y = 19 + math.sin(j.giro * 1.4) * 12
		if toca(j, "espiral", dt, 0.16 / dif) then espiral(s, j, cx, cy, 0.5, 24 * dif) end
		if j.ataque < 0.5 then j.avisos[1] = { x = cx - 2, y = cy - 1, w = 2, h = 2 } end
		if j.ataque <= 0 then
			j.ataque = 3.2 / dif
			for _, a in ipairs({ -1.2, -0.4, 0.4, 1.2 }) do
				bala_frenada(s, cx, cy, -math.cos(a) * 40, math.sin(a) * 40, 0.5, 38 * dif)
			end
		end
	end
end

-- la tenaza (el Triángulo Negro) embiste a lo ancho: antes tiembla (aviso) y fija la altura.
-- Fase 1: disparo doble recto desde las pinzas.
-- Fase 2: tijera: las dos pinzas disparan en diagonal y las balas se cruzan.
-- Fase 3: embestida doble; en la ida deja una estela de balas que se frenan y apuntan.
local function tenaza(s, j, dt)
	local dif = dificultad(s)
	j.avisos = {}
	-- las pinzas: abiertas mientras apunta, cerradas al embestir, y si no se mueven solas
	if j.cargando == "preparando" then
		j.dibujo = "tenaza_c"
	elseif j.cargando == "ida" then
		j.dibujo = "tenaza"
	else
		j.dibujo = ({ "tenaza", "tenaza_b", "tenaza_c", "tenaza_b" })[math.floor(j.t * 4) % 4 + 1]
	end
	if j.cargando == "preparando" then
		j.preparar = j.preparar - dt
		j.x = j.casa_x + ((math.floor(j.preparar * 30) % 2 == 0) and 1 or -1)
		-- línea en tono medio por donde va a pasar
		j.avisos[1] = { x = 0, y = j.objetivo_y + j.h / 2, w = j.casa_x, h = 1 }
		if j.preparar <= 0 then
			j.cargando = "ida"
			sonar(s, "embestida")
		end
		return
	elseif j.cargando == "ida" then
		j.x = j.x - 75 * dif * dt
		j.y = j.y + math.max(-30 * dt, math.min(30 * dt, j.objetivo_y - j.y))
		if j.fase_n == 3 and toca(j, "estela", dt, 0.11) then
			j.paso = (j.paso or 0) + 1
			bala_frenada(s, j.x + j.w, j.y + j.h / 2, 0, j.paso % 2 == 0 and 14 or -14, 0.6, 30 * dif)
		end
		if j.x <= 0 then
			j.x, j.cargando = 0, "vuelta"
		end
		return
	elseif j.cargando == "vuelta" then
		j.x = j.x + 40 * dt
		if j.x >= j.casa_x then
			j.x, j.cargando = j.casa_x, nil
			-- en la fase 3 embiste dos veces seguidas
			if j.fase_n == 3 and not j.segunda then
				j.segunda = true
				j.cargando, j.preparar = "preparando", 0.5
				j.objetivo_y = math.max(TECHO + 1, math.min(ALTO - j.h - 1, s.nave.y + 2 - j.h / 2))
			else
				j.segunda = nil
			end
		end
		return
	end
	j.embestida = j.embestida - dt
	if j.embestida <= 0 then
		j.embestida = ({ 4, 3.6, 4.2 })[j.fase_n] / dif
		j.cargando, j.preparar = "preparando", 0.6
		j.objetivo_y = math.max(TECHO + 1, math.min(ALTO - j.h - 1, s.nave.y + 2 - j.h / 2))
		return
	end
	j.ataque = j.ataque - dt
	if j.ataque <= 0 then
		if j.fase_n == 2 then
			j.ataque = 0.9 / dif
			disparo_enemigo(s, j.x, j.y + 5, -30 * dif, 9 * dif)
			disparo_enemigo(s, j.x, j.y + 9, -30 * dif, -9 * dif)
		else
			j.ataque = 1.1 / dif
			disparo_enemigo(s, j.x, j.y + 5, -34 * dif, 0)
			disparo_enemigo(s, j.x, j.y + 9, -34 * dif, 0)
		end
	end
end

-- el Gris de los Hill: solo recibe daño con el ojo abierto.
-- Cerrado ataca fuerte; abierto dispara menos (es el momento de pegarle). No sube y baja a
-- ritmo fijo: elige alturas (a veces la tuya) y parpadea a destiempo.
-- Fase 1: cerrado, abanicos hacia ti con un hueco que cambia de lugar; al abrir, la mirada:
--   una línea punteada te marca y por ahí sale una ráfaga rápida.
-- Fase 2: el mapa estelar de Betty Hill: cerrado, siembra estrellas quietas, las une con
--   líneas de aviso, las líneas se vuelven rayos y al final cada estrella revienta en cuatro.
-- Fase 3: cerrado abanicos y espiral; abierto ráfagas de tres; abre menos tiempo.
local PARPADOS = { { 2.0, 2.5 }, { 2.6, 2.0 }, { 2.6, 1.6 } }
L.MIRADA_AVISO, L.MAPA_AVISO, L.MAPA_RAYO, L.MAPA_REVIENTA = 0.6, 0.8, 0.5, 2.4
-- las estrellas del mapa de Betty Hill (las dos grandes de Zeta Reticuli y las que se unen a ellas)
local MAPA_HILL = { { 0, 8 }, { 3, 11 }, { 12, 2 }, { 13, 11 }, { 21, 5 }, { 23, 13 } }
local LINEAS_HILL = { { 1, 3 }, { 1, 4 }, { 2, 4 }, { 3, 5 }, { 4, 6 }, { 5, 6 } }
local herir_nave

-- ¿un rayo de (x1, y1) a (x2, y2) pasa por la nave?
local function rayo_toca_nave(s, x1, y1, x2, y2)
	local n = s.nave
	if n.oculta then return false end
	local d = D.dibujos[L.forma_nave(s)]
	local nw, nh = #d[1], #d
	local pasos = math.max(1, math.floor(math.max(math.abs(x2 - x1), math.abs(y2 - y1))))
	for i = 0, pasos do
		local x, y = x1 + (x2 - x1) * i / pasos, y1 + (y2 - y1) * i / pasos
		if x >= n.x + 1 and x < n.x + nw - 1 and y >= n.y + 1 and y < n.y + nh - 1 then return true end
	end
	return false
end

-- ángulo hacia la nave medido como en los abanicos (0 = recto a la izquierda)
local function angulo_a_nave(s, x, y)
	local a = math.atan2(s.nave.y + 2 - y, -(s.nave.x + 3 - x))
	return math.max(-0.9, math.min(0.9, a))
end

local function sembrar_mapa(s, j)
	local ox = 14 + math.floor(s.azar() * 14)
	local oy = TECHO + 3 + math.floor(s.azar() * (ALTO - TECHO - 24))
	local estrellas = {}
	for i, e in ipairs(MAPA_HILL) do
		local tx, ty = ox + e[1] * 1.6, oy + e[2] * 1.4
		-- sale del ojo y se frena justo en su lugar
		local b = { x = j.x + 4, y = j.y + 9, frena = 0.45, quieta = L.MAPA_REVIENTA - 0.45, revienta = 16 * dificultad(s) }
		b.vx0, b.vy0 = (tx - b.x) * 2 / 0.45, (ty - b.y) * 2 / 0.45
		b.vx, b.vy = b.vx0, b.vy0
		s.balas_enemigas[#s.balas_enemigas + 1] = b
		estrellas[i] = b
	end
	j.mapa = { t = 0, estrellas = estrellas }
end

local function ojo(s, j, dt)
	local dif = dificultad(s)
	j.avisos, j.lineas = {}, {}
	local f = j.fase_n
	-- al cambiar de fase las balas se deshacen: el mapa se olvida
	if j.fase_vista ~= f then
		j.fase_vista, j.mapa, j.mirada = f, nil, nil
	end
	-- se mueve a una altura nueva cada tanto; a veces a la tuya
	j.meta_y = j.meta_y or j.y
	j.mover = (j.mover or 0) - dt
	if j.mover <= 0 then
		j.mover = 1.2 + s.azar() * 1.6
		local alto = ALTO - j.h - 1
		if s.azar() < 0.5 then
			j.meta_y = s.nave.y + 2 - 9
		else
			j.meta_y = TECHO + 1 + s.azar() * (alto - TECHO - 1)
		end
		j.meta_y = math.max(TECHO + 1, math.min(alto, j.meta_y))
	end
	local paso = 14 * dif * dt
	j.y = j.y + math.max(-paso, math.min(paso, j.meta_y - j.y))

	j.parpado = j.parpado - dt
	if j.parpado <= 0 then
		j.cerrado = not j.cerrado
		local base = j.cerrado and PARPADOS[f][1] or PARPADOS[f][2]
		j.parpado = base * (0.75 + s.azar() * 0.5)
		j.ataque, j.rafaga = 0.4, 0
		if j.cerrado and f == 2 and not j.mapa then sembrar_mapa(s, j) end
		if not j.cerrado and f == 1 then j.mirada = { t = 0 } end
		if not j.cerrado and f == 2 then
			for _, a in ipairs({ -0.8, 0, 0.8 }) do
				bala_frenada(s, j.x + 4, j.y + 9, -math.cos(a) * 36, math.sin(a) * 36, 0.4, 34 * dif)
			end
		end
	end
	-- el párpado titila en tono medio antes de abrirse
	local centro, ex = j.y + 9, j.x + 4
	-- el dibujo: con el párpado cerrado (a medias y titilando justo antes de abrirse) o
	-- abierto mirando hacia la nave; los tentáculos se mecen en cuatro cuadros
	local k = math.floor(j.t * 5) % 4
	if j.cerrado then
		local avisa = j.parpado < 0.4 and math.floor(j.parpado * 10) % 2 == 0
		j.dibujo = (avisa and "ojo_m" or "ojo_c") .. k
	else
		local dy = s.nave.y + 2.5 - centro
		j.dibujo = "ojo_" .. (dy < -4 and 0 or (dy > 4 and 2 or 1)) .. k
	end
	j.ataque = j.ataque - dt

	-- la mirada: marca la línea hacia la nave, la deja fija y dispara por ahí
	if j.mirada then
		local m = j.mirada
		m.t = m.t + dt
		if m.t < L.MIRADA_AVISO then
			m.angulo = angulo_a_nave(s, ex, centro)
		end
		local x2, y2 = ex - math.cos(m.angulo) * 90, centro + math.sin(m.angulo) * 90
		if m.t >= 0 and m.t < L.MIRADA_AVISO then
			j.lineas[#j.lineas + 1] = { x1 = ex, y1 = centro, x2 = x2, y2 = y2, aviso = true }
		elseif (m.disparos or 0) < 3 and m.t >= L.MIRADA_AVISO + (m.disparos or 0) * 0.1 then
			m.disparos = (m.disparos or 0) + 1
			disparo_enemigo(s, ex, centro, -math.cos(m.angulo) * 48 * dif, math.sin(m.angulo) * 48 * dif)
			if m.disparos == 3 then
				-- si sigue abierto, vuelve a mirar al rato
				j.mirada = (not j.cerrado and j.parpado > 1.4) and { t = -0.5 } or nil
			end
		end
	end

	-- el mapa estelar: las estrellas se unen con líneas de aviso, que luego son rayos
	if j.mapa then
		local mp = j.mapa
		mp.t = mp.t + dt
		local desde = 0.45
		for _, l in ipairs(LINEAS_HILL) do
			local a, b = mp.estrellas[l[1]], mp.estrellas[l[2]]
			if not a.usada and not b.usada and mp.t >= desde then
				local rayo = mp.t >= desde + L.MAPA_AVISO and mp.t < desde + L.MAPA_AVISO + L.MAPA_RAYO
				if mp.t < desde + L.MAPA_AVISO or rayo then
					j.lineas[#j.lineas + 1] = { x1 = a.x + 1, y1 = a.y + 1, x2 = b.x + 1, y2 = b.y + 1, aviso = not rayo }
				end
				if rayo and rayo_toca_nave(s, a.x + 1, a.y + 1, b.x + 1, b.y + 1) then herir_nave(s) end
			end
		end
		if mp.t > L.MAPA_REVIENTA + 0.1 then j.mapa = nil end
	end

	if j.cerrado then
		if f == 2 then
			-- mientras el mapa está puesto, solo algún disparo suelto
			if j.ataque <= 0 then
				j.ataque = 1.4 / dif
				local vx, vy = apuntar(s, ex, centro, 30 * dif)
				disparo_enemigo(s, ex, centro, vx, vy)
			end
		elseif j.ataque <= 0 then
			j.ataque = (f == 1 and 1.0 or 1.2) / dif
			j.paso = (j.paso or 0) + 1
			if f == 1 then
				-- abanico de cinco hacia la nave con un hueco que cambia de lugar
				local a0 = angulo_a_nave(s, ex, centro)
				local hueco = 1 + math.floor(s.azar() * 5)
				local angulos = {}
				for k = 1, 5 do
					if k ~= hueco then angulos[#angulos + 1] = a0 + (k - 3) * 0.25 end
				end
				abanico(s, ex, centro, angulos, 28 * dif)
			else
				abanico(s, ex, centro, j.paso % 2 == 1 and ABANICO_5 or ABANICO_4, 28 * dif)
			end
		end
		if f == 3 and toca(j, "espiral", dt, 0.3 / dif) then
			espiral(s, j, ex, centro, 0.55, 22 * dif)
		end
	elseif j.ataque <= 0 and not (j.mirada and j.mirada.t >= 0) then
		if f == 3 then
			-- ráfaga de tres balas apuntadas
			j.rafaga = (j.rafaga or 0) + 1
			j.ataque = (j.rafaga % 3 == 0 and 0.9 or 0.12) / dif
		else
			j.ataque = (f == 1 and 0.8 or 1.0) / dif
		end
		local vx, vy = apuntar(s, ex, centro, 34 * dif)
		disparo_enemigo(s, ex, centro, vx, vy)
	end
	if f ~= 2 and toca(j, "invocar", dt, 4 / dif) then
		crear_enemigo(s, "dardo", j.x - 4, j.y + 5)
	end
end

-- la serpiente (el tren de luces de Lubbock): solo la cabeza recibe daño, el cuerpo frena las balas.
-- Fase 1: cascada: cada vagón dispara recto por turno y dibuja la curva del tren.
-- Fase 2: se mueve más rápido; cascada y abanico de tres desde la cabeza.
-- Fase 3: todas las luces se encienden (aviso) y cada vagón suelta una bala que se frena y apunta.
local function serpiente(s, j, dt)
	local dif = dificultad(s)
	local f = j.fase_n
	j.avisos = {}
	j.giro = (j.giro or 0) + dt * ({ 1.2, 1.5, 1.4 })[f] * dif
	j.x = 54 + math.sin(j.giro * 1.3) * 18
	j.y = math.max(TECHO + 1, math.min(ALTO - j.h - 1, 25 + math.sin(j.giro * 2.2) * 14))
	-- el rastro se guarda 30 veces por segundo, sin importar los cuadros por segundo
	j.reloj_rastro = (j.reloj_rastro or 0) + dt
	if #j.rastro == 0 or j.reloj_rastro >= 1 / 30 then
		j.reloj_rastro = 0
		table.insert(j.rastro, 1, { j.x, j.y })
		if #j.rastro > 60 then
			j.rastro[#j.rastro] = nil
		end
	end
	j.bloques = {}
	for k = 1, 6 do
		local p = j.rastro[math.min(#j.rastro, k * 6)]
		local ola = (math.floor(j.t * 5) + k) % 2 == 0
		j.bloques[k] = { x = p[1] + 4, y = p[2] + 1, w = 5, h = 5, dibujo = ola and "serpiente_cuerpo" or "serpiente_cuerpo_b" }
	end
	if f < 3 and toca(j, "cascada", dt, (f == 1 and 0.55 or 0.45) / dif) then
		j.paso = (j.paso or 0) + 1
		local q = j.bloques[j.paso % 6 + 1]
		disparo_enemigo(s, q.x, q.y + 2, -26 * dif, 0)
	end
	-- la punta de la cabeza se abre un momento cuando dispara
	j.boca = math.max(0, (j.boca or 0) - dt)
	j.dibujo = j.boca > 0 and "serpiente_boca" or "serpiente_cabeza"
	if f == 2 and toca(j, "ataque", dt, 1.4 / dif) then
		abanico(s, j.x, j.y + 3, { -0.35, 0, 0.35 }, 28 * dif)
		j.boca = 0.25
	end
	if f == 3 then
		j.luces = (j.luces or 1.5) - dt
		if j.luces < 0.5 then
			for _, q in ipairs(j.bloques) do
				j.avisos[#j.avisos + 1] = { x = q.x + 1, y = q.y + 1, w = 3, h = 3 }
			end
		end
		if j.luces <= 0 then
			j.luces = 3.0 / dif
			for _, q in ipairs(j.bloques) do
				bala_frenada(s, q.x + 1, q.y + 2, -16, 0, 0.5, 30 * dif)
			end
		end
		if toca(j, "ataque", dt, 1.1 / dif) then
			local vx, vy = apuntar(s, j.x, j.y + 3, 32 * dif)
			disparo_enemigo(s, j.x, j.y + 3, vx, vy)
			j.boca = 0.25
		end
	end
end

-- el núcleo (la insignia de Socorro) gira escudos a su alrededor que frenan las balas.
-- Fase 1: espiral de un brazo y abanico de tres.
-- Fase 2: dos espirales que giran al revés: una red con rombos por donde pasar.
-- Fase 3: los escudos se abren y giran más rápido; anillo de balas que se frenan y apuntan.
local function nucleo(s, j, dt)
	local dif = dificultad(s)
	local f = j.fase_n
	j.avisos = {}
	j.giro = (j.giro or 0) + dt * (f == 3 and 2.4 or 1.6)
	local radio = f == 3 and 18 or 15
	local cx, cy = j.x + 14, j.y + 11
	j.dibujo = ({ "nucleo", "nucleo_b", "nucleo_c", "nucleo_d" })[math.floor(j.t * 8) % 4 + 1]
	j.bloques = {}
	for k = 0, 3 do
		local a = j.giro + k * math.pi / 2
		j.bloques[#j.bloques + 1] = { x = cx + math.cos(a) * radio, y = cy + math.sin(a) * radio, w = 3, h = 3, dibujo = "escudo" }
	end
	if f == 2 then
		if toca(j, "espiral", dt, 0.24 / dif) then
			espiral(s, j, cx, cy, 0.5, 22 * dif, "angulo")
			espiral(s, j, cx, cy, -0.5, 22 * dif, "angulo_b")
		end
	elseif toca(j, "espiral", dt, (f == 1 and 0.3 or 0.36) / dif) then
		espiral(s, j, cx, cy, 0.7, 24 * dif)
	end
	if f == 1 and toca(j, "invocar", dt, 3 / dif) then
		abanico(s, j.x, cy, { -0.3, 0, 0.3 }, 32 * dif)
	end
	if f == 3 then
		j.anillo = (j.anillo or 2) - dt
		if j.anillo < 0.5 then j.avisos[1] = { x = cx - 1, y = cy - 1, w = 3, h = 3 } end
		if j.anillo <= 0 then
			j.anillo = 3 / dif
			for k = 0, 5 do
				local a = math.pi / 2 + k * math.pi / 5
				bala_frenada(s, cx, cy, math.cos(a + math.pi / 2) * 36, math.sin(a + math.pi / 2) * 36, 0.4, 34 * dif)
			end
		end
	end
end

-- la nodriza (la V de Phoenix) patrulla en lo alto: solo la alcanzan los cohetes y el rayo de la oruga.
-- Fase 1: bombas desde las patas y rodantes por el suelo.
-- Fase 2: cortina de siete bombas con un hueco; antes se marcan en tono medio.
-- Fase 3: bombas que al tocar el suelo revientan en dos balas rasantes (hay que saltarlas).
local HUECOS_NODRIZA = { 2, 5, 3, 1, 4 }
local function nodriza(s, j, dt)
	local dif = dificultad(s)
	local f = j.fase_n
	j.avisos = {}
	j.dibujo = ({ "nodriza", "nodriza_b", "nodriza_c", "nodriza_d" })[math.floor(j.t * 6) % 4 + 1]
	j.rumbo_x = j.rumbo_x or -1
	j.x = j.x + j.rumbo_x * 16 * dif * dt
	if j.x < 4 then
		j.x, j.rumbo_x = 4, 1
	elseif j.x > ANCHO - j.w - 2 then
		j.x, j.rumbo_x = ANCHO - j.w - 2, -1
	end
	local bajo = j.y + j.h
	if f == 1 and toca(j, "ataque", dt, 0.9 / dif) then
		-- desde las góndolas de las puntas
		disparo_enemigo(s, j.x + 2, bajo, -4, 28 * dif)
		disparo_enemigo(s, j.x + j.w - 3, bajo, -4, 28 * dif)
	elseif f == 2 then
		if toca(j, "ataque", dt, 1.5 / dif) then
			disparo_enemigo(s, j.x + j.w / 2, bajo, 0, 28 * dif)
		end
		j.cortina = (j.cortina or 1.5) - dt
		local hueco = HUECOS_NODRIZA[(j.paso or 0) % #HUECOS_NODRIZA + 1]
		local x0 = j.x + j.w / 2 - 19
		for k = 0, 6 do
			local x = x0 + k * 6
			local libre = k == hueco or k == hueco + 1
			if not libre and x > 0 and x < ANCHO - 2 then
				if j.cortina <= 0 then
					disparo_enemigo(s, x, bajo, 0, 24 * dif)
				elseif j.cortina < 0.6 then
					j.avisos[#j.avisos + 1] = { x = x, y = bajo + 1, w = 2, h = 1 }
				end
			end
		end
		if j.cortina <= 0 then
			j.cortina, j.paso = 2.6 / dif, (j.paso or 0) + 1
			sonar(s, "pulso")
		end
	elseif f == 3 and toca(j, "ataque", dt, 1.5 / dif) then
		s.balas_enemigas[#s.balas_enemigas + 1] = { x = j.x + j.w / 2, y = bajo, vx = 0, vy = 26 * dif, estalla = 24 * dif }
	end
	-- sombra en el suelo donde va a caer cada bomba que revienta
	for _, b in ipairs(s.balas_enemigas) do
		if b.estalla then
			j.avisos[#j.avisos + 1] = { x = b.x - 1, y = ALTO - suelo_bajo(s, b.x, 2) - 1, w = 4, h = 1 }
		end
	end
	if f ~= 2 and toca(j, "invocar", dt, 5 / dif) then
		local _, alto = tam("rodante")
		crear_enemigo(s, "rodante", ANCHO + 2, ALTO - alto - suelo_bajo(s, ANCHO - 6, 6))
	end
end

-- el objeto de Shag Harbour: flota disparando, se hunde, se acerca por debajo
-- (una columna de burbujas avisa dónde) y sube de golpe soltando un abanico
local GEISERES = { 20, 44, 32, 12, 52, 28 }
local function shag(s, j, dt)
	local a = agua(s)
	j.avisos = j.avisos or {}
	j.fase = j.fase or "arriba"
	j.reloj = j.reloj or 4
	j.dibujo = ({ "shag", "shag_b", "shag_c" })[math.floor(j.t * 4) % 3 + 1]
	if j.fase == "arriba" then
		j.x = j.x + math.max(-10 * dt, math.min(10 * dt, j.casa_x - j.x))
		j.reloj = j.reloj - dt
		j.ataque = j.ataque - dt
		local f = j.fase_n
		if j.ataque <= 0 then
			j.ataque = (f == 2 and 1.2 or 0.9) / dificultad(s)
			j.rafaga = (j.rafaga or 0) + 1
			if f == 3 then
				-- abanicos alternos de 3 y 2, hacia arriba y adelante
				abanico(s, j.x, j.y + 4, j.rafaga % 2 == 1 and { -0.6, -0.3, 0 } or { -0.45, -0.15 }, 28 * dificultad(s))
			elseif f == 1 and j.rafaga % 3 == 0 then
				for _, vy in ipairs({ -16, -6, 4 }) do
					disparo_enemigo(s, j.x, j.y + 4, -28 * dificultad(s), vy)
				end
			else
				local vx, vy = apuntar(s, j.x, j.y + 4, 30 * dificultad(s))
				disparo_enemigo(s, j.x, j.y + 4, vx, vy)
			end
		end
		-- fase 2: géiseres que salen del agua en lugares fijos; antes el agua burbujea
		if f == 2 then
			j.geiser = (j.geiser or 1.2) - dt
			local x = GEISERES[(j.paso or 0) % #GEISERES + 1]
			if j.geiser < 0.6 then
				j.avisos = { { x = x - 1, y = a - 1, w = 4, h = 1 } }
			end
			if j.geiser <= 0 then
				j.geiser, j.paso, j.avisos = 1.6 / dificultad(s), (j.paso or 0) + 1, {}
				for k = 0, 3 do
					disparo_enemigo(s, x, a - 2, 0, -(30 - k * 6) * dificultad(s))
				end
				salpicar(s, x, a)
			end
		end
		if f ~= 2 and toca(j, "invocar", dt, 4.5 / dificultad(s)) then
			local _, alto = tam("orbe")
			crear_enemigo(s, "orbe", j.x - 8, ALTO - alto - 2)
		end
		if j.reloj <= 0 then
			j.avisos = {}
			j.fase = "hunde"
		end
	elseif j.fase == "hunde" then
		j.y = j.y + 22 * dt
		if j.y >= ALTO - j.h - 1 then
			j.y, j.fase, j.reloj = ALTO - j.h - 1, "abajo", 2.4
			j.objetivo_x = math.max(10, math.min(ANCHO - j.w - 1, s.nave.x - 6))
		end
	elseif j.fase == "abajo" then
		j.x = j.x + math.max(-20 * dt, math.min(20 * dt, j.objetivo_x - j.x))
		j.reloj = j.reloj - dt
		if j.reloj <= 0 then
			j.fase = "sube"
			sonar(s, "embestida")
		end
	else
		j.y = j.y - 45 * dt
		if j.y <= a - 6 then
			j.y, j.fase, j.reloj = a - 6, "arriba", j.fase_n == 3 and 4 or 5.5
			local abanico_sube = j.fase_n == 3 and { -30, -20, -10, 0, 10, 20, 30 } or { -24, -12, 0, 12, 24 }
			for _, vx in ipairs(abanico_sube) do
				disparo_enemigo(s, j.x + j.w / 2, j.y, vx * dificultad(s), -26 * dificultad(s))
			end
			if j.fase_n == 3 then
				bala_frenada(s, j.x, j.y, -30, -20, 0.5, 32 * dificultad(s))
				bala_frenada(s, j.x + j.w, j.y, 30, -20, 0.5, 32 * dificultad(s))
			end
		end
	end
	j.sumergido = j.y >= a + 1
	j.burbujas = j.fase == "abajo"
	local fuera = j.y + 3 < a
	if j.fuera ~= nil and j.fuera ~= fuera then
		salpicar(s, j.x + 4, a)
		salpicar(s, j.x + j.w - 4, a)
	end
	j.fuera = fuera
end

-- ¿el ángulo cae dentro del hueco del anillo? El hueco mide unos 20 píxeles
-- de arco sin importar el tamaño del anillo, para que la nave siempre quepa con holgura
function L.en_hueco(an, ang)
	local medio = math.min(1.3, 10 / math.max(an.r, 1))
	local function dentro(centro) return math.abs((ang - centro + math.pi) % (math.pi * 2) - math.pi) < medio end
	if dentro(an.hueco) then return true end
	-- cortes que le abrió el obús lleno
	for _, c in ipairs(an.cortes or {}) do
		if dentro(c) then return true end
	end
	return false
end

local CORRIMIENTOS = { 0, 0.35, -0.35, 0.2, -0.45, 0.45 }
-- la pirámide del Triángulo: descansa en el fondo y lanza anillos de luz con un hueco
-- por donde pasar; cuando abre la punta dispara y solo entonces recibe daño
local function piramide(s, j, dt)
	j.fase = j.fase or "cerrada"
	j.reloj = j.reloj or 3
	j.anillos = j.anillos or {}
	-- la punta es el blanco; el resto del cuerpo frena las balas
	j.blanco = { 6, 0, 9, 5 }
	j.bloques = { { x = j.x, y = j.y + 4, w = j.w, h = j.h - 4 } }
	-- se desliza despacio por el fondo
	j.rumbo_x = j.rumbo_x or -1
	j.x = j.x + j.rumbo_x * 5 * dificultad(s) * dt
	if j.x < 38 then
		j.x, j.rumbo_x = 38, 1
	elseif j.x > j.casa_x then
		j.x, j.rumbo_x = j.casa_x, -1
	end
	local cx, cy = j.x + 10.5, j.y + 1
	j.reloj = j.reloj - dt
	j.ataque = j.ataque - dt
	if j.fase == "cerrada" then
		j.cerrado, j.dibujo = true, "piramide"
		if j.ataque <= 0 then
			j.ataque = ({ 2.2, 1.8, 2.4 })[j.fase_n] / dificultad(s)
			-- el hueco se abre cerca de la nave, corrido siempre en el mismo orden:
			-- hay que moverse para colarse, pero siempre se puede
			j.paso = (j.paso or 0) + 1
			local hacia = math.atan2(s.nave.y + 2.5 - cy, s.nave.x + 3.5 - cx)
			local corrido = CORRIMIENTOS[j.paso % #CORRIMIENTOS + 1]
			j.anillos[#j.anillos + 1] = { x = cx, y = cy, r = 2, hueco = hacia + corrido }
			-- fase 3: un segundo anillo pegado con el hueco del otro lado (zigzag)
			if j.fase_n == 3 then
				j.anillos[#j.anillos + 1] = { x = cx, y = cy, r = -20, hueco = hacia + corrido + (corrido >= 0 and -0.2 or 0.2) }
			end
			sonar(s, "pulso")
		end
		if toca(j, "invocar", dt, 7 / dificultad(s)) then
			j.cilindros = (j.cilindros or 0) + 1
			crear_enemigo(s, "cilindro", ANCHO + 2, TECHO + 4 + (j.cilindros * 5) % 14)
		end
		if j.reloj <= 0 then
			j.fase, j.reloj, j.ataque = "abierta", 3.8, 0.4
			sonar(s, "embestida")
			-- fase 2: al abrirse suelta tres balas que se frenan y apuntan
			if j.fase_n == 2 then
				for _, a in ipairs({ -2.4, -1.57, -0.7 }) do
					bala_frenada(s, cx, cy, math.cos(a) * 30, math.sin(a) * 30, 0.4, 30 * dificultad(s))
				end
			end
		end
	else
		j.cerrado, j.dibujo = false, "piramide_abierta"
		if j.ataque <= 0 then
			j.ataque = 0.55 / dificultad(s)
			local vx, vy = apuntar(s, cx, cy, 30 * dificultad(s))
			disparo_enemigo(s, cx, cy, vx, vy)
		end
		if j.reloj <= 0 then
			j.fase, j.reloj, j.ataque = "cerrada", 2.0, 0.3
		end
	end
	-- los anillos crecen; tocan la nave si pasa por el borde fuera del hueco
	local n = s.nave
	local nx, ny = n.x + 3.5, n.y + 2.5
	for _, an in ipairs(j.anillos) do
		an.r = an.r + 15 * dt
		-- el obús lleno que cruza el borde le abre un hueco ahí mismo
		for _, o in ipairs(s.balas) do
			if o.lleno and an.r > 1 then
				local ox, oy = o.x + 2.5 - an.x, o.y + 2.5 - an.y
				local ang = math.atan2(oy, ox)
				if math.abs(math.sqrt(ox * ox + oy * oy) - an.r) < 3 and not L.en_hueco(an, ang) then
					an.cortes = an.cortes or {}
					an.cortes[#an.cortes + 1] = ang
					sonar(s, "rebote")
					for _, v in ipairs({ { 20, -15 }, { 20, 15 }, { 30, 0 } }) do
						s.gotas[#s.gotas + 1] = { x = o.x + 2, y = o.y + 2, vx = v[1], vy = v[2], t = 0.35 }
					end
				end
			end
		end
		local dx, dy = nx - an.x, ny - an.y
		local d = math.sqrt(dx * dx + dy * dy)
		if not n.oculta and an.r > 1 and dy < an.r * 0.3 and math.abs(d - an.r) < 2 and not L.en_hueco(an, math.atan2(dy, dx)) then
			j.toca_anillo = true
		end
	end
	local quedan = {}
	for _, an in ipairs(j.anillos) do
		if an.r < 70 then quedan[#quedan + 1] = an end
	end
	j.anillos = quedan
end

-- bloque de hielo lanzado en arco para caer donde está la nave
local function lanzar_bloque(s, x, y, adelante)
	local T, g = 1.2, 70
	local tx, ty = s.nave.x + 3 + (adelante or 0), s.nave.y + 3
	local vx = (tx - x) / T
	local vy = (ty - y - 0.5 * g * T * T) / T
	s.balas_enemigas[#s.balas_enemigas + 1] = { x = x, y = y, vx = vx, vy = vy, g = g, forma = "bloque_hielo" }
end

-- el gigante plateado del Baikal: asoma por un agujero y lanza bloques de hielo;
-- abre el visor para disparar (solo entonces recibe daño); se hunde y revienta
-- el hielo en otro lado, con una grieta que avisa dónde
local function gigante(s, j, dt)
	local a = agua(s)
	j.fase = j.fase or "sube"
	j.reloj = (j.reloj or 0) - dt
	j.ataque = j.ataque - dt
	if j.fase == "sube" then
		j.cerrado, j.dibujo = true, "gigante"
		j.agujero = { x = j.x - 1, w = j.w + 2 }
		j.y = j.y - 40 * dt
		if j.y <= a - 8 then
			j.y, j.fase, j.reloj, j.ataque = a - 8, "asoma", 3.2, 0.6
			salpicar(s, j.x + 3, a)
			salpicar(s, j.x + j.w - 3, a)
			-- fase 3: al salir lanza esquirlas de hielo en abanico que caen
			if j.fase_n == 3 then
				for _, vx in ipairs({ -30, -18, -6 }) do
					s.balas_enemigas[#s.balas_enemigas + 1] = { x = j.x + j.w / 2, y = j.y, vx = vx * dificultad(s), vy = -44, g = 70 }
				end
			end
		end
	elseif j.fase == "asoma" then
		j.cerrado, j.dibujo = true, "gigante"
		if j.ataque <= 0 then
			j.ataque = (j.fase_n == 1 and 1.1 or 1.4) / dificultad(s)
			lanzar_bloque(s, j.x + 2, j.y + 1)
			-- desde la fase 2 lanza un segundo bloque un poco más adelante: hay que quedarse o retroceder
			if j.fase_n >= 2 then
				lanzar_bloque(s, j.x + 2, j.y + 1, 14)
			end
		end
		if j.reloj <= 0 then
			j.fase, j.reloj, j.ataque = "visor", 2.6, 0.5
			j.cerrado, j.dibujo = false, "gigante_visor"
			sonar(s, "embestida")
		end
	elseif j.fase == "visor" then
		-- rayo recto: bajo hay que saltarlo; desde la fase 2 se alterna con uno alto
		-- (quedarse en el piso). Una línea en tono medio avisa la altura
		j.cerrado, j.dibujo = false, "gigante_visor"
		j.rayos = j.rayos or 0
		local alto = j.fase_n >= 2 and j.rayos % 2 == 1
		local y = alto and j.y - 8 or j.y + 4
		j.avisos = {}
		if j.ataque < 0.4 then
			j.avisos[1] = { x = 0, y = y + 0.5, w = j.x, h = 1 }
		end
		if j.ataque <= 0 then
			j.ataque = 0.9 / dificultad(s)
			j.rayos = j.rayos + 1
			for k = 0, 2 do
				disparo_enemigo(s, j.x + 3 + k * 4, y, -48 * dificultad(s), 0)
			end
		end
		if j.reloj <= 0 then
			j.fase, j.cerrado, j.dibujo = "hunde", true, "gigante"
			j.avisos = {}
		end
	elseif j.fase == "hunde" then
		j.y = j.y + 26 * dt
		if j.y >= a + 2 then
			j.y, j.fase, j.reloj = a + 2, "nada", 1.5
			j.agujero = nil
			-- revienta donde está la nave, pero nunca tan atrás que no se le pueda disparar
			j.objetivo_x = math.max(30, math.min(ANCHO - j.w - 1, s.nave.x - 3))
			j.grieta = { x = j.objetivo_x, w = j.w }
		end
	else
		j.x = j.x + math.max(-40 * dt, math.min(40 * dt, j.objetivo_x - j.x))
		if j.reloj <= 0 then
			j.fase, j.grieta = "sube", nil
			j.x = j.objetivo_x
			sonar(s, "embestida")
		end
	end
	j.blanco = { 5, 3, 7, 3 }
	j.sumergido = j.y >= a + 1
end

-- cargas de profundidad: bajan desde la superficie hasta "meta" y revientan en un anillo de
-- balas con un destello que alumbra lo que haya cerca
local function soltar_carga(s, x, meta)
	local a = agua(s)
	s.cargas[#s.cargas + 1] = { x = x, y = a - 1, meta = math.max(a + 3, math.min(ALTO - 3, meta)) }
end

-- el submarino fantasma de Golfo Nuevo: recorre puntos fijos bajo el agua y solo se le puede
-- pegar mientras lo alumbran. Fase 1: al alumbrarlo sube a cota de periscopio. Fase 2: aparece
-- un segundo submarino que se queda hondo. Fase 3: reflectores apagados; solo lo revelan los
-- destellos de las cargas que la Armada tira cerca de él, siempre hondo
L.FANTASMA_EXPUESTO, L.FANTASMA_ESCAPE = 2.2, 2.2
local RECORRIDO_FANTASMA = { 58, 34, 50, 22, 44, 60, 28 }
local CARGAS_FASE2 = { 30, 54, 18, 64, 42 }
local function fantasma(s, j, dt)
	local a = agua(s)
	local f, dif = j.fase_n or 1, dificultad(s)
	local hondo, cota = ALTO - j.h - 2, a + 1
	-- recorrido fijo, con una pausa en cada punto
	j.paso = j.paso or 1
	local meta = RECORRIDO_FANTASMA[(j.paso - 1) % #RECORRIDO_FANTASMA + 1]
	local dx = meta - j.x
	if math.abs(dx) > 0.5 then
		j.x = j.x + math.max(-9 * dt, math.min(9 * dt, dx))
		j.espera = 1.2
	else
		j.espera = (j.espera or 1.2) - dt
		if j.espera <= 0 then j.paso = j.paso + 1 end
	end
	-- descubierto: alumbrado ahora o hace muy poco (tarda en escapar de la luz). Si lo tienen
	-- alumbrado mucho rato se escabulle hondo y por un momento la luz no lo encuentra
	j.escape = math.max(0, (j.escape or 0) - dt)
	if j.escape <= 0 and L.alumbrado(s, j.x, j.y, j.w, j.h) then
		j.visto = f == 3 and 0.4 or 0.9
	else
		j.visto = math.max(0, (j.visto or 0) - dt)
	end
	if j.visto > 0 then
		j.expuesto = (j.expuesto or 0) + dt
		if j.expuesto > L.FANTASMA_EXPUESTO then
			j.escape, j.visto, j.expuesto = L.FANTASMA_ESCAPE, 0, 0
			sonar(s, "embestida")
		end
	else
		j.expuesto = 0
	end
	local descubierto = j.visto > 0
	local quiere_y = (descubierto and f < 3) and cota or hondo
	j.y = j.y + math.max(-16 * dt, math.min(16 * dt, quiere_y - j.y))
	j.periscopio = j.y <= cota + 1
	j.sumergido = not descubierto
	j.alumbrado = descubierto
	-- desde la cota de periscopio dispara apuntado (en la fase 2, de a tres)
	if j.periscopio then
		if toca(j, "ataque", dt, (f == 1 and 0.85 or 1.15) / dif) then
			local px, py = j.x + 9, a - 3
			local vx, vy = apuntar(s, px, py, 30 * dif)
			disparo_enemigo(s, px, py, vx, vy)
			if f == 2 then
				disparo_enemigo(s, px, py, vx, vy - 10)
				disparo_enemigo(s, px, py, vx, vy + 10)
			else
				disparo_enemigo(s, px, py, vx * 0.8, vy * 0.8)
			end
		end
	-- hondo y a oscuras suelta burbujas que suben: el que vuela bajo tiene que esquivarlas
	elseif toca(j, "burbuja", dt, (f == 3 and 1.2 or 1.7) / dif) then
		disparo_enemigo(s, j.x + 10, j.y - 1, -4, -16 * dif)
		if f == 3 then disparo_enemigo(s, j.x + 4, j.y - 1, -8, -13 * dif) end
	end
	-- fase 2: el segundo submarino, hondo, del lado contrario
	if f == 2 and not j.gemelo then
		crear_enemigo(s, "gemelo", ANCHO + 2, hondo)
		j.gemelo = s.enemigos[#s.enemigos]
	end
	local g = j.gemelo
	if g and not g.retira then
		if f >= 3 then
			g.retira = true
		else
			local gm = j.x + j.w / 2 < ANCHO / 2 and 58 or 6
			g.x = g.x + math.max(-10 * dt, math.min(10 * dt, gm - g.x))
			g.y = hondo
			if toca(j, "burbuja_g", dt, 1.6 / dif) then
				disparo_enemigo(s, g.x + 10, g.y - 1, -4, -16 * dif)
			end
		end
	end
	-- las cargas de la Armada: en la fase 2 en lugares fijos, en la fase 3 sobre el jefe
	if f == 2 and toca(j, "carga", dt, 3.2 / dif) then
		j.carga_n = (j.carga_n or 0) + 1
		soltar_carga(s, CARGAS_FASE2[(j.carga_n - 1) % #CARGAS_FASE2 + 1], hondo + 1)
	elseif f == 3 and toca(j, "carga", dt, 2.6 / dif) then
		j.carga_n = (j.carga_n or 0) + 1
		soltar_carga(s, j.x + ({ 4, 15, 9 })[(j.carga_n - 1) % 3 + 1], hondo + 1)
	end
end

local ATAQUES = { fantasma = fantasma, coloso = coloso, tenaza = tenaza, ojo = ojo, serpiente = serpiente, nucleo = nucleo, nodriza = nodriza, shag = shag, piramide = piramide, gigante = gigante }

local function mover_jefe(s, dt)
	local j = s.jefe
	j.t = j.t + dt
	j.golpe = math.max(0, j.golpe - dt)
	if not j.llego then
		j.x = math.max(j.casa_x, j.x - 12 * dt)
		j.llego = j.x <= j.casa_x
		return
	end
	-- cambio de fase: quieto, blindado y sin disparar un momento
	revisar_fase(s, j)
	j.rebote = math.max(0, (j.rebote or 0) - dt)
	if j.cambio then
		j.cambio = j.cambio - dt
		j.blindado = j.cambio > 0
		-- primero se sacude soltando chispazos; al final el escudo avisa que se va
		j.sacudida = j.cambio > L.CAMBIO_FASE - L.SACUDIDA
		j.escudo_aviso = j.blindado and j.cambio < L.ESCUDO_AVISO
		if j.sacudida and toca(j, "chispazo", dt, 0.15) then
			s.explosiones[#s.explosiones + 1] = { x = j.x + s.azar() * (j.w - 4), y = j.y + s.azar() * (j.h - 4), t = 0 }
		end
		if j.blindado then return end
		j.cambio, j.sacudida, j.escudo_aviso = nil, nil, nil
	end
	-- los jefes con velocidad 0 manejan su altura ellos mismos
	if not j.cargando and JEFES[j.tipo].velocidad > 0 then
		j.y = j.y + j.rumbo * JEFES[j.tipo].velocidad * dificultad(s) * dt
		if j.y < TECHO + 1 then
			j.y, j.rumbo = TECHO + 1, 1
		elseif j.y > ALTO - j.h - 1 then
			j.y, j.rumbo = ALTO - j.h - 1, -1
		end
	end
	ATAQUES[j.tipo](s, j, dt)
end

-- ---------- daño y premios

-- la explosión dura siete cuadros (chispa y humo); la muerte del jefe, un poco más
L.EXPLOSION, L.CUADRO_EXPLOSION = 0.46, 0.066
L.SUPERADO, L.JEFE_ROTO = 3.8, 1.3
local function explotar(s, x, y)
	s.explosiones[#s.explosiones + 1] = { x = x, y = y, t = 0 }
end

-- cápsulas: entre una y otra pasan al menos L.MEJORA_PAUSA segundos; si pasan L.MEJORA_SEGURA
-- sin ninguna, llega una de regalo
L.MEJORA_PAUSA, L.MEJORA_SEGURA = 8, 20
local INSTANTANEAS = { triple = true, rayo = true, vida = true }

-- qué cápsulas pueden salir al azar: en la primera vuelta, las instantáneas y los poderes
-- de los expedientes ya jugados; desde la segunda, todas
function L.mejoras_posibles(s)
	local lista = {}
	for _, nombre in ipairs(D.MEJORAS) do
		local sirve = INSTANTANEAS[nombre] or s.ciclo > 1
		if not sirve then
			for i = 1, math.min(s.nivel, #D.GUION) do
				if D.GUION[i].poder == nombre then sirve = true end
			end
		end
		if sirve then lista[#lista + 1] = nombre end
	end
	return lista
end

local function mejora_al_azar(s)
	local lista, total = L.mejoras_posibles(s), 0
	for _, n in ipairs(lista) do total = total + D.PESOS_MEJORA[n] end
	local r = s.azar() * total
	for _, n in ipairs(lista) do
		r = r - D.PESOS_MEJORA[n]
		if r < 0 then return "mejora_" .. n end
	end
	return "mejora_" .. lista[#lista]
end

local function aparecer_mejora(s, tipo, x, y)
	s.mejoras[#s.mejoras + 1] = { tipo = tipo, x = x, y = y }
	s.reloj_mejora = 0
end

-- cápsula que entra por la derecha a la altura de la nave (en tierra, sobre el suelo)
local function mejora_entrante(s, tipo)
	local y
	if L.forma_nave(s) == "oruga" then
		y = ALTO - suelo_bajo(s, ANCHO - 6, 5) - 6
	else
		y = math.max(TECHO + 2, math.min(ALTO - 7, s.nave.y))
	end
	aparecer_mejora(s, tipo, ANCHO - 2, y)
end

-- un enemigo destruido suelta cápsula según lo que vale: las chispas poco, los grandes más
local function soltar_mejora(s, x, y, e)
	local puntos = D.enemigos[e.tipo].puntos
	if puntos <= 0 or (s.reloj_mejora or 99) < L.MEJORA_PAUSA then return end
	if s.azar() > math.min(0.2, 0.02 + puntos / 400) then return end
	aparecer_mejora(s, mejora_al_azar(s), x, y)
end

local herir_jefe

local function herir_enemigo(s, e, dano)
	-- el gemelo del fantasma: el daño es para el jefe
	if e.tipo == "gemelo" then
		e.golpe = 0.1
		if s.jefe then herir_jefe(s, dano) end
		return
	end
	if D.enemigos[e.tipo].invulnerable then
		sonar(s, "rebote")
		return
	end
	e.vida = e.vida - dano
	e.golpe = 0.1
	if e.vida <= 0 and not e.muerto then
		e.muerto = true
		s.puntos = s.puntos + D.enemigos[e.tipo].puntos
		explotar(s, e.x + e.w / 2 - 2, e.y + e.h / 2 - 2)
		soltar_mejora(s, e.x, e.y, e)
		if e.tipo == "espora" then
			crear_enemigo(s, "esporita", e.x, e.y + 1, -1)
			crear_enemigo(s, "esporita", e.x, e.y + 1, 1)
		end
		sonar(s, "explosion")
	else
		sonar(s, "golpe")
	end
end

-- caja donde el jefe recibe daño (la pirámide solo en la punta)
local function blanco_jefe(j)
	if j.blanco then
		return j.x + j.blanco[1], j.y + j.blanco[2], j.blanco[3], j.blanco[4]
	end
	return j.x, j.y, j.w, j.h
end
L.blanco_jefe = blanco_jefe

herir_jefe = function(s, dano)
	local j = s.jefe
	if not j.llego or j.vida <= 0 then
		return
	end
	if j.cerrado or j.sumergido or j.blindado then
		-- el escudo destella para que se note que el tiro rebotó
		if j.blindado then j.rebote = 0.12 end
		sonar(s, "rebote")
		return
	end
	j.vida = j.vida - dano
	j.golpe = 0.08
	sonar(s, "golpe")
	if j.vida <= 0 then
		s.puntos = s.puntos + 500 * s.nivel * s.ciclo
		-- extra por vencerlo rápido: 10 puntos por cada segundo por debajo de 60
		s.bono_rapido = math.max(0, math.floor(60 - j.t)) * 10 * s.ciclo
		s.puntos = s.puntos + s.bono_rapido
		-- premio para llegar con aire al siguiente expediente: una vida (o puntos si ya hay 5)
		if s.vidas < 5 then
			s.vidas, s.premio = s.vidas + 1, "VIDA +1"
		else
			s.puntos, s.premio = s.puntos + 1000, "+1000"
		end
		-- lo que queda del jefe: tiembla con explosiones encima y al rato revienta (ver nivel_superado)
		s.restos = { dibujo = j.dibujo, x = j.x, y = j.y, w = j.w, h = j.h, cada = 0 }
		s.jefe = nil
		s.balas_enemigas = {}
		s.cargas = {}
		for _, en in ipairs(s.enemigos) do
			if en.tipo == "gemelo" and not en.muerto then
				en.muerto = true
				explotar(s, en.x + 4, en.y)
				explotar(s, en.x + 12, en.y)
			end
		end
		sonar(s, "victoria")
		cambiar(s, "nivel_superado")
	end
end

herir_nave = function(s)
	-- en modo de prueba solo hay daño si se activó en su menú
	if s.prueba and not s.prueba.dano then
		return
	end
	if s.invencible > 0 or s.escudo > 0 or s.estado ~= "jugando" then
		return
	end
	s.vidas = s.vidas - 1
	s.triple = 0
	-- la nave revienta en varias explosiones
	local n = s.nave
	explotar(s, n.x, n.y - 1)
	explotar(s, n.x + 3, n.y + 1)
	explotar(s, n.x - 2, n.y + 2)
	sonar(s, "dano")
	if s.vidas <= 0 then
		cambiar(s, "muriendo")
	else
		-- desaparece un momento y luego vuelve a entrar desde atrás
		n.oculta = 1.0
		n.entrando = nil
		s.invencible = 4
		s.rayo_activo = 0
	end
end

-- poderes de cápsula que se guardan y se usan con Y; triple, rayo y vida actúan al recogerlos
L.GUARDABLES = { mejora_escudo = true, mejora_tiempo = true, mejora_sonda = true, mejora_abduccion = true }

function L.usar_poder(s)
	local p = s.poder
	if not p then return false end
	s.poder = nil
	if p == "mejora_escudo" then
		s.escudo = 6
	elseif p == "mejora_tiempo" then
		s.lento = L.TIEMPO_PERDIDO
	elseif p == "mejora_sonda" then
		local n = s.nave
		s.sonda = { t = L.SONDA, x = n.x + 2, y = n.y - 5, enfriar = 0.3 }
	elseif p == "mejora_abduccion" then
		s.abduccion, s.abducidas = L.ABDUCCION, 0
	end
	return true
end

-- la descarga de la abducción: una bala por cada una tragada (al menos 3), en abanico
L.ABDUCIDAS_MAX = 10
function L.devolver_abducidas(s)
	local n = s.nave
	local cuantas = math.max(3, s.abducidas or 0)
	s.abducidas = 0
	if n.oculta then return end
	local nw = #D.dibujos[L.forma_nave(s)][1]
	for i = 1, cuantas do
		local vy = (i - (cuantas + 1) / 2) * 9
		s.balas[#s.balas + 1] = { x = n.x + nw, y = n.y + 2, vx = 80, vy = vy, dano = 1 }
	end
	sonar(s, "pulso")
end

-- poderes nuevos: cuánto duran (segundos) y cuánto frena el mundo el tiempo perdido
L.TIEMPO_PERDIDO, L.LENTO = 6, 0.2
L.SONDA, L.ABDUCCION = 15, 8
L.SONDA_COHETE = 1

L.NOMBRES_PODER = { mejora_escudo = "ESCUDO", mejora_tiempo = "TIEMPO PERDIDO", mejora_sonda = "SONDA", mejora_abduccion = "ABDUCCION" }

local function recoger(s, m)
	if m.tipo == "mejora_triple" then
		s.triple = 12
	elseif m.tipo == "mejora_rayo" then
		s.rayos = math.min(9, s.rayos + 2)
	elseif m.tipo == "mejora_vida" then
		s.vidas = math.min(5, s.vidas + 1)
	elseif L.GUARDABLES[m.tipo] then
		-- se guarda para usarlo con Y (si ya había uno guardado, lo reemplaza)
		s.poder = m.tipo
	end
	s.puntos = s.puntos + 5
	-- nombre de la mejora un momento en pantalla
	local nombres = { mejora_triple = "TRIPLE", mejora_rayo = L.nave_actual(s).especial == "pulso" and "PULSO" or "RAYO", mejora_vida = "VIDA" }
	s.cartel = { texto = nombres[m.tipo] or L.NOMBRES_PODER[m.tipo], t = 1.2 }
	s.aprendidos = s.aprendidos or {}
	if L.GUARDABLES[m.tipo] and not s.aprendidos[m.tipo] and s.ciclo == 1 then
		s.aprendidos[m.tipo] = true
		s.cartel = { texto = "Y: " .. L.NOMBRES_PODER[m.tipo], t = 2.5 }
	end
	sonar(s, "mejora")
end

-- ---------- Golfo Nuevo: reflectores que barren, cargas que bajan y revientan

local function actualizar_golfo(s, dt)
	local a = agua(s)
	s.luz_t = s.luz_t + dt
	-- contra el fantasma alumbra un solo buque: el de la derecha en la fase 1, el de la
	-- izquierda en la 2; en la 3 se apagan los dos
	local j = s.jefe
	for i, r in ipairs(s.reflectores) do
		r.dx = r.base + r.amplitud * math.sin(s.luz_t * r.rapidez + r.fase)
		if j and j.tipo == "fantasma" and j.llego then
			local f = j.fase_n or 1
			r.encendido = (f == 1 and i == 2) or (f == 2 and i == 1)
		end
	end
	for _, d in ipairs(s.destellos) do d.t = d.t - dt end
	local quedan = {}
	for _, d in ipairs(s.destellos) do if d.t > 0 then quedan[#quedan + 1] = d end end
	s.destellos = quedan
	-- durante la oleada la Armada tira cargas sueltas
	if not s.jefe and s.tiempo_nivel > 6 then
		s.carga_reloj = s.carga_reloj - dt
		if s.carga_reloj <= 0 then
			s.carga_reloj = 5 / dificultad(s)
			soltar_carga(s, 24 + math.floor(s.azar() * 52), a + 6 + s.azar() * (ALTO - a - 10))
		end
	end
	local siguen = {}
	for _, c in ipairs(s.cargas) do
		c.y = c.y + 14 * dt
		if c.y >= c.meta then
			-- revienta: anillo de seis balas, destello que alumbra y daño a lo que esté cerca
			explotar(s, c.x - 2, c.y - 2)
			s.destellos[#s.destellos + 1] = { x = c.x, y = c.y, r = 12, t = 0.7 }
			for k = 0, 5 do
				local ang = k * math.pi / 3 + math.pi / 6
				disparo_enemigo(s, c.x, c.y, math.cos(ang) * 20, math.sin(ang) * 20)
			end
			for _, en in ipairs(s.enemigos) do
				if not en.muerto and en.tipo ~= "gemelo" and (en.x + en.w / 2 - c.x) ^ 2 + (en.y + en.h / 2 - c.y) ^ 2 < 81 then
					herir_enemigo(s, en, 2)
				end
			end
			sonar(s, "explosion")
		else
			siguen[#siguen + 1] = c
		end
	end
	s.cargas = siguen
end

-- ---------- turno de juego

local function filtrar(lista, sigue)
	local n = 0
	for i = 1, #lista do
		local v = lista[i]
		if sigue(v) then
			n = n + 1
			lista[n] = v
		end
	end
	for i = #lista, n + 1, -1 do
		lista[i] = nil
	end
end

-- cañón cargado de la oruga: segundos de carga para el obús más débil y el más fuerte
L.CARGA_MIN, L.CARGA_MAX = 0.6, 1.6

-- a qué apunta un cohete: el jefe si se le puede hacer daño; si no, el enemigo más cercano;
-- si no hay ninguno, el jefe igual
local function blanco_cohete(s, b)
	local j = s.jefe
	if j and j.llego and not j.sumergido and not j.cerrado and not j.blindado then
		local x, y, w, h = blanco_jefe(j)
		return x + w / 2, y + h / 2
	end
	local mejor, tx, ty = 1e9, nil, nil
	for _, en in ipairs(s.enemigos) do
		if not en.muerto and not en.bajo_agua and not D.enemigos[en.tipo].invulnerable and en.x > b.x - 10 then
			local d = (en.x - b.x) ^ 2 + (en.y - b.y) ^ 2
			if d < mejor then mejor, tx, ty = d, en.x + en.w / 2, en.y + en.h / 2 end
		end
	end
	if tx then return tx, ty end
	if j and j.llego and not j.sumergido then
		local x, y, w, h = blanco_jefe(j)
		return x + w / 2, y + h / 2
	end
end

-- el cohete sube un momento y después gira hacia su blanco, pero con un giro limitado:
-- a lo quieto o lento le acierta casi siempre; lo que se mueve rápido lo esquiva
local function guiar_cohete(s, b, dt)
	b.t = (b.t or 0) + dt
	if b.t > 1.8 then
		b.usada = true
		return
	end
	if b.t < 0.12 then return end
	local tx, ty = blanco_cohete(s, b)
	if not tx then return end
	local vel = 62
	local ang = math.atan2(b.vy, b.vx)
	local quiere = math.atan2(ty - (b.y + 1.5), tx - (b.x + 1.5))
	local giro = (quiere - ang + math.pi) % (math.pi * 2) - math.pi
	local max = 5 * dt
	ang = ang + math.max(-max, math.min(max, giro))
	b.vx, b.vy = math.cos(ang) * vel, math.sin(ang) * vel
end

local function jugar(s, dt, e)
	local nave = s.nave
	local tierra = en_tierra(s)
	if s.prueba then
		s.rayos = math.max(s.rayos, 5)
	end
	local nw, nh = tam(L.forma_nave(s))

	-- después de explotar: espera oculta y luego entra sola desde la izquierda
	if nave.oculta then
		nave.oculta = nave.oculta - dt
		if nave.oculta <= 0 then
			nave.oculta, nave.entrando = nil, true
			nave.x, nave.vx = -nw, 0
			if tierra then
				nave.y, nave.vy = ALTO - suelo_bajo(s, 0, nw) - nh, 0
			else
				-- a media altura del hueco libre
				local arriba, abajo = 0, 0
				for cx = 0, 20 do
					arriba, abajo = math.max(arriba, s.arriba[cx]), math.max(abajo, s.abajo[cx])
				end
				nave.y = math.floor((TECHO + arriba + ALTO - abajo - nh) / 2)
			end
		end
	elseif nave.entrando then
		nave.x = nave.x + 30 * dt
		if nave.x >= 16 then
			nave.entrando = nil
		end
	end
	local control = not nave.oculta and not nave.entrando
	if not control then
		e = {}
	end

	-- nave (en el mar, bajo el agua va más lenta y salpica al cruzar la superficie)
	local vel = 36
	local a = agua(s)
	if a then
		local fuera = nave.y + nh / 2 < a
		if not fuera and not hielo(s) then
			vel = 20
		end
		if nave.fuera ~= nil and nave.fuera ~= fuera and control then
			salpicar(s, nave.x + 3, a)
		end
		nave.fuera = fuera
	end
	local sub = submarino(s)
	local patina = hielo(s)
	if sub or patina then
		-- el batiscafo acelera y frena de a poco; en el hielo la oruga resbala todavía más
		local quiere_x = ((e.derecha and 1 or 0) - (e.izquierda and 1 or 0)) * (sub and 32 or 38)
		local suave = math.min(1, (sub and 4 or 1.8) * dt)
		nave.vx = (nave.vx or 0) + (quiere_x - (nave.vx or 0)) * suave
		if sub then
			local quiere_y = ((e.abajo and 1 or 0) - (e.arriba and 1 or 0)) * 32
			nave.vy = (nave.vy or 0) + (quiere_y - (nave.vy or 0)) * suave
		end
		if control then
			nave.x = nave.x + nave.vx * dt
		else
			nave.vx, nave.vy = 0, 0
		end
	else
		if e.izquierda then nave.x = nave.x - vel * dt end
		if e.derecha then nave.x = nave.x + vel * dt end
	end
	if control then
		local x = math.max(0, math.min(ANCHO - nw, nave.x))
		if x ~= nave.x then nave.vx = 0 end
		nave.x = x
	end
	if tierra then
		-- la oruga cae con gravedad y salta con ARRIBA cuando pisa suelo
		local piso = ALTO - suelo_bajo(s, nave.x, nw) - nh
		if patina then
			-- en el hielo cuenta lo que hay bajo el centro de la oruga: así cae en los agujeros
			piso = ALTO - suelo_bajo(s, nave.x + 3, nw - 6) - nh
			local ag = s.jefe and s.jefe.agujero
			if ag and nave.x + 3 < ag.x + ag.w and nave.x + nw - 3 > ag.x then
				piso = ALTO - nh
			end
		end
		if e.arriba_pulsado and nave.en_suelo then
			nave.vy, nave.en_suelo = -62, false
			sonar(s, "salto")
		end
		nave.vy = (nave.vy or 0) + 160 * dt
		nave.y = nave.y + nave.vy * dt
		if nave.y >= piso then
			nave.y, nave.vy, nave.en_suelo = piso, 0, true
		else
			nave.en_suelo = false
		end
		nave.y = math.max(TECHO, nave.y)
		-- cayó al agua: pierde una vida; si no puede perderla (escudo, prueba sin daño) sale de un salto
		local hundida = a and a - nh + 3
		if patina and not nave.oculta and nave.y > hundida then
			salpicar(s, nave.x + nw / 2, a)
			herir_nave(s)
			if not nave.oculta then
				nave.y, nave.vy = hundida, -80
			end
		end
	else
		if sub then
			nave.y = nave.y + nave.vy * dt
		else
			if e.arriba then nave.y = nave.y - vel * dt end
			if e.abajo then nave.y = nave.y + vel * dt end
		end
		local y = math.max(TECHO, math.min(ALTO - nh, nave.y))
		if y ~= nave.y then nave.vy = 0 end
		nave.y = y
	end

	nave.enfriar = nave.enfriar - dt
	nave.cohete = (nave.cohete or 0) - dt
	local modelo = L.nave_actual(s)
	if e.a and nave.enfriar <= 0 and #s.balas < 14 then
		if sub then
			-- torpedos: salen lentos y van tomando velocidad
			local function torpedo(y)
				s.balas[#s.balas + 1] = { x = nave.x + nw - 2, y = y, vx = 30, vy = 0, w = 4, torpedo = true }
			end
			if modelo.arma == "doble" then
				nave.enfriar = 0.3
				torpedo(nave.y + 1)
				torpedo(nave.y + 4)
			else
				nave.enfriar = 0.22
				torpedo(nave.y + 2)
			end
		elseif modelo.arma == "doble" and not tierra then
			-- dos balas paralelas, una por ala
			nave.enfriar = 0.26
			s.balas[#s.balas + 1] = { x = nave.x + nw - 1, y = nave.y, vy = 0 }
			s.balas[#s.balas + 1] = { x = nave.x + nw - 1, y = nave.y + 4, vy = 0 }
		else
			nave.enfriar = 0.2
			s.balas[#s.balas + 1] = { x = nave.x + nw, y = nave.y + 2, vy = 0 }
		end
		if s.triple > 0 then
			s.balas[#s.balas + 1] = { x = nave.x + nw - 2, y = nave.y + 2, vy = -14 }
			s.balas[#s.balas + 1] = { x = nave.x + nw - 2, y = nave.y + 2, vy = 14 }
		end
		sonar(s, "disparo")
	end
	-- en tierra, el mismo botón A lanza también cohetes: suben y luego giran hacia el blanco (a ritmo fijo)
	if tierra and e.a and nave.cohete <= 0 then
		nave.cohete = 0.3
		s.balas[#s.balas + 1] = { x = nave.x + 1, y = nave.y - 3, vx = 10, vy = -60, w = 3, h = 3, dano = 1, cohete = true, t = 0 }
	end
	-- disparo cargado (oruga, nave y batiscafo): mientras se mantiene A se sigue disparando
	-- y se va cargando; al soltarlo sale un obús
	do
		if e.a then
			nave.carga = (nave.carga or 0) + dt
		else
			if (nave.carga or 0) >= L.CARGA_MIN then
				local k = math.min(1, (nave.carga - L.CARGA_MIN) / (L.CARGA_MAX - L.CARGA_MIN))
				if nave.carga >= L.CARGA_MAX then
					-- carga llena: el obús grande repele (frena balas y corta los anillos de la pirámide)
					s.balas[#s.balas + 1] = { x = nave.x + nw, y = nave.y, vx = 75, vy = 0, w = 5, h = 5, dano = 6, obus = true, lleno = true }
				else
					s.balas[#s.balas + 1] = { x = nave.x + nw, y = nave.y + 1, vx = 75, vy = 0, w = 4, h = 3, dano = math.floor(2 + 4 * k + 0.5), obus = true }
				end
				sonar(s, "rayo")
			end
			nave.carga = 0
		end
	end
	if e.b_pulsado and s.rayos > 0 and s.rayo_activo <= 0 and not s.pulso then
		s.rayos = s.rayos - 1
		if modelo.especial == "pulso" then
			-- onda circular que crece desde la nave
			s.pulso = { x = nave.x + nw / 2, y = nave.y + nh / 2, r = 0, golpeados = {} }
			sonar(s, "pulso")
		else
			s.rayo_activo, s.rayo_golpe = 0.45, 0
			-- en tierra sale hacia arriba, o hacia adelante si se mantiene la derecha
			s.rayo_adelante = tierra and e.derecha
			sonar(s, "rayo")
		end
	end

	-- Y: usa el poder de cápsula guardado
	if e.poder_pulsado and s.poder then
		local nombre = L.NOMBRES_PODER[s.poder]
		L.usar_poder(s)
		s.cartel = { texto = nombre, t = 1.2 }
		sonar(s, "mejora")
	end

	s.triple = math.max(0, s.triple - dt)
	-- tiempo perdido: tic tac cada medio segundo mientras dura
	if s.lento > 0 then
		local antes = s.lento
		s.lento = math.max(0, s.lento - dt)
		if s.lento > 0 and math.floor(antes * 2) ~= math.floor(s.lento * 2) then
			sonar(s, math.floor(s.lento * 2) % 2 == 0 and "tic" or "tac")
		end
	end
	-- abducción: al acabarse devuelve lo que se tragó, en abanico hacia adelante
	local abduciendo = s.abduccion > 0
	s.abduccion = math.max(0, s.abduccion - dt)
	if abduciendo and s.abduccion <= 0 then L.devolver_abducidas(s) end
	-- sonda: sigue a la nave por arriba (por abajo si no hay lugar) y dispara recto;
	-- en tierra suelta cada segundo un cohete chico que busca al blanco, como los de la oruga
	if s.sonda then
		local so = s.sonda
		so.t = so.t - dt
		local mx, my = nave.x + 2, nave.y - 5
		if my < TECHO + 1 then my = nave.y + 7 end
		so.x = so.x + (mx - so.x) * math.min(1, 6 * dt)
		so.y = so.y + (my - so.y) * math.min(1, 6 * dt)
		so.enfriar = so.enfriar - dt
		if so.enfriar <= 0 and not nave.oculta and #s.balas < 16 then
			if tierra then
				so.enfriar = L.SONDA_COHETE
				s.balas[#s.balas + 1] = { x = so.x + 1, y = so.y - 2, vx = 10, vy = -50, w = 3, h = 3, dano = 1, cohete = true, t = 0 }
			else
				so.enfriar = 0.35
				s.balas[#s.balas + 1] = { x = so.x + 3, y = so.y + 1, vy = 0 }
			end
		end
		if so.t <= 0 then s.sonda = nil end
	end
	if s.cartel then
		s.cartel.t = s.cartel.t - dt
		if s.cartel.t <= 0 then s.cartel = nil end
	end
	s.escudo = math.max(0, s.escudo - dt)
	s.invencible = math.max(0, s.invencible - dt)

	-- fondo y terreno
	for _, st in ipairs(s.estrellas) do
		st.x = st.x - st.v * dt
		if st.x < 0 then
			st.x, st.y = ANCHO, TECHO + s.azar() * (ALTO - TECHO)
		end
	end
	s.desplazamiento = s.desplazamiento + 14 * dt
	s.recorrido = s.recorrido + 14 * dt
	while s.desplazamiento >= 1 do
		s.desplazamiento = s.desplazamiento - 1
		nueva_columna(s)
	end

	-- oleadas y jefe
	s.tiempo_nivel = s.tiempo_nivel + dt
	s.reloj_mejora = (s.reloj_mejora or 0) + dt
	local nivel = datos_nivel(s)
	if s.tiempo_nivel < nivel.duracion then
		-- el guion: el poder del expediente a 30 % y 65 %, la vida fija a mitad
		local progreso = s.tiempo_nivel / nivel.duracion
		local g = D.GUION[s.nivel] or {}
		s.guion = s.guion or {}
		for _, paso in ipairs({ { 0.3, g.poder }, { 0.5, g.vida and "vida" }, { 0.65, g.segundo or g.poder } }) do
			if paso[2] and progreso >= paso[1] and not s.guion[paso[1]] then
				s.guion[paso[1]] = true
				mejora_entrante(s, "mejora_" .. paso[2])
			end
		end
		if s.reloj_mejora >= L.MEJORA_SEGURA then
			mejora_entrante(s, mejora_al_azar(s))
		end
		-- carteles que enseñan (solo la primera vuelta)
		if s.ciclo == 1 then
			for i, en in ipairs(D.ENSENANZAS) do
				if en[1] == s.nivel and s.tiempo_nivel >= en[2] and not s.guion["ensena" .. i] then
					s.guion["ensena" .. i] = true
					local texto = en[3] == "B: ESPECIAL" and ("B: " .. (L.nave_actual(s).especial == "pulso" and "PULSO" or "RAYO")) or en[3]
					s.cartel = { texto = texto, t = 2.5 }
				end
			end
		end
		s.oleada = s.oleada - dt
		if s.oleada <= 0 then
			-- el nivel empieza tranquilo y se va llenando hasta el jefe
			local progreso = s.tiempo_nivel / nivel.duracion
			L.lanzar_oleada(s, progreso)
			s.oleada = (1.9 + s.azar() * 0.9) * L.ritmo_oleadas(progreso) / dificultad(s)
		end
	elseif not s.jefe and #s.enemigos == 0 and not s.aviso_dado then
		s.aviso_dado = true
		-- antes del jefe llega una mejora segura delante de la nave: triple en vuelo;
		-- en tierra y bajo el agua (donde el triple no sirve) dos rayos más
		local tipo = (tierra or sub) and "mejora_rayo" or "mejora_triple"
		mejora_entrante(s, tipo)
		cambiar(s, "aviso_jefe")
		return
	end

	-- movimiento
	for _, b in ipairs(s.balas) do
		if b.torpedo then
			b.vx = math.min(100, b.vx + 170 * dt)
		end
		if b.cohete then
			guiar_cohete(s, b, dt)
		end
		b.x = b.x + (b.vx or 70) * dt
		b.y = b.y + b.vy * dt
	end
	-- tiempo perdido: balas, enemigos y jefe van en cámara lenta; la nave no
	local dtm = s.lento > 0 and dt * L.LENTO or dt
	local revientan = {}
	for _, b in ipairs(s.balas_enemigas) do
		local dt = dtm
		if b.frena then
			-- se va frenando hasta quedar quieta
			b.frena = b.frena - dt
			local k = math.max(0, b.frena / 0.45)
			b.vx, b.vy = b.vx0 * k, b.vy0 * k
			if b.frena <= 0 then b.frena = nil end
		elseif b.espera then
			b.espera = b.espera - dt
			if b.espera <= 0 then
				b.espera = nil
				b.vx, b.vy = apuntar(s, b.x, b.y, b.rapidez)
			end
		elseif b.quieta then
			-- estrella del mapa: queda quieta y al final revienta en cuatro en diagonal
			b.vx, b.vy = 0, 0
			b.quieta = b.quieta - dt
			if b.quieta <= 0 then
				b.usada = true
				for _, d in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
					revientan[#revientan + 1] = { x = b.x, y = b.y, vx = d[1] * b.revienta, vy = d[2] * b.revienta }
				end
			end
		end
		b.vy = b.vy + (b.g or 0) * dt
		b.x = b.x + b.vx * dt
		b.y = b.y + b.vy * dt
		-- bomba que revienta en el suelo en dos balas rasantes
		if b.estalla and not b.usada and b.y + 2 >= ALTO - suelo_bajo(s, b.x, 2) then
			b.usada = true
			local y = ALTO - suelo_bajo(s, b.x, 2) - 3
			disparo_enemigo(s, b.x, y, -b.estalla, 0)
			disparo_enemigo(s, b.x, y, b.estalla, 0)
			explotar(s, b.x - 2, y - 1)
		end
	end
	for _, b in ipairs(revientan) do s.balas_enemigas[#s.balas_enemigas + 1] = b end
	for _, en in ipairs(s.enemigos) do
		mover_enemigo(s, en, dtm)
	end
	if s.jefe then
		mover_jefe(s, dtm)
	end
	if datos_nivel(s).reflectores then
		actualizar_golfo(s, dtm)
	end
	for _, m in ipairs(s.mejoras) do
		m.x = m.x - 10 * dt
		if tierra then
			-- en tierra las mejoras caen al suelo para que la oruga las alcance
			m.y = m.y + 18 * dt
		end
		respetar_terreno(s, m, 7, 7)
	end
	local helado = hielo(s)
	for _, b in ipairs(s.balas_enemigas) do
		if choca_terreno(s, b.x, b.y, 2, 2) then
			b.usada = true
			-- en el lago, lo que cae con fuerza raja el hielo
			if helado and b.vy > 10 and #s.grietas < 4 then
				rajar(s, b.x + 1, 7)
			end
		end
	end
	if helado then
		for _, g in ipairs(s.grietas) do
			g.x = g.x - 14 * dt
			g.t = g.t + dt
			if g.t >= 1.2 then
				g.abierta = true
				abrir_agujero(s, g.x, g.ancho)
				salpicar(s, g.x, agua(s))
			end
		end
		filtrar(s.grietas, function(g) return not g.abierta and g.x > -8 end)
	end
	for _, x in ipairs(s.explosiones) do
		x.t = x.t + dt
	end
	for _, g in ipairs(s.gotas) do
		g.t = g.t + dt
		g.vy = g.vy + 90 * dt
		g.x = g.x + (g.vx - 14) * dt
		g.y = g.y + g.vy * dt
	end

	-- balas de la nave
	for _, b in ipairs(s.balas) do
		local bw, bh, dano = b.w or 3, b.h or 1, b.dano or 1
		for _, en in ipairs(s.enemigos) do
			if not b.usada and not en.muerto and not en.bajo_agua and choca(b.x, b.y, bw, bh, en.x, en.y, en.w, en.h) then
				b.usada = true
				herir_enemigo(s, en, dano)
			end
		end
		if not b.usada and s.jefe then
			for _, q in ipairs(s.jefe.bloques) do
				if not b.usada and choca(b.x, b.y, bw, bh, q.x, q.y, q.w, q.h) then
					b.usada = true
					sonar(s, "rebote")
				end
			end
		end
		if not b.usada and s.jefe and choca(b.x, b.y, bw, bh, blanco_jefe(s.jefe)) then
			b.usada = true
			herir_jefe(s, dano)
		end
		if not b.usada and choca_terreno(s, b.x, b.y, bw, bh) then
			b.usada = true
		end
	end

	-- rayo: en el aire una franja hacia adelante; en tierra una columna hacia arriba
	s.rayo_caja = nil
	if s.rayo_activo > 0 then
		s.rayo_activo = s.rayo_activo - dt
		s.rayo_golpe = s.rayo_golpe - dt
		local rx, ry, rw, rh
		if tierra and not s.rayo_adelante then
			rx, ry, rw, rh = nave.x + 1, TECHO, 4, math.max(0, nave.y - TECHO)
		else
			rx, ry, rw, rh = nave.x + nw, nave.y + 1, ANCHO, 3
		end
		s.rayo_caja = { rx, ry, rw, rh }
		if s.rayo_golpe <= 0 then
			s.rayo_golpe = 0.1
			for _, en in ipairs(s.enemigos) do
				if not en.muerto and not en.bajo_agua and choca(rx, ry, rw, rh, en.x, en.y, en.w, en.h) then
					herir_enemigo(s, en, 1)
				end
			end
			if s.jefe and choca(rx, ry, rw, rh, blanco_jefe(s.jefe)) then
				herir_jefe(s, 1)
			end
		end
		for _, b in ipairs(s.balas_enemigas) do
			if choca(rx, ry, rw, rh, b.x, b.y, 2, 2) then
				b.usada = true
			end
		end
	end

	-- pulso del Interceptor: golpea una vez a cada enemigo que alcanza y borra balas
	if s.pulso then
		local pu = s.pulso
		pu.r = pu.r + 80 * dt
		local function dentro(x, y, w, h)
			local cx = math.max(x, math.min(pu.x, x + w))
			local cy = math.max(y, math.min(pu.y, y + h))
			return (cx - pu.x) ^ 2 + (cy - pu.y) ^ 2 <= pu.r ^ 2
		end
		for _, en in ipairs(s.enemigos) do
			if not en.muerto and not en.bajo_agua and not pu.golpeados[en] and dentro(en.x, en.y, en.w, en.h) then
				pu.golpeados[en] = true
				herir_enemigo(s, en, 2)
			end
		end
		if s.jefe and not pu.golpeados.jefe and dentro(blanco_jefe(s.jefe)) then
			pu.golpeados.jefe = true
			herir_jefe(s, 4)
		end
		for _, b in ipairs(s.balas_enemigas) do
			if dentro(b.x, b.y, 2, 2) then
				b.usada = true
			end
		end
		if pu.r > 46 then
			s.pulso = nil
		end
	end

	-- abducción: atrae las mejoras y se traga las balas que entran en su cono (cada una le
	-- cuesta un segundo y se devuelve al final); la sonda para balas
	s.abduccion_caja = nil
	if s.abduccion > 0 and not nave.oculta then
		local ox, oy = nave.x + nw, nave.y + nh / 2
		s.abduccion_caja = { x = ox, y = oy, largo = 14 }
		for _, m in ipairs(s.mejoras) do
			local dx, dy = ox - 3 - (m.x + 3), oy - (m.y + 3)
			local d = math.sqrt(dx * dx + dy * dy)
			if d < 34 and d > 0.5 then
				m.x, m.y = m.x + dx / d * 46 * dt, m.y + dy / d * 46 * dt
			end
		end
		for _, b in ipairs(s.balas_enemigas) do
			local dx, dy = b.x + 1 - ox, b.y + 1 - oy
			if not b.usada and dx >= 0 and dx <= 14 and math.abs(dy) <= 1 + dx * 0.45 then
				b.usada = true
				s.abducidas = math.min(L.ABDUCIDAS_MAX, (s.abducidas or 0) + 1)
				s.abduccion = math.max(0, s.abduccion - 1)
				if s.abduccion <= 0 then L.devolver_abducidas(s) end
				s.gotas[#s.gotas + 1] = { x = b.x, y = b.y, vx = -20, vy = -10, t = 0.4 }
			end
		end
	end
	-- el obús lleno se lleva por delante las balas enemigas que toca
	for _, o in ipairs(s.balas) do
		if o.lleno and not o.usada then
			for _, b in ipairs(s.balas_enemigas) do
				if not b.usada and choca(b.x, b.y, 2, 2, o.x - 1, o.y - 1, o.w + 2, o.h + 2) then
					b.usada = true
					s.gotas[#s.gotas + 1] = { x = b.x, y = b.y, vx = 25, vy = (b.y < o.y + 2 and -20 or 20), t = 0.3 }
				end
			end
		end
	end
	if s.sonda then
		for _, b in ipairs(s.balas_enemigas) do
			if not b.usada and choca(b.x, b.y, 2, 2, s.sonda.x, s.sonda.y, 3, 3) then
				b.usada = true
				s.sonda.t = s.sonda.t - 5
				explotar(s, s.sonda.x - 1, s.sonda.y - 1)
			end
		end
	end

	-- golpes contra la nave (no cuenta mientras está oculta tras explotar)
	if not nave.oculta then
		for _, b in ipairs(s.balas_enemigas) do
			if not b.usada and choca(b.x, b.y, 2, 2, nave.x + 1, nave.y + 1, nw - 2, nh - 2) then
				b.usada = true
				herir_nave(s)
			end
		end
		for _, en in ipairs(s.enemigos) do
			if not en.muerto and not en.bajo_agua and choca(en.x, en.y, en.w, en.h, nave.x + 1, nave.y + 1, nw - 2, nh - 2) then
				herir_enemigo(s, en, 3)
				herir_nave(s)
			end
		end
		if s.jefe and s.jefe.toca_anillo then
			s.jefe.toca_anillo = nil
			herir_nave(s)
		end
		if s.jefe and not s.jefe.sumergido and choca(s.jefe.x, s.jefe.y, s.jefe.w, s.jefe.h, nave.x + 1, nave.y + 1, nw - 2, nh - 2) then
			herir_nave(s)
		end
		if s.jefe then
			for _, q in ipairs(s.jefe.bloques) do
				if choca(q.x, q.y, q.w, q.h, nave.x + 1, nave.y + 1, nw - 2, nh - 2) then
					herir_nave(s)
				end
			end
		end
		for _, c in ipairs(s.cargas or {}) do
			if choca(c.x - 1, c.y - 2, 3, 4, nave.x + 1, nave.y + 1, nw - 2, nh - 2) then
				herir_nave(s)
			end
		end
		if not tierra and choca_terreno(s, nave.x + 1, nave.y + 1, nw - 2, nh - 2) then
			herir_nave(s)
		end
		for _, m in ipairs(s.mejoras) do
			if not m.usada and choca(m.x, m.y, 7, 7, nave.x, nave.y, nw, nh) then
				m.usada = true
				recoger(s, m)
			end
		end
	end

	-- limpieza
	filtrar(s.balas, function(b) return not b.usada and b.x < ANCHO and b.y > TECHO - 2 and b.y < ALTO end)
	filtrar(s.balas_enemigas, function(b)
		return not b.usada and b.x > -3 and b.x < ANCHO + 3 and b.y > TECHO - 3 and b.y < ALTO + 1
	end)
	filtrar(s.enemigos, function(en) return not en.muerto and en.x > -12 end)
	filtrar(s.mejoras, function(m) return not m.usada and m.x > -6 end)
	filtrar(s.explosiones, function(x) return x.t < L.EXPLOSION end)
	filtrar(s.gotas, function(g) return g.t < 0.8 and not (g.vy > 0 and a and g.y >= a) end)

	if s.puntos > s.record and not s.prueba then
		s.record = s.puntos
		s.record_nuevo = true
	end
end

-- ---------- máquina de estados

-- fin de la partida: pide iniciales si entra en la tabla, si no va al cierre
local function terminar_partida(s)
	s.puntos = math.max(s.puntos, s.mejor_tramo or 0)
	if L.entra_en_tabla(s, s.puntos) then
		s.letras, s.letra = { 1, 1, 1 }, 1
		cambiar(s, "iniciales")
		sonar(s, "victoria")
	else
		cambiar(s, "fin")
		sonar(s, s.victoria and "victoria" or "fin")
	end
end

-- ---------- menú de la portada: JUGAR, NAVE, RECORDS y OPCIONES
-- Las opciones (sonido, color, idioma) viven en main.lua: aquí solo se pide el cambio
-- en s.ajuste = { que = "sonido" | "color" | "idioma", paso = 1 | -1 }.
L.MENU = { "jugar", "nave", "records", "opciones" }
L.OPCIONES = { "sonido", "color", "idioma", "volver" }

function L.abrir_menu(s)
	s.menu = { hoja = "principal", fila = 1, pagina = 1 }
	cambiar(s, "menu")
	sonar(s, "menu")
end

function L.paginas_records()
	return math.ceil(L.PUESTOS / 5)
end

function L.actualizar_menu(s, e)
	local m = s.menu
	local function mover(cuantas)
		if e.arriba_pulsado or e.abajo_pulsado then
			m.fila = (m.fila - 1 + (e.abajo_pulsado and 1 or -1)) % cuantas + 1
			sonar(s, "menu")
		end
	end
	local paso = e.derecha_pulsado and 1 or e.izquierda_pulsado and -1
	local function cambiar_nave(p)
		s.nave_elegida = ((s.nave_elegida or 1) - 1 + p) % #L.NAVES + 1
		sonar(s, "menu")
	end
	local function al_principal()
		m.hoja, m.fila = "principal", m.vuelve or 1
		sonar(s, "menu")
	end
	if m.hoja == "principal" then
		if e.b_pulsado or e.select_pulsado then
			cambiar(s, "titulo")
			sonar(s, "menu")
			return
		end
		-- START juega directo desde cualquier fila
		if e.start_pulsado then return L.empezar_partida(s) end
		mover(#L.MENU)
		local fila = L.MENU[m.fila]
		if fila == "nave" and paso then cambiar_nave(paso) end
		if e.a_pulsado then
			m.vuelve = m.fila
			if fila == "jugar" then
				return L.empezar_partida(s)
			elseif fila == "nave" then
				m.hoja = "nave"
			elseif fila == "records" then
				m.hoja, m.pagina = "records", 1
			else
				m.hoja, m.fila = "opciones", 1
			end
			sonar(s, "menu")
		end
	elseif m.hoja == "nave" then
		if paso then cambiar_nave(paso) end
		if e.a_pulsado or e.start_pulsado or e.b_pulsado or e.select_pulsado then al_principal() end
	elseif m.hoja == "records" then
		local p = paso or (e.abajo_pulsado and 1) or (e.arriba_pulsado and -1)
		if p then
			m.pagina = (m.pagina - 1 + p) % L.paginas_records() + 1
			sonar(s, "menu")
		end
		if e.a_pulsado or e.start_pulsado or e.b_pulsado or e.select_pulsado then al_principal() end
	else
		if e.b_pulsado or e.select_pulsado or e.start_pulsado then return al_principal() end
		mover(#L.OPCIONES)
		local fila = L.OPCIONES[m.fila]
		if fila == "volver" then
			if e.a_pulsado then al_principal() end
		elseif paso or e.a_pulsado then
			s.ajuste = { que = fila, paso = paso or 1 }
			sonar(s, "menu")
		end
	end
end

-- filas del menú de prueba, en orden
L.FILAS_PRUEBA = { "nivel", "nave", "vuelta", "dano", "choques", "lento" }
L.VUELTAS_PRUEBA = 5
-- cuántas veces más lento corre el juego: normal, a la mitad, a un cuarto
L.LENTOS = { 1, 2, 4 }

-- pausa pedida desde afuera (por ejemplo, YouTube al salir de la pestaña)
function L.pausar(s)
	if s.estado == "jugando" then
		cambiar(s, "pausa")
		s.opcion_pausa = 1
	end
end

function L.actualizar(s, dt, e)
	-- cámara lenta del modo de prueba (en la portada el menú va a velocidad normal)
	if s.prueba and s.estado ~= "titulo" then
		dt = dt / L.LENTOS[s.prueba.lento or 1]
	end
	s.t = s.t + dt
	if s.estado == "titulo" then
		-- B tres veces seguidas activa el modo de prueba; dentro de él, una B lo quita
		if e.b_pulsado and s.prueba then
			s.prueba, s.toques_b = nil, 0
			sonar(s, "menu")
		elseif e.b_pulsado then
			s.toques_b = (s.t - (s.ultimo_b or -9) < 0.8) and (s.toques_b or 0) + 1 or 1
			s.ultimo_b = s.t
			if s.toques_b >= 3 then
				s.toques_b = 0
				s.prueba = (not s.prueba) and { nivel = 1 } or nil
				sonar(s, s.prueba and "mejora" or "menu")
			end
		end
		-- fuera del modo de prueba, izquierda y derecha eligen la nave
		s.aviso_nave = math.max(0, (s.aviso_nave or 0) - dt)
		if not s.prueba and (e.izquierda_pulsado or e.derecha_pulsado) then
			local paso = e.derecha_pulsado and 1 or -1
			s.nave_elegida = ((s.nave_elegida or 1) - 1 + paso) % #L.NAVES + 1
			s.aviso_nave = 2
			sonar(s, "menu")
		end
		-- en modo de prueba: arriba/abajo eligen la fila e izquierda/derecha su valor
		if s.prueba then
			local p = s.prueba
			p.fila = p.fila or 1
			if e.abajo_pulsado or e.arriba_pulsado then
				p.fila = (p.fila - 1 + (e.abajo_pulsado and 1 or -1)) % #L.FILAS_PRUEBA + 1
				sonar(s, "menu")
			end
			if e.derecha_pulsado or e.izquierda_pulsado then
				local paso = e.derecha_pulsado and 1 or -1
				local fila = L.FILAS_PRUEBA[p.fila]
				if fila == "nivel" then
					p.nivel = (p.nivel - 1 + paso) % #D.niveles + 1
				elseif fila == "nave" then
					s.nave_elegida = ((s.nave_elegida or 1) - 1 + paso) % #L.NAVES + 1
				elseif fila == "vuelta" then
					p.vuelta = ((p.vuelta or 1) - 1 + paso) % L.VUELTAS_PRUEBA + 1
				elseif fila == "lento" then
					p.lento = ((p.lento or 1) - 1 + paso) % #L.LENTOS + 1
				else
					p[fila] = not p[fila]
				end
				sonar(s, "menu")
			end
		end
		if e.start_pulsado or e.a_pulsado then
			-- en modo de prueba se juega directo; si no, se abre el menú
			if s.prueba then L.empezar_partida(s) else L.abrir_menu(s) end
		end
	elseif s.estado == "menu" then
		L.actualizar_menu(s, e)
	elseif s.estado == "inicio_nivel" then
		s.aviso_dado = false
		if en_tierra(s) then
			-- la nave baja a tierra y se transforma en oruga
			local _, alto = tam("oruga")
			s.nave.y = math.min(ALTO - suelo_bajo(s, s.nave.x, 10) - alto, s.nave.y + 14 * dt)
			if s.t >= 1.4 and not s.transformada then
				s.transformada = true
				sonar(s, "mejora")
			end
		end
		if submarino(s) and s.t >= 1.4 and not s.transformada then
			-- la nave se sumerge y se vuelve batiscafo
			s.transformada = true
			sonar(s, "mejora")
		end
		if s.t > 2 then
			cambiar(s, "jugando")
		end
	elseif s.estado == "jugando" then
		if e.start_pulsado then
			cambiar(s, "pausa")
			s.opcion_pausa = 1
			sonar(s, "menu")
			return
		end
		-- en modo de prueba, SELECT salta directo al jefe
		if s.prueba and e.select_pulsado and not s.jefe and not s.aviso_dado then
			s.tiempo_nivel, s.enemigos = datos_nivel(s).duracion, {}
		end
		jugar(s, dt, e)
	elseif s.estado == "pausa" then
		-- SEGUIR o SALIR con el cursor; SELECT sigue saliendo de una
		s.opcion_pausa = s.opcion_pausa or 1
		if e.arriba_pulsado or e.abajo_pulsado then
			s.opcion_pausa = 3 - s.opcion_pausa
			sonar(s, "menu")
		end
		if e.select_pulsado or ((e.a_pulsado or e.start_pulsado) and s.opcion_pausa == 2) then
			cambiar(s, "titulo")
		elseif e.a_pulsado or e.start_pulsado then
			cambiar(s, "jugando")
			sonar(s, "menu")
		end
	elseif s.estado == "aviso_jefe" then
		if s.t > 2 then
			cambiar(s, "jugando")
			crear_jefe(s)
		end
	elseif s.estado == "nivel_superado" then
		for _, x in ipairs(s.explosiones) do
			x.t = x.t + dt
		end
		filtrar(s.explosiones, function(x) return x.t < L.EXPLOSION end)
		local r = s.restos
		if r and not r.roto then
			r.cada = r.cada - dt
			if r.cada <= 0 then
				r.cada = 0.12
				explotar(s, r.x + s.azar() * (r.w - 4), r.y + s.azar() * (r.h - 4))
				sonar(s, "explosion")
			end
			if s.t >= L.JEFE_ROTO then
				r.roto = true
				sonar(s, "explosion")
			end
		end
		if s.t > L.SUPERADO then
			s.restos = nil
			-- el jefe dejó su estrella: se ve el mapa
			s.pieza = s.nivel
			cambiar(s, "mapa")
		end
	elseif s.estado == "prologo" then
		if pasar_pagina(s, e, L.PAGINA) then
			s.pagina = s.pagina + 1
			s.t = 0
			if s.pagina > #D.historia.prologo then
				cambiar(s, "inicio_nivel")
			end
		end
	elseif s.estado == "mapa" then
		if pasar_pagina(s, e, L.PAGINA_MAPA) then
			s.nivel = s.nivel + 1
			if s.nivel > #D.niveles then
				-- cerrada la puerta: el final y luego se pregunta si seguir más difícil
				s.nivel = #D.niveles
				s.pagina = 1
				cambiar(s, "final")
				sonar(s, "victoria")
			else
				empezar_nivel(s)
			end
		end
	elseif s.estado == "final" then
		if pasar_pagina(s, e, L.PAGINA) then
			s.pagina = s.pagina + 1
			s.t = 0
			if s.pagina > #D.historia.final then
				s.opcion_ronda = 1
				cambiar(s, "ronda_completa")
			end
		end
	elseif s.estado == "ronda_completa" then
		if e.arriba_pulsado or e.abajo_pulsado then
			s.opcion_ronda = 3 - s.opcion_ronda
			sonar(s, "menu")
		end
		-- espera un momento para que el disparo mantenido no elija sin querer
		if s.t > 1.5 and (e.a_pulsado or e.start_pulsado) then
			if s.opcion_ronda == 1 then
				s.nivel, s.ciclo = 1, s.ciclo + 1
				empezar_nivel(s)
			else
				s.victoria = true
				terminar_partida(s)
			end
		end
	elseif s.estado == "muriendo" then
		for _, x in ipairs(s.explosiones) do
			x.t = x.t + dt
		end
		if s.t > 1.5 then
			s.cuenta = L.CUENTA_CONTINUAR
			cambiar(s, "continuar")
		end
	elseif s.estado == "continuar" then
		-- cuenta de 9 a 0: A o START siguen, B se rinde
		local antes = math.ceil(s.cuenta) - 1
		s.cuenta = s.cuenta - dt
		if math.ceil(s.cuenta) - 1 ~= antes and s.cuenta > 0 then sonar(s, "menu") end
		if s.t > 0.4 and (e.a_pulsado or e.start_pulsado) then
			L.continuar(s)
		elseif s.cuenta <= 0 or (s.t > 0.4 and e.b_pulsado) then
			terminar_partida(s)
		end
	elseif s.estado == "iniciales" then
		-- arriba/abajo cambian la letra, derecha o A pasan a la siguiente, START guarda
		local total = #L.ABECEDARIO
		local i = s.letra
		if e.arriba_pulsado then s.letras[i] = s.letras[i] % total + 1; sonar(s, "menu") end
		if e.abajo_pulsado then s.letras[i] = (s.letras[i] - 2) % total + 1; sonar(s, "menu") end
		if e.izquierda_pulsado and i > 1 then s.letra = i - 1 end
		if (e.derecha_pulsado or e.a_pulsado) and i < 3 then
			s.letra = i + 1
		elseif e.start_pulsado or (e.a_pulsado and i == 3) then
			local nombre = ""
			for _, n in ipairs(s.letras) do
				nombre = nombre .. L.ABECEDARIO:sub(n, n)
			end
			L.anotar(s, nombre, s.puntos, { nave = s.nave_elegida or 1, nivel = s.nivel, ciclo = s.ciclo })
			cambiar(s, "fin")
		end
	elseif s.estado == "fin" then
		if s.t > 1.5 and (e.start_pulsado or e.a_pulsado) then
			cambiar(s, "titulo")
		end
	end
end

function L.entra_en_tabla(s, puntos)
	if puntos <= 0 or s.prueba then return false end
	return #s.tabla < L.PUESTOS or puntos > s.tabla[#s.tabla].puntos
end

function L.anotar(s, nombre, puntos, extra)
	local fila = { nombre = nombre, puntos = puntos }
	for k, v in pairs(extra or {}) do fila[k] = v end
	table.insert(s.tabla, fila)
	table.sort(s.tabla, function(a, b) return a.puntos > b.puntos end)
	while #s.tabla > L.PUESTOS do
		table.remove(s.tabla)
	end
	s.puesto = nil
	for i, f in ipairs(s.tabla) do
		if f == fila then s.puesto = i end
	end
	s.record = s.tabla[1].puntos
	s.tabla_cambio = true
end

return L

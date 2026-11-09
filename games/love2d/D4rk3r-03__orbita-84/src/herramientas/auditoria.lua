-- Auditoría de balance: un piloto que apunta y esquiva balas juega cada nivel con las dos
-- naves (4 partidas) y mide enemigos y balas en pantalla, golpes recibidos y cuánto dura el jefe.
-- No es un humano: esquiva balas al instante pero no salta bien ni busca los huecos de los anillos.
-- Uso: luajit herramientas/auditoria.lua [nivel ...]
package.path = "juego/?.lua;" .. package.path
local L = require("logica")
local D = require("datos")
local dt = 1 / 60

-- piloto "decente": apunta a lo más cercano, esquiva balas que vienen, dispara siempre
local function piloto(s)
	local n = s.nave
	local e = { a = true, poder = true, poder_pulsado = true }
	local meta
	if s.jefe and s.jefe.llego then
		local bx, by, bw, bh = L.blanco_jefe(s.jefe)
		meta = by + bh / 2 - 2
	else
		local mejor = 1e9
		for _, en in ipairs(s.enemigos) do
			if not en.muerto and not en.bajo_agua and en.x > n.x then
				local d = en.x - n.x
				if d < mejor then mejor, meta = d, en.y + en.h / 2 - 2 end
			end
		end
	end
	-- esquivar: bala que en 0,5 s pasa cerca
	local peligro
	for _, b in ipairs(s.balas_enemigas) do
		for k = 1, 5 do
			local tt = k * 0.1
			local bx, by = b.x + (b.vx or 0) * tt, b.y + (b.vy or 0) * tt
			if math.abs(bx - (n.x + 3)) < 5 and math.abs(by - (n.y + 2)) < 4 then
				peligro = by
				break
			end
		end
		if peligro then break end
	end
	if peligro then
		if peligro > n.y + 2 then e.arriba = true else e.abajo = true end
	elseif meta then
		e.arriba = n.y > meta + 1
		e.abajo = n.y < meta - 1
	end
	e.izquierda = n.x > 20
	e.derecha = n.x < 8
	return e
end

local function medir(nivel, nave, semilla)
	math.randomseed(semilla)
	local s = L.nuevo({}, math.random)
	s.nave_elegida = nave
	s.prueba = { nivel = nivel, dano = true }
	L.empezar_partida(s)
	s.prueba = nil
	local r = { golpes_oleada = 0, golpes_jefe = 0, enemigos = 0, balas = 0, cuadros_oleada = 0, nacidos = 0, jefe_t = nil, oleada_t = 0 }
	local vistos = {}
	local vidas = s.vidas
	for i = 1, 60 * 400 do
		s.vidas = math.max(s.vidas, 2)
		local antes = s.vidas
		L.actualizar(s, dt, piloto(s))
		if s.vidas < antes then
			if s.jefe then r.golpes_jefe = r.golpes_jefe + 1 else r.golpes_oleada = r.golpes_oleada + 1 end
		end
		if s.estado == "jugando" and not s.jefe then
			r.cuadros_oleada = r.cuadros_oleada + 1
			r.enemigos = r.enemigos + #s.enemigos
			r.balas = r.balas + #s.balas_enemigas
			for _, en in ipairs(s.enemigos) do if not vistos[en] then vistos[en] = true; r.nacidos = r.nacidos + 1 end end
		end
		if s.jefe and s.jefe.llego and not r.jefe_desde then r.jefe_desde = i end
		if s.estado == "nivel_superado" then
			r.jefe_t = (i - (r.jefe_desde or i)) / 60
			break
		end
		if s.estado == "muriendo" or s.estado == "continuar" then L.continuar(s) end
	end
	r.oleada_t = r.cuadros_oleada / 60
	return r
end

print("nivel  nave  oleada_s  enem/pant  balas/pant  nacidos/min  golpes_oleada  jefe_s  golpes_jefe  vida_jefe")
local niveles = {}
for _, a in ipairs(arg or {}) do niveles[#niveles + 1] = tonumber(a) end
if #niveles == 0 then for n = 1, #D.niveles do niveles[n] = n end end
for _, nivel in ipairs(niveles) do
	for nave = 1, 2 do
		local t = { o = 0, e = 0, b = 0, n = 0, go = 0, j = 0, gj = 0, jn = 0 }
		local N = 4
		for k = 1, N do
			local r = medir(nivel, nave, 100 + k)
			t.o = t.o + r.oleada_t
			t.e = t.e + r.enemigos / math.max(1, r.cuadros_oleada)
			t.b = t.b + r.balas / math.max(1, r.cuadros_oleada)
			t.n = t.n + r.nacidos / math.max(1, r.oleada_t) * 60
			t.go = t.go + r.golpes_oleada
			if r.jefe_t then t.j = t.j + r.jefe_t; t.jn = t.jn + 1 end
			t.gj = t.gj + r.golpes_jefe
		end
		print(("%5d  %4d  %8.0f  %9.1f  %10.1f  %11.0f  %13.1f  %6s  %11.1f  %9d"):format(nivel, nave, t.o / N, t.e / N, t.b / N, t.n / N, t.go / N,
			t.jn > 0 and ("%.0f"):format(t.j / t.jn) or "NO", t.gj / N, D.niveles[nivel].jefe_vida))
	end
end

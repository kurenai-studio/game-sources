-- Prueba de la lógica sin LÖVE: un piloto automático juega muchas partidas.
-- Uso (desde la carpeta del proyecto): luajit herramientas/probar_logica.lua
package.path = "juego/?.lua;" .. package.path
local L = require("logica")
local D = require("datos")

math.randomseed(84)
local dt = 1 / 60

-- número de nivel de un caso (así las pruebas no dependen del orden de la historia)
local function nivel_de(caso)
	for i, n in ipairs(D.niveles) do
		if n.caso == caso then return i end
	end
	error("no hay nivel " .. caso)
end

-- las partidas de verdad empiezan con el prólogo; para las pruebas se salta (salvo la suya)
local empezar_con_prologo = L.empezar_partida
L.empezar_partida = function(s)
	empezar_con_prologo(s)
	if s.estado == "prologo" then s.estado, s.t = "inicio_nivel", 0 end
end

local function entrada_al_azar(t)
	local e = {
		arriba = math.random() < 0.3, abajo = math.random() < 0.3,
		izquierda = math.random() < 0.2, derecha = math.random() < 0.25,
		a = math.random() < 0.8, b = math.random() < 0.02, poder = math.random() < 0.05,
	}
	e.poder_pulsado = e.poder
	e.b_pulsado = e.b
	e.start_pulsado = math.random() < 0.002
	e.a_pulsado = e.a
	e.select_pulsado = false
	return e
end

local function revisar(s)
	assert(s.nave.x >= -10 and s.nave.x <= D.ANCHO - 7, "nave fuera en x: " .. s.nave.x .. " " .. s.estado .. " " .. tostring(s.nivel) .. " " .. L.forma_nave(s))
	assert(s.nave.y >= D.TECHO and s.nave.y <= D.ALTO, "nave fuera en y")
	assert(s.vidas >= 0 and s.vidas <= 5, "vidas raras")
	assert(#s.enemigos < 60 and #s.balas_enemigas < 80, "demasiados objetos")
	for x = 0, D.ANCHO do
		assert(s.arriba[x] + s.abajo[x] < D.ALTO - D.TECHO - 10, "terreno tapa el paso")
	end
	for _, en in ipairs(s.enemigos) do
		-- los nadadores del lago helado van bajo el hielo a propósito
		local bajo_hielo = en.tipo == "plateado" or en.tipo == "luz"
		for cx = math.max(0, math.floor(en.x)), bajo_hielo and -1 or math.min(D.ANCHO, math.floor(en.x + en.w - 1)) do
			assert(en.y + en.h <= D.ALTO - s.abajo[cx] + 0.01, "enemigo dentro del suelo: " .. en.tipo)
			assert(en.tipo == "roca" or en.y >= D.TECHO + s.arriba[cx] - 0.01, "enemigo dentro del techo: " .. en.tipo)
		end
	end
end

-- 1) partidas normales: deben terminar sin errores
local estados_vistos, partidas, mejor = {}, 0, 0
for _ = 1, 40 do
	local s = L.nuevo({}, math.random)
	L.empezar_partida(s)
	for _ = 1, 60 * 60 * 6 do
		local e = entrada_al_azar()
		if s.estado == "pausa" then e.start_pulsado = true end
		-- al morir, la mitad de las veces sigue y la otra se rinde
		if s.estado == "continuar" then
			e.a_pulsado, e.start_pulsado = false, math.random() < 0.01
			e.b_pulsado = not e.start_pulsado and math.random() < 0.01
		end
		L.actualizar(s, dt, e)
		estados_vistos[s.estado] = true
		if s.nave then revisar(s) end
		if s.estado == "titulo" then break end
	end
	partidas = partidas + 1
	mejor = math.max(mejor, s.record)
end
print(("partidas al azar: %d, mejor puntaje %d"):format(partidas, mejor))

-- 2) piloto invencible: debe pasar todos los niveles (incluidos tierra y mar), vencer a los jefes y empezar la vuelta 2
local s = L.nuevo({}, math.random)
L.empezar_partida(s)
local jefes, niveles = 0, {}
for _ = 1, 60 * 60 * 20 do
	s.invencible = 5
	local e = entrada_al_azar()
	e.start_pulsado = false
	-- apunta al jefe: se pone a su altura
	if s.jefe then
		-- (a los jefes bajitos, como el submarino, se les apunta más arriba)
		local meta = s.jefe.y + (s.jefe.blanco and 0 or s.jefe.h <= 6 and 1 or 5)
		e.arriba = s.nave.y > meta + 0.5
		e.abajo = s.nave.y < meta - 0.5
		e.a, e.poder_pulsado = true, true
		-- se queda delante del jefe (ahora la nave puede cruzar toda la pantalla)
		e.derecha = false
		e.izquierda = s.nave.x > 30
	end
	local antes = s.estado
	L.actualizar(s, dt, e)
	if s.estado == "nivel_superado" and antes ~= "nivel_superado" then
		jefes = jefes + 1
	end
	niveles[s.nivel .. "-" .. s.ciclo] = true
	estados_vistos[s.estado] = true
	revisar(s)
	if s.ciclo >= 2 and s.nivel >= 2 then break end
end
print(("piloto invencible: %d jefes vencidos, vuelta %d nivel %d, puntos %d"):format(jefes, s.ciclo, s.nivel, s.puntos))
assert(jefes >= #D.niveles, "no llegó a vencer a todos los jefes")

-- 3) tabla de récords: cinco puestos ordenados, y las iniciales se escriben con la cruceta
local s3 = L.nuevo({}, math.random)
for _, p in ipairs({ 300, 1200, 50, 800, 999, 10, 2000, 400, 500, 600, 700, 900 }) do
	if L.entra_en_tabla(s3, p) then L.anotar(s3, "AAA", p) end
end
assert(#s3.tabla == L.PUESTOS and L.PUESTOS == 10 and s3.tabla[1].puntos == 2000 and s3.tabla[10].puntos == 300, "tabla mal ordenada")
assert(not L.entra_en_tabla(s3, 100) and L.entra_en_tabla(s3, 301), "corte de la tabla mal")
L.empezar_partida(s3)
s3.puntos = 5000
s3.vidas = 1
s3.invencible, s3.escudo = 0, 0
s3.estado = "jugando"
-- un golpe directo para perder la última vida
s3.balas_enemigas[1] = { x = s3.nave.x + 2, y = s3.nave.y + 2, vx = 0, vy = 0 }
local function paso(teclas)
	local e = { }
	for k, v in pairs(teclas or {}) do e[k] = v end
	L.actualizar(s3, dt, e)
end
paso()
for _ = 1, 120 do paso() end
-- primero ofrece continuar; con B se rinde
assert(s3.estado == "continuar", "no ofreció continuar: " .. s3.estado)
for _ = 1, 30 do paso() end
paso({ b_pulsado = true })
assert(s3.estado == "iniciales", "no pidió iniciales: " .. s3.estado)
paso({ abajo_pulsado = true })                 -- A -> 9
paso({ derecha_pulsado = true })
paso({ arriba_pulsado = true }); paso({ arriba_pulsado = true }) -- A -> C
paso({ start_pulsado = true })
assert(s3.estado == "fin" and s3.tabla[1].nombre == "9CA" and s3.puesto == 1, "iniciales mal guardadas: " .. s3.tabla[1].nombre)
print("tabla de récords: bien (" .. s3.tabla[1].nombre .. " " .. s3.tabla[1].puntos .. ")")

-- 4) nivel en tierra: aterriza, salta, lanza cohetes y el pincho no se rompe
local s4 = L.nuevo({}, math.random)
L.empezar_partida(s4)
s4.nivel = nivel_de("PHOENIX 1997")
for _ = 1, 150 do L.actualizar(s4, dt, {}) end
assert(s4.estado == "jugando" and L.forma_nave(s4) == "oruga", "no se transformó en oruga")
for _ = 1, 30 do s4.invencible = 5; L.actualizar(s4, dt, {}) end
local piso = s4.nave.y
assert(s4.nave.en_suelo, "la oruga no está en el suelo")
s4.invencible = 5
L.actualizar(s4, dt, { arriba = true, arriba_pulsado = true })
local cima = piso
for _ = 1, 40 do s4.invencible = 5; L.actualizar(s4, dt, { arriba = true }); cima = math.min(cima, s4.nave.y) end
assert(piso - cima >= 9 and piso - cima <= 14, "salto raro: " .. (piso - cima))
for _ = 1, 60 do s4.invencible = 5; L.actualizar(s4, dt, {}) end
assert(s4.nave.en_suelo, "no volvió a caer")
s4.enemigos = {}
L.actualizar(s4, dt, { a = true, a_pulsado = true })
local function contar_cohetes()
	local n = 0
	for _, b in ipairs(s4.balas) do if b.cohete then n = n + 1 end end
	return n
end
assert(contar_cohetes() == 1, "A no lanzó el cohete junto con el disparo")
s4.balas = {}
L.actualizar(s4, dt, { poder = true, poder_pulsado = true })
assert(contar_cohetes() == 0, "Y no debería lanzar cohetes")
s4.enemigos[1] = { tipo = "pincho", x = 30, y = 40, base_y = 40, w = 5, h = 3, vida = 1, t = 0, fase = 0, golpe = 0, disparo = 9 }
for _ = 1, 30 do s4.invencible = 5; L.actualizar(s4, dt, { a = true }) end
assert(#s4.enemigos >= 1 and s4.enemigos[1].tipo == "pincho", "el pincho se rompió")
print(("nivel en tierra: bien (salto de %.1f px)"):format(piso - cima))

-- 5) modo de prueba: B tres veces en el título, elegir nivel, sin daño y SELECT salta al jefe
local s5 = L.nuevo({}, math.random)
for _ = 1, 3 do L.actualizar(s5, dt, { b_pulsado = true }); L.actualizar(s5, dt, {}) end
assert(s5.prueba, "no se activó el modo de prueba")
L.actualizar(s5, dt, { derecha_pulsado = true }); L.actualizar(s5, dt, {})
L.actualizar(s5, dt, { derecha_pulsado = true }); L.actualizar(s5, dt, {})
L.actualizar(s5, dt, { start_pulsado = true })
assert(s5.nivel == 3, "no empezó en el nivel elegido: " .. tostring(s5.nivel))
for _ = 1, 150 do L.actualizar(s5, dt, {}) end
L.actualizar(s5, dt, { select_pulsado = true })
for _ = 1, 200 do L.actualizar(s5, dt, {}) end
assert(s5.jefe, "SELECT no llevó al jefe")
local vidas = s5.vidas
s5.balas_enemigas[#s5.balas_enemigas + 1] = { x = s5.nave.x + 2, y = s5.nave.y + 2, vx = 0, vy = 0 }
L.actualizar(s5, dt, {})
assert(s5.vidas == vidas, "en modo de prueba no debería perder vidas")
assert(not L.entra_en_tabla(s5, 999999), "en modo de prueba no se anotan récords")
-- salir del modo de prueba: volver al título y una sola B
local s5b = L.nuevo({}, math.random)
for _ = 1, 3 do L.actualizar(s5b, dt, { b_pulsado = true }); L.actualizar(s5b, dt, {}) end
assert(s5b.prueba, "no entró al modo de prueba")
L.actualizar(s5b, dt, { b_pulsado = true })
assert(not s5b.prueba, "una B no quitó el modo de prueba")
-- menú de prueba: abajo pasa a la nave, abajo otra vez al daño; con daño activado sí se pierden vidas
local s5c = L.nuevo({}, math.random)
for _ = 1, 3 do L.actualizar(s5c, dt, { b_pulsado = true }); L.actualizar(s5c, dt, {}) end
L.actualizar(s5c, dt, { abajo_pulsado = true }); L.actualizar(s5c, dt, { derecha_pulsado = true })
assert(s5c.nave_elegida == 2, "el menú de prueba no cambió la nave")
L.actualizar(s5c, dt, { abajo_pulsado = true }); L.actualizar(s5c, dt, { derecha_pulsado = true })
assert(s5c.prueba.vuelta == 2, "el menú de prueba no cambió la vuelta")
L.actualizar(s5c, dt, { abajo_pulsado = true }); L.actualizar(s5c, dt, { derecha_pulsado = true })
assert(s5c.prueba.dano, "el menú de prueba no activó el daño")
L.actualizar(s5c, dt, { abajo_pulsado = true }); L.actualizar(s5c, dt, { derecha_pulsado = true })
assert(s5c.prueba.choques, "el menú de prueba no activó los choques")
L.actualizar(s5c, dt, { abajo_pulsado = true }); L.actualizar(s5c, dt, { derecha_pulsado = true })
assert(s5c.prueba.lento == 2, "el menú de prueba no activó el modo lento")
L.actualizar(s5c, dt, { start_pulsado = true })
assert(s5c.ciclo == 2, "no empezó en la vuelta elegida")
-- en cámara lenta a la mitad, un segundo real son medio segundo de juego
local t0 = s5c.t
for _ = 1, 60 do L.actualizar(s5c, 1 / 60, {}) end
assert(math.abs(s5c.t - t0 - 0.5) < 0.01, "el modo lento no frena el juego: " .. (s5c.t - t0))
s5c.prueba.lento = 1
for _ = 1, 200 do L.actualizar(s5c, dt, {}) end
s5c.invencible, s5c.escudo = 0, 0
local vidas_c = s5c.vidas
s5c.balas_enemigas[#s5c.balas_enemigas + 1] = { x = s5c.nave.x + 2, y = s5c.nave.y + 2, vx = 0, vy = 0 }
L.actualizar(s5c, dt, {})
assert(s5c.vidas == vidas_c - 1, "con daño activado debería perder una vida")
assert(not L.entra_en_tabla(s5c, 999999), "en modo de prueba con daño tampoco se anotan récords")
-- rayo en tierra: columna hacia arriba que alcanza a la nodriza
for _ = 1, 200 do L.actualizar(s5, dt, {}) end
s5.jefe.x = s5.nave.x - 4
local antes = s5.jefe.vida
L.actualizar(s5, dt, { b = true, b_pulsado = true })
for _ = 1, 10 do s5.jefe.x = s5.nave.x - 4; L.actualizar(s5, dt, {}) end
assert(s5.jefe.vida < antes, "el rayo hacia arriba no le hizo daño a la nodriza")
print("modo de prueba y rayo hacia arriba: bien")

-- 5b) jefe de Roswell por fases: pasa de 1 a 3 según su vida, borra las balas al cambiar
-- y los muros de la fase 2 siempre dejan un hueco de al menos 8 píxeles
local s5d = L.nuevo({}, math.random)
s5d.prueba = { nivel = 1 }
L.empezar_partida(s5d)
for _ = 1, 300 do L.actualizar(s5d, dt, {}) end
s5d.tiempo_nivel = 999
for _ = 1, 600 do L.actualizar(s5d, dt, {}); if s5d.jefe and s5d.jefe.llego then break end end
assert(s5d.jefe and s5d.jefe.tipo == "coloso", "no apareció el platillo de Roswell")
local vistas = {}
for fase = 1, 3 do
	s5d.jefe.vida = s5d.jefe.maximo * (1.05 - fase / 3)
	for _ = 1, 60 * 6 do
		L.actualizar(s5d, dt, {})
		vistas[s5d.jefe.fase_n or 1] = true
		if fase == 2 and not s5d.jefe.cambio then
			local ys = {}
			for _, b in ipairs(s5d.balas_enemigas) do
				if b.vy == 0 and b.x > s5d.jefe.x - 4 then ys[#ys + 1] = b.y end
			end
			if #ys > 5 then
				table.sort(ys)
				local hueco = math.max(ys[1] - D.TECHO, D.ALTO - ys[#ys] - 2)
				for q = 2, #ys do hueco = math.max(hueco, ys[q] - ys[q - 1] - 2) end
				assert(hueco >= 8, "muro sin hueco suficiente: " .. hueco)
			end
		end
	end
end
assert(vistas[1] and vistas[2] and vistas[3], "el platillo no pasó por sus tres fases")
print("platillo de Roswell por fases: bien")

-- 5c) todos los jefes pasan por sus tres fases, al cambiar quedan blindados y sin balas,
-- y vencer rápido da puntos extra
for nivel = 1, #D.niveles do
	local sj = L.nuevo({}, math.random)
	sj.prueba = { nivel = nivel }
	L.empezar_partida(sj)
	for _ = 1, 200 do L.actualizar(sj, dt, {}) end
	sj.tiempo_nivel, sj.enemigos = 999, {}
	for _ = 1, 60 * 10 do L.actualizar(sj, dt, {}); if sj.jefe and sj.jefe.llego then break end end
	local j = sj.jefe
	assert(j and j.llego, "no llegó el jefe del nivel " .. nivel)
	local vistas = {}
	for fase = 1, 3 do
		j.vida = j.maximo * (1.05 - fase / 3)
		L.actualizar(sj, dt, {})
		if fase > 1 then
			assert(j.blindado and #sj.balas_enemigas == 0, "el jefe " .. j.tipo .. " no se blindó ni borró las balas al pasar a la fase " .. fase)
		end
		for _ = 1, 60 * 8 do
			L.actualizar(sj, dt, {})
			vistas[j.fase_n] = true
		end
	end
	assert(vistas[1] and vistas[2] and vistas[3], "el jefe " .. j.tipo .. " no pasó por sus tres fases")
	-- vencerlo de golpe al poco tiempo da puntos extra
	-- (se reintenta cada cuadro por si el jefe está hundido o cerrado en ese momento)
	local vidas_antes = sj.vidas
	for _ = 1, 60 * 6 do
		if sj.estado == "nivel_superado" then break end
		j.t, j.vida = 9.9, 0.5
		sj.balas = { { x = select(1, L.blanco_jefe(j)) + 1, y = select(2, L.blanco_jefe(j)) + 1, vy = 0 } }
		L.actualizar(sj, dt, {})
	end
	assert(sj.estado == "nivel_superado" and sj.bono_rapido == 500, "sin puntos por rapidez con el jefe " .. j.tipo .. ": " .. tostring(sj.bono_rapido))
	-- premio por vencerlo: una vida más (o puntos si ya tenía cinco)
	assert(sj.vidas == math.min(5, vidas_antes + 1) and sj.premio, "sin premio al vencer al jefe " .. j.tipo)
end
-- el cambio de fase va por partes: sacudida, escudo quieto que rebota tiros, aviso y vuelta
do
	local sf = L.nuevo({}, math.random)
	sf.prueba = { nivel = 1 }
	L.empezar_partida(sf)
	sf.tiempo_nivel, sf.enemigos = 999, {}
	for _ = 1, 60 * 30 do L.actualizar(sf, dt, {}); if sf.jefe and sf.jefe.llego then break end end
	local j = sf.jefe
	sf.balas_enemigas = { { x = 30, y = 20, vx = -10, vy = 0 } }
	local puntos = sf.puntos
	j.vida = j.maximo * 0.6
	L.actualizar(sf, dt, {})
	assert(j.sacudida and j.blindado and #sf.balas_enemigas == 0 and #sf.gotas > 0, "no empezó bien el cambio de fase")
	local vida = j.vida
	local visto_escudo, visto_aviso = false, false
	for _ = 1, math.ceil(L.CAMBIO_FASE / dt) + 2 do
		if j.blindado and not j.sacudida and not visto_escudo then
			visto_escudo = true
			sf.balas = { { x = select(1, L.blanco_jefe(j)) + 1, y = select(2, L.blanco_jefe(j)) + 1, vy = 0 } }
		end
		if j.escudo_aviso then visto_aviso = true end
		L.actualizar(sf, dt, {})
	end
	assert(visto_escudo and visto_aviso and j.vida == vida, "el escudo del cambio de fase no protegió o no avisó")
	assert(not j.blindado and not j.cambio, "el jefe no volvió a pelear después del escudo")
end
print("jefes por fases y puntos por rapidez: bien")

-- 6) perder una vida: la nave explota, desaparece y vuelve a entrar desde la izquierda
local s6 = L.nuevo({}, math.random)
L.empezar_partida(s6)
for _ = 1, 150 do L.actualizar(s6, dt, {}) end
s6.invencible, s6.escudo = 0, 0
s6.balas_enemigas[#s6.balas_enemigas + 1] = { x = s6.nave.x + 2, y = s6.nave.y + 2, vx = 0, vy = 0 }
L.actualizar(s6, dt, {})
assert(s6.vidas == 2 and s6.nave.oculta, "no explotó la nave")
local vista_entrando, minimo_x = false, 99
for _ = 1, 180 do
	s6.enemigos, s6.balas_enemigas = {}, {}
	L.actualizar(s6, dt, { derecha = true, a = true })
	if s6.nave.entrando then vista_entrando = true; minimo_x = math.min(minimo_x, s6.nave.x) end
end
assert(vista_entrando and minimo_x < 0, "no entró desde atrás")
assert(not s6.nave.oculta and not s6.nave.entrando and s6.nave.x >= 16, "no recuperó el control")
print("explosión y reaparición: bien")

-- 7) elegir nave en la portada con izquierda/derecha
local s7 = L.nuevo({}, math.random)
assert(L.forma_nave(s7) == "nave", "la nave por defecto debería ser la de cabina")
L.actualizar(s7, dt, { derecha_pulsado = true })
assert(L.forma_nave(s7) == "nave_interceptor", "no cambió a interceptor")
L.actualizar(s7, dt, { derecha_pulsado = true })
assert(L.forma_nave(s7) == "nave", "no volvió a la de cabina")
L.actualizar(s7, dt, { izquierda_pulsado = true })
L.empezar_partida(s7)
for _ = 1, 150 do L.actualizar(s7, dt, {}) end
assert(L.forma_nave(s7) == "nave_interceptor", "la partida no usa la nave elegida")
print("elegir nave: bien")

-- 8) Interceptor: disparo doble y pulso que borra balas y golpea a los cercanos
local s8 = L.nuevo({}, math.random)
s8.nave_elegida = 2
L.empezar_partida(s8)
for _ = 1, 150 do L.actualizar(s8, dt, {}) end
s8.enemigos, s8.balas = {}, {}
L.actualizar(s8, dt, { a = true, a_pulsado = true })
assert(#s8.balas == 2 and s8.balas[1].y ~= s8.balas[2].y, "el Interceptor no lanzó dos balas paralelas")
s8.balas_enemigas = { { x = s8.nave.x + 14, y = s8.nave.y + 2, vx = 0, vy = 0 } }
s8.enemigos = { { tipo = "chispa", x = s8.nave.x + 18, y = s8.nave.y, base_y = s8.nave.y, w = 5, h = 5, vida = 1, t = 0, fase = 0, golpe = 0, disparo = 9 } }
local rayos = s8.rayos
L.actualizar(s8, dt, { b = true, b_pulsado = true })
assert(s8.pulso and s8.rayos == rayos - 1 and s8.rayo_activo <= 0, "B no lanzó el pulso")
for _ = 1, 30 do s8.invencible = 5; L.actualizar(s8, dt, {}) end
assert(#s8.balas_enemigas == 0, "el pulso no borró la bala enemiga")
assert(s8.puntos > 0, "el pulso no destruyó al enemigo cercano")
print("Interceptor (doble y pulso): bien")

-- 9) nivel de mar: el agua frena, lo sumergido no se toca, el remolino arrastra y el jefe se hunde
local s9 = L.nuevo({}, math.random)
s9.prueba = { nivel = nivel_de("SHAG HARBOUR 1967") }
L.empezar_partida(s9)
for _ = 1, 150 do L.actualizar(s9, dt, {}) end
assert(s9.estado == "jugando" and D.niveles[nivel_de("SHAG HARBOUR 1967")].modo == "mar", "no arrancó el nivel de Shag Harbour")
local AGUA = D.niveles[nivel_de("SHAG HARBOUR 1967")].agua
s9.enemigos = {}
local function avance(y)
	s9.nave.x, s9.nave.y = 10, y
	for _ = 1, 30 do L.actualizar(s9, dt, { derecha = true }) end
	return s9.nave.x - 10
end
local arriba_x, abajo_x = avance(14), avance(AGUA + 4)
assert(abajo_x < arriba_x * 0.7, ("el agua no frena: %.1f contra %.1f"):format(abajo_x, arriba_x))
-- un orbe en el fondo no recibe balas; al saltar fuera del agua sí
s9.nave.x, s9.nave.y = 10, D.ALTO - 6
s9.enemigos = { { tipo = "orbe", x = 30, y = D.ALTO - 6, base_y = D.ALTO - 6, w = 7, h = 4, vida = 2, t = 0, fase = 0, golpe = 0, disparo = 9, espera = 9 } }
for _ = 1, 40 do L.actualizar(s9, dt, { a = true, a_pulsado = true }) end
assert(s9.enemigos[1] and s9.enemigos[1].vida == 2 and s9.enemigos[1].bajo_agua, "el orbe sumergido recibió daño")
s9.enemigos[1].espera, s9.enemigos[1].x = 0, 40
local salio = false
for _ = 1, 120 do
	L.actualizar(s9, dt, {})
	if s9.enemigos[1] and not s9.enemigos[1].bajo_agua and s9.enemigos[1].y < AGUA - 6 then salio = true end
end
assert(salio and #s9.gotas >= 0, "el orbe no saltó fuera del agua")
-- el remolino tira de la nave hacia abajo
s9.enemigos = { { tipo = "torbellino", x = 30, y = AGUA, base_y = AGUA, w = 9, h = 4, vida = 1, t = 0, fase = 0, golpe = 0, disparo = 9 } }
s9.nave.x, s9.nave.y = 28, AGUA - 10
local y0 = s9.nave.y
for _ = 1, 30 do L.actualizar(s9, dt, {}) end
assert(s9.nave.y > y0 + 3, "el remolino no arrastra la nave")
-- jefe: pasa por sus cuatro fases y no recibe daño hundido
s9.enemigos = {}
L.actualizar(s9, dt, { select_pulsado = true })
for _ = 1, 60 * 6 do L.actualizar(s9, dt, {}) if s9.jefe and s9.jefe.llego then break end end
assert(s9.jefe and s9.jefe.tipo == "shag", "no apareció el jefe de Shag Harbour")
local fases, hundido_sin_dano = {}, nil
for _ = 1, 60 * 20 do
	L.actualizar(s9, dt, {})
	local j = s9.jefe
	if not j then break end
	fases[j.fase] = true
	if j.sumergido and hundido_sin_dano == nil then
		local vida = j.vida
		s9.balas = { { x = j.x + 2, y = j.y + 2, vy = 0 } }
		L.actualizar(s9, dt, {})
		hundido_sin_dano = s9.jefe.vida == vida
	end
end
assert(fases.arriba and fases.hunde and fases.abajo and fases.sube, "el jefe no recorrió sus fases")
assert(hundido_sin_dano, "el jefe recibió daño bajo el agua")
print("nivel de mar: bien")

-- 10) nivel submarino: batiscafo con inercia, torpedos que aceleran y pirámide con punta vulnerable
local s10 = L.nuevo({}, math.random)
s10.prueba = { nivel = nivel_de("BERMUDAS 1945") }
L.empezar_partida(s10)
for _ = 1, 150 do L.actualizar(s10, dt, {}) end
assert(s10.estado == "jugando" and L.forma_nave(s10) == "batiscafo", "no se volvió batiscafo")
s10.enemigos = {}
s10.nave.x, s10.nave.y = 10, 20
for _ = 1, 30 do L.actualizar(s10, dt, { derecha = true }) end
local x_suelto = s10.nave.x
for _ = 1, 10 do L.actualizar(s10, dt, {}) end
assert(s10.nave.x > x_suelto + 1, "el batiscafo no tiene inercia")
s10.balas = {}
L.actualizar(s10, dt, { a = true, a_pulsado = true })
local tp = s10.balas[1]
assert(tp and tp.torpedo, "no lanzó torpedo")
local v0 = tp.vx
for _ = 1, 10 do L.actualizar(s10, dt, {}) end
assert(tp.vx > v0, "el torpedo no acelera")
L.actualizar(s10, dt, { select_pulsado = true })
for _ = 1, 60 * 8 do L.actualizar(s10, dt, {}) if s10.jefe and s10.jefe.llego then break end end
local j = s10.jefe
assert(j and j.tipo == "piramide", "no apareció la pirámide")
L.actualizar(s10, dt, {})
-- cerrada: la punta rebota y el cuerpo frena
j.fase, j.reloj = "cerrada", 3
L.actualizar(s10, dt, {})
local vida = j.vida
s10.balas = { { x = j.x + 9, y = j.y + 1, vy = 0 }, { x = j.x + 5, y = j.y + 7, vy = 0 } }
L.actualizar(s10, dt, {})
assert(j.vida == vida, "la pirámide recibió daño cerrada o en el cuerpo")
-- abierta: la punta sí recibe daño
j.fase, j.reloj = "abierta", 2
L.actualizar(s10, dt, {})
s10.balas = { { x = j.x + 9, y = j.y + 1, vy = 0 } }
L.actualizar(s10, dt, {})
assert(j.vida < vida, "la punta abierta no recibió daño")
-- un anillo que pasa por la nave fuera del hueco la daña
s10.prueba = nil
s10.invencible, s10.escudo = 0, 0
local vidas = s10.vidas
s10.balas_enemigas, s10.enemigos = {}, {}
s10.nave.x, s10.nave.y, s10.nave.vx, s10.nave.vy = 20, 20, 0, 0
local cx, cy = j.x + 10.5, j.y + 1
local d = math.sqrt((23.5 - cx) ^ 2 + (22.5 - cy) ^ 2)
j.anillos = { { x = cx, y = cy, r = d - 0.2, hueco = 0 } }
L.actualizar(s10, dt, {})
assert(s10.vidas == vidas - 1, "el anillo no dañó la nave")
-- dentro del hueco no hay daño, y el hueco siempre deja pasar la nave (al menos 14 píxeles de arco)
s10.invencible, s10.escudo = 0, 0
vidas = s10.vidas
local hacia = math.atan2(22.5 - cy, 23.5 - cx)
j.anillos = { { x = cx, y = cy, r = d - 0.2, hueco = hacia } }
L.actualizar(s10, dt, {})
assert(s10.vidas == vidas, "la nave recibió daño dentro del hueco")
for r = 4, 60, 4 do
	local an = { r = r, hueco = 0 }
	local paso, ancho = 0.01, 0
	for a2 = -1.5, 1.5, paso do
		if L.en_hueco(an, a2) then ancho = ancho + paso * r end
	end
	assert(ancho >= 14 or r < 8, ("hueco muy angosto: %.1f px con radio %d"):format(ancho, r))
end
print("nivel submarino: bien")

-- 11) ronda completa: pregunta antes de la vuelta 2; terminar anota el puntaje
local function ronda(eleccion_abajo)
	local r = L.nuevo({}, math.random)
	L.empezar_partida(r)
	r.nivel, r.puntos = #D.niveles, 4321
	r.estado, r.t = "nivel_superado", 0
	-- tras el último jefe: el mapa, el final de la historia y recién ahí la pregunta
	local vistos = {}
	for _ = 1, 60 * 30 do
		L.actualizar(r, dt, {})
		vistos[r.estado] = true
		if r.estado == "ronda_completa" then break end
	end
	assert(vistos.mapa and vistos.final, "no pasó por el mapa y el final")
	assert(r.estado == "ronda_completa", "no apareció la pantalla de ronda: " .. r.estado)
	L.actualizar(r, dt, { a_pulsado = true })
	assert(r.estado == "ronda_completa", "eligió sin esperar")
	if eleccion_abajo then L.actualizar(r, dt, { abajo_pulsado = true }) end
	for _ = 1, 100 do L.actualizar(r, dt, {}) end
	L.actualizar(r, dt, { a_pulsado = true })
	return r
end
local r1 = ronda(false)
assert(r1.estado == "inicio_nivel" and r1.ciclo == 2 and r1.nivel == 1, "SEGUIR no empezó la vuelta 2")
local r2 = ronda(true)
assert(r2.estado == "iniciales" and r2.victoria, "TERMINAR no pidió las iniciales: " .. r2.estado)
print("ronda completa: bien")

-- 12) lago helado: la oruga resbala, cae en los agujeros, las grietas abren agujeros,
-- el nadador bajo el hielo no se toca y el gigante solo recibe daño con el visor abierto
local s12 = L.nuevo({}, math.random)
s12.prueba = { nivel = nivel_de("BAIKAL 1982") }
L.empezar_partida(s12)
for _ = 1, 150 do L.actualizar(s12, dt, {}) end
assert(s12.estado == "jugando" and L.forma_nave(s12) == "oruga", "no aterrizó en el hielo")
local AGUA9 = D.niveles[nivel_de("BAIKAL 1982")].agua
s12.enemigos, s12.balas_enemigas = {}, {}
for x = 0, D.ANCHO do s12.abajo[x] = D.ALTO - AGUA9 end
s12.nave.x, s12.nave.vx = 10, 0
for _ = 1, 40 do L.actualizar(s12, dt, { derecha = true }) end
local suelta = s12.nave.x
for _ = 1, 20 do L.actualizar(s12, dt, {}) end
assert(s12.nave.x > suelta + 3, "la oruga no resbala")
-- agujero bajo la oruga: cae y pierde una vida
s12.prueba = nil
s12.invencible, s12.escudo = 0, 0
local vidas12 = s12.vidas
for x = 0, D.ANCHO do s12.abajo[x] = D.ALTO - AGUA9 end
s12.nave.x, s12.nave.vx = 30, 0
for x = 26, 44 do s12.abajo[x] = 0 end
for _ = 1, 60 do L.actualizar(s12, dt, {}) end
assert(s12.vidas == vidas12 - 1, "caer al agua no quitó una vida")
-- una bomba que cae raja el hielo y al rato abre un agujero
s12.prueba = { nivel = nivel_de("BAIKAL 1982") }
for x = 0, D.ANCHO do s12.abajo[x] = D.ALTO - AGUA9 end
s12.grietas, s12.enemigos = {}, {}
s12.balas_enemigas = { { x = 60, y = AGUA9 - 3, vx = 0, vy = 30 } }
for _ = 1, 10 do L.actualizar(s12, dt, {}) end
assert(#s12.grietas == 1, "la bomba no rajó el hielo")
local grieta12 = s12.grietas[1]
for _ = 1, 90 do s12.oleada = 9 L.actualizar(s12, dt, {}) end
local hueco = false
for x = 40, 70 do if s12.abajo[x] == 0 then hueco = true end end
assert(hueco and grieta12.abierta, "la grieta no se abrió")
-- nadador bajo el hielo: las balas no lo tocan; después asoma
s12.enemigos = { { tipo = "plateado", x = 40, y = D.ALTO - 7, base_y = D.ALTO - 7, w = 5, h = 6, vida = 2, t = 0, fase = 0, golpe = 0, disparo = 9, meta = 38 } }
s12.nave.x, s12.nave.y = 10, D.ALTO - 7
s12.balas = { { x = 38, y = D.ALTO - 5, vy = 0 } }
L.actualizar(s12, dt, {})
assert(s12.enemigos[1] and s12.enemigos[1].vida == 2 and s12.enemigos[1].bajo_agua, "el nadador bajo el hielo recibió daño")
local asomo = false
for _ = 1, 200 do
	L.actualizar(s12, dt, {})
	if s12.enemigos[1] and not s12.enemigos[1].bajo_agua then asomo = true end
end
assert(asomo, "el nadador no asomó")
-- gigante
s12.enemigos = {}
L.actualizar(s12, dt, { select_pulsado = true })
for _ = 1, 60 * 8 do L.actualizar(s12, dt, {}) if s12.jefe and s12.jefe.llego and s12.jefe.fase == "asoma" then break end end
local g = s12.jefe
assert(g and g.tipo == "gigante" and g.fase == "asoma", "no asomó el gigante")
local vg = g.vida
s12.balas = { { x = g.x + 7, y = g.y + 4, vy = 0 } }
L.actualizar(s12, dt, {})
assert(g.vida == vg, "el gigante recibió daño con el visor cerrado")
g.fase, g.reloj = "visor", 2
L.actualizar(s12, dt, {})
s12.balas = { { x = g.x + 7, y = g.y + 4, vy = 0 } }
L.actualizar(s12, dt, {})
assert(g.vida < vg, "el visor abierto no recibió daño")
local fases12 = {}
for _ = 1, 60 * 15 do L.actualizar(s12, dt, {}) if s12.jefe then fases12[s12.jefe.fase] = true end end
assert(fases12.hunde and fases12.nada and fases12.sube, "el gigante no se hundió ni volvió a salir")
print("lago helado: bien")

-- 12b) armas de la oruga: cohetes que buscan, rayo hacia adelante con la derecha y obús cargado
local so = L.nuevo({}, math.random)
so.prueba = { nivel = nivel_de("BAIKAL 1982") }
L.empezar_partida(so)
for _ = 1, 200 do L.actualizar(so, dt, {}) end
so.enemigos, so.balas, so.jefe = {}, {}, nil
-- un enemigo quieto adelante y abajo: el cohete sale para arriba y debe ir a buscarlo
so.enemigos[1] = { tipo = "rodante", x = so.nave.x + 30, y = so.nave.y, base_y = so.nave.y, w = 5, h = 3, vida = 99, t = 0, fase = 0, golpe = 0, disparo = 99 }
L.actualizar(so, dt, { a = true })
local alcanzado = false
for _ = 1, 90 do
	so.enemigos[1].x, so.enemigos[1].y = so.nave.x + 30, so.nave.y
	L.actualizar(so, dt, {})
	if so.enemigos[1].vida < 99 then alcanzado = true break end
end
assert(alcanzado, "el cohete no fue a buscar al enemigo")
-- obús: no sale con un toque, sí al soltar tras cargar
so.enemigos, so.balas = {}, {}
L.actualizar(so, dt, { a = true }); L.actualizar(so, dt, {})
for _, b in ipairs(so.balas) do assert(not b.obus, "salió un obús sin cargar") end
for _ = 1, math.ceil(L.CARGA_MAX / dt) + 2 do L.actualizar(so, dt, { a = true }) end
L.actualizar(so, dt, {})
local obus
for _, b in ipairs(so.balas) do if b.obus then obus = b end end
assert(obus and obus.dano >= 5, "el obús cargado no salió o pega poco")
-- rayo: con la derecha apretada sale hacia adelante
so.rayos, so.rayo_activo = 3, 0
L.actualizar(so, dt, { b_pulsado = true, derecha = true })
assert(so.rayo_caja and so.rayo_caja[3] > 20 and so.rayo_caja[4] <= 4, "el rayo de la oruga no salió hacia adelante")
so.rayo_activo = 0
for _ = 1, 40 do L.actualizar(so, dt, {}) end
so.rayos = 3
L.actualizar(so, dt, { b_pulsado = true })
assert(so.rayo_caja and so.rayo_caja[3] == 4, "sin la derecha el rayo de la oruga debía salir hacia arriba")
-- obús lleno: frena una bala enemiga en su camino; el obús a medias no
so.enemigos, so.balas, so.balas_enemigas = {}, {}, {}
for _ = 1, math.ceil(L.CARGA_MAX / dt) + 2 do L.actualizar(so, dt, { a = true }) end
L.actualizar(so, dt, {})
local lleno
for _, b in ipairs(so.balas) do if b.lleno then lleno = b end end
assert(lleno, "la carga llena no dio el obús grande")
so.balas_enemigas = { { x = lleno.x + 8, y = lleno.y + 2, vx = -20, vy = 0 } }
for _ = 1, 10 do L.actualizar(so, dt, {}) end
assert(#so.balas_enemigas == 0, "el obús lleno no frenó la bala")
so.balas = {}
for _ = 1, math.ceil((L.CARGA_MIN + 0.2) / dt) do L.actualizar(so, dt, { a = true }) end
L.actualizar(so, dt, {})
local medio
for _, b in ipairs(so.balas) do if b.obus then medio = b end end
assert(medio and not medio.lleno, "el obús a medias salió lleno")
so.balas_enemigas = { { x = medio.x + 8, y = medio.y + 1, vx = -20, vy = 0 } }
so.balas = { medio }
for _ = 1, 6 do L.actualizar(so, dt, {}) end
assert(#so.balas_enemigas == 1, "el obús a medias no debería frenar balas")
-- la sonda en tierra suelta cohetes que buscan, y le pega a un enemigo del suelo
do
	local st = L.nuevo({}, math.random)
	st.prueba = { nivel = nivel_de("BAIKAL 1982") }
	L.empezar_partida(st)
	for _ = 1, 200 do L.actualizar(st, dt, {}) end
	st.enemigos, st.balas, st.jefe = {}, {}, nil
	st.enemigos[1] = { tipo = "rodante", x = st.nave.x + 34, y = st.nave.y, base_y = st.nave.y, w = 5, h = 3, vida = 99, t = 0, fase = 0, golpe = 0, disparo = 99 }
	st.sonda = { t = 10, x = st.nave.x + 2, y = st.nave.y - 5, enfriar = 0 }
	local pego = false
	for _ = 1, 150 do
		st.invencible = 5
		st.enemigos[1].x, st.enemigos[1].y = st.nave.x + 34, st.nave.y
		L.actualizar(st, dt, {})
		for _, b in ipairs(st.balas) do assert(b.cohete, "la sonda en tierra disparó algo que no es cohete") end
		if st.enemigos[1].vida < 99 then pego = true break end
	end
	assert(pego, "los cohetes de la sonda no le pegaron al enemigo del suelo")
end
print("armas de la oruga: bien")

-- menú de la portada: START lo abre; NAVE, OPCIONES y RECORDS; START juega
do
	local sm = L.nuevo({}, math.random)
	local function p(e) L.actualizar(sm, dt, e) end
	p({ start_pulsado = true })
	assert(sm.estado == "menu" and sm.menu.hoja == "principal", "START no abrió el menú")
	p({ b_pulsado = true })
	assert(sm.estado == "titulo", "B no volvió a la portada")
	p({ a_pulsado = true })
	assert(sm.estado == "menu", "A no abrió el menú")
	p({ abajo_pulsado = true })
	assert(L.MENU[sm.menu.fila] == "nave", "abajo no bajó a NAVE")
	local antes = sm.nave_elegida or 1
	p({ derecha_pulsado = true })
	assert((sm.nave_elegida or 1) ~= antes, "derecha no cambió la nave")
	p({ a_pulsado = true })
	assert(sm.menu.hoja == "nave", "A en NAVE no abrió la ficha de la nave")
	p({ a_pulsado = true })
	assert(sm.menu.hoja == "principal" and L.MENU[sm.menu.fila] == "nave", "la ficha de la nave no volvió a su fila")
	p({ abajo_pulsado = true })
	p({ a_pulsado = true })
	assert(sm.menu.hoja == "records" and sm.menu.pagina == 1, "no abrió los records")
	p({ derecha_pulsado = true })
	assert(sm.menu.pagina == 2, "no pasó a la página 2 de records")
	p({ b_pulsado = true })
	p({ abajo_pulsado = true })
	p({ a_pulsado = true })
	assert(sm.menu.hoja == "opciones", "no abrió las opciones")
	p({ derecha_pulsado = true })
	assert(sm.ajuste and sm.ajuste.que == "sonido", "no pidió cambiar el sonido")
	sm.ajuste = nil
	p({ abajo_pulsado = true }); p({ izquierda_pulsado = true })
	assert(sm.ajuste and sm.ajuste.que == "color" and sm.ajuste.paso == -1, "no pidió cambiar el color")
	sm.ajuste = nil
	p({ abajo_pulsado = true }); p({ abajo_pulsado = true }); p({ a_pulsado = true })
	assert(sm.menu.hoja == "principal" and not sm.ajuste, "VOLVER no volvió al menú")
	p({ start_pulsado = true })
	assert(sm.estado == "prologo" or sm.estado == "inicio_nivel", "START en el menú no empezó la partida: " .. sm.estado)
	-- el récord guarda nave, nivel y vuelta
	local sr = L.nuevo({}, math.random)
	sr.nave_elegida, sr.nivel, sr.ciclo = 2, 7, 1
	L.anotar(sr, "ABC", 900, { nave = 2, nivel = 7, ciclo = 1 })
	assert(sr.tabla[1].nave == 2 and sr.tabla[1].nivel == 7, "el récord no guardó nave y nivel")
	print("menú de la portada: bien")
end

-- guion de cápsulas: el poder del expediente sale fijo; el azar solo da lo ya aprendido
do
	local sg = L.nuevo({}, math.random)
	sg.prueba = { nivel = 1 }
	L.empezar_partida(sg)
	local posibles = {}
	for _, n in ipairs(L.mejoras_posibles(sg)) do posibles[n] = true end
	assert(posibles.escudo and posibles.triple and posibles.vida and not posibles.tiempo and not posibles.abduccion, "el azar del nivel 1 trae poderes no aprendidos")
	sg.ciclo = 2
	assert(#L.mejoras_posibles(sg) == #D.MEJORAS, "en la vuelta 2 deberían salir todas")
	sg.ciclo = 1
	local vistos, carteles = {}, {}
	local dur = D.niveles[1].duracion
	for _ = 1, math.floor((dur * 0.65 + 3) / dt) do
		sg.invencible = 5
		L.actualizar(sg, dt, {})
		if sg.cartel then carteles[sg.cartel.texto] = true end
		for _, m in ipairs(sg.mejoras) do
			if not m.visto then m.visto = true; vistos[m.tipo .. "_n"] = (vistos[m.tipo .. "_n"] or 0) + 1 end
		end
	end
	assert((vistos.mejora_escudo_n or 0) >= 2, "el escudo del expediente 1 no salió dos veces")
	assert(carteles["MANTEN A: CARGA"] and (carteles["B: RAYO"] or carteles["B: PULSO"]), "faltaron los carteles que enseñan")
	-- la cápsula segura: 20 s sin ninguna y llega una
	sg.mejoras, sg.reloj_mejora = {}, L.MEJORA_SEGURA - dt / 2
	sg.tiempo_nivel = 1
	L.actualizar(sg, dt, {})
	assert(#sg.mejoras == 1, "no llegó la cápsula segura")
	-- recoger un poder por primera vez enseña el botón
	sg.aprendidos = {}
	sg.mejoras = { { tipo = "mejora_sonda", x = sg.nave.x, y = sg.nave.y } }
	L.actualizar(sg, dt, {})
	assert(sg.cartel and sg.cartel.texto == "Y: SONDA", "no enseñó el botón Y")
	print("guion de cápsulas: bien")
end

-- el obús lleno corta un anillo de la pirámide donde lo cruza
do
	local an = { x = 40, y = 40, r = 20, hueco = math.pi }
	local ang = -math.pi / 4
	assert(not L.en_hueco(an, ang), "el anillo ya tenía hueco ahí")
	an.cortes = { ang }
	assert(L.en_hueco(an, ang), "el corte no abrió hueco")
	local sp = L.nuevo({}, math.random)
	sp.prueba = { nivel = nivel_de("BERMUDAS 1945") }
	L.empezar_partida(sp)
	for _ = 1, 200 do L.actualizar(sp, dt, {}) end
	sp.prueba.saltar_jefe = true
	local llego = false
	for _ = 1, 60 * 90 do
		sp.invencible = 5
		L.actualizar(sp, dt, { select_pulsado = true })
		if sp.jefe and sp.jefe.anillos and #sp.jefe.anillos > 0 then llego = true break end
	end
	assert(llego, "la pirámide no lanzó anillos")
	local a1 = sp.jefe.anillos[1]
	a1.r = 20
	local oa = -math.pi / 3
	if L.en_hueco(a1, oa) then oa = oa + 1.2 end
	sp.balas = { { x = a1.x + math.cos(oa) * 20.3 - 2.5, y = a1.y + math.sin(oa) * 20.3 - 2.5, vx = 0, vy = 0, w = 5, h = 5, dano = 6, obus = true, lleno = true } }
	L.actualizar(sp, dt, {})
	assert(a1.cortes and #a1.cortes >= 1, "el obús lleno no cortó el anillo")
	print("obús lleno contra la pirámide: bien")
end

-- controles táctiles: ventana de teléfono horizontal (1200x540) con toques simulados
do
	local antes = love
	love = { graphics = { getDimensions = function() return 1200, 540 end } }
	local T = require("tactil")
	local function claves(e)
		local t = {}
		for k in pairs(e) do t[#t + 1] = k end
		table.sort(t)
		return table.concat(t, ",")
	end
	local function ve(esperado, mensaje) assert(claves(T.leer()) == esperado, "táctil: " .. mensaje) end
	-- la cruceta queda centrada en (111, 335) y el grupo de botones en (1089, 335)
	T.presionar(1, 171, 335) ve("derecha", "derecha")
	T.mover(1, 171, 275) ve("arriba,derecha", "diagonal")
	T.mover(1, 116, 335) ve("", "zona muerta del centro")
	T.mover(1, 400, 335) ve("derecha", "el dedo que empezó en la cruceta sigue en ella")
	T.soltar(1) ve("derecha", "un toque corto cuenta una vez") ve("", "y luego se borra")
	T.presionar(2, 1133, 335) ve("a", "botón A")
	T.mover(2, 1040, 400) ve("b", "deslizar de A a B")
	T.presionar(3, 111, 405) ve("abajo,b", "dos dedos a la vez")
	T.soltar(2) T.soltar(3) T.leer()
	T.presionar(4, 1089, 70) ve("start", "START") T.soltar(4) T.leer()
	T.presionar(5, 600, 270) ve("a", "tocar la pantalla vale como A") T.soltar(5) T.leer()
	love = antes
	print("controles táctiles: bien")
end

-- puente con la página de YouTube: argumentos y pausa pedida desde afuera
do
	local P = require("puente")
	P.iniciar({ "./game.love", "--youtube", "--tactil", "--ajustes=paleta=2|puesto=DRK:5035" })
	assert(P.activo and P.tactil, "puente: no leyó --youtube o --tactil")
	local l = P.lineas()
	assert(#l == 2 and l[1] == "paleta=2" and l[2] == "puesto=DRK:5035", "puente: ajustes mal separados")
	local sp = L.nuevo({}, math.random)
	L.empezar_partida(sp)
	sp.estado = "jugando"
	L.pausar(sp)
	assert(sp.estado == "pausa", "puente: la pausa de afuera no pausó")
	sp.estado = "titulo"
	L.pausar(sp)
	assert(sp.estado == "titulo", "puente: la pausa no debe tocar el título")
	P.iniciar({ "./game.love", "--idioma=en-US" })
	assert(P.idioma == "en-US", "puente: no leyó --idioma")
	print("puente con YouTube: bien")
end

-- pausa con cursor: START sigue, abajo + A sale al título, SELECT sale de una
do
	local sp = L.nuevo({}, math.random)
	L.empezar_partida(sp)
	sp.estado = "jugando"
	L.actualizar(sp, 0.016, { start_pulsado = true })
	assert(sp.estado == "pausa" and sp.opcion_pausa == 1, "pausa: no pausó o el cursor no empezó en SEGUIR")
	L.actualizar(sp, 0.016, { start_pulsado = true })
	assert(sp.estado == "jugando", "pausa: START no siguió")
	L.actualizar(sp, 0.016, { start_pulsado = true })
	L.actualizar(sp, 0.016, { abajo_pulsado = true })
	assert(sp.opcion_pausa == 2, "pausa: abajo no movió el cursor")
	L.actualizar(sp, 0.016, { a_pulsado = true })
	assert(sp.estado == "titulo", "pausa: SALIR no volvió al título")
	sp.estado = "jugando"
	L.actualizar(sp, 0.016, { start_pulsado = true })
	L.actualizar(sp, 0.016, { select_pulsado = true })
	assert(sp.estado == "titulo", "pausa: SELECT no salió")
	print("pausa con cursor: bien")
end

local lista = {}
for k in pairs(estados_vistos) do lista[#lista + 1] = k end
table.sort(lista)
print("estados recorridos: " .. table.concat(lista, ", "))
-- idioma: traducciones al inglés que caben en la pantalla y usan letras que existen
do
	local I = require("idioma")
	assert(I.normalizar("en-US") == "en" and I.normalizar("es_CO") == "es" and I.normalizar("fr") == nil, "idioma: códigos mal leídos")
	I.actual = "en"
	local casos = {
		["NIVEL 3"] = "LEVEL 3", ["FASE 2"] = "PHASE 2", ["RAPIDO +500"] = "SPEED +500",
		["< DANO: SI >"] = "< DAMAGE: YES >", ["RONDA 2 COMPLETA"] = "ROUND 2 CLEAR",
		["PUESTO 1 DE 5"] = "RANK 1 OF 5", ["MEJOR DKR 5035"] = "BEST DKR 5035",
		["ROSWELL 1947"] = "ROSWELL 1947", ["CUIDADO!"] = "WARNING!",
	}
	for es, en in pairs(casos) do
		assert(I.t(es) == en, "idioma: '" .. es .. "' dio '" .. I.t(es) .. "'")
		assert(I.t(I.t(es)) == en, "idioma: traducir dos veces cambia '" .. es .. "'")
	end
	-- todos los textos de los niveles y expedientes, en los dos idiomas
	local textos = {}
	for _, n in ipairs(D.niveles) do
		for _, c in ipairs({ n.nombre, n.caso, n.aviso }) do textos[#textos + 1] = c end
	end
	for _, x in ipairs(D.expedientes) do textos[#textos + 1] = x[2]; textos[#textos + 1] = x[3] end
	for _, idioma in ipairs(I.IDIOMAS) do
		I.actual = idioma
		for _, c in ipairs(textos) do
			local v = I.t(c)
			assert(#v <= 21, "idioma " .. idioma .. ": '" .. v .. "' no cabe")
			for k = 1, #v do
				local letra = v:sub(k, k)
				assert(letra == " " or D.letras[letra], "idioma " .. idioma .. ": falta la letra '" .. letra .. "' en '" .. v .. "'")
			end
		end
	end
	I.actual = "es"
	print("idioma inglés: bien")
end

-- continuar: cuenta de 9 a 0; A sigue ahí mismo con 3 vidas y 0 puntos, sin perder el daño al jefe;
-- al terminar, para los récords cuenta el mejor tramo
do
	local sc = L.nuevo({}, math.random)
	sc.prueba = { nivel = 1, dano = true }
	L.empezar_partida(sc)
	sc.prueba = nil
	sc.tiempo_nivel, sc.enemigos = 999, {}
	for _ = 1, 60 * 30 do L.actualizar(sc, dt, {}); if sc.jefe and sc.jefe.llego then break end end
	sc.jefe.vida = sc.jefe.maximo * 0.5
	-- (deja pasar el cambio de fase, que borra las balas)
	for _ = 1, math.ceil(L.CAMBIO_FASE / dt) + 2 do L.actualizar(sc, dt, {}) end
	local vida_jefe = sc.jefe.vida
	sc.puntos, sc.vidas, sc.invencible = 4321, 1, 0
	sc.balas_enemigas = { { x = sc.nave.x + 2, y = sc.nave.y + 2, vx = 0, vy = 0 } }
	for _ = 1, 60 * 3 do L.actualizar(sc, dt, {}); if sc.estado == "continuar" then break end end
	assert(sc.estado == "continuar" and sc.cuenta > 9, "no ofreció continuar: " .. sc.estado .. " " .. tostring(sc.cuenta) .. " " .. sc.vidas)
	for _ = 1, 30 do L.actualizar(sc, dt, {}) end
	L.actualizar(sc, dt, { a_pulsado = true })
	assert(sc.estado == "jugando" and sc.vidas == 3 and sc.puntos == 0 and sc.jefe and sc.jefe.vida <= vida_jefe, "continuar no siguió ahí mismo")
	assert(sc.mejor_tramo == 4321, "no guardó el mejor tramo")
	-- ahora se rinde dejando pasar la cuenta: el puntaje final es el mejor tramo
	sc.vidas, sc.invencible, sc.nave.oculta = 1, 0, nil
	sc.balas_enemigas = { { x = sc.nave.x + 2, y = sc.nave.y + 2, vx = 0, vy = 0 } }
	for _ = 1, 60 * 15 do L.actualizar(sc, dt, {}); if sc.estado == "iniciales" or sc.estado == "fin" then break end end
	assert(sc.estado == "iniciales" and sc.puntos == 4321, "al rendirse no contó el mejor tramo: " .. sc.estado .. " " .. sc.puntos)
	print("continuar: bien")
end

-- Golfo Nuevo: lo hundido solo se toca alumbrado; las cargas revientan y alumbran;
-- el gemelo del fantasma pasa el daño al jefe y se va en la fase 3
do
	local sg = L.nuevo({}, math.random)
	sg.prueba = { nivel = nivel_de("GOLFO NUEVO 1960") }
	L.empezar_partida(sg)
	for _ = 1, 200 do L.actualizar(sg, dt, {}) end
	local a = D.niveles[nivel_de("GOLFO NUEVO 1960")].agua
	sg.enemigos = {}
	sg.enemigos[1] = { tipo = "cilindro", x = 40, y = a + 8, base_y = a + 8, w = 9, h = 4, vida = 2, t = 0, fase = 0, golpe = 0, disparo = 9 }
	local r = sg.reflectores[1]
	r.base, r.amplitud = 44, 0
	sg.reflectores[2].encendido = false
	L.actualizar(sg, dt, {})
	assert(sg.enemigos[1] and not sg.enemigos[1].bajo_agua and sg.enemigos[1].alumbrado, "el cilindro alumbrado debería poder tocarse")
	r.encendido = false
	L.actualizar(sg, dt, {})
	assert(sg.enemigos[1].bajo_agua, "el cilindro a oscuras debería ser intocable")
	-- carga: baja, revienta en un anillo de balas y deja un destello que alumbra
	sg.balas_enemigas, sg.cargas = {}, {}
	sg.cargas[1] = { x = 60, y = a + 2, meta = a + 6 }
	for _ = 1, 60 do L.actualizar(sg, dt, {}); if #sg.cargas == 0 then break end end
	assert(#sg.cargas == 0 and #sg.balas_enemigas >= 6, "la carga no reventó: " .. #sg.cargas .. " " .. #sg.balas_enemigas .. " " .. sg.estado)
	sg.destellos = {}
	sg.cargas[1] = { x = 60, y = a + 5.9, meta = a + 6 }
	L.actualizar(sg, dt, {})
	assert(#sg.destellos == 1 and L.alumbrado(sg, 58, a + 5, 3, 3), "el destello no alumbra")
	-- el fantasma: fase 2 con gemelo; el daño al gemelo es del jefe
	sg.tiempo_nivel, sg.enemigos, sg.cargas = 999, {}, {}
	for _ = 1, 60 * 30 do L.actualizar(sg, dt, {}); if sg.jefe and sg.jefe.llego then break end end
	local j = sg.jefe
	assert(j and j.tipo == "fantasma" and j.sumergido, "el fantasma debería llegar hundido")
	j.vida = j.maximo * 0.6
	for _ = 1, 60 * 4 do L.actualizar(sg, dt, {}) end
	local g = j.gemelo
	assert(g and g.tipo == "gemelo", "en la fase 2 no apareció el segundo submarino")
	local antes = j.vida
	g.bajo_agua = false
	sg.balas = { { x = g.x + 2, y = g.y + 3, vx = 0, vy = 0 } }
	local alumbrar = L.alumbrado
	L.alumbrado = function() return true end
	L.actualizar(sg, dt, {})
	L.alumbrado = alumbrar
	assert(j.vida < antes and not g.muerto, "el daño al gemelo no le llegó al jefe")
	j.vida = j.maximo * 0.3
	for _ = 1, 60 * 8 do L.actualizar(sg, dt, {}) end
	assert(g.retira and (g.muerto or g.x > 60), "en la fase 3 el gemelo no se fue")
	assert(not sg.reflectores[1].encendido and not sg.reflectores[2].encendido, "en la fase 3 los reflectores siguen encendidos")
	print("golfo nuevo: bien")
end

-- enemigos por nivel: más bravos, más resistentes y algunos armados (avisan y disparan)
do
	assert(L.prob_armado(1) == 0 and L.prob_armado(2) == 0 and L.prob_armado(10) == 0.5, "probabilidad de armados rara")
	assert(L.vida_extra(1, "chispa") == 0 and L.vida_extra(5, "chispa") == 1 and L.vida_extra(9, "chispa") == 2, "vida extra rara")
	assert(L.vida_extra(9, "caparazon") == 0 and L.vida_extra(9, "mina") == 0, "los duros y las minas no llevan vida extra")
	local sa = L.nuevo({}, math.random)
	sa.prueba = { nivel = 6 }
	L.empezar_partida(sa)
	for _ = 1, 200 do L.actualizar(sa, dt, {}) end
	local d1 = L.dificultad_enemigos({ ciclo = 1, nivel = 1 })
	local d10 = L.dificultad_enemigos({ ciclo = 1, nivel = 10 })
	assert(d1 < 1 and d10 > 1.1, "la dificultad de los enemigos no sube por nivel")
	sa.enemigos, sa.balas_enemigas = {}, {}
	sa.enemigos[1] = { tipo = "chispa", x = 50, y = 20, base_y = 20, w = 5, h = 4, vida = 1, t = 0, fase = 0, golpe = 0, disparo = 9, armado = 1 }
	local aviso, disparo = false, false
	for _ = 1, 90 do
		L.actualizar(sa, dt, {})
		local en = sa.enemigos[1]
		if en and en.avisando then aviso = true end
		if aviso and #sa.balas_enemigas > 0 then disparo = true break end
	end
	assert(aviso and disparo, "el enemigo armado no avisó antes de disparar")
	print("enemigos por nivel: bien")
end

-- el ojo de los Hill: la mirada avisa y luego dispara; el mapa estelar une estrellas con rayos
do
	local so = L.nuevo({}, math.random)
	so.prueba = { nivel = nivel_de("LOS HILL 1961"), dano = true }
	L.empezar_partida(so)
	for _ = 1, 200 do L.actualizar(so, dt, {}) end
	so.tiempo_nivel, so.enemigos = 999, {}
	for _ = 1, 60 * 30 do L.actualizar(so, dt, {}); if so.jefe and so.jefe.llego then break end end
	local j = so.jefe
	assert(j and j.tipo == "ojo", "no llegó el ojo")
	-- fase 1: al abrir, primero la línea de aviso y recién después las balas
	j.cerrado, j.parpado, j.mirada = true, 0, nil
	so.balas_enemigas, so.invencible = {}, 99
	L.actualizar(so, dt, {})
	assert(not j.cerrado and j.mirada, "al abrir el ojo no empezó la mirada")
	assert(#j.lineas == 1 and j.lineas[1].aviso, "la mirada no marcó su línea")
	local vistas = 0
	for _ = 1, math.floor(L.MIRADA_AVISO / dt) - 2 do
		L.actualizar(so, dt, {})
		for _, b in ipairs(so.balas_enemigas) do if math.abs(b.vx) > 40 then vistas = vistas + 1 end end
	end
	assert(vistas == 0, "la mirada disparó antes de terminar el aviso")
	for _ = 1, 30 do L.actualizar(so, dt, {}) end
	local rapidas = 0
	for _, b in ipairs(so.balas_enemigas) do if math.abs(b.vx) + math.abs(b.vy) > 40 then rapidas = rapidas + 1 end end
	assert(rapidas >= 2, "la mirada no soltó su ráfaga")
	-- fase 2: el mapa siembra seis estrellas que quedan quietas y el rayo daña
	j.vida = j.maximo * 0.6
	for _ = 1, 60 * 4 do L.actualizar(so, dt, {}) end
	assert(j.fase_n == 2, "no pasó a la fase 2")
	j.cerrado, j.parpado, j.mapa = false, 0, nil
	so.balas_enemigas = {}
	L.actualizar(so, dt, {})
	assert(j.cerrado and j.mapa and #j.mapa.estrellas == 6, "al cerrar en la fase 2 no sembró el mapa")
	for _ = 1, math.floor((0.45 + L.MAPA_AVISO + 0.1) / dt) do L.actualizar(so, dt, {}) end
	local e1, e3 = j.mapa.estrellas[1], j.mapa.estrellas[3]
	assert(e1.vx == 0 and e1.vy == 0, "la estrella no quedó quieta")
	local rayos = 0
	for _, l in ipairs(j.lineas) do if not l.aviso then rayos = rayos + 1 end end
	assert(rayos > 0, "las líneas del mapa no se volvieron rayos")
	-- la nave justo en medio de un rayo pierde una vida
	so.invencible, so.escudo = 0, 0
	so.nave.oculta, so.nave.entrando = nil, nil
	so.nave.x, so.nave.y = (e1.x + e3.x) / 2 - 3, (e1.y + e3.y) / 2 - 2
	local vidas = so.vidas
	L.actualizar(so, dt, {})
	assert(so.vidas == vidas - 1, "el rayo del mapa no dañó a la nave")
	for _ = 1, 60 * 2 do L.actualizar(so, dt, {}) end
	assert(not j.mapa, "el mapa no terminó")
	print("ojo de los Hill: bien")
end

-- disparo cargado en vuelo y los poderes nuevos
do
	local sp = L.nuevo({}, math.random)
	sp.prueba = { nivel = 1 }
	L.empezar_partida(sp)
	for _ = 1, 200 do L.actualizar(sp, dt, {}) end
	assert(sp.estado == "jugando", "no empezó el nivel 1")
	sp.enemigos, sp.oleada = {}, 999
	-- mantener A sigue disparando y carga; al soltar sale el obús
	sp.balas = {}
	for _ = 1, math.floor((L.CARGA_MAX + 0.1) / dt) do L.actualizar(sp, dt, { a = true }) end
	local normales = #sp.balas
	assert(normales >= 4, "mientras carga dejó de disparar")
	L.actualizar(sp, dt, {})
	local obus
	for _, b in ipairs(sp.balas) do if b.obus then obus = b end end
	assert(obus and obus.dano >= 5, "en vuelo no salió el disparo cargado")
	-- todas las mejoras tienen su dibujo con la mira de radar
	for _, nombre in ipairs(D.MEJORAS) do
		local d = D.dibujos["mejora_" .. nombre]
		assert(d and #d == 7 and #d[1] == 7, "falta la mejora " .. nombre)
	end
	local function recoger(tipo)
		sp.mejoras = { { tipo = tipo, x = sp.nave.x, y = sp.nave.y } }
		L.actualizar(sp, dt, {})
		assert(#sp.mejoras == 0, "no se recogió " .. tipo)
		-- se guarda y se usa con Y
		assert(sp.poder == tipo, "no quedó guardado " .. tipo)
		L.actualizar(sp, dt, { poder = true, poder_pulsado = true })
		assert(sp.poder == nil, "Y no usó " .. tipo)
	end
	-- el escudo: no se activa solo, el nuevo reemplaza al guardado y Y lo activa
	sp.escudo = 0
	sp.mejoras = { { tipo = "mejora_escudo", x = sp.nave.x, y = sp.nave.y } }
	L.actualizar(sp, dt, {})
	assert(sp.escudo == 0 and sp.poder == "mejora_escudo", "el escudo se activó solo")
	sp.mejoras = { { tipo = "mejora_sonda", x = sp.nave.x, y = sp.nave.y } }
	L.actualizar(sp, dt, {})
	assert(sp.poder == "mejora_sonda" and not sp.sonda, "la sonda no reemplazó al escudo guardado")
	sp.poder = "mejora_escudo"
	L.actualizar(sp, dt, { poder = true, poder_pulsado = true })
	assert(sp.escudo > 5, "Y no activó el escudo")
	sp.escudo = 0
	-- tiempo perdido: las balas enemigas van más lentas
	sp.balas_enemigas = { { x = 60, y = 30, vx = -30, vy = 0 } }
	recoger("mejora_tiempo")
	local x0 = sp.balas_enemigas[1].x
	L.actualizar(sp, dt, {})
	assert(math.abs(sp.balas_enemigas[1].x - x0) < 30 * dt * 0.5, "el tiempo perdido no frenó las balas")
	sp.lento = 0
	-- sonda: acompaña y dispara
	sp.balas = {}
	recoger("mejora_sonda")
	for _ = 1, 40 do L.actualizar(sp, dt, {}) end
	assert(sp.sonda and #sp.balas >= 1, "la sonda no disparó")
	sp.sonda = nil
	-- abducción: atrae mejoras, se traga balas del cono y al final las devuelve
	recoger("mejora_abduccion")
	local n = sp.nave
	sp.balas_enemigas = { { x = n.x + 12, y = n.y + 2, vx = -1, vy = 0 } }
	L.actualizar(sp, dt, {})
	assert(#sp.balas_enemigas == 0 and sp.abduccion < L.ABDUCCION - 0.5 and sp.abducidas == 1, "la abducción no se tragó la bala")
	sp.mejoras = { { tipo = "mejora_vida", x = n.x + 25, y = n.y } }
	local x1 = sp.mejoras[1].x
	for _ = 1, 10 do L.actualizar(sp, dt, {}) end
	assert(sp.mejoras[1] == nil or sp.mejoras[1].x < x1 - 4, "la abducción no atrajo la mejora")
	sp.balas = {}
	sp.abducidas = 5
	sp.abduccion = dt / 2
	L.actualizar(sp, dt, {})
	assert(#sp.balas >= 5 and sp.abducidas == 0, "la abducción no devolvió lo tragado: " .. #sp.balas)
	-- ya no hay bengalas
	for _, nombre in ipairs(D.MEJORAS) do assert(nombre ~= "bengala", "quedaron bengalas") end
	print("poderes nuevos: bien")
end

-- la historia: el prólogo al empezar, el mapa tras cada jefe (se pasa con A) y el informe
do
	local sh = L.nuevo({}, math.random)
	empezar_con_prologo(sh)
	assert(sh.estado == "prologo" and sh.pagina == 1, "la partida no empezó con el prólogo")
	for _ = 1, 50 do L.actualizar(sh, dt, {}) end
	L.actualizar(sh, dt, { a_pulsado = true })
	assert(sh.pagina == 2, "A no pasó la página del prólogo")
	for _ = 1, math.floor((L.PAGINA + 0.2) / dt) do L.actualizar(sh, dt, {}) end
	assert(sh.estado == "inicio_nivel" and sh.nivel == 1, "tras el prólogo no empezó el nivel 1")
	-- cada nivel tiene su informe que cabe en el cartel, y cada jefe una estrella y una frase
	for i, n in ipairs(D.niveles) do
		assert(n.informe and #n.informe <= 19, "el informe del nivel " .. i .. " falta o no cabe")
		assert(D.historia.piezas[i] and D.historia.tras_jefe[i], "al nivel " .. i .. " le falta su pieza del mapa")
	end
	-- vencido el jefe, el mapa muestra la pieza de ese nivel y luego sigue el siguiente
	sh.estado, sh.t = "nivel_superado", 0
	for _ = 1, math.floor((L.SUPERADO + 0.1) / dt) do L.actualizar(sh, dt, {}) end
	assert(sh.estado == "mapa" and sh.pieza == 1, "no apareció el mapa tras el jefe")
	for _ = 1, 50 do L.actualizar(sh, dt, {}) end
	L.actualizar(sh, dt, { a_pulsado = true })
	assert(sh.estado == "inicio_nivel" and sh.nivel == 2, "del mapa no pasó al nivel 2")
	print("historia: bien")
end

print("todo bien")

-- Órbita 84: shooter de naves al estilo de los celulares de antes.
-- Pantalla de 84x48 a dos colores, escalada sin suavizado.

local D = require("datos")
local L = require("logica")

local ANCHO, ALTO = D.ANCHO, D.ALTO
local Fondos = require("fondos")
local Portada = require("portada")
local Tactil = require("tactil")
local Puente = require("puente")
local Idioma = require("idioma")
local tr = Idioma.t
local imagenes_medio, tono_medio = {}, nil
local contorno_de
local nave_elegida = 1
local lienzo, imagenes, sonidos, s
-- transiciones: foto guarda la última pantalla vieja; mezcla junta la pantalla y la cortina
local foto, mezcla, transicion, ultimo_estado, ultima_prueba
local paleta = 1
local silencio = false
local mando
local musica_titulo
local anterior = {}
local entrada_actual = {}
local silencio_externo = false -- YouTube apagó el sonido
local primer_cuadro = false

-- ---------- guardado (récord y preferencias)

local function cargar_ajustes()
	local tabla = {}
	-- dentro de YouTube los ajustes vienen de su nube; si no, del archivo local
	local lineas = Puente.activo and Puente.lineas()
	if not lineas and love.filesystem.getInfo("ajustes.txt") then
		lineas = {}
		for linea in love.filesystem.lines("ajustes.txt") do lineas[#lineas + 1] = linea end
	end
	if lineas then
		for _, linea in ipairs(lineas) do
			-- puesto=ABC:12340 (versiones viejas) o puesto=ABC:12340:nave:nivel:vuelta
			local nombre, puntos, resto = linea:match("^puesto=(%w%w%w):(%d+)(.*)$")
			if nombre then
				local nave, nivel, ciclo = resto:match("^:(%d+):(%d+):(%d+)$")
				tabla[#tabla + 1] = { nombre = nombre, puntos = tonumber(puntos), nave = tonumber(nave), nivel = tonumber(nivel), ciclo = tonumber(ciclo) }
			end
			local clave, valor = linea:match("^(%w+)=(%d+)$")
			-- (récord de la versión anterior, sin iniciales)
			if clave == "record" and tonumber(valor) > 0 and #tabla == 0 then
				tabla[1] = { nombre = "???", puntos = tonumber(valor) }
			end
			if clave == "paleta" then paleta = math.max(1, math.min(#D.paletas, tonumber(valor))) end
			if clave == "silencio" then silencio = valor == "1" end
			if clave == "nave" then nave_elegida = tonumber(valor) end
			local idioma = linea:match("^idioma=(%a+)$")
			if idioma then Idioma.elegir(idioma) end
		end
	end
	table.sort(tabla, function(a, b) return a.puntos > b.puntos end)
	return tabla
end

local function guardar_ajustes()
	local lineas = { ("paleta=%d"):format(paleta), ("silencio=%d"):format(silencio and 1 or 0) }
	if s and s.nave_elegida then lineas[#lineas + 1] = ("nave=%d"):format(s.nave_elegida) end
	lineas[#lineas + 1] = "idioma=" .. Idioma.actual
	for _, f in ipairs(s and s.tabla or {}) do
		if f.nivel then
			lineas[#lineas + 1] = ("puesto=%s:%d:%d:%d:%d"):format(f.nombre, f.puntos, f.nave or 1, f.nivel, f.ciclo or 1)
		else
			lineas[#lineas + 1] = ("puesto=%s:%d"):format(f.nombre, f.puntos)
		end
	end
	love.filesystem.write("ajustes.txt", table.concat(lineas, "\n") .. "\n")
	Puente.avisar("guardar", table.concat(lineas, "|"))
end

-- ---------- imágenes: cada dibujo pasa a una imagen blanca que se tiñe al dibujar

-- marca: "#" para la tinta, "+" para la capa de tono medio
local function hacer_imagen(filas, marca)
	marca = marca or "#"
	local datos = love.image.newImageData(#filas[1], #filas)
	for y, fila in ipairs(filas) do
		for x = 1, #fila do
			if fila:sub(x, x) == marca then
				datos:setPixel(x - 1, y - 1, 1, 1, 1, 1)
			end
		end
	end
	local img = love.graphics.newImage(datos)
	img:setFilter("nearest", "nearest")
	return img
end

-- ---------- sonidos: pitidos de onda cuadrada, como el altavoz de un celular

local function pitido(notas, duracion_nota, tipo)
	local frecuencia = 22050
	local por_nota = math.floor(frecuencia * duracion_nota)
	local datos = love.sound.newSoundData(por_nota * #notas, frecuencia, 16, 1)
	local i = 0
	for _, f in ipairs(notas) do
		for n = 0, por_nota - 1 do
			local v
			if tipo == "ruido" then
				v = (love.math.random() * 2 - 1) * (1 - n / por_nota)
			elseif f == 0 then
				v = 0
			else
				v = ((n * f / frecuencia) % 1 < 0.5) and 1 or -1
			end
			datos:setSample(i, v * 0.18)
			i = i + 1
		end
	end
	return love.audio.newSource(datos, "static")
end

-- convierte "A4", "G#5" o "-" en frecuencia (La4 = 440 Hz)
local SEMITONO = { C = -9, D = -7, E = -5, F = -4, G = -2, A = 0, B = 2 }
local function frecuencia(nota)
	if nota == "-" then return 0 end
	local letra, alteracion, octava = nota:match("^([A-G])(#?)(%d)$")
	local n = SEMITONO[letra] + (alteracion == "#" and 1 or 0) + (tonumber(octava) - 4) * 12
	return 440 * 2 ^ (n / 12)
end

-- melodía tipo tono de celular: onda cuadrada con un corte breve entre notas
local function melodia(def)
	local muestras = 22050
	local corchea = 60 / def.tempo / 2
	local partes, total = {}, 0
	for nota, duracion in def.notas:gmatch("([%w#%-]+):(%d+)") do
		local largo = math.floor(muestras * corchea * tonumber(duracion))
		partes[#partes + 1] = { frecuencia(nota), largo }
		total = total + largo
	end
	local datos = love.sound.newSoundData(total, muestras, 16, 1)
	local i = 0
	for _, p in ipairs(partes) do
		local f, largo = p[1], p[2]
		for n = 0, largo - 1 do
			local v = 0
			if f > 0 and n < largo * 0.85 then
				v = ((n * f / muestras) % 1 < 0.5) and 0.12 or -0.12
			end
			datos:setSample(i, v)
			i = i + 1
		end
	end
	return love.audio.newSource(datos, "static")
end

local function crear_sonidos()
	sonidos = {
		disparo = pitido({ 1760 }, 0.03),
		rayo = pitido({ 880, 1320, 1760, 2349 }, 0.04),
		pulso = pitido({ 2349, 1760, 1175, 880, 587 }, 0.035),
		golpe = pitido({ 440 }, 0.03),
		explosion = pitido({ 1 }, 0.18, "ruido"),
		mejora = pitido({ 1047, 1319, 1568, 2093 }, 0.05),
		dano = pitido({ 330, 220, 147 }, 0.08),
		jefe = pitido({ 440, 0, 440, 0, 440, 0, 330 }, 0.1),
		victoria = melodia(D.melodias.victoria),
		inicio = melodia(D.melodias.nivel),
		fin = pitido({ 392, 330, 262, 196 }, 0.15),
		menu = pitido({ 1319 }, 0.04),
		rebote = pitido({ 2637 }, 0.02),
		embestida = pitido({ 196, 220, 247, 262 }, 0.05),
		salto = pitido({ 523, 659, 784 }, 0.025),
		tic = pitido({ 2093 }, 0.015),
		tac = pitido({ 1568 }, 0.015),
	}
	musica_titulo = melodia(D.melodias.titulo)
	musica_titulo:setLooping(true)
end

-- ---------- controles: teclado y mando juntos

local function leer_entrada()
	local k = love.keyboard.isDown
	local function boton(b)
		return mando and mando:isGamepadDown(b)
	end
	local function eje(nombre, signo)
		if not mando then return false end
		local v = mando:getGamepadAxis(nombre)
		return v * signo > 0.5
	end
	local e = {
		arriba = k("up", "w") or boton("dpup") or eje("lefty", -1),
		abajo = k("down", "s") or boton("dpdown") or eje("lefty", 1),
		izquierda = k("left", "a") or boton("dpleft") or eje("leftx", -1),
		derecha = k("right", "d") or boton("dpright") or eje("leftx", 1),
		a = k("z", "j", "space") or boton("a"),
		b = k("x", "k") or boton("b"),
		poder = k("c", "l") or boton("y") or boton("x"),
		start = k("return", "kpenter") or boton("start"),
		select = k("tab", "backspace") or boton("back"),
	}
	-- los controles táctiles se suman a teclado y mando
	for nombre in pairs(Tactil.leer()) do e[nombre] = true end
	-- "pulsado" solo el primer cuadro en que se aprieta
	for _, nombre in ipairs({ "a", "b", "poder", "start", "select", "arriba", "abajo", "izquierda", "derecha" }) do
		e[nombre .. "_pulsado"] = e[nombre] and not anterior[nombre]
		anterior[nombre] = e[nombre]
	end
	return e
end

-- ---------- dibujo

local function color(c, alfa)
	love.graphics.setColor(c[1], c[2], c[3], alfa or 1)
end

-- dibuja un sprite: primero la capa de tono medio (si tiene) y encima la tinta
local function dibujar(nombre, x, y, escala)
	x, y, escala = math.floor(x + 0.5), math.floor(y + 0.5), escala or 1
	local medio = imagenes_medio[nombre]
	if medio and tono_medio then
		local r, g, b, a = love.graphics.getColor()
		love.graphics.setColor(tono_medio)
		love.graphics.draw(medio, x, y, 0, escala, escala)
		love.graphics.setColor(r, g, b, a)
	end
	love.graphics.draw(imagenes[nombre], x, y, 0, escala, escala)
end

-- contorno de un dibujo para el escudo de los jefes: los píxeles a 2 (cerca) y a 3 (lejos) del
-- dibujo, cada uno con su ángulo alrededor del centro para que los trazos den la vuelta
local contornos = {}
function contorno_de(nombre)
	if contornos[nombre] then return contornos[nombre] end
	local filas = D.dibujos[nombre]
	local w, h = #filas[1], #filas
	local lleno = {}
	for y, f in ipairs(filas) do
		for x = 1, w do
			if f:sub(x, x) ~= "." then lleno[(y - 1) * 1000 + (x - 1)] = true end
		end
	end
	local function distancia(x, y, r)
		for dy = -r, r do
			for dx = -r, r do
				if lleno[(y + dy) * 1000 + (x + dx)] then return true end
			end
		end
		return false
	end
	local c = { cerca = {}, lejos = {} }
	local cx, cy = w / 2 - 0.5, h / 2 - 0.5
	for y = -3, h + 2 do
		for x = -3, w + 2 do
			if not distancia(x, y, 1) then
				local a = math.atan2(y - cy, (x - cx) * 0.6) / (2 * math.pi) * 18
				if distancia(x, y, 2) then
					c.cerca[#c.cerca + 1] = { x, y, a }
				elseif distancia(x, y, 3) then
					c.lejos[#c.lejos + 1] = { x, y, a }
				end
			end
		end
	end
	contornos[nombre] = c
	return c
end

-- en el mar, la parte bajo la línea del agua se dibuja entera en tono medio
-- (salvo que un reflector lo alumbre: entonces va entero en tinta, porque se puede tocar)
local function dibujar_hundible(nombre, x, y, alumbrado)
	local a = s.nivel and D.niveles[s.nivel].agua
	if not a or alumbrado then
		return dibujar(nombre, x, y)
	end
	local xx, yy = math.floor(x + 0.5), math.floor(y + 0.5)
	if yy < a then
		love.graphics.setScissor(0, 0, ANCHO, a)
		dibujar(nombre, x, y)
	end
	if yy + #D.dibujos[nombre] > a then
		love.graphics.setScissor(0, a, ANCHO, ALTO - a)
		local r, g, b, al = love.graphics.getColor()
		love.graphics.setColor(tono_medio)
		if imagenes_medio[nombre] then love.graphics.draw(imagenes_medio[nombre], xx, yy) end
		love.graphics.draw(imagenes[nombre], xx, yy)
		love.graphics.setColor(r, g, b, al)
	end
	love.graphics.setScissor()
end

-- si el dibujo tiene segundo cuadro ("_b"), alterna entre los dos
local function animado(nombre, rapidez)
	if imagenes[nombre .. "_b"] and math.floor(s.t * (rapidez or 4)) % 2 == 1 then
		return nombre .. "_b"
	end
	return nombre
end

local function texto(cadena, x, y)
	cadena = tr(cadena):upper()
	for i = 1, #cadena do
		local c = cadena:sub(i, i)
		if imagenes["letra_" .. c] then
			love.graphics.draw(imagenes["letra_" .. c], x + (i - 1) * 4, y)
		end
	end
end

local function texto_centrado(cadena, y)
	cadena = tr(cadena)
	texto(cadena, math.floor((ANCHO - #cadena * 4 + 1) / 2), y)
end

-- contorno de un píxel hecho con cuatro rectángulos (exacto en el lienzo de 84x48)
local function marco(x, y, w, h)
	love.graphics.rectangle("fill", x, y, w, 1)
	love.graphics.rectangle("fill", x, y + h - 1, w, 1)
	love.graphics.rectangle("fill", x, y, 1, h)
	love.graphics.rectangle("fill", x + w - 1, y, 1, h)
end

-- el marco de todos los menús ("ficha"): caja con franja de título en negativo y, si hay pie,
-- una línea punteada en tono medio que lo separa. Devuelve dónde empieza el cuerpo.
local paleta_juego
local function ficha(titulo, alto_cuerpo, pie, ancho, centro, pie_medio)
	local p = paleta_juego()
	local alto = 10 + alto_cuerpo + (pie and 8 or 0) + 2
	ancho = math.max(ancho or 68, #tr(titulo) * 4 + 7, pie and #tr(pie) * 4 + 7 or 0)
	ancho = math.min(ancho, ANCHO)
	local izq = math.floor((ANCHO - ancho) / 2)
	local arriba = math.max(0, math.min(ALTO - alto, (centro or 24) - math.floor(alto / 2)))
	local abajo = arriba + alto - 1
	color(p.fondo)
	love.graphics.rectangle("fill", izq, arriba, ancho, alto)
	color(p.tinta)
	marco(izq, arriba, ancho, alto)
	love.graphics.rectangle("fill", izq, arriba, ancho, 8)
	color(p.fondo)
	texto_centrado(titulo, arriba + 2)
	if pie then
		color(tono_medio)
		for x = izq + 2, izq + ancho - 3 do
			if x % 2 == 0 then love.graphics.rectangle("fill", x, abajo - 9, 1, 1) end
		end
		color(pie_medio and tono_medio or p.tinta)
		texto_centrado(pie, abajo - 7)
	end
	color(p.tinta)
	return arriba + 10, izq, ancho
end

-- opciones con cursor: la elegida en tinta con '>' que titila, las otras en tono medio
local function opciones(lista, elegida, y)
	local largo = 0
	for _, o in ipairs(lista) do largo = math.max(largo, #tr(o)) end
	local x = math.floor((ANCHO - (largo * 4 - 1)) / 2) + 3
	for i, o in ipairs(lista) do
		if i == elegida then
			color(paleta_juego().tinta)
			if math.floor(s.t * 4) % 2 == 0 then texto(">", x - 7, y) end
		else
			color(tono_medio)
		end
		texto(o, x, y)
		y = y + 7
	end
	color(paleta_juego().tinta)
end

-- menú de la portada: principal, nave, records y opciones (ver L.actualizar_menu)
local function dibujar_menu(p)
	local m = s.menu
	local elegida = L.NAVES[s.nave_elegida or 1]
	if m.hoja == "principal" then
		local fila = L.MENU[m.fila]
		local pies = { jugar = "START: JUGAR", nave = "< > " .. tr(elegida.detalle), records = "LOS 10 MEJORES", opciones = "SONIDO COLOR IDIOMA" }
		local y0 = ficha("ORBITA 84", 28, pies[fila], 84, 24, true)
		opciones({ "JUGAR", tr("NAVE") .. " " .. tr(elegida.nombre), "RECORDS", "OPCIONES" }, m.fila, y0)
	elseif m.hoja == "nave" then
		local y0 = ficha("NAVE", 25, "A: LISTO", 76)
		texto("<", 22, y0 + 3)
		texto(">", 59, y0 + 3)
		dibujar(elegida.dibujo, 35, y0, 2)
		texto_centrado(elegida.nombre, y0 + 12)
		color(tono_medio)
		texto_centrado(elegida.detalle, y0 + 19)
		color(p.tinta)
	elseif m.hoja == "opciones" then
		local y0 = ficha("OPCIONES", 28, "< > CAMBIA", 84, 24, true)
		opciones({
			tr("SONIDO") .. ": " .. tr(silencio and "NO" or "SI"),
			tr("COLOR") .. ": " .. tr(D.paletas[paleta].nombre),
			tr("IDIOMA") .. ": " .. tr(Idioma.NOMBRES[Idioma.actual]),
			"VOLVER",
		}, m.fila, y0)
	else
		-- records: cinco por página con puesto, iniciales, puntaje, nave y hasta dónde llegó
		local total = L.paginas_records()
		local y0 = ficha(tr("RECORDS") .. " " .. m.pagina .. "/" .. total, 35, nil, 84, 24)
		if #s.tabla == 0 then
			color(tono_medio)
			texto_centrado("SIN RECORDS", y0 + 14)
			color(p.tinta)
			return
		end
		for i = 1, 5 do
			local puesto = (m.pagina - 1) * 5 + i
			local f = s.tabla[puesto]
			local y = y0 + (i - 1) * 7
			if f then
				texto(("%2d"):format(puesto), 2, y)
				texto(f.nombre, 12, y)
				texto(("%6d"):format(f.puntos), 28, y)
				if f.nave and L.NAVES[f.nave] then dibujar(L.NAVES[f.nave].dibujo, 54, y) end
				if f.nivel then
					local donde = (f.ciclo or 1) > 1 and (f.ciclo .. "-" .. f.nivel) or tr("N" .. f.nivel)
					color(tono_medio)
					texto(donde, 82 - #donde * 4, y)
					color(p.tinta)
				end
			else
				color(tono_medio)
				texto(("%2d ---"):format(puesto), 2, y)
				color(p.tinta)
			end
		end
	end
end

local function marcador()
	-- vidas y especial como contadores: un ícono con su número
	dibujar("vida", 0, 1)
	texto(tostring(math.max(0, math.min(9, s.vidas))), 4, 0)
	dibujar(L.nave_actual(s).especial, 10, 0)
	texto(tostring(math.min(9, s.rayos)), 14, 0)
	texto(("%05d"):format(s.puntos % 100000), 64, 0)
	-- la ranura del poder de cápsula guardado: una Y y dos rayas en tono medio con el
	-- ícono adentro (vacía si no hay nada guardado)
	do
		local r, g, b, a = love.graphics.getColor()
		color(tono_medio)
		texto("Y", 21, 0)
		love.graphics.rectangle("fill", 25, 0, 1, 5)
		love.graphics.rectangle("fill", 31, 0, 1, 5)
		love.graphics.setColor(r, g, b, a)
		if s.poder then dibujar("icono_" .. s.poder:sub(8), 27, 0) end
	end
	-- poderes con tiempo activos: su ícono entre los rayos y los puntos (titila al acabarse).
	-- Si no hay ninguno, en qué nivel vamos en tono medio ("N4"; en inglés "L4").
	-- Con el jefe en pantalla ahí va su barra de vida
	local activos = {}
	for _, a in ipairs({ { "triple", s.triple }, { "escudo", s.escudo }, { "tiempo", s.lento },
		{ "sonda", s.sonda and s.sonda.t }, { "abduccion", s.abduccion } }) do
		if (a[2] or 0) > 0 and #activos < 3 then activos[#activos + 1] = a end
	end
	if s.jefe and s.jefe.llego then
		-- nada: la barra del jefe
	elseif #activos > 0 then
		for i, a in ipairs(activos) do
			if a[2] > 1.5 or math.floor(s.t * 8) % 2 == 0 then
				dibujar("icono_" .. a[1], 44 + (i - 1) * 4, 0)
			end
		end
	elseif s.nivel then
		local r, g, b, a = love.graphics.getColor()
		color(tono_medio)
		local cual = tr("N" .. s.nivel)
		texto(cual, 53 - #cual * 2, 0)
		love.graphics.setColor(r, g, b, a)
	end
	love.graphics.rectangle("fill", 0, D.TECHO - 2, ANCHO, 1)
	-- tiempo perdido: barra punteada de lo que queda bajo la línea y cuatro esquinas que se cierran
	if s.lento > 0 then
		local r, g, b, a = love.graphics.getColor()
		color(tono_medio)
		local resto = s.lento / L.TIEMPO_PERDIDO
		for x = 0, math.floor(ANCHO * resto) - 1, 2 do
			love.graphics.rectangle("fill", x, D.TECHO - 1, 1, 1)
		end
		local largo = 3 + math.floor(6 * resto + 0.5)
		love.graphics.rectangle("fill", 0, D.TECHO + 1, largo, 1)
		love.graphics.rectangle("fill", 0, D.TECHO + 1, 1, largo)
		love.graphics.rectangle("fill", ANCHO - largo, D.TECHO + 1, largo, 1)
		love.graphics.rectangle("fill", ANCHO - 1, D.TECHO + 1, 1, largo)
		love.graphics.rectangle("fill", 0, ALTO - 1, largo, 1)
		love.graphics.rectangle("fill", 0, ALTO - largo, 1, largo)
		love.graphics.rectangle("fill", ANCHO - largo, ALTO - 1, largo, 1)
		love.graphics.rectangle("fill", ANCHO - 1, ALTO - largo, 1, largo)
		love.graphics.setColor(r, g, b, a)
	end
end

-- modo de prueba: cajas de choque. Debajo de los dibujos, lo que daña se rellena en
-- tono medio; encima, un marco alrededor del lugar donde el jefe recibe daño y,
-- en las balas con dibujo grande, el punto que de verdad golpea
local function rellenar(x, y, w, h)
	love.graphics.rectangle("fill", math.floor(x + 0.5), math.floor(y + 0.5), math.max(1, math.floor(w + 0.5)), math.max(1, math.floor(h + 0.5)))
end

-- el remolino: dos brazos de espiral que giran (el frente va hacia la izquierda, como su
-- dibujo) y por los que el agua se va metiendo hacia el centro y hacia abajo, más el borde
-- del embudo. Todo en tono medio porque no se toca.
local function particulas_remolino(en)
	local cx, a = en.x + en.w / 2, math.floor(en.y)
	color(tono_medio)
	local function punto(x, y) love.graphics.rectangle("fill", math.floor(x + 0.5), math.floor(y + 0.5), 1, 1) end
	for brazo = 0, 1 do
		for j = 0, 11 do
			local u = (j / 12 + s.t * 0.35) % 1 -- 0 afuera, 1 en el fondo del embudo
			local radio = 1.5 + (1 - u) * 11
			local angulo = s.t * 3 + brazo * math.pi + u * 5.5
			local x, y = cx + math.cos(angulo) * radio, a + 1 + u * 4 + math.sin(angulo) * radio * 0.3
			punto(x, y)
			-- estela: un píxel detrás, del lado de donde viene
			if radio > 4 then punto(x + (math.sin(angulo) > 0 and 1 or -1), y) end
		end
	end
	-- borde del embudo: un anillo de gotas que da vueltas sobre la línea del agua
	for k = 0, 7 do
		local angulo = s.t * 2 + k * math.pi / 4
		if math.sin(angulo) < 0 then punto(cx + math.cos(angulo) * 13, a - 1 + math.sin(angulo) * 1.5) end
	end
end

local function choques_debajo()
	color(tono_medio)
	if not s.nave.oculta then
		local d = D.dibujos[L.forma_nave(s)]
		rellenar(s.nave.x + 1, s.nave.y + 1, #d[1] - 2, #d - 2)
	end
	for _, en in ipairs(s.enemigos) do
		if not en.muerto and not en.bajo_agua then rellenar(en.x, en.y, en.w, en.h) end
	end
	local j = s.jefe
	if j then
		if not j.sumergido then rellenar(j.x, j.y, j.w, j.h) end
		for _, q in ipairs(j.bloques) do rellenar(q.x, q.y, q.w, q.h) end
	end
end

local function choques_encima(p)
	for _, b in ipairs(s.balas_enemigas) do
		if b.forma then
			color(p.fondo)
			rellenar(b.x, b.y, 2, 2)
		end
	end
	-- la caja de la nave queda tapada por su dibujo: se marca su borde en tono medio
	if not s.nave.oculta then
		local d = D.dibujos[L.forma_nave(s)]
		color(tono_medio)
		marco(math.floor(s.nave.x + 0.5) + 1, math.floor(s.nave.y + 0.5) + 1, #d[1] - 2, #d - 2)
	end
	color(p.tinta)
	if s.jefe then
		local bx, by, bw, bh = L.blanco_jefe(s.jefe)
		marco(math.floor(bx + 0.5) - 1, math.floor(by + 0.5) - 1, math.floor(bw + 0.5) + 2, math.floor(bh + 0.5) + 2)
	end
end

-- en los niveles "invertido" (Golfo Nuevo, de noche) la pantalla se da vuelta: fondo con la
-- tinta y lo jugable con el color del fondo. Al entrar, parpadea un momento antes de quedar así
local invertidas = {}
local FUERA_DEL_NIVEL = { titulo = true, iniciales = true, fin = true, ronda_completa = true, prologo = true, mapa = true, final = true }
function paleta_juego()
	local p = D.paletas[paleta]
	local datos = s and s.nivel and D.niveles[s.nivel]
	if not (datos and datos.invertido) or FUERA_DEL_NIVEL[s.estado] then return p end
	if s.estado == "inicio_nivel" and s.t < 0.6 and math.floor(s.t * 10) % 2 == 0 then return p end
	if not invertidas[paleta] then
		invertidas[paleta] = { nombre = p.nombre, fondo = p.tinta, tinta = p.fondo, marco = p.marco }
	end
	return invertidas[paleta]
end

local function escena()
	local p = paleta_juego()
	tono_medio = Fondos.tono(p, 0.45)
	color(p.fondo)
	love.graphics.rectangle("fill", 0, 0, ANCHO, ALTO)
	color(p.tinta)

	if s.estado == "titulo" and s.prueba then
		local pr = s.prueba
		local ayudas = { "START: JUGAR", "SELECT: JEFE", "B: SALIR" }
		local y0, izq, ancho = ficha("MODO PRUEBA", 24, ayudas[math.floor(s.t / 1.5) % 3 + 1], 76)
		local si = function(v) return v and "SI" or "NO" end
		local valores = {
			nivel = "NIVEL " .. pr.nivel,
			nave = L.nave_actual(s).nombre,
			vuelta = "VUELTA " .. (pr.vuelta or 1),
			dano = "DANO: " .. si(pr.dano),
			choques = "CHOQUES: " .. si(pr.choques),
			lento = "LENTO: " .. ({ "NO", "1/2", "1/4" })[pr.lento or 1],
		}
		-- se ven cuatro filas; la elegida va en tinta y entre flechas, las otras en tono medio.
		-- Unas flechitas a la derecha avisan si hay más filas arriba o abajo
		local elegida, total = pr.fila or 1, #L.FILAS_PRUEBA
		local primera = math.max(1, math.min(total - 3, elegida - 1))
		for k = 0, 3 do
			local i = primera + k
			local fila, y = L.FILAS_PRUEBA[i], y0 + k * 6
			if i == elegida then
				color(p.tinta)
				texto_centrado("< " .. valores[fila] .. " >", y)
			else
				color(tono_medio)
				texto_centrado(valores[fila], y)
			end
		end
		color(tono_medio)
		local fx = izq + ancho - 5
		if primera > 1 then
			love.graphics.rectangle("fill", fx + 1, y0, 1, 1)
			love.graphics.rectangle("fill", fx, y0 + 1, 3, 1)
		end
		if primera + 3 < total then
			love.graphics.rectangle("fill", fx, y0 + 21, 3, 1)
			love.graphics.rectangle("fill", fx + 1, y0 + 22, 1, 1)
		end
		color(p.tinta)
		return
	end

	if s.estado == "iniciales" then
		local y0 = ficha("NUEVO RECORD!", 23, "START GUARDA")
		texto_centrado(s.puntos, y0)
		color(tono_medio)
		texto_centrado("TUS INICIALES", y0 + 7)
		color(p.tinta)
		for i, n in ipairs(s.letras) do
			local x = 30 + (i - 1) * 9
			texto(L.ABECEDARIO:sub(n, n), x + 2, y0 + 14)
			if i == s.letra and math.floor(s.t * 4) % 2 == 0 then
				love.graphics.rectangle("fill", x + 1, y0 + 20, 5, 1)
			end
		end
		return
	end

	if s.estado == "titulo" then
		Portada.dibujar(s, {
			dibujar = dibujar, texto = texto, centrado = texto_centrado,
			tinta = p.tinta, medio = tono_medio, suave = Fondos.tono(p, 0.22),
			nave = L.forma_nave(s),
		})
		-- al cambiar de nave con izquierda/derecha se muestra cuál quedó
		if (s.aviso_idioma or 0) > 0 then
			local y0 = ficha("IDIOMA", 7, nil, 52)
			texto_centrado(Idioma.NOMBRES[Idioma.actual], y0)
		elseif not s.prueba and (s.aviso_nave or 0) > 0 then
			local elegida = L.NAVES[s.nave_elegida or 1]
			local y0 = ficha("NAVE", 25, "PULSA START", 76)
			texto("<", 22, y0 + 3)
			texto(">", 59, y0 + 3)
			dibujar(elegida.dibujo, 35, y0, 2)
			texto_centrado(elegida.nombre, y0 + 12)
			color(tono_medio)
			texto_centrado(elegida.detalle, y0 + 19)
			color(p.tinta)
		end
		return
	end

	if s.estado == "menu" then
		Portada.dibujar(s, {
			dibujar = dibujar, texto = texto, centrado = texto_centrado,
			tinta = p.tinta, medio = tono_medio, suave = Fondos.tono(p, 0.22),
			nave = L.forma_nave(s),
		})
		dibujar_menu(p)
		return
	end

	-- la historia: prólogo y final son carteles con estrellas; las líneas con "+" van en tono medio
	if s.estado == "prologo" or s.estado == "final" then
		color(Fondos.tono(p, 0.22))
		for _, st in ipairs(s.estrellas) do love.graphics.rectangle("fill", math.floor(st.x), math.floor(st.y), 1, 1) end
		local pagina = D.historia[s.estado][s.pagina] or {}
		local alto = 7 * #pagina + 3
		local ancho = 60
		for _, l in ipairs(pagina) do ancho = math.max(ancho, #tr((l:gsub("^%+", ""))) * 4 + 5) end
		local izq, arriba = math.floor((ANCHO - ancho) / 2), math.floor(25 - alto / 2)
		color(p.tinta)
		marco(izq, arriba, ancho, alto)
		for i, l in ipairs(pagina) do
			-- las líneas aparecen de a una, como un teletipo
			if s.t > (i - 1) * 0.45 then
				color(l:sub(1, 1) == "+" and tono_medio or p.tinta)
				texto_centrado((l:gsub("^%+", "")), arriba + 2 + 7 * (i - 1))
			end
		end
		color(p.tinta)
		return
	end

	-- el mapa de Betty Hill: una estrella por jefe vencido; desde Los Hill se ven las líneas
	if s.estado == "mapa" then
		local h = D.historia
		color(Fondos.tono(p, 0.22))
		for _, st in ipairs(s.estrellas) do love.graphics.rectangle("fill", math.floor(st.x), math.floor(st.y), 1, 1) end
		color(p.tinta)
		texto_centrado("PIEZA " .. s.pieza .. " DE " .. #D.niveles, 1)
		love.graphics.rectangle("fill", 0, 7, ANCHO, 1)
		local function lugar(i)
			local e = h.mapa[i]
			return 12 + math.floor(e[1] * 2.05 + 0.5), 11 + math.floor(e[2] * 1.75 + 0.5)
		end
		local prendidas, nueva = {}, {}
		for n = 1, s.pieza do
			for _, i in ipairs(h.piezas[n]) do prendidas[i] = true; nueva[i] = n == s.pieza end
		end
		local se_ve = s.pieza >= h.revela
		if se_ve then
			for _, l in ipairs(h.lineas) do
				local x1, y1 = lugar(l[1])
				local x2, y2 = lugar(l[2])
				color((prendidas[l[1]] and prendidas[l[2]]) and p.tinta or tono_medio)
				local pasos = math.max(math.abs(x2 - x1), math.abs(y2 - y1))
				for k = 2, pasos - 1, 2 do
					love.graphics.rectangle("fill", math.floor(x1 + (x2 - x1) * k / pasos + 0.5), math.floor(y1 + (y2 - y1) * k / pasos + 0.5), 1, 1)
				end
			end
		end
		for i, e in ipairs(h.mapa) do
			local x, y = lugar(i)
			if prendidas[i] then
				color(p.tinta)
				love.graphics.rectangle("fill", x, y, 1, 1)
				if e[3] or nueva[i] then
					color(e[3] and p.tinta or tono_medio)
					love.graphics.rectangle("fill", x - 1, y, 3, 1)
					love.graphics.rectangle("fill", x, y - 1, 1, 3)
				end
				-- la recién ganada lleva la mira de radar de las mejoras, que titila
				if nueva[i] and s.t > 0.5 and math.floor(s.t * 3) % 2 == 0 then
					color(p.tinta)
					-- cuatro esquinas de 2 px: (lado x, lado y) = (-1/+1, -1/+1)
					for _, d in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
						local cx, cy = x + 3 * d[1], y + 3 * d[2]
						love.graphics.rectangle("fill", math.min(cx, cx - d[1]), cy, 2, 1)
						love.graphics.rectangle("fill", cx, math.min(cy, cy - d[2]), 1, 2)
					end
				end
			elseif se_ve then
				color(tono_medio)
				love.graphics.rectangle("fill", x, y, 1, 1)
			end
		end
		color(p.tinta)
		if s.t > 0.8 then texto_centrado(h.tras_jefe[s.pieza] or "", 42) end
		return
	end

	-- ronda completa: seguir con más dificultad o terminar y anotar el puntaje
	if s.estado == "ronda_completa" then
		local y0 = ficha("RONDA " .. s.ciclo .. " COMPLETA", 30, nil, 76)
		texto_centrado(s.puntos, y0)
		color(tono_medio)
		texto_centrado("OTRA MAS DIFICIL?", y0 + 7)
		opciones({ "SEGUIR", "TERMINAR" }, s.opcion_ronda, y0 + 16)
		return
	end

	if s.estado == "fin" then
		local y0 = ficha(s.victoria and "MISION CUMPLIDA" or "FIN DEL JUEGO", s.victoria and 24 or 14, nil, 72)
		texto_centrado(s.puntos, y0)
		color(tono_medio)
		if s.puesto then
			texto_centrado("PUESTO " .. s.puesto .. " DE " .. #s.tabla, y0 + 7)
		else
			texto_centrado("MEJOR " .. s.record, y0 + 7)
		end
		color(p.tinta)
		-- el sello del caso: marco en tinta con otro en tono medio por dentro
		if s.victoria then
			local sello = tr("CASO CERRADO")
			local w = #sello * 4 + 5
			local x, y = math.floor((ANCHO - w) / 2), y0 + 15
			marco(x, y, w, 9)
			color(tono_medio)
			marco(x + 1, y + 1, w - 2, 7)
			color(p.tinta)
			texto_centrado(sello, y + 2)
		end
		return
	end

	-- partida: fondo del nivel, terreno y objetos
	Fondos.dibujar(s, p)
	-- el hielo se dibuja después de los enemigos: lo que nada debajo queda tapado por la placa
	local helado = D.niveles[s.nivel].hielo
	if not helado then Fondos.terreno(s, p) end
	if s.prueba and s.prueba.choques then
		choques_debajo()
		color(p.tinta)
	end
	for _, m in ipairs(s.mejoras) do
		if math.floor(s.t * 6) % 2 == 0 then
			dibujar(m.tipo, m.x, m.y)
		end
	end
	-- tiempo perdido: la silueta de cada enemigo en tono medio, un poco atrás
	if s.lento > 0 then
		color(tono_medio)
		for _, en in ipairs(s.enemigos) do
			local img = imagenes[en.tipo]
			if img and not en.bajo_agua then love.graphics.draw(img, math.floor(en.x + 3.5), math.floor(en.y + 0.5)) end
		end
		color(p.tinta)
	end
	for _, en in ipairs(s.enemigos) do
		if en.golpe <= 0 or math.floor(s.t * 30) % 2 == 0 then
			dibujar_hundible(animado(en.tipo, en.tipo == "rodante" and 8 or 4), en.x, en.y, en.alumbrado)
			-- enemigo armado a punto de disparar: marco en tono medio que titila
			if en.avisando and math.floor(s.t * 12) % 2 == 0 then
				color(tono_medio)
				marco(math.floor(en.x) - 1, math.floor(en.y) - 1, en.w + 2, en.h + 2)
				color(p.tinta)
			end
			if en.tipo == "torbellino" then
				particulas_remolino(en)
				color(p.tinta)
			end
			-- la luz del hielo deja una columna de puntos al subir
			if en.tipo == "luz" and not en.bajo_agua then
				local a = D.niveles[s.nivel].agua or D.ALTO
				color(tono_medio)
				for y = math.floor(en.y) + 6, a - 1, 2 do
					love.graphics.rectangle("fill", math.floor(en.x + 2.5), y, 1, 1)
				end
				color(p.tinta)
			end
			-- mira del francotirador: línea punteada que titila mientras apunta
			if en.apuntando and math.floor(s.t * 12) % 2 == 0 then
				for x = math.floor(en.x) - 4, 0, -4 do
					love.graphics.rectangle("fill", x, math.floor(en.y + 2.5), 2, 1)
				end
			end
		end
	end
	if s.jefe then
		for _, q in ipairs(s.jefe.bloques) do
			if q.dibujo then dibujar(q.dibujo, q.x, q.y) end
		end
	end
	if s.jefe and (s.jefe.golpe <= 0 or math.floor(s.t * 30) % 2 == 0) then
		local dx = s.jefe.sacudida and (math.floor(s.t * 24) % 2 * 2 - 1) or 0
		dibujar_hundible(s.jefe.dibujo, s.jefe.x + dx, s.jefe.y, s.jefe.alumbrado)
		-- el fantasma a cota de periscopio: el periscopio asoma sobre el agua
		if s.jefe.periscopio then
			dibujar("periscopio", s.jefe.x + dx + 9, D.niveles[s.nivel].agua - 3)
		end
	end
	-- cargas de profundidad: la carga en tinta (golpea) y, en tono medio, una columna
	-- punteada con un marco donde va a reventar
	for _, c in ipairs(s.cargas or {}) do
		color(tono_medio)
		for y = math.floor(c.y) + 3, math.floor(c.meta) - 3, 2 do
			love.graphics.rectangle("fill", math.floor(c.x), y, 1, 1)
		end
		marco(math.floor(c.x) - 3, math.floor(c.meta) - 2, 7, 5)
		color(p.tinta)
		dibujar("carga", c.x - 1, c.y - 2)
	end
	-- escudo del cambio de fase: un contorno en tono medio que sigue la forma del jefe a dos
	-- píxeles, con trazos que le dan la vuelta. Al rebotar un tiro se enciende en tinta y suelta
	-- una segunda onda; titila rápido justo antes de apagarse
	local j = s.jefe
	if j and j.blindado and not j.sacudida and not (j.escudo_aviso and math.floor(s.t * 12) % 2 == 0) then
		local c = contorno_de(j.dibujo)
		local x0, y0 = math.floor(j.x + 0.5), math.floor(j.y + 0.5)
		if j.rebote > 0 then
			for _, q in ipairs(c.cerca) do love.graphics.rectangle("fill", x0 + q[1], y0 + q[2], 1, 1) end
			color(tono_medio)
			for _, q in ipairs(c.lejos) do
				if (q[1] + q[2]) % 2 == 0 then love.graphics.rectangle("fill", x0 + q[1], y0 + q[2], 1, 1) end
			end
		else
			color(tono_medio)
			local giro = s.t * 13
			for _, q in ipairs(c.cerca) do
				if math.floor(q[3] + giro) % 3 ~= 0 then love.graphics.rectangle("fill", x0 + q[1], y0 + q[2], 1, 1) end
			end
		end
		color(p.tinta)
	end
	if helado then
		Fondos.terreno(s, p)
		if not s.nave.oculta and L.forma_nave(s) == "oruga" then
			Fondos.reflejo(s, p, D.dibujos.oruga, s.nave.x, s.nave.y)
		end
	end
	-- columna de burbujas que avisa por dónde va a subir el jefe hundido
	if s.jefe and s.jefe.burbujas then
		color(tono_medio)
		local a = D.niveles[s.nivel].agua
		local cx = math.floor(s.jefe.x + s.jefe.w / 2)
		local alto = a - D.TECHO - 2
		for k = 0, 4 do
			local y = math.floor(s.jefe.y - ((s.t * 18 + k * 7) % (s.jefe.y - D.TECHO - 2)))
			local x = cx - 1 + math.floor(math.sin(s.t * 6 + k) + 0.5)
			if alto > 0 then
				love.graphics.rectangle("fill", x + 1, y, 1, 1)
				love.graphics.rectangle("fill", x, y + 1, 1, 1)
				love.graphics.rectangle("fill", x + 2, y + 1, 1, 1)
				love.graphics.rectangle("fill", x + 1, y + 2, 1, 1)
			end
		end
		color(p.tinta)
	end
	-- anillos de luz de la pirámide: media vuelta hacia arriba con un hueco para pasar
	if s.jefe and s.jefe.anillos then
		for _, an in ipairs(s.jefe.anillos) do
			local pasos = math.floor(an.r * 7)
			for k = 0, pasos - 1 do
				local ang = k / pasos * math.pi * 2
				local dy = math.sin(ang) * an.r
				if dy < an.r * 0.3 and not L.en_hueco(an, ang) and an.y + dy >= D.TECHO then
					love.graphics.rectangle("fill", math.floor(an.x + math.cos(ang) * an.r + 0.5), math.floor(an.y + dy + 0.5), 1, 1)
				end
			end
		end
	end
	-- avisos del jefe: marcas en tono medio que titilan antes de un ataque
	if s.jefe and s.jefe.avisos and math.floor(s.t * 10) % 2 == 0 then
		color(tono_medio)
		for _, a in ipairs(s.jefe.avisos) do
			love.graphics.rectangle("fill", math.floor(a.x + 0.5), math.floor(a.y + 0.5), a.w, a.h)
		end
		color(p.tinta)
	end
	-- líneas del jefe: de aviso, punteadas en tono medio que titilan; de rayo, llenas en tinta
	if s.jefe and s.jefe.lineas then
		for _, l in ipairs(s.jefe.lineas) do
			if not l.aviso or math.floor(s.t * 10) % 2 == 0 then
				color(l.aviso and tono_medio or p.tinta)
				local pasos = math.max(1, math.floor(math.max(math.abs(l.x2 - l.x1), math.abs(l.y2 - l.y1))))
				for i = 0, pasos, l.aviso and 2 or 1 do
					local x, y = l.x1 + (l.x2 - l.x1) * i / pasos, l.y1 + (l.y2 - l.y1) * i / pasos
					love.graphics.rectangle("fill", math.floor(x + 0.5), math.floor(y + 0.5), 1, 1)
				end
			end
		end
		color(p.tinta)
	end
	-- gotas de las salpicaduras
	if s.gotas and #s.gotas > 0 then
		color(tono_medio)
		for _, g in ipairs(s.gotas) do
			love.graphics.rectangle("fill", math.floor(g.x), math.floor(g.y), 1, 1)
		end
		color(p.tinta)
	end
	for _, b in ipairs(s.balas) do
		dibujar(b.cohete and "cohete" or b.torpedo and animado("torpedo", 8) or b.lleno and "obus_lleno" or b.obus and "obus" or "bala", b.x, b.y)
	end
	-- tiempo perdido: cada bala enemiga deja dos puntos de estela en tono medio
	if s.lento > 0 then
		color(tono_medio)
		for _, b in ipairs(s.balas_enemigas) do
			local largo = math.sqrt(b.vx * b.vx + b.vy * b.vy)
			if largo > 1 then
				for k = 1, 2 do
					love.graphics.rectangle("fill", math.floor(b.x - b.vx / largo * 2 * k + 0.5), math.floor(b.y - b.vy / largo * 2 * k + 0.5), 1, 1)
				end
			end
		end
		color(p.tinta)
	end
	for _, b in ipairs(s.balas_enemigas) do
		dibujar(b.forma or "bala_enemiga", b.x, b.y)
	end
	-- pulso: anillo que crece, con un eco en tono medio por dentro
	if s.pulso then
		for capa = 1, 2 do
			local r = s.pulso.r - (capa == 2 and 4 or 0)
			if r > 1 then
				if capa == 2 then color(tono_medio) end
				local pasos = math.floor(r * 6)
				for k = 0, pasos - 1 do
					local a = k / pasos * math.pi * 2
					love.graphics.rectangle("fill", math.floor(s.pulso.x + math.cos(a) * r + 0.5), math.floor(s.pulso.y + math.sin(a) * r + 0.5), 1, 1)
				end
				color(p.tinta)
			end
		end
	end
	if s.rayo_caja and math.floor(s.t * 20) % 2 == 0 then
		local c = s.rayo_caja
		love.graphics.rectangle("fill", math.floor(c[1]), math.floor(c[2]), c[3], math.floor(c[4]))
	end
	local parpadeo = (s.invencible > 0 and s.invencible < 2) or (s.escudo > 0 and s.escudo < 1.5)
	if s.estado ~= "muriendo" and not s.nave.oculta and (not parpadeo or math.floor(s.t * 12) % 2 == 0) then
		local forma = L.forma_nave(s)
		if forma == "batiscafo" then
			-- estela de burbujas en tono medio detrás de la hélice
			color(tono_medio)
			for k = 0, 2 do
				local f = (s.t * 3 + k / 3) % 1
				love.graphics.rectangle("fill", math.floor(s.nave.x - 1 - f * 6), math.floor(s.nave.y + 3 - f * 3 + (k % 2)), 1, 1)
			end
			color(p.tinta)
		elseif forma ~= "oruga" and s.estado ~= "titulo" then
			-- llama del motor: titila entre uno y dos píxeles
			local largo = (math.floor(s.t * 15) % 2 == 0) and 2 or 1
			love.graphics.rectangle("fill", math.floor(s.nave.x + 0.5) - largo, math.floor(s.nave.y + 0.5) + 2, largo, 1)
		end
		dibujar(animado(forma, 10), s.nave.x, s.nave.y)
		-- carga del cañón de la oruga: un punto delante del cañón que crece; lleno, titila en tinta
		local carga = s.nave.carga or 0
		if carga >= L.CARGA_MIN then
			local lleno = carga >= L.CARGA_MAX
			local x, y = math.floor(s.nave.x + 0.5) + #D.dibujos[forma][1], math.floor(s.nave.y + 0.5) + 2
			if lleno then
				if math.floor(s.t * 12) % 2 == 0 then love.graphics.rectangle("fill", x, y - 1, 2, 3) end
			else
				color(tono_medio)
				love.graphics.rectangle("fill", x, y, carga >= (L.CARGA_MIN + L.CARGA_MAX) / 2 and 2 or 1, 1)
				color(p.tinta)
			end
		end
		-- abducción: cono punteado en tono medio delante de la nave (no se toca)
		if s.abduccion_caja then
			local c = s.abduccion_caja
			color(tono_medio)
			local corre = math.floor(s.t * 12) % 3
			for dx = 1, c.largo, 3 do
				local abre = math.floor(1 + (dx + corre) * 0.45)
				love.graphics.rectangle("fill", math.floor(c.x + dx + corre), math.floor(c.y - abre), 1, 1)
				love.graphics.rectangle("fill", math.floor(c.x + dx + corre), math.floor(c.y + abre), 1, 1)
			end
			color(p.tinta)
		end
		-- la sonda
		if s.sonda and (s.sonda.t > 1.5 or math.floor(s.t * 8) % 2 == 0) then
			dibujar("sonda", s.sonda.x, s.sonda.y)
		end
		if s.escudo > 0 then
			local d = D.dibujos[forma]
			marco(math.floor(s.nave.x) - 1, math.floor(s.nave.y) - 2, #d[1] + 3, #d + 4)
		end
	end
	-- el jefe vencido: tiembla con explosiones encima y revienta en una onda grande con humo
	local r = s.estado == "nivel_superado" and s.restos
	if r then
		local t = s.t - L.JEFE_ROTO
		if t < 0 then
			dibujar(r.dibujo, r.x + (math.floor(s.t * 24) % 2 * 2 - 1), r.y)
		else
			local cx, cy = math.floor(r.x + r.w / 2), math.floor(r.y + r.h / 2)
			local n = math.floor(t / 0.1) + 1
			if n <= 5 then
				local d = D.dibujos["onda" .. n]
				dibujar("onda" .. n, cx - #d[1], cy - #d, 2)
			end
			local h = math.floor((t - 0.3) / 0.12) + 4
			if h >= 4 and h <= 7 then
				for _, ox in ipairs({ -7, 7 }) do
					local d = D.dibujos["explosion" .. h]
					dibujar("explosion" .. h, cx + ox - 3, cy - 3 - (h - 4))
				end
			end
		end
	end
	-- explosión: chispa que se abre en estrella y humo en tono medio que sube; centrada en
	-- el cuadro de 5x5 donde nació
	for _, x in ipairs(s.explosiones) do
		local n = math.min(7, math.floor(x.t / L.CUADRO_EXPLOSION) + 1)
		local d = D.dibujos["explosion" .. n]
		local sube = (n >= 5 and 1 or 0) + (n >= 6 and 1 or 0)
		local ex, ey = x.x + 2 - math.floor(#d[1] / 2), x.y + 2 - math.floor(#d / 2) - sube
		-- la chispa recorta lo que tiene detrás con un borde del color de fondo, para que se vea
		-- también encima de un jefe (tinta sobre tinta)
		if n <= 3 then
			color(p.fondo)
			for _, o in ipairs({ { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }) do
				love.graphics.draw(imagenes["explosion" .. n], math.floor(ex + 0.5) + o[1], math.floor(ey + 0.5) + o[2])
			end
			color(p.tinta)
		end
		dibujar("explosion" .. n, ex, ey)
	end
	if s.prueba and s.prueba.choques then
		choques_encima(p)
	end

	-- barra de vida del jefe
	if s.jefe and s.jefe.llego then
		-- seis bloques como la batería de un celular; cada bloque se vacía
		-- de arriba abajo en 4 filas, y el que se está gastando titila al recibir un golpe
		local filas = math.ceil(24 * math.max(0, s.jefe.vida) / s.jefe.maximo)
		local gastandose = math.floor((filas - 1) / 4)
		local titila = s.jefe.golpe > 0 and math.floor(s.t * 30) % 2 == 0
		-- con el escudo puesto la barra baja a tono medio: ahora no se le puede quitar vida
		if s.jefe.blindado then color(tono_medio) end
		for i = 0, 5 do
			local alto = math.max(0, math.min(4, filas - i * 4))
			if alto > 0 and not (titila and i == gastandose) then
				love.graphics.rectangle("fill", 42 + i * 3, 4 - alto, 2, alto)
			elseif alto == 0 then
				-- bloque vacío: un puntito para que se vea dónde estaba
				love.graphics.rectangle("fill", 42 + i * 3, 3, 1, 1)
			end
		end
		color(p.tinta)
	end
	marcador()

	-- nombre de la mejora recién recogida
	if s.cartel and s.estado == "jugando" then
		local ancho = #tr(s.cartel.texto) * 4 + 3
		local x = math.floor((ANCHO - ancho) / 2)
		color(p.fondo)
		love.graphics.rectangle("fill", x, 8, ancho, 7)
		color(p.tinta)
		texto(s.cartel.texto, x + 2, 9)
	end

	-- carteles
	if s.estado == "inicio_nivel" then
		color(p.fondo)
		local datos = D.niveles[s.nivel]
		local lineas = { datos.nombre }
		if datos.caso then lineas[#lineas + 1] = datos.caso end
		local informe = (s.ciclo > 1 and datos.informe_vuelta) or datos.informe
		if informe then lineas[#lineas + 1] = informe end
		if datos.aviso then lineas[#lineas + 1] = datos.aviso end
		if s.ciclo > 1 then lineas[#lineas + 1] = "VUELTA " .. s.ciclo end
		-- cartel centrado en la zona de juego, crece según las líneas
		local alto = 7 * #lineas + 3
		local arriba = math.floor(27 - alto / 2)
		-- se ensancha si algún nombre de caso es largo
		local ancho = 60
		for _, linea in ipairs(lineas) do ancho = math.max(ancho, #tr(linea) * 4 + 5) end
		local izquierda = math.floor((ANCHO - ancho) / 2)
		love.graphics.rectangle("fill", izquierda, arriba, ancho, alto)
		color(p.tinta)
		marco(izquierda, arriba, ancho, alto)
		for i, linea in ipairs(lineas) do
			if i == 2 and datos.caso then color(tono_medio) end
			texto_centrado(linea, arriba + 2 + 7 * (i - 1))
			color(p.tinta)
		end
	elseif s.estado == "aviso_jefe" and math.floor(s.t * 4) % 2 == 0 then
		color(p.fondo)
		love.graphics.rectangle("fill", 22, 19, 40, 11)
		color(p.tinta)
		marco(22, 19, 40, 11)
		texto_centrado("CUIDADO!", 22)
	elseif s.estado == "nivel_superado" and s.restos and s.t >= L.JEFE_ROTO and s.t < L.JEFE_ROTO + 0.07 then
		-- destello del estallido: un cuadro con toda la pantalla en tinta
		color(p.tinta)
		love.graphics.rectangle("fill", 0, 0, ANCHO, ALTO)
	elseif s.estado == "nivel_superado" and not (s.restos and s.t < L.JEFE_ROTO + 0.7) then
		local t0 = s.restos and L.JEFE_ROTO + 0.7 or 0
		color(p.fondo)
		love.graphics.rectangle("fill", 20, 19, 44, 11)
		color(p.tinta)
		marco(20, 19, 44, 11)
		texto_centrado("SUPERADO!", 22)
		-- premio por vencer al jefe y puntos extra por hacerlo rápido, uno tras otro
		local abajo = {}
		if s.premio and s.t > t0 + 0.6 then abajo[#abajo + 1] = s.premio end
		if (s.bono_rapido or 0) > 0 and s.t > t0 + 1.2 then abajo[#abajo + 1] = "RAPIDO +" .. s.bono_rapido end
		for i, linea in ipairs(abajo) do
			local ancho = #tr(linea) * 4 + 3
			local y = 31 + (i - 1) * 8
			color(p.fondo)
			love.graphics.rectangle("fill", math.floor((ANCHO - ancho) / 2), y, ancho, 8)
			color(p.tinta)
			texto_centrado(linea, y + 2)
		end
	elseif s.estado == "continuar" then
		local turno = math.floor(s.t / 1.5) % 2 == 0
		local y0 = ficha("CONTINUAR?", 17, turno and "START SIGUE" or "PUNTOS A 0", 56, 27, not turno)
		-- el número grande, al triple de tamaño
		local n = math.max(0, math.ceil(s.cuenta) - 1)
		love.graphics.draw(imagenes["letra_" .. n], 38, y0, 0, 3, 3)
	elseif s.estado == "pausa" then
		-- la pausa dice en qué expediente vamos: nivel (y vuelta) y el caso
		local datos = D.niveles[s.nivel] or {}
		local y0 = ficha("PAUSA", 28, nil, 72, 26)
		local cual = tr(datos.nombre or "")
		if (s.ciclo or 1) > 1 then cual = cual .. " " .. tr("VUELTA " .. s.ciclo) end
		texto_centrado(cual, y0)
		color(tono_medio)
		texto_centrado(datos.caso or "", y0 + 7)
		opciones({ "SEGUIR", "SALIR" }, s.opcion_pausa or 1, y0 + 14)
	end
end

-- ---------- LÖVE

function love.load(argumentos)
	Puente.iniciar(argumentos)
	Idioma.elegir(Puente.idioma or os.getenv("ORBITA_IDIOMA"))
	-- en un teléfono (la web en móvil o la app de Android) los controles se ven desde el arranque
	if Puente.tactil or love.system.getOS() == "Android" or love.system.getOS() == "iOS" then Tactil.activo = true end
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setLineStyle("rough")
	love.mouse.setVisible(false)
	lienzo = love.graphics.newCanvas(ANCHO, ALTO)
	foto = love.graphics.newCanvas(ANCHO, ALTO)
	mezcla = love.graphics.newCanvas(ANCHO, ALTO)
	imagenes = {}
	imagenes_medio = {}
	for nombre, filas in pairs(D.dibujos) do
		imagenes[nombre] = hacer_imagen(filas)
		if table.concat(filas):find("+", 1, true) then
			imagenes_medio[nombre] = hacer_imagen(filas, "+")
		end
	end
	for letra, filas in pairs(D.letras) do
		imagenes["letra_" .. letra] = hacer_imagen(filas)
	end
	crear_sonidos()
	love.math.setRandomSeed(os.time())
	s = L.nuevo(cargar_ajustes(), love.math.random)
	-- para probar, ORBITA_IDIOMA manda sobre lo guardado
	if os.getenv("ORBITA_IDIOMA") then Idioma.elegir(os.getenv("ORBITA_IDIOMA")) end
	s.nave_elegida = math.max(1, math.min(#L.NAVES, nave_elegida or 1))
	local mandos = love.joystick.getJoysticks()
	mando = mandos[1]
	-- ORBITA_VENTANA=ANCHOxALTO prueba otros tamaños (por ejemplo un teléfono)
	local vw, vh = (os.getenv("ORBITA_VENTANA") or ""):match("^(%d+)x(%d+)$")
	if vw then love.window.setMode(tonumber(vw), tonumber(vh), { resizable = true }) end
end

-- ---------- toques (los controles táctiles aparecen con el primero)

function love.touchpressed(id, x, y) Tactil.presionar(id, x, y) end
function love.touchmoved(id, x, y) Tactil.mover(id, x, y) end
function love.touchreleased(id) Tactil.soltar(id) end
-- con ORBITA_TACTIL=1 el ratón hace de dedo (los toques de verdad ya llegan arriba)
function love.mousepressed(x, y, _, toque)
	if Tactil.forzado and not toque then Tactil.presionar("raton", x, y) end
end
function love.mousemoved(x, y, _, _, toque)
	if Tactil.forzado and not toque then Tactil.mover("raton", x, y) end
end
function love.mousereleased(_, _, _, toque)
	if Tactil.forzado and not toque then Tactil.soltar("raton") end
end
function love.gamepadpressed() Tactil.esconder() end

function love.joystickadded(j)
	if not mando then mando = j end
end

function love.joystickremoved(j)
	if mando == j then mando = nil end
end

-- modo de capturas para revisar el aspecto (ORBITA_CAPTURA=1): juega solo y guarda imágenes
local captura = os.getenv("ORBITA_CAPTURA") and { reloj = 0, hechas = {} }
local momentos = { 1.5, 5, 9, 13, 16, 19, 22, 25 }
-- ORBITA_MOMENTOS="6,10,14" cambia los segundos de las capturas (y termina tras la última)
if os.getenv("ORBITA_MOMENTOS") then
	momentos = {}
	for n in os.getenv("ORBITA_MOMENTOS"):gmatch("[%d%.]+") do momentos[#momentos + 1] = tonumber(n) end
end
-- demo en video (ORBITA_VIDEO=1 junto a ORBITA_CAPTURA): guarda cada cuadro entre
-- ORBITA_VIDEO_DESDE y ORBITA_VIDEO_HASTA (segundos) en video/ del directorio de datos
local video = captura and os.getenv("ORBITA_VIDEO") and {
	desde = tonumber(os.getenv("ORBITA_VIDEO_DESDE") or "0"),
	hasta = tonumber(os.getenv("ORBITA_VIDEO_HASTA") or "15"),
	cuadro = 0,
}
local franja -- lienzo de una línea para los letreros del demo

local function piloto()
	local e = leer_entrada()
	-- en la portada el piloto no cambia el idioma (las tomas salen en el idioma pedido)
	if s.estado == "titulo" then e.poder, e.poder_pulsado = false, false end
	e.a, e.a_pulsado = true, captura.reloj < 3.5 and captura.reloj > 3
	e.start_pulsado = e.a_pulsado
	-- en el menú de la portada, START juega directo
	if s.estado == "menu" then e.start_pulsado = true end
	if s.nave then
		s.invencible = 5
		local objetivo = s.jefe and s.jefe.y + (s.jefe.blanco and 0 or 5) or 20 + math.sin(captura.reloj) * 12
		e.arriba, e.abajo = s.nave.y > objetivo + 1, s.nave.y < objetivo - 1
		if L.forma_nave(s) == "oruga" or os.getenv("ORBITA_LLENO") then
			-- suelta A un instante cada dos segundos para disparar el obús cargado
			-- (ORBITA_LLENO=1 lo hace con cualquier nave: el obús sale lleno)
			e.a = captura.reloj % 2 < 1.93
			e.arriba_pulsado = math.floor(captura.reloj * 10) % 15 == 0
		end
		-- usa el poder guardado un momento después de recogerlo
		-- (ORBITA_PODER=escudo|tiempo|sonda|abduccion lo da al empezar y ORBITA_USAR=s dice cuándo usarlo)
		if os.getenv("ORBITA_PODER") then
			if not captura.poder_dado and s.estado == "jugando" then
				captura.poder_dado, s.poder = true, "mejora_" .. os.getenv("ORBITA_PODER")
			end
			local usar = tonumber(os.getenv("ORBITA_USAR") or "")
			e.poder_pulsado = usar ~= nil and captura.reloj >= usar and not captura.poder_usado
			if e.poder_pulsado then captura.poder_usado = true end
		else
			e.poder_pulsado = s.poder ~= nil and math.floor(captura.reloj * 10) % 20 == 0
		end
		e.b_pulsado = math.floor(captura.reloj * 10) % 70 == 0
	end
	return e
end

-- ---------- transiciones entre pantallas (cuadros a mano, como en estetica/transiciones.py)
-- cada cuadro: { fuente, forma, valor }; fuente "foto" es la pantalla vieja, "nueva" la de ahora
local HISTORIA = { prologo = true, mapa = true, final = true }
local MENUS = { titulo = true, menu = true, pausa = true, ronda_completa = true, continuar = true, iniciales = true, fin = true }
local TRANSICIONES = {
	-- A · persiana: franjas que se cierran cada 6 filas y se abren sobre la otra
	persiana = { paso = 0.025, cuadros = {
		{ "foto", "persiana", 1 }, { "foto", "persiana", 2 }, { "foto", "persiana", 3 },
		{ "foto", "persiana", 4 }, { "foto", "persiana", 5 }, { "foto", "persiana", 6 },
		{ "nueva", "persiana", 5 }, { "nueva", "persiana", 4 }, { "nueva", "persiana", 3 },
		{ "nueva", "persiana", 2 }, { "nueva", "persiana", 1 }, { "nueva", "persiana", 0 } } },
	-- E · carpeta: dos tapas se juntan con el 84 en el lomo y se abren
	carpeta = { paso = 0.045, cuadros = {
		{ "foto", "carpeta", 32 }, { "foto", "carpeta", 22 }, { "foto", "carpeta", 12 },
		{ "foto", "carpeta", 4 }, { "foto", "carpeta", 0 }, { "foto", "carpeta", 0 }, { "foto", "carpeta", 0 },
		{ "nueva", "carpeta", 4 }, { "nueva", "carpeta", 12 }, { "nueva", "carpeta", 22 }, { "nueva", "carpeta", 32 } } },
	-- F · tele que se apaga: se aplasta en una línea, queda un punto y se abre lo nuevo
	apagado = { paso = 0.055, cuadros = {
		{ "foto", "aplastar", 34 }, { "foto", "aplastar", 20 }, { "foto", "aplastar", 10 },
		{ "foto", "aplastar", 4 }, { "foto", "linea", 84 }, { "foto", "linea", 7 }, { "foto", "linea", 1 },
		{ "foto", "linea", 1 }, { "foto", "linea", 0 }, { "foto", "linea", 0 },
		{ "nueva", "linea", 84 }, { "nueva", "aplastar", 4 }, { "nueva", "aplastar", 12 },
		{ "nueva", "aplastar", 26 }, { "nueva", "aplastar", 40 } } },
}

-- cuál transición va entre dos estados (nil = corte directo, como dentro del juego)
local function elegir_transicion(antes, prueba_antes)
	if not antes or captura and os.getenv("ORBITA_PANTALLA") then return end
	local ahora = s.estado
	local tipo
	if antes == ahora then
		-- en el título, entrar o salir del modo de prueba también es un menú
		if ahora == "titulo" and prueba_antes ~= (s.prueba ~= nil) then tipo = "persiana" end
	elseif antes == "continuar" and (ahora == "fin" or ahora == "iniciales") then
		tipo = "apagado" -- FIN DEL JUEGO
	elseif HISTORIA[antes] or HISTORIA[ahora] then
		tipo = "carpeta"
	elseif MENUS[antes] or MENUS[ahora] then
		tipo = "persiana"
	end
	if tipo then
		local d = TRANSICIONES[tipo]
		transicion = { tipo = tipo, t = 0, paso = d.paso, cuadros = d.cuadros, foto_pendiente = true }
	end
end

function love.update(dt)
	dt = math.min(dt, 1 / 20)
	if video then dt = 1 / 30 end
	local e
	if captura and os.getenv("ORBITA_PANTALLA") then
		-- muestra una pantalla fija (tabla o iniciales) y se cierra
		captura.reloj = captura.reloj + dt
		if not captura.puesta then
			captura.puesta = true
			s.tabla = {}
			for i, p in ipairs({ 12340, 9800, 5550, 2100, 640 }) do
				s.tabla[i] = { nombre = ({ "DRK", "LUI", "ABC", "NOK", "ZZZ" })[i], puntos = p }
			end
			if os.getenv("ORBITA_PANTALLA") == "enemigos" then
				-- vitrina con los enemigos nuevos, para revisar los dibujos
				L.empezar_partida(s)
				s.estado = "jugando"
				local function poner(tipo, x, y, extra)
					local d = D.dibujos[tipo]
					local en = { tipo = tipo, x = x, y = y, w = #d[1], h = #d, golpe = 0, t = 0 }
					for k, v in pairs(extra or {}) do en[k] = v end
					s.enemigos[#s.enemigos + 1] = en
				end
				poner("chispa", 14, 9); poner("medusa", 24, 10); poner("dardo", 34, 10); poner("rombo", 46, 9)
				poner("caparazon", 56, 8); poner("planeador", 68, 10); poner("espora", 76, 9)
				poner("avispa", 14, 19); poner("lazo", 26, 20); poner("orbitador", 36, 18)
				poner("minador", 48, 20); poner("mina", 60, 21); poner("francotirador", 68, 20, { apuntando = true })
				poner("torreta", 20, 44); poner("saltarin", 30, 43); poner("pincho", 40, 45); poner("roca", 50, 30)
				s.jefe = { tipo = "coloso", dibujo = "jefe", x = 58, y = 31, w = 23, h = 11, vida = 30, maximo = 30, golpe = 0, bloques = {}, llego = true }
			elseif os.getenv("ORBITA_PANTALLA") == "menu" then
				-- ORBITA_HOJA=principal|nave|opciones|records, ORBITA_FILA=n, ORBITA_PAGINA=n
				L.abrir_menu(s)
				s.menu.hoja = os.getenv("ORBITA_HOJA") or "principal"
				s.menu.fila = tonumber(os.getenv("ORBITA_FILA") or "1")
				s.menu.pagina = tonumber(os.getenv("ORBITA_PAGINA") or "1")
				for i, f in ipairs(s.tabla) do f.nave, f.nivel, f.ciclo = i % 2 + 1, 11 - i * 2, i == 1 and 2 or 1 end
				for i = 6, 8 do s.tabla[i] = { nombre = "ANA", puntos = 600 - i * 50, nave = 1, nivel = 2, ciclo = 1 } end
			elseif os.getenv("ORBITA_PANTALLA") == "nave" then
				s.estado, s.t, s.nave_elegida, s.aviso_nave = "titulo", 0, 2, 2
			elseif os.getenv("ORBITA_PANTALLA") == "prueba" then
				s.estado, s.t, s.prueba = "titulo", 0, { nivel = 3, fila = 5, dano = true, choques = true, vuelta = 2, lento = 2 }
			elseif os.getenv("ORBITA_PANTALLA") == "ronda" then
				L.empezar_partida(s)
				s.estado, s.t, s.puntos, s.opcion_ronda = "ronda_completa", 0, 18450, 1
			elseif os.getenv("ORBITA_PANTALLA") == "cumplida" then
				L.empezar_partida(s)
				s.estado, s.t, s.puntos, s.victoria, s.puesto = "fin", 0, 18450, true, 1
			elseif os.getenv("ORBITA_PANTALLA") == "continuar" then
				L.empezar_partida(s)
				s.estado, s.t, s.cuenta, s.vidas, s.puntos = "continuar", 0, 7.5, 0, 3420
				s.nave.oculta = true
			elseif os.getenv("ORBITA_PANTALLA") == "prologo" or os.getenv("ORBITA_PANTALLA") == "final" then
				-- ORBITA_PAGINA=n elige la página
				L.empezar_partida(s)
				s.estado, s.t, s.pagina = os.getenv("ORBITA_PANTALLA"), 9, tonumber(os.getenv("ORBITA_PAGINA") or "1")
			elseif os.getenv("ORBITA_PANTALLA") == "mapa" then
				-- ORBITA_PIEZA=n: el mapa tras el jefe del nivel n
				L.empezar_partida(s)
				s.estado, s.t, s.pieza = "mapa", 2, tonumber(os.getenv("ORBITA_PIEZA") or "1")
			elseif os.getenv("ORBITA_PANTALLA") == "superado" then
				-- la muerte del jefe del nivel ORBITA_NIVEL, ORBITA_T segundos después del último golpe
				s.prueba = { nivel = tonumber(os.getenv("ORBITA_NIVEL") or "1") }
				L.empezar_partida(s)
				s.prueba = nil
				local dibujos = { coloso = "jefe", tenaza = "tenaza", nodriza = "nodriza", nucleo = "nucleo", ojo = "ojo_abierto",
					shag = "shag", gigante = "gigante", fantasma = "fantasma", serpiente = "serpiente_cabeza", piramide = "piramide" }
				local d = D.dibujos[dibujos[D.niveles[s.nivel].jefe]]
				s.estado, s.t, s.premio, s.bono_rapido = "nivel_superado", 0, "VIDA +1", 200
				s.restos = { dibujo = dibujos[D.niveles[s.nivel].jefe], x = ANCHO - #d[1] - 6, y = 24 - math.floor(#d / 2), w = #d[1], h = #d, cada = 0 }
				local hasta = tonumber(os.getenv("ORBITA_T") or "0.6")
				while s.t < hasta do L.actualizar(s, 1 / 30, {}) end
			elseif os.getenv("ORBITA_PANTALLA") == "pausa" then
				s.prueba = { nivel = tonumber(os.getenv("ORBITA_NIVEL") or "7") }
				L.empezar_partida(s)
				s.prueba = nil
				s.estado, s.t, s.ciclo, s.puntos = "pausa", 0, 2, 3420
			elseif os.getenv("ORBITA_PANTALLA") == "iniciales" then
				s.estado, s.puntos, s.letras, s.letra = "iniciales", 15000, { 4, 18, 11 }, 2
			else
				s.estado, s.t = "titulo", 8
			end
		end
		if captura.reloj > 1 and not captura.hechas[1] then
			captura.hechas[1] = true
			love.graphics.captureScreenshot("captura_pantalla.png")
		end
		if captura.reloj > 2 then love.event.quit() end
		return
	end
	if captura then
		captura.reloj = captura.reloj + dt
		e = piloto()
		if (s.estado == "inicio_nivel" or s.estado == "prologo") and not captura.nivel then
			captura.nivel = tonumber(os.getenv("ORBITA_NIVEL") or "1")
			-- empieza de nuevo en ese nivel para que su terreno arranque bien
			s.prueba = { nivel = captura.nivel }
			L.empezar_partida(s)
			-- ORBITA_CHOQUES=1 deja el modo de prueba puesto para ver las cajas de choque
			s.prueba = os.getenv("ORBITA_CHOQUES") and { nivel = captura.nivel, choques = true } or nil
		end
		-- (ORBITA_OLEADAS=1 no salta al jefe, para ver las oleadas)
		if s.estado == "jugando" and captura.reloj > 8 and not s.jefe and s.tiempo_nivel < 100 and not os.getenv("ORBITA_OLEADAS") then
			s.tiempo_nivel, s.enemigos = 100, {}
		end
		-- ORBITA_FASE=n deja al jefe en esa fase (los que pelean por fases)
		local fase = tonumber(os.getenv("ORBITA_FASE") or "")
		if fase and s.jefe and s.jefe.llego then
			s.jefe.vida = s.jefe.maximo * (1.05 - fase / 3)
		end
		for i, m in ipairs(momentos) do
			if not video and captura.reloj >= m and not captura.hechas[i] then
				captura.hechas[i] = true
				love.graphics.captureScreenshot(("captura_%02d.png"):format(i))
			end
		end
		if captura.reloj > (video and video.hasta or (os.getenv("ORBITA_MOMENTOS") and momentos[#momentos] + 0.5) or 27) then love.event.quit() end
	else
		e = leer_entrada()
	end
	entrada_actual = e
	local estado_antes = s.estado

	if transicion then
		-- mientras cambia la pantalla la lógica espera, para que nada pase sin verse
		transicion.t = transicion.t + dt
		if transicion.t >= transicion.paso * #transicion.cuadros then transicion = nil end
		e = {}
	end

	-- en el título: SELECT cambia los colores y ARRIBA/ABAJO activa o quita el sonido
	if not transicion and s.estado == "titulo" then
		s.aviso_idioma = math.max(0, (s.aviso_idioma or 0) - dt)
		if e.poder_pulsado and not s.prueba then
			Idioma.siguiente()
			s.aviso_idioma, s.aviso_nave = 1.5, 0
			guardar_ajustes()
		end
		if e.select_pulsado then
			paleta = paleta % #D.paletas + 1
			guardar_ajustes()
		elseif (e.arriba_pulsado or e.abajo_pulsado) and not s.prueba then
			silencio = not silencio
			guardar_ajustes()
		end
	end

	if not transicion then L.actualizar(s, dt, e) end
	-- cambios pedidos desde OPCIONES del menú
	if s.ajuste then
		local a = s.ajuste
		s.ajuste = nil
		if a.que == "sonido" then
			silencio = not silencio
		elseif a.que == "color" then
			paleta = (paleta - 1 + a.paso) % #D.paletas + 1
		elseif a.que == "idioma" then
			Idioma.siguiente()
		end
		guardar_ajustes()
	end
	elegir_transicion(ultimo_estado, ultima_prueba)
	ultimo_estado, ultima_prueba = s.estado, s.prueba ~= nil
	-- al terminar una partida de verdad, el puntaje va a YouTube
	if s.estado == "fin" and estado_antes ~= "fin" and not s.prueba then
		Puente.avisar("puntaje", math.floor(s.puntos))
	end
	if s.nave_elegida ~= nave_elegida then
		nave_elegida = s.nave_elegida
		guardar_ajustes()
	end

	-- al grabar video se anota cada sonido con su cuadro, para armar el audio después
	local anotar = video and captura.reloj >= video.desde and captura.reloj <= video.hasta
	if anotar then
		love.filesystem.createDirectory("video")
		local titulo = s.estado == "titulo"
		if titulo ~= video.musica then
			video.musica = titulo
			love.filesystem.append("video/sonidos.txt", (video.cuadro + 1) .. (titulo and " musica_on\n" or " musica_off\n"))
		end
	end
	for _, nombre in ipairs(s.sonidos) do
		if anotar then love.filesystem.append("video/sonidos.txt", (video.cuadro + 1) .. " " .. nombre .. "\n") end
		if not silencio and not silencio_externo and sonidos[nombre] then
			sonidos[nombre]:stop()
			sonidos[nombre]:play()
		end
	end
	s.sonidos = {}
	-- la melodía del título suena solo en el título
	local quiere = s.estado == "titulo" and not silencio and not silencio_externo
	if quiere and not musica_titulo:isPlaying() then
		musica_titulo:play()
	elseif not quiere and musica_titulo:isPlaying() then
		musica_titulo:stop()
	end
	if s.tabla_cambio then
		s.tabla_cambio = false
		guardar_ajustes()
	end
end

-- texto con las letras del juego a cualquier escala, centrado en x
local function escribir(cadena, x, y, k)
	cadena = tr(cadena)
	x = math.floor(x - (#cadena * 4 - 1) * k / 2 + 0.5)
	y = math.floor(y + 0.5)
	for i = 1, #cadena do
		local letra = imagenes["letra_" .. cadena:sub(i, i)]
		if letra then love.graphics.draw(letra, x + (i - 1) * 4 * k, y, 0, k, k) end
	end
end

-- dibuja un cuadro de la transición sobre el lienzo actual
local function cortina(cuadro)
	local fuente, forma, v = cuadro[1], cuadro[2], cuadro[3]
	local base = fuente == "foto" and foto or lienzo
	local pj = paleta_juego()
	local mitad = ALTO / 2
	if forma == "aplastar" or forma == "linea" then
		color(pj.fondo)
		love.graphics.rectangle("fill", 0, 0, ANCHO, ALTO)
	end
	love.graphics.setColor(1, 1, 1)
	if forma == "aplastar" then
		love.graphics.draw(base, 0, mitad - math.floor(v / 2), 0, 1, v / ALTO)
		return
	elseif forma ~= "linea" then
		love.graphics.draw(base, 0, 0)
	end
	color(pj.tinta)
	if forma == "persiana" then
		for y = 0, ALTO - 1, 6 do
			if v > 0 then love.graphics.rectangle("fill", 0, y, ANCHO, v) end
		end
	elseif forma == "carpeta" then
		local izq = ANCHO / 2 - v
		love.graphics.rectangle("fill", 0, 0, izq, ALTO)
		love.graphics.rectangle("fill", ANCHO / 2 + v, 0, ANCHO - (ANCHO / 2 + v), ALTO)
		if v <= 0 then
			-- el lomo del expediente: líneas punteadas en tono medio y el 84 en negativo
			color(tono_medio)
			for x = 0, ANCHO - 1, 2 do
				love.graphics.rectangle("fill", x, mitad - 6, 1, 1)
				love.graphics.rectangle("fill", x, mitad + 6, 1, 1)
			end
			color(pj.fondo)
			escribir("84", ANCHO / 2, mitad - 2, 1)
		end
	elseif forma == "linea" and v > 0 then
		love.graphics.rectangle("fill", math.floor((ANCHO - v) / 2), mitad, v, 1)
	end
end

function love.draw()
	if transicion and transicion.foto_pendiente then
		-- el lienzo todavía tiene el último cuadro de la pantalla vieja
		transicion.foto_pendiente = false
		love.graphics.setCanvas(foto)
		love.graphics.clear()
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(lienzo, 0, 0)
	end
	love.graphics.setCanvas(lienzo)
	love.graphics.clear()
	escena()
	local salida = lienzo
	if transicion then
		local n = math.min(#transicion.cuadros, math.floor(transicion.t / transicion.paso) + 1)
		love.graphics.setCanvas(mezcla)
		love.graphics.clear()
		cortina(transicion.cuadros[n])
		salida = mezcla
	end
	love.graphics.setCanvas()

	-- escala entera, centrada, con marco y rejilla de píxeles tipo LCD
	local p = D.paletas[paleta]
	local w, h = love.graphics.getDimensions()
	local escala = math.max(1, math.floor(math.min(w / ANCHO, h / ALTO)))
	local ox, oy = math.floor((w - ANCHO * escala) / 2), math.floor((h - ALTO * escala) / 2)
	if Tactil.activo then escala, ox, oy = Tactil.pantalla() end
	love.graphics.clear(p.marco[1], p.marco[2], p.marco[3])
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(salida, ox, oy, 0, escala, escala)
	if escala >= 4 then
		color(paleta_juego().fondo, 0.35)
		for x = 1, ANCHO - 1 do
			love.graphics.rectangle("fill", ox + x * escala, oy, 1, ALTO * escala)
		end
		for y = 1, ALTO - 1 do
			love.graphics.rectangle("fill", ox, oy + y * escala, ANCHO * escala, 1)
		end
	end
	if video then
		-- letreros del demo en el marco, con las letras del juego
		if not franja then franja = love.graphics.newCanvas(ANCHO, 5) end
		local function letrero(cadena, y)
			love.graphics.setCanvas(franja)
			love.graphics.clear(0, 0, 0, 0)
			love.graphics.setColor(1, 1, 1)
			texto_centrado(cadena, 0)
			love.graphics.setCanvas()
			color(p.fondo, 0.9)
			love.graphics.draw(franja, ox, y, 0, escala, escala)
		end
		local borde = math.floor((oy - 5 * escala) / 2)
		letrero("ORBITA 84 - DEMO", borde)
		if math.floor(captura.reloj * 2) % 2 == 0 then
			letrero("START: JUGAR", oy + ALTO * escala + borde)
		end
		if captura.reloj >= video.desde and captura.reloj <= video.hasta then
			video.cuadro = video.cuadro + 1
			love.filesystem.createDirectory("video")
			love.graphics.captureScreenshot(("video/%05d.png"):format(video.cuadro))
		end
	elseif s.estado == "titulo" and not Tactil.activo and h - (oy + ALTO * escala) >= 18 then
		-- la ayuda va debajo de la pantalla, solo si cabe (en una ventana justa no se ve)
		color(p.fondo, 0.6)
		local ayuda = Idioma.actual == "en" and "SELECT: colors (%s)   UP/DOWN: sound %s   Y: language"
			or "SELECT: colores (%s)   ARRIBA/ABAJO: sonido %s   Y: idioma"
		love.graphics.print(ayuda:format(D.paletas[paleta].nombre, silencio and tr("NO") or tr("SI")), 8, h - 18)
	end
	Tactil.dibujar(p, entrada_actual, escribir)
	if not primer_cuadro then
		primer_cuadro = true
		Puente.avisar("listo")
	end
end

function love.keypressed(tecla)
	-- teclas que manda la página de YouTube: F9 pausa, F7 silencia y F8 devuelve el sonido
	if tecla == "f9" then L.pausar(s) return end
	if tecla == "f7" or tecla == "f8" then silencio_externo = tecla == "f7" return end
	-- en Android el botón atrás llega como escape: pausa la partida y desde la portada cierra
	if tecla == "escape" and love.system.getOS() == "Android" then
		if s.estado == "titulo" then
			love.event.quit()
		elseif s.estado == "jugando" then
			L.pausar(s)
		end
		return
	end
	Tactil.esconder()
	if tecla == "escape" then
		if s.estado == "titulo" then
			love.event.quit()
		else
			s.estado, s.t = "titulo", 0
		end
	elseif tecla == "f11" then
		love.window.setFullscreen(not love.window.getFullscreen())
	end
end

function love.quit()
	guardar_ajustes()
end

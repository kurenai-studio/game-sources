-- Idioma de los textos: el juego está escrito en español y aquí se traduce al inglés
-- justo antes de dibujar. Se elige en la portada (botón Y) o lo pasa la página
-- (YouTube o el navegador) con --idioma=en; ORBITA_IDIOMA=en sirve para probar.

local I = { actual = "es" }
I.IDIOMAS = { "es", "en" }
I.NOMBRES = { es = "ESPANOL", en = "ENGLISH" }

-- textos completos
local EN = {
	-- portada, menús y pantallas
	["PULSA START"] = "PRESS START",
	["CLASIFICADO"] = "CLASSIFIED",
	["EXPEDIENTE"] = "CASE FILE",
	["MEJORES"] = "BEST",
	["MODO PRUEBA"] = "TEST MODE",
	["START: JUGAR"] = "START: PLAY",
	["SELECT: JEFE"] = "SELECT: BOSS",
	["B: SALIR"] = "B: EXIT",
	["NUEVO RECORD!"] = "NEW RECORD!",
	["TUS INICIALES"] = "YOUR INITIALS",
	["START GUARDA"] = "START SAVES",
	["OTRA MAS DIFICIL?"] = "HARDER ONE?",
	["SEGUIR"] = "GO ON",
	["SALIR"] = "QUIT",
	["CASO CERRADO"] = "CASE CLOSED",
	["NAVE"] = "SHIP",
	["IDIOMA"] = "LANGUAGE",
	["TERMINAR"] = "FINISH",
	["MISION CUMPLIDA"] = "MISSION COMPLETE",
	["FIN DEL JUEGO"] = "GAME OVER",
	["PUNTOS"] = "SCORE",
	["CUIDADO!"] = "WARNING!",
	["SUPERADO!"] = "CLEARED!",
	["PAUSA"] = "PAUSE",
	["CONTINUAR?"] = "CONTINUE?",
	["START SIGUE"] = "START: GO ON",
	["PUNTOS A 0"] = "SCORE TO 0",
	-- mejoras y premios
	["VIDA"] = "LIFE",
	["VIDA +1"] = "LIFE +1",
	["ESCUDO"] = "SHIELD",
	["RAYO"] = "BEAM",
	["PULSO"] = "PULSE",
	["TIEMPO PERDIDO"] = "LOST TIME",
	["SONDA"] = "PROBE",
	["ABDUCCION"] = "ABDUCTION",
	["MANTEN A: CARGA"] = "HOLD A: CHARGE",
	["COHETES"] = "ROCKETS",
	-- naves
	["CABINA"] = "COCKPIT",
	-- menú de la portada
	["JUGAR"] = "PLAY",
	["RECORDS"] = "SCORES",
	["OPCIONES"] = "OPTIONS",
	["SONIDO"] = "SOUND",
	["VOLVER"] = "BACK",
	["LISTO"] = "READY",
	["LOS 10 MEJORES"] = "TOP 10",
	["SONIDO COLOR IDIOMA"] = "SOUND COLOR LANG",
	["< > CAMBIA"] = "< > CHANGE",
	["SIN RECORDS"] = "NO SCORES YET",
	["SI"] = "YES",
	["VERDE"] = "GREEN",
	["AZUL"] = "BLUE",
	["AMBAR"] = "AMBER",
	["GRIS"] = "GRAY",
	["DISPARO + RAYO"] = "SHOT + BEAM",
	["DOBLE + PULSO"] = "DOUBLE + PULSE",
	-- controles táctiles
	["DISPARO"] = "FIRE",
	["PODER"] = "POWER",
	-- avisos de los niveles
	["A TIERRA!"] = "LANDING!",
	["AL MAR!"] = "TO THE SEA!",
	["A FONDO!"] = "DIVE!",
	["AL HIELO!"] = "ON THE ICE!",
	["A OSCURAS!"] = "IN THE DARK!",
	["EL FANTASMA"] = "THE PHANTOM",
	-- la historia: informes de los carteles, prólogo, mapa y final
	["ALGO CAYO DEL CIELO"] = "SOMETHING FELL",
	["ESTE AUN NO OCURRE"] = "THIS HASNT HAPPENED",
	["LLEGO ANTES DE HORA"] = "IT CAME TOO EARLY",
	["VIENEN POR LO SUYO"] = "THEY WANT IT BACK",
	["ELLA DIBUJO UN MAPA"] = "SHE DREW A MAP",
	["SE HUNDIO SIN RUIDO"] = "IT SANK IN SILENCE",
	["VIVE BAJO EL HIELO"] = "IT LIVES UNDER ICE",
	["LA ARMADA LOS VIO"] = "THE NAVY SAW THEM",
	["SE PONEN EN FILA"] = "THEY FALL IN LINE",
	["EL VUELO 19 CRUZO"] = "FLIGHT 19 CROSSED",
	["LAS LUCES VUELVEN"] = "THE LIGHTS RETURN",
	["PROGRAMA SECRETO"] = "SECRET PROGRAM",
	["DIEZ CASOS"] = "TEN CASES",
	["LAS MISMAS LUCES"] = "THE SAME LIGHTS",
	["DOS EXPEDIENTES"] = "TWO CASE FILES",
	["TIENEN FECHA"] = "ARE DATED",
	["QUE AUN NO LLEGA"] = "IN THE FUTURE",
	["UNA LUZ. NADA MAS"] = "ONE LIGHT. NOTHING",
	["OTRA. MUY LEJOS"] = "ANOTHER. FAR AWAY",
	["TRES PUNTOS"] = "THREE POINTS",
	["NO ESTAN AL AZAR"] = "NOT AT RANDOM",
	["ES UN MAPA"] = "IT IS A MAP",
	["FALTAN CINCO"] = "FIVE TO GO",
	["SE ACERCAN"] = "THEY ARE CLOSER",
	["CASI COMPLETO"] = "ALMOST COMPLETE",
	["ES POR DONDE ENTRAN"] = "IT IS THEIR DOOR",
	["LA PUERTA SE CIERRA"] = "THE DOOR CLOSES",
	["LOS INFORMES"] = "THE REPORTS",
	["DE 1990 Y 1997"] = "OF 1990 AND 1997",
	["LLEVAN TU FIRMA"] = "BEAR YOUR NAME",
	["FIN DEL EXPEDIENTE"] = "END OF FILE",
	["UN JUEGO DE"] = "A GAME BY",
	["POR D4RK3R"] = "BY D4RK3R",
	-- casos y expedientes (los nombres propios quedan igual)
	["BELGICA 1990"] = "BELGIUM 1990",
	["BELGICA 1989"] = "BELGIUM 1989",
	["LOS HILL 1961"] = "THE HILLS 1961",
	["BERMUDAS 1945"] = "BERMUDA 1945",
	["BERMUDAS"] = "BERMUDA",
	["GUERRA 1944"] = "WAR 1944",
	["PLATILLO"] = "SAUCER",
	["DIAMANTE"] = "DIAMOND",
	["TRIANGULO"] = "TRIANGLE",
	["LA V"] = "THE V",
	["ORBE"] = "ORB",
	["EL GRIS"] = "THE GREY",
	["LUCES"] = "LIGHTS",
	["CIRCULO"] = "CIRCLE",
	["TRIGALES 1990"] = "CROPS 1990",
	["CIGARRO"] = "CIGAR",
	["SIN FECHA"] = "NO DATE",
	["CABALLERO"] = "BLACK",
	["NEGRO 1960"] = "KNIGHT 1960",
	["INSIGNIA"] = "INSIGNIA",
	["ORBE MARINO"] = "SEA ORB",
	["BUZO"] = "DIVER",
	["REMOLINO"] = "WHIRLPOOL",
	["EL OBJETO"] = "THE OBJECT",
	["CILINDRO"] = "CYLINDER",
	["PIRAMIDE"] = "PYRAMID",
	["LUZ DEL HIELO"] = "ICE LIGHT",
	["EL GIGANTE"] = "THE GIANT",
}

-- textos con números u otras partes que cambian
local PATRONES = {
	{ "^NIVEL (%d+)$", "LEVEL %1" },
	{ "^VUELTA (%d+)$", "LOOP %1" },
	{ "^FASE (%d+)$", "PHASE %1" },
	{ "^RAPIDO %+(%d+)$", "SPEED +%1" },
	{ "^RONDA (%d+) COMPLETA$", "ROUND %1 CLEAR" },
	{ "^PUESTO (%d+) DE (%d+)$", "RANK %1 OF %2" },
	{ "^MEJOR (.+)$", "BEST %1" },
	{ "^DANO: (%a+)$", "DAMAGE: %1" },
	{ "^CHOQUES: (%a+)$", "HITBOX: %1" },
	{ "^LENTO: (.+)$", "SLOW: %1" },
	{ "^N(%d+)$", "L%1" },
	{ "^PIEZA (%d+) DE (%d+)$", "PIECE %1 OF %2" },
}
local PALABRAS = { SI = "YES", NO = "NO" }

function I.t(cadena)
	cadena = tostring(cadena)
	if I.actual ~= "en" then return cadena end
	if EN[cadena] then return EN[cadena] end
	-- ayuda de un botón: "Y: ESCUDO", "B: RAYO"
	local boton, que = cadena:match("^([ABY]): (.+)$")
	if boton then return boton .. ": " .. I.t(que) end
	-- fila elegida de un menú: "< TEXTO >"
	local dentro = cadena:match("^< (.+) >$")
	if dentro then return "< " .. I.t(dentro) .. " >" end
	for _, p in ipairs(PATRONES) do
		local hecho, n = cadena:gsub(p[1], p[2])
		if n > 0 then
			return (hecho:gsub("%a+$", function(w) return PALABRAS[w] or w end))
		end
	end
	return cadena
end

-- "es", "en", "en-US", "es_CO"... → uno de los idiomas del juego (o nil)
function I.normalizar(codigo)
	local c = tostring(codigo or ""):lower():match("^(%a%a)")
	for _, i in ipairs(I.IDIOMAS) do
		if i == c then return i end
	end
	return nil
end

function I.elegir(codigo)
	I.actual = I.normalizar(codigo) or I.actual
end

function I.siguiente()
	I.actual = I.actual == "es" and "en" or "es"
	return I.actual
end

return I

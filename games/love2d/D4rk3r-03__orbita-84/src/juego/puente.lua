-- Puente con la página web que envuelve al juego (YouTube Playables).
-- La página le pasa argumentos al arrancar y el juego le avisa cosas con
-- líneas "ORBITA84:tipo:dato" por la salida estándar, que la página lee.
--   --youtube          el juego corre dentro de YouTube: guarda en su nube
--   --ajustes=a|b|c    líneas de ajustes.txt guardadas en la nube (separadas por |)
--   --tactil           mostrar los controles táctiles desde el principio
--   --idioma=en        idioma del jugador (si no eligió otro en la portada)

local P = { activo = false, tactil = false }

function P.iniciar(argumentos)
	for _, a in ipairs(argumentos or {}) do
		if a == "--youtube" then P.activo = true end
		if a == "--tactil" then P.tactil = true end
		local ajustes = type(a) == "string" and a:match("^%-%-ajustes=(.*)$")
		if ajustes then P.ajustes = ajustes end
		local idioma = type(a) == "string" and a:match("^%-%-idioma=(.*)$")
		if idioma then P.idioma = idioma end
	end
end

-- líneas de ajustes que llegaron de la nube (nil si no hay)
function P.lineas()
	if not P.ajustes or P.ajustes == "" then return nil end
	local lineas = {}
	for linea in P.ajustes:gmatch("[^|]+") do lineas[#lineas + 1] = linea end
	return lineas
end

function P.avisar(tipo, dato)
	if P.activo then
		print(("ORBITA84:%s:%s"):format(tipo, tostring(dato or "")))
		io.stdout:flush()
	end
end

return P

-- Levels: los niveles del juego, descritos como DATOS.
-- 0 = vacío · 1 = ladrillo normal · 2 = ladrillo resistente.
-- Agregar un nivel nuevo es agregar una tabla, sin tocar la lógica.
return {
    { -- Nivel 1
        { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
        { 1, 2, 1, 1, 1, 1, 1, 1, 2, 1 },
        { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    },
    { -- Nivel 2
        { 2, 2, 1, 1, 1, 1, 1, 1, 2, 2 },
        { 1, 1, 2, 1, 1, 1, 1, 2, 1, 1 },
        { 1, 1, 1, 2, 1, 1, 2, 1, 1, 1 },
        { 1, 1, 1, 1, 2, 2, 1, 1, 1, 1 },
    },
    { -- Nivel 3
        { 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 },
        { 1, 1, 2, 1, 1, 1, 1, 2, 1, 1 },
        { 1, 2, 1, 1, 2, 2, 1, 1, 2, 1 },
        { 2, 1, 1, 1, 1, 1, 1, 1, 1, 2 },
    },
    { -- Nivel 4 · Corona final (propuesta Jonnathan)
        { 0, 0, 1, 2, 2, 2, 2, 1, 0, 0 },
        { 0, 2, 1, 1, 2, 2, 1, 1, 2, 0 },
        { 2, 1, 1, 2, 1, 1, 2, 1, 1, 2 },
        { 2, 1, 2, 1, 1, 1, 1, 2, 1, 2 },
        { 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 },
    },
}

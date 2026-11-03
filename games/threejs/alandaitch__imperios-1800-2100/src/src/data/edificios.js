/**
 * Tabla de edificios. El índice ES el defId. Las medidas están en metros
 * y en celdas de rejilla (1 celda = 2 m) para el emplazado y la navegación.
 */
const c = (alimento = 0, materiales = 0, capital = 0, energia = 0) => ({ alimento, materiales, capital, energia });

export const EDIFICIOS = [
  { clave: 'sede', nombre: 'Sede Municipal', edad: 0, coste: c(0, 275, 100), tiempo: 150,
    vida: 2400, celdas: [5, 5], armadura: 3, armaduraPerf: 5, vision: 34, pop: 5,
    deposito: ['alimento', 'materiales', 'capital', 'energia'], entrena: ['colono'],
    descripcion: 'El corazón del imperio. Deposita todos los recursos y avanza de edad.' },

  { clave: 'vivienda', nombre: 'Vivienda', edad: 0, coste: c(0, 30), tiempo: 25,
    vida: 620, celdas: [2, 2], armadura: 0, armaduraPerf: 3, vision: 12, pop: 5,
    descripcion: 'Aloja a 5 habitantes más.' },

  { clave: 'granja', nombre: 'Granja', edad: 0, coste: c(0, 60), tiempo: 15,
    vida: 480, celdas: [3, 3], armadura: 0, armaduraPerf: 0, vision: 8, recursoInfinito: 'alimento',
    descripcion: 'Alimento renovable. Se replanta cuando se agota.' },

  { clave: 'molino', nombre: 'Molino', edad: 0, coste: c(0, 100), tiempo: 35,
    vida: 900, celdas: [3, 3], armadura: 0, armaduraPerf: 4, vision: 20, deposito: ['alimento'],
    descripcion: 'Punto de acopio de Alimento. Después será silo y luego planta agroquímica.' },

  { clave: 'aserradero', nombre: 'Aserradero', edad: 0, coste: c(0, 100), tiempo: 35,
    vida: 900, celdas: [3, 3], armadura: 0, armaduraPerf: 4, vision: 20, deposito: ['materiales'],
    descripcion: 'Punto de acopio de Materiales, junto al bosque.' },

  { clave: 'mina', nombre: 'Campamento Minero', edad: 0, coste: c(0, 100), tiempo: 35,
    vida: 900, celdas: [3, 3], armadura: 0, armaduraPerf: 4, vision: 20, deposito: ['capital', 'energia'],
    descripcion: 'Punto de acopio de Capital y Energía, junto a la veta.' },

  { clave: 'cuartel', nombre: 'Cuartel', edad: 0, coste: c(0, 175), tiempo: 50,
    vida: 1500, celdas: [4, 4], armadura: 2, armaduraPerf: 5, vision: 24,
    entrena: ['miliciano', 'fusilero_linea', 'infante_asalto', 'fusilero_motorizado', 'exoinfante', 'piquero', 'artillero_at', 'bazoquero', 'misilista', 'lanza_enjambre'],
    descripcion: 'Entrena infantería. Lo primero que se construye cuando aprieta el vecino.' },

  { clave: 'empalizada', nombre: 'Empalizada', edad: 0, coste: c(0, 2), tiempo: 5,
    vida: 250, celdas: [1, 1], armadura: 0, armaduraPerf: 2, vision: 8, muro: true,
    descripcion: 'Madera y alambre. Frena, no detiene.' },

  { clave: 'astillero', nombre: 'Astillero', edad: 0, coste: c(0, 150), tiempo: 40,
    vida: 1400, celdas: [4, 3], armadura: 0, armaduraPerf: 6, vision: 26, costero: true,
    entrena: ['pesquero', 'transporte', 'fragata', 'destructor'],
    descripcion: 'Botadura de naves. Debe tocar el agua.' },

  /* ------------ Edad Eléctrica ------------ */
  { clave: 'mercado', nombre: 'Mercado', edad: 1, coste: c(0, 175), tiempo: 60,
    vida: 1800, celdas: [4, 4], armadura: 1, armaduraPerf: 6, vision: 30,
    entrena: ['caravana'], comercio: true,
    descripcion: 'Compra y vende recursos. Base de las rutas comerciales.' },

  { clave: 'fundicion', nombre: 'Fundición', edad: 1, coste: c(0, 150), tiempo: 40,
    vida: 1500, celdas: [3, 3], armadura: 1, armaduraPerf: 5, vision: 22,
    descripcion: 'Mejoras de armas y armaduras para todo el ejército.' },

  { clave: 'poligono', nombre: 'Polígono de Tiro', edad: 1, coste: c(0, 175), tiempo: 50,
    vida: 1500, celdas: [4, 4], armadura: 2, armaduraPerf: 5, vision: 24,
    entrena: ['tirador', 'francotirador', 'tirador_designado', 'tirador_riel', 'escaramuzador', 'cazador_dron'],
    descripcion: 'Entrena tiradores. La distancia es un arma.' },

  { clave: 'establo', nombre: 'Establo', edad: 1, coste: c(0, 175), tiempo: 50,
    vida: 1500, celdas: [4, 4], armadura: 2, armaduraPerf: 5, vision: 24,
    entrena: ['husar', 'blindado_ligero', 'tanque_medio', 'tanque_autonomo'],
    descripcion: 'Primero caballos, después motores. Todo lo que corre.' },

  { clave: 'taller', nombre: 'Taller de Artillería', edad: 1, coste: c(0, 200), tiempo: 60,
    vida: 1600, celdas: [4, 4], armadura: 2, armaduraPerf: 6, vision: 24,
    entrena: ['canon_campana', 'obus', 'artilleria_auto', 'canon_riel', 'ariete_blindado'],
    descripcion: 'Piezas pesadas. Lentas, caras y decisivas.' },

  { clave: 'torreta', nombre: 'Torreta', edad: 1, coste: c(0, 125, 0), tiempo: 40,
    vida: 1100, celdas: [2, 2], armadura: 4, armaduraPerf: 8, vision: 34,
    ataque: 16, alcance: 10, cadencia: 2.0, proyectil: 'bala', guarnicion: 5,
    descripcion: 'Fuego defensivo. Los aldeanos pueden refugiarse adentro.' },

  /* ------------ Edad Atómica ------------ */
  { clave: 'muro_hormigon', nombre: 'Muro de Hormigón', edad: 2, coste: c(0, 5), tiempo: 8,
    vida: 1400, celdas: [1, 1], armadura: 8, armaduraPerf: 10, vision: 8, muro: true,
    descripcion: 'Hormigón armado. Ahora sí hay que traer artillería.' },

  { clave: 'ciudadela', nombre: 'Ciudadela', edad: 2, coste: c(0, 250, 400), tiempo: 200,
    vida: 4800, celdas: [6, 6], armadura: 10, armaduraPerf: 12, vision: 40,
    ataque: 34, alcance: 13, cadencia: 1.6, proyectil: 'obus', guarnicion: 20,
    entrena: [], unica: true,
    descripcion: 'Fortaleza y símbolo. Entrena la unidad única de tu civilización.' },

  { clave: 'instituto', nombre: 'Instituto', edad: 2, coste: c(0, 200), tiempo: 60,
    vida: 1800, celdas: [4, 4], armadura: 1, armaduraPerf: 7, vision: 26,
    descripcion: 'Investigación: defensas, visión, economía y ciencia militar.' },

  { clave: 'ministerio', nombre: 'Ministerio de Información', edad: 2, coste: c(0, 175), tiempo: 40,
    vida: 1400, celdas: [4, 4], armadura: 1, armaduraPerf: 6, vision: 26,
    entrena: ['agitador', 'hacker'], reliquias: true,
    descripcion: 'Custodia Patentes y forma agitadores. La guerra también es de relato.' },

  /* ------------ Edad de la Información ------------ */
  { clave: 'aerodromo', nombre: 'Aeródromo', edad: 3, coste: c(0, 250, 150), tiempo: 70,
    vida: 2000, celdas: [5, 4], armadura: 2, armaduraPerf: 7, vision: 30,
    entrena: ['dron_ataque', 'enjambre'],
    descripcion: 'Pista y hangar. Abre la tercera dimensión de la guerra.' },

  { clave: 'central', nombre: 'Central Energética', edad: 3, coste: c(0, 220, 120), tiempo: 65,
    vida: 2000, celdas: [4, 4], armadura: 2, armaduraPerf: 6, vision: 24, generaEnergia: 0.8,
    descripcion: 'Produce Energía sola, sin aldeanos. Explota fuerte si la destruyen.' },

  /* ------------ Edad Sintética ------------ */
  { clave: 'maravilla', nombre: 'Maravilla', edad: 4, coste: c(1000, 1000, 1000, 1000), tiempo: 420,
    vida: 6000, celdas: [8, 8], armadura: 10, armaduraPerf: 14, vision: 40, maravilla: true,
    descripcion: 'Si sobrevive el conteo, ganás la partida. Todo el mundo lo va a saber.' },
];

export const EDIFICIO_POR_CLAVE = new Map(EDIFICIOS.map((e, i) => [e.clave, i]));
export const defEdificio = (clave) => EDIFICIOS[EDIFICIO_POR_CLAVE.get(clave)];

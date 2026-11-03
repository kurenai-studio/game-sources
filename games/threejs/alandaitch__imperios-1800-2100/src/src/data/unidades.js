/**
 * Tabla de unidades. El índice del array ES el defId que guarda World.defId.
 *
 * Campos:
 *  clave        identificador estable (lo usan las fábricas de malla)
 *  nombre       nombre visible, en español
 *  linea        línea de mejora (las unidades de la misma línea comparten silueta)
 *  clase        'infanteria'|'tirador'|'caballeria'|'asedio'|'aldeano'|'apoyo'|'nave'|'aereo'
 *  edad         edad mínima
 *  coste        { alimento, materiales, capital, energia }
 *  tiempo       segundos de entrenamiento
 *  pop          espacio de población
 *  vida, ataque, alcance, cadencia (s), armadura, armaduraPerf, velocidad (m/s), vision
 *  bonos        { claseObjetivo: daño extra }
 *  desde        edificio que la entrena
 *  proyectil    tipo de proyectil si es a distancia
 */

const c = (alimento = 0, materiales = 0, capital = 0, energia = 0) => ({ alimento, materiales, capital, energia });

export const UNIDADES = [
  /* ---------------- 0. Aldeano ---------------- */
  { clave: 'colono', nombre: 'Colono', linea: 'colono', clase: 'aldeano', edad: 0,
    coste: c(50), tiempo: 25, pop: 1, vida: 40, ataque: 4, alcance: 0.6, cadencia: 2.0,
    armadura: 0, armaduraPerf: 0, velocidad: 4.6, vision: 22, desde: 'sede',
    descripcion: 'Recolecta, construye y repara. La columna vertebral de tu imperio.' },

  /* ---------------- Infantería ---------------- */
  { clave: 'miliciano', nombre: 'Miliciano', linea: 'infanteria', clase: 'infanteria', edad: 0,
    coste: c(60, 20), tiempo: 21, pop: 1, vida: 45, ataque: 9, alcance: 0.7, cadencia: 2.0,
    armadura: 0, armaduraPerf: 1, velocidad: 4.5, vision: 22, desde: 'cuartel',
    descripcion: 'Voluntarios con mosquete y bayoneta. Baratos y numerosos.' },
  { clave: 'fusilero_linea', nombre: 'Fusilero de Línea', linea: 'infanteria', clase: 'infanteria', edad: 1,
    coste: c(60, 20), tiempo: 21, pop: 1, vida: 70, ataque: 13, alcance: 0.8, cadencia: 2.0,
    armadura: 1, armaduraPerf: 1, velocidad: 4.5, vision: 24, desde: 'cuartel', mejoraDe: 'miliciano',
    descripcion: 'Formación cerrada, fuego por descargas. Aguanta el choque frontal.' },
  { clave: 'infante_asalto', nombre: 'Infante de Asalto', linea: 'infanteria', clase: 'infanteria', edad: 2,
    coste: c(60, 20), tiempo: 20, pop: 1, vida: 100, ataque: 18, alcance: 0.9, cadencia: 1.9,
    armadura: 2, armaduraPerf: 2, velocidad: 4.7, vision: 25, desde: 'cuartel', mejoraDe: 'fusilero_linea',
    descripcion: 'Subfusil, casco de acero y granadas. Rompe líneas y edificios.' },
  { clave: 'fusilero_motorizado', nombre: 'Fusilero Motorizado', linea: 'infanteria', clase: 'infanteria', edad: 3,
    coste: c(60, 20), tiempo: 18, pop: 1, vida: 130, ataque: 24, alcance: 1.0, cadencia: 1.8,
    armadura: 3, armaduraPerf: 3, velocidad: 5.0, vision: 27, desde: 'cuartel', mejoraDe: 'infante_asalto',
    descripcion: 'Chaleco balístico, visión nocturna y radio táctica.' },
  { clave: 'exoinfante', nombre: 'Exoinfante', linea: 'infanteria', clase: 'infanteria', edad: 4,
    coste: c(60, 30, 10), tiempo: 17, pop: 1, vida: 175, ataque: 32, alcance: 1.1, cadencia: 1.6,
    armadura: 5, armaduraPerf: 4, velocidad: 5.4, vision: 30, desde: 'cuartel', mejoraDe: 'fusilero_motorizado',
    descripcion: 'Exoesqueleto asistido. Corre más rápido de lo que un humano debería.' },

  /* ---------------- Anti-blindaje (línea del piquero) ---------------- */
  { clave: 'piquero', nombre: 'Piquero', linea: 'antiblindaje', clase: 'infanteria', edad: 0,
    coste: c(35, 25), tiempo: 22, pop: 1, vida: 55, ataque: 4, alcance: 0.9, cadencia: 3.0,
    armadura: 0, armaduraPerf: 0, velocidad: 4.4, vision: 20, desde: 'cuartel',
    bonos: { caballeria: 18, nave: 6 },
    descripcion: 'Cuadro de picas contra la carga de caballería.' },
  { clave: 'artillero_at', nombre: 'Artillero Antitanque', linea: 'antiblindaje', clase: 'infanteria', edad: 1,
    coste: c(35, 25), tiempo: 22, pop: 1, vida: 65, ataque: 5, alcance: 5.0, cadencia: 3.0,
    armadura: 0, armaduraPerf: 0, velocidad: 4.4, vision: 22, desde: 'cuartel', mejoraDe: 'piquero',
    bonos: { caballeria: 26, asedio: 12, nave: 8 }, proyectil: 'cohete',
    descripcion: 'Fusil antitanque de cerrojo. Un solo tiro y hay que recargar.' },
  { clave: 'bazoquero', nombre: 'Bazoquero', linea: 'antiblindaje', clase: 'infanteria', edad: 2,
    coste: c(35, 25), tiempo: 20, pop: 1, vida: 85, ataque: 8, alcance: 6.0, cadencia: 2.8,
    armadura: 1, armaduraPerf: 0, velocidad: 4.5, vision: 24, desde: 'cuartel', mejoraDe: 'artillero_at',
    bonos: { caballeria: 40, asedio: 20, nave: 12 }, proyectil: 'cohete',
    descripcion: 'Carga hueca. Convierte un tanque en chatarra humeante.' },
  { clave: 'misilista', nombre: 'Misilista', linea: 'antiblindaje', clase: 'infanteria', edad: 3,
    coste: c(35, 30), tiempo: 19, pop: 1, vida: 105, ataque: 10, alcance: 8.0, cadencia: 2.6,
    armadura: 2, armaduraPerf: 1, velocidad: 4.6, vision: 27, desde: 'cuartel', mejoraDe: 'bazoquero',
    bonos: { caballeria: 55, asedio: 28, aereo: 30, nave: 16 }, proyectil: 'misil',
    descripcion: 'Misil guiado por infrarrojos. También derriba aeronaves.' },
  { clave: 'lanza_enjambre', nombre: 'Lanzaenjambres', linea: 'antiblindaje', clase: 'infanteria', edad: 4,
    coste: c(35, 35, 15), tiempo: 18, pop: 1, vida: 130, ataque: 13, alcance: 9.0, cadencia: 2.2,
    armadura: 3, armaduraPerf: 2, velocidad: 4.8, vision: 30, desde: 'cuartel', mejoraDe: 'misilista',
    bonos: { caballeria: 70, asedio: 36, aereo: 45, nave: 20 }, proyectil: 'enjambre',
    descripcion: 'Lanza una nube de micromisiles que buscan blanco por su cuenta.' },

  /* ---------------- Tiradores ---------------- */
  { clave: 'tirador', nombre: 'Tirador', linea: 'tirador', clase: 'tirador', edad: 1,
    coste: c(0, 25, 45), tiempo: 27, pop: 1, vida: 35, ataque: 8, alcance: 9.0, cadencia: 2.0,
    armadura: 0, armaduraPerf: 0, velocidad: 4.4, vision: 30, desde: 'poligono', proyectil: 'bala',
    descripcion: 'Rifle estriado. Pega desde lejos y muere de cerca.' },
  { clave: 'francotirador', nombre: 'Francotirador', linea: 'tirador', clase: 'tirador', edad: 2,
    coste: c(0, 25, 45), tiempo: 27, pop: 1, vida: 45, ataque: 11, alcance: 11.0, cadencia: 2.0,
    armadura: 0, armaduraPerf: 1, velocidad: 4.4, vision: 34, desde: 'poligono', mejoraDe: 'tirador', proyectil: 'bala',
    descripcion: 'Mira telescópica y paciencia. Alcance brutal.' },
  { clave: 'tirador_designado', nombre: 'Tirador Designado', linea: 'tirador', clase: 'tirador', edad: 3,
    coste: c(0, 25, 50), tiempo: 25, pop: 1, vida: 60, ataque: 14, alcance: 12.5, cadencia: 1.9,
    armadura: 1, armaduraPerf: 1, velocidad: 4.5, vision: 38, desde: 'poligono', mejoraDe: 'francotirador', proyectil: 'bala',
    descripcion: 'Telemetría láser: nunca falla el primer disparo.' },
  { clave: 'tirador_riel', nombre: 'Tirador de Riel', linea: 'tirador', clase: 'tirador', edad: 4,
    coste: c(0, 30, 60, 20), tiempo: 24, pop: 1, vida: 75, ataque: 19, alcance: 14.0, cadencia: 1.8,
    armadura: 2, armaduraPerf: 2, velocidad: 4.6, vision: 42, desde: 'poligono', mejoraDe: 'tirador_designado', proyectil: 'riel',
    descripcion: 'Proyectil hipersónico. Atraviesa dos cuerpos y sigue de largo.' },

  { clave: 'escaramuzador', nombre: 'Escaramuzador', linea: 'escaramuza', clase: 'tirador', edad: 1,
    coste: c(25, 35), tiempo: 22, pop: 1, vida: 30, ataque: 3, alcance: 6.0, cadencia: 3.0,
    armadura: 0, armaduraPerf: 3, velocidad: 4.4, vision: 24, desde: 'poligono', proyectil: 'bala',
    bonos: { tirador: 12 },
    descripcion: 'Tiradores dispersos que cazan a otros tiradores.' },
  { clave: 'cazador_dron', nombre: 'Cazador de Drones', linea: 'escaramuza', clase: 'tirador', edad: 3,
    coste: c(25, 40), tiempo: 21, pop: 1, vida: 55, ataque: 6, alcance: 8.0, cadencia: 2.6,
    armadura: 1, armaduraPerf: 6, velocidad: 4.7, vision: 30, desde: 'poligono', mejoraDe: 'escaramuzador', proyectil: 'bala',
    bonos: { tirador: 20, aereo: 24 },
    descripcion: 'Escopeta de perdigones y jammer de banda ancha.' },

  /* ---------------- Caballería → blindados ---------------- */
  { clave: 'husar', nombre: 'Húsar', linea: 'blindado', clase: 'caballeria', edad: 1,
    coste: c(80, 0, 20), tiempo: 30, pop: 1, vida: 100, ataque: 10, alcance: 0.9, cadencia: 1.9,
    armadura: 1, armaduraPerf: 0, velocidad: 7.5, vision: 30, desde: 'establo',
    descripcion: 'Sable, galope y sorpresa. Ideal para incordiar recolectores.' },
  { clave: 'blindado_ligero', nombre: 'Blindado Ligero', linea: 'blindado', clase: 'caballeria', edad: 2,
    coste: c(80, 40, 20), tiempo: 30, pop: 1, vida: 150, ataque: 16, alcance: 3.0, cadencia: 1.9,
    armadura: 3, armaduraPerf: 1, velocidad: 7.0, vision: 32, desde: 'establo', mejoraDe: 'husar', proyectil: 'bala',
    descripcion: 'Semioruga con ametralladora. Rápido y molesto.' },
  { clave: 'tanque_medio', nombre: 'Tanque Medio', linea: 'blindado', clase: 'caballeria', edad: 3,
    coste: c(80, 60, 40), tiempo: 32, pop: 2, vida: 260, ataque: 30, alcance: 5.0, cadencia: 2.6,
    armadura: 6, armaduraPerf: 3, velocidad: 5.6, vision: 32, desde: 'establo', mejoraDe: 'blindado_ligero', proyectil: 'obus',
    bonos: { edificio: 10 },
    descripcion: 'Cañón estabilizado y blindaje compuesto. El puño del ejército.' },
  { clave: 'tanque_autonomo', nombre: 'Tanque Autónomo', linea: 'blindado', clase: 'caballeria', edad: 4,
    coste: c(80, 80, 60, 30), tiempo: 32, pop: 2, vida: 360, ataque: 42, alcance: 6.5, cadencia: 2.3,
    armadura: 9, armaduraPerf: 5, velocidad: 6.2, vision: 36, desde: 'establo', mejoraDe: 'tanque_medio', proyectil: 'obus',
    bonos: { edificio: 16 },
    descripcion: 'Sin tripulación, sin miedo. Coordina fuego con sus pares.' },

  /* ---------------- Asedio ---------------- */
  { clave: 'canon_campana', nombre: 'Cañón de Campaña', linea: 'artilleria', clase: 'asedio', edad: 1,
    coste: c(0, 160, 80), tiempo: 40, pop: 2, vida: 120, ataque: 40, alcance: 11.0, cadencia: 5.0,
    armadura: 1, armaduraPerf: 4, velocidad: 2.4, vision: 26, desde: 'taller', proyectil: 'obus',
    bonos: { edificio: 90, asedio: 20 }, salpicadura: 1.2,
    descripcion: 'Ánima lisa sobre cureña. Los muros dejan de ser un problema.' },
  { clave: 'obus', nombre: 'Obús', linea: 'artilleria', clase: 'asedio', edad: 2,
    coste: c(0, 180, 90), tiempo: 42, pop: 2, vida: 150, ataque: 55, alcance: 13.0, cadencia: 5.0,
    armadura: 2, armaduraPerf: 5, velocidad: 2.6, vision: 28, desde: 'taller', mejoraDe: 'canon_campana', proyectil: 'obus',
    bonos: { edificio: 130, asedio: 30 }, salpicadura: 1.8,
    descripcion: 'Tiro parabólico: cae desde arriba, ignora la muralla.' },
  { clave: 'artilleria_auto', nombre: 'Artillería Autopropulsada', linea: 'artilleria', clase: 'asedio', edad: 3,
    coste: c(0, 200, 120), tiempo: 45, pop: 3, vida: 200, ataque: 70, alcance: 16.0, cadencia: 4.6,
    armadura: 4, armaduraPerf: 6, velocidad: 4.2, vision: 30, desde: 'taller', mejoraDe: 'obus', proyectil: 'obus',
    bonos: { edificio: 170, asedio: 40 }, salpicadura: 2.4,
    descripcion: 'Dispara, se mueve, vuelve a disparar. Contrabatería incluida.' },
  { clave: 'canon_riel', nombre: 'Cañón de Riel', linea: 'artilleria', clase: 'asedio', edad: 4,
    coste: c(0, 240, 160, 90), tiempo: 48, pop: 3, vida: 240, ataque: 95, alcance: 20.0, cadencia: 4.2,
    armadura: 6, armaduraPerf: 8, velocidad: 3.8, vision: 34, desde: 'taller', mejoraDe: 'artilleria_auto', proyectil: 'riel',
    bonos: { edificio: 220, asedio: 55 }, salpicadura: 2.8,
    descripcion: 'Sin pólvora: pura energía cinética a mach 7.' },

  { clave: 'ariete_blindado', nombre: 'Ariete Blindado', linea: 'ariete', clase: 'asedio', edad: 2,
    coste: c(0, 160, 0), tiempo: 36, pop: 2, vida: 340, ataque: 12, alcance: 0.8, cadencia: 4.5,
    armadura: 0, armaduraPerf: 12, velocidad: 3.0, vision: 18, desde: 'taller',
    bonos: { edificio: 140 },
    descripcion: 'Bulldozer acorazado. Le rebotan las balas y come muros.' },

  /* ---------------- Apoyo ---------------- */
  { clave: 'agitador', nombre: 'Agitador', linea: 'apoyo', clase: 'apoyo', edad: 2,
    coste: c(0, 0, 100), tiempo: 45, pop: 1, vida: 30, ataque: 0, alcance: 8.0, cadencia: 6.0,
    armadura: 0, armaduraPerf: 0, velocidad: 4.2, vision: 34, desde: 'ministerio',
    cura: 12, convierte: true,
    descripcion: 'Panfletos y discursos: convierte unidades enemigas y cura a las tuyas.' },
  { clave: 'hacker', nombre: 'Operador de Red', linea: 'apoyo', clase: 'apoyo', edad: 3,
    coste: c(0, 20, 120), tiempo: 42, pop: 1, vida: 45, ataque: 0, alcance: 10.0, cadencia: 5.0,
    armadura: 0, armaduraPerf: 1, velocidad: 4.4, vision: 40, desde: 'ministerio', mejoraDe: 'agitador',
    cura: 20, convierte: true,
    descripcion: 'Toma el control remoto de vehículos y drones enemigos.' },
  { clave: 'caravana', nombre: 'Caravana Comercial', linea: 'comercio', clase: 'apoyo', edad: 1,
    coste: c(0, 50, 50), tiempo: 51, pop: 1, vida: 70, ataque: 0, alcance: 0, cadencia: 0,
    armadura: 0, armaduraPerf: 0, velocidad: 4.6, vision: 20, desde: 'mercado',
    descripcion: 'Va y vuelve entre mercados generando Capital.' },

  /* ---------------- Aéreo ---------------- */
  { clave: 'dron_ataque', nombre: 'Dron de Ataque', linea: 'aereo', clase: 'aereo', edad: 3,
    coste: c(0, 60, 80, 40), tiempo: 30, pop: 2, vida: 110, ataque: 22, alcance: 7.0, cadencia: 2.2,
    armadura: 0, armaduraPerf: 2, velocidad: 9.0, vision: 42, desde: 'aerodromo', proyectil: 'misil', vuela: true,
    descripcion: 'Ignora el terreno y la muralla. Frágil frente al fuego antiaéreo.' },
  { clave: 'enjambre', nombre: 'Enjambre', linea: 'aereo', clase: 'aereo', edad: 4,
    coste: c(0, 80, 100, 70), tiempo: 28, pop: 2, vida: 140, ataque: 30, alcance: 8.0, cadencia: 1.6,
    armadura: 1, armaduraPerf: 3, velocidad: 10.5, vision: 46, desde: 'aerodromo', mejoraDe: 'dron_ataque', proyectil: 'enjambre', vuela: true,
    salpicadura: 1.4,
    descripcion: 'Cientos de micro-drones con una sola mente compartida.' },

  /* ---------------- Navales ---------------- */
  { clave: 'pesquero', nombre: 'Pesquero', linea: 'naval', clase: 'nave', edad: 0,
    coste: c(0, 75), tiempo: 40, pop: 1, vida: 60, ataque: 0, alcance: 0, cadencia: 0,
    armadura: 0, armaduraPerf: 4, velocidad: 4.6, vision: 30, desde: 'astillero', naval: true,
    descripcion: 'Saca Alimento del agua sin volver a la costa.' },
  { clave: 'fragata', nombre: 'Fragata', linea: 'naval', clase: 'nave', edad: 1,
    coste: c(0, 90, 30), tiempo: 36, pop: 2, vida: 160, ataque: 14, alcance: 10.0, cadencia: 3.0,
    armadura: 0, armaduraPerf: 6, velocidad: 5.0, vision: 34, desde: 'astillero', proyectil: 'obus', naval: true,
    descripcion: 'Andanadas de babor y estribor. Domina la costa.' },
  { clave: 'destructor', nombre: 'Destructor', linea: 'naval', clase: 'nave', edad: 3,
    coste: c(0, 120, 60, 20), tiempo: 36, pop: 2, vida: 280, ataque: 26, alcance: 13.0, cadencia: 2.6,
    armadura: 2, armaduraPerf: 8, velocidad: 5.6, vision: 40, desde: 'astillero', mejoraDe: 'fragata', proyectil: 'misil', naval: true,
    descripcion: 'Misiles y sonar. Nada se le acerca sin que lo vea antes.' },
  { clave: 'transporte', nombre: 'Transporte', linea: 'naval', clase: 'nave', edad: 1,
    coste: c(0, 125), tiempo: 46, pop: 1, vida: 220, ataque: 0, alcance: 0, cadencia: 0,
    armadura: 4, armaduraPerf: 8, velocidad: 5.4, vision: 26, desde: 'astillero', naval: true, capacidad: 10,
    descripcion: 'Cruza tropas de una orilla a la otra.' },
];

export const UNIDAD_POR_CLAVE = new Map(UNIDADES.map((u, i) => [u.clave, i]));
export const defUnidad = (clave) => UNIDADES[UNIDAD_POR_CLAVE.get(clave)];

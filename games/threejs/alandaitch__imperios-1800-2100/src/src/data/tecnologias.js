/**
 * Árbol tecnológico. `efecto(estado, jugador)` se aplica al completarse.
 * `estado` es el objeto de modificadores del jugador que mantiene sim/Economia.js:
 *   { velRecoleccion:{}, ataque:{}, armadura:{}, vida:{}, velocidad:{}, vision:{}, ... }
 */
const c = (alimento = 0, materiales = 0, capital = 0, energia = 0) => ({ alimento, materiales, capital, energia });

export const TECNOLOGIAS = [
  /* ---- Economía ---- */
  { clave: 'arado', nombre: 'Arado de Acero', edad: 0, en: 'molino', coste: c(75), tiempo: 20,
    descripcion: '+15% de recolección de Alimento.',
    efecto: (m) => { m.velRecoleccion.alimento *= 1.15; } },
  { clave: 'cosechadora', nombre: 'Cosechadora', edad: 1, en: 'molino', coste: c(180, 60), tiempo: 45,
    requiere: 'arado', descripcion: '+20% más de Alimento y las granjas duran el doble.',
    efecto: (m) => { m.velRecoleccion.alimento *= 1.20; m.duracionGranja *= 2; } },
  { clave: 'agroquimica', nombre: 'Agroquímica', edad: 3, en: 'molino', coste: c(300, 150), tiempo: 60,
    requiere: 'cosechadora', descripcion: '+25% de Alimento. Las granjas no se agotan.',
    efecto: (m) => { m.velRecoleccion.alimento *= 1.25; m.granjaInfinita = true; } },

  { clave: 'sierra_circular', nombre: 'Sierra Circular', edad: 0, en: 'aserradero', coste: c(0, 100), tiempo: 25,
    descripcion: '+20% de recolección de Materiales.',
    efecto: (m) => { m.velRecoleccion.materiales *= 1.20; } },
  { clave: 'motosierra', nombre: 'Motosierra', edad: 2, en: 'aserradero', coste: c(0, 200, 100), tiempo: 50,
    requiere: 'sierra_circular', descripcion: '+25% de Materiales.',
    efecto: (m) => { m.velRecoleccion.materiales *= 1.25; } },
  { clave: 'talado_robotico', nombre: 'Talado Robótico', edad: 4, en: 'aserradero', coste: c(0, 300, 200, 100), tiempo: 60,
    requiere: 'motosierra', descripcion: '+30% de Materiales y los colonos cargan +5.',
    efecto: (m) => { m.velRecoleccion.materiales *= 1.30; m.capacidadCarga += 5; } },

  { clave: 'dinamita', nombre: 'Dinamita', edad: 1, en: 'mina', coste: c(0, 100, 75), tiempo: 30,
    descripcion: '+20% de Capital y Energía extraídos.',
    efecto: (m) => { m.velRecoleccion.capital *= 1.20; m.velRecoleccion.energia *= 1.20; } },
  { clave: 'perforadora', nombre: 'Perforadora Rotativa', edad: 2, en: 'mina', coste: c(0, 150, 150), tiempo: 45,
    requiere: 'dinamita', descripcion: '+25% de Capital y Energía.',
    efecto: (m) => { m.velRecoleccion.capital *= 1.25; m.velRecoleccion.energia *= 1.25; } },
  { clave: 'mineria_autonoma', nombre: 'Minería Autónoma', edad: 4, en: 'mina', coste: c(0, 250, 250, 150), tiempo: 60,
    requiere: 'perforadora', descripcion: '+30% de Capital y Energía.',
    efecto: (m) => { m.velRecoleccion.capital *= 1.30; m.velRecoleccion.energia *= 1.30; } },

  { clave: 'carretilla', nombre: 'Carretilla', edad: 1, en: 'sede', coste: c(175, 50), tiempo: 45,
    descripcion: 'Los colonos caminan +10% y cargan +3.',
    efecto: (m) => { m.velocidad.aldeano *= 1.10; m.capacidadCarga += 3; } },
  { clave: 'camioneta', nombre: 'Camioneta', edad: 2, en: 'sede', coste: c(300, 200), tiempo: 60,
    requiere: 'carretilla', descripcion: 'Los colonos caminan +12% y cargan +5.',
    efecto: (m) => { m.velocidad.aldeano *= 1.12; m.capacidadCarga += 5; } },
  { clave: 'exoesqueleto_civil', nombre: 'Exoesqueleto Civil', edad: 4, en: 'sede', coste: c(400, 300, 200), tiempo: 70,
    requiere: 'camioneta', descripcion: 'Colonos +15% de velocidad, +40 de vida y construyen 30% más rápido.',
    efecto: (m) => { m.velocidad.aldeano *= 1.15; m.vidaExtra.aldeano += 40; m.velConstruccion *= 1.3; } },

  { clave: 'banca', nombre: 'Banca Moderna', edad: 1, en: 'mercado', coste: c(0, 0, 200), tiempo: 40,
    descripcion: 'Mejor tasa de cambio y +25% de Capital por comercio.',
    efecto: (m) => { m.tasaMercado *= 0.7; m.bonoComercio *= 1.25; } },
  { clave: 'contenedor', nombre: 'Contenedorización', edad: 3, en: 'mercado', coste: c(0, 200, 300), tiempo: 60,
    requiere: 'banca', descripcion: 'Caravanas +30% más rápidas y +30% de Capital.',
    efecto: (m) => { m.velocidad.comercio *= 1.3; m.bonoComercio *= 1.3; } },

  /* ---- Militar: ataque ---- */
  { clave: 'polvora_mejorada', nombre: 'Pólvora Mejorada', edad: 1, en: 'fundicion', coste: c(0, 100, 50), tiempo: 40,
    descripcion: '+2 de ataque a infantería y tiradores.',
    efecto: (m) => { m.ataque.infanteria += 2; m.ataque.tirador += 2; } },
  { clave: 'municion_perforante', nombre: 'Munición Perforante', edad: 2, en: 'fundicion', coste: c(0, 200, 100), tiempo: 55,
    requiere: 'polvora_mejorada', descripcion: '+3 de ataque a infantería, tiradores y blindados.',
    efecto: (m) => { m.ataque.infanteria += 3; m.ataque.tirador += 3; m.ataque.caballeria += 3; } },
  { clave: 'municion_guiada', nombre: 'Munición Guiada', edad: 3, en: 'fundicion', coste: c(0, 300, 200), tiempo: 65,
    requiere: 'municion_perforante', descripcion: '+4 de ataque a todo y +1 de alcance a los tiradores.',
    efecto: (m) => { for (const k in m.ataque) m.ataque[k] += 4; m.alcance.tirador += 1; } },
  { clave: 'nanomunicion', nombre: 'Nanomunición', edad: 4, en: 'fundicion', coste: c(0, 400, 300, 200), tiempo: 75,
    requiere: 'municion_guiada', descripcion: '+6 de ataque a todo el ejército.',
    efecto: (m) => { for (const k in m.ataque) m.ataque[k] += 6; } },

  /* ---- Militar: defensa ---- */
  { clave: 'placa_hierro', nombre: 'Placa de Hierro', edad: 1, en: 'fundicion', coste: c(0, 100, 50), tiempo: 40,
    descripcion: '+1 de armadura y +1 antiperforación a la infantería.',
    efecto: (m) => { m.armadura.infanteria += 1; m.armaduraPerf.infanteria += 1; } },
  { clave: 'blindaje_soldado', nombre: 'Blindaje Soldado', edad: 2, en: 'fundicion', coste: c(0, 200, 100), tiempo: 55,
    requiere: 'placa_hierro', descripcion: '+2 de armadura a infantería y blindados.',
    efecto: (m) => { m.armadura.infanteria += 2; m.armadura.caballeria += 2; } },
  { clave: 'compuesto_ceramico', nombre: 'Compuesto Cerámico', edad: 3, en: 'fundicion', coste: c(0, 300, 200), tiempo: 65,
    requiere: 'blindaje_soldado', descripcion: '+2 de armadura y +2 antiperforación a todo.',
    efecto: (m) => { for (const k in m.armadura) { m.armadura[k] += 2; m.armaduraPerf[k] += 2; } } },
  { clave: 'blindaje_reactivo', nombre: 'Blindaje Reactivo', edad: 4, en: 'fundicion', coste: c(0, 400, 300, 200), tiempo: 75,
    requiere: 'compuesto_ceramico', descripcion: '+3 de armadura y +3 antiperforación a todo.',
    efecto: (m) => { for (const k in m.armadura) { m.armadura[k] += 3; m.armaduraPerf[k] += 3; } } },

  /* ---- Instituto ---- */
  { clave: 'telemetria', nombre: 'Telemetría', edad: 2, en: 'instituto', coste: c(0, 150, 100), tiempo: 45,
    descripcion: '+2 de alcance y +4 de visión a torretas y ciudadelas.',
    efecto: (m) => { m.alcance.edificio += 2; m.vision.edificio += 4; } },
  { clave: 'hormigon_armado', nombre: 'Hormigón Armado', edad: 2, en: 'instituto', coste: c(0, 200), tiempo: 50,
    descripcion: '+30% de vida a muros y torretas.',
    efecto: (m) => { m.vidaEdificioDefensa *= 1.3; } },
  { clave: 'radar', nombre: 'Radar', edad: 3, en: 'instituto', coste: c(0, 200, 150), tiempo: 55,
    descripcion: '+6 de visión a todas las unidades. Revela unidades aéreas enemigas.',
    efecto: (m) => { for (const k in m.vision) m.vision[k] += 6; m.detectaAereo = true; } },
  { clave: 'logistica', nombre: 'Logística', edad: 3, en: 'instituto', coste: c(300, 200), tiempo: 60,
    descripcion: 'Toda unidad militar se entrena 25% más rápido.',
    efecto: (m) => { m.velEntrenamiento *= 1.25; } },
  { clave: 'ia_tactica', nombre: 'IA Táctica', edad: 4, en: 'instituto', coste: c(0, 300, 400, 300), tiempo: 80,
    requiere: 'radar', descripcion: 'Las unidades se autoenfocan al blanco óptimo: +15% de daño efectivo.',
    efecto: (m) => { m.autoFoco = true; for (const k in m.ataque) m.ataque[k] += 2; } },
  { clave: 'autorreparacion', nombre: 'Autorreparación', edad: 4, en: 'instituto', coste: c(0, 350, 250, 250), tiempo: 70,
    descripcion: 'Los edificios recuperan vida solos.',
    efecto: (m) => { m.autorreparacion = 2.5; } },

  /* ---- Ministerio ---- */
  { clave: 'propaganda', nombre: 'Propaganda', edad: 2, en: 'ministerio', coste: c(0, 0, 175), tiempo: 50,
    descripcion: 'Los agitadores convierten un 35% más rápido.',
    efecto: (m) => { m.velConversion *= 1.35; } },
  { clave: 'contrainteligencia', nombre: 'Contrainteligencia', edad: 3, en: 'ministerio', coste: c(0, 100, 200), tiempo: 55,
    descripcion: 'Tus unidades resisten la conversión enemiga.',
    efecto: (m) => { m.resistenciaConversion = 0.75; } },
  { clave: 'red_neuronal', nombre: 'Red Neuronal', edad: 4, en: 'ministerio', coste: c(0, 200, 400, 200), tiempo: 70,
    requiere: 'propaganda', descripcion: 'Los operadores de red convierten a distancia y curan el doble.',
    efecto: (m) => { m.alcance.apoyo += 4; m.multiplicadorCura *= 2; } },

  /* ---- Movilidad ---- */
  { clave: 'herradura', nombre: 'Herradura de Acero', edad: 1, en: 'establo', coste: c(0, 100, 50), tiempo: 40,
    descripcion: 'Caballería y blindados +10% de velocidad.',
    efecto: (m) => { m.velocidad.caballeria *= 1.10; } },
  { clave: 'suspension', nombre: 'Suspensión Independiente', edad: 3, en: 'establo', coste: c(0, 200, 150), tiempo: 55,
    requiere: 'herradura', descripcion: 'Blindados +12% de velocidad y +25 de vida.',
    efecto: (m) => { m.velocidad.caballeria *= 1.12; m.vidaExtra.caballeria += 25; } },
  { clave: 'orugas_activas', nombre: 'Orugas Activas', edad: 4, en: 'establo', coste: c(0, 300, 250, 150), tiempo: 65,
    requiere: 'suspension', descripcion: 'Blindados ignoran la penalización de pendiente.',
    efecto: (m) => { m.ignoraPendiente = true; m.velocidad.caballeria *= 1.08; } },

  { clave: 'retroceso_hidraulico', nombre: 'Retroceso Hidráulico', edad: 2, en: 'taller', coste: c(0, 200, 100), tiempo: 50,
    descripcion: 'La artillería dispara 20% más rápido.',
    efecto: (m) => { m.cadencia.asedio *= 0.8; } },
  { clave: 'balistica_asistida', nombre: 'Balística Asistida', edad: 3, en: 'taller', coste: c(0, 250, 200), tiempo: 60,
    requiere: 'retroceso_hidraulico', descripcion: '+2 de alcance a la artillería y menos dispersión.',
    efecto: (m) => { m.alcance.asedio += 2; m.dispersion *= 0.6; } },
];

export const TECNO_POR_CLAVE = new Map(TECNOLOGIAS.map((t, i) => [t.clave, i]));
export const defTecno = (clave) => TECNOLOGIAS[TECNO_POR_CLAVE.get(clave)];

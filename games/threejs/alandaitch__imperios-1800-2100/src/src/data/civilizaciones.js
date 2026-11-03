/**
 * Civilizaciones jugables. Cada una tiene bono pasivo, unidad única y color.
 * Los colores son los del jugador: se inyectan en los materiales de las mallas.
 */
export const CIVILIZACIONES = [
  { clave: 'rioplatense', nombre: 'Rioplatenses', color: '#4aa8e0', colorSec: '#f2f7fb',
    bono: 'Los Colonos recolectan Alimento un 15% más rápido; las Granjas cuestan 25% menos.',
    unica: { clave: 'gaucho', nombre: 'Gaucho Montonero', desc: 'Caballería ligera que ignora la penalización de pendiente y es inmune a la conversión.' },
    equipo: 'Las Caravanas generan +10% de Capital.',
    mod: (m) => { m.velRecoleccion.alimento *= 1.15; m.descuentoGranja = 0.75; } },

  { clave: 'britanica', nombre: 'Británicos', color: '#d24b4b', colorSec: '#f4e6c8',
    bono: 'Los Tiradores tienen +1 de alcance por edad a partir de la Eléctrica; los Astilleros trabajan 20% más rápido.',
    unica: { clave: 'casaca_roja', nombre: 'Casaca Roja', desc: 'Fusilero de descarga: dispara dos veces seguidas y luego recarga.' },
    equipo: 'Las naves cuestan 10% menos.',
    mod: (m) => { m.alcance.tirador += 1; m.velAstillero *= 1.2; } },

  { clave: 'prusiana', nombre: 'Prusianos', color: '#3f4b5c', colorSec: '#c9ced6',
    bono: 'La infantería se entrena 25% más rápido; las mejoras de la Fundición cuestan 30% menos.',
    unica: { clave: 'granadero_prusiano', nombre: 'Granadero de la Guardia', desc: 'Infantería pesada con granada de fragmentación: daño en área contra grupos.' },
    equipo: 'Los Cuarteles tienen +20% de vida.',
    mod: (m) => { m.velEntrenamientoInf *= 1.25; m.descuentoFundicion = 0.7; } },

  { clave: 'estadounidense', nombre: 'Estadounidenses', color: '#2e9e6b', colorSec: '#e8f2e0',
    bono: 'Los edificios se construyen 20% más rápido; +5 de población por Vivienda a partir de la Atómica.',
    unica: { clave: 'marine', nombre: 'Marine', desc: 'Infantería anfibia: se mueve por agua poco profunda y ataca desde el transporte.' },
    equipo: 'Los aliados ven las rutas comerciales enemigas.',
    mod: (m) => { m.velConstruccion *= 1.2; } },

  { clave: 'sovietica', nombre: 'Soviéticos', color: '#c8452e', colorSec: '#e8c34a',
    bono: 'Las unidades militares cuestan 15% menos de Alimento; +1 de población gratis por cada Vivienda.',
    unica: { clave: 'katiusha', nombre: 'Katiusha', desc: 'Lanzacohetes múltiple: salva de 8 cohetes con dispersión amplia.' },
    equipo: 'Las Fundiciones investigan 20% más rápido.',
    mod: (m) => { m.descuentoAlimentoMilitar = 0.85; } },

  { clave: 'japonesa', nombre: 'Japoneses', color: '#e0e0e0', colorSec: '#c8354a',
    bono: 'Los edificios de acopio cuestan 50% menos; las unidades de apoyo curan 30% más.',
    unica: { clave: 'ingeniero_kaizen', nombre: 'Ingeniero Kaizen', desc: 'Repara al doble de velocidad y mejora edificios cercanos de forma pasiva.' },
    equipo: 'Los Institutos investigan 15% más rápido.',
    mod: (m) => { m.descuentoAcopio = 0.5; m.multiplicadorCura *= 1.3; } },

  { clave: 'india', nombre: 'Indios', color: '#e08a2e', colorSec: '#2e7d5b',
    bono: '+1 de Capital por minuto por cada Colono; el Mercado no cobra comisión.',
    unica: { clave: 'mahout_blindado', nombre: 'Mahout Blindado', desc: 'Vehículo pesado que arrolla: daña a todo lo que atropella en su avance.' },
    equipo: 'Las Caravanas viajan 15% más rápido.',
    mod: (m) => { m.tasaMercado = 0; m.capitalPorColono = 1; } },

  { clave: 'sintetica', nombre: 'Sintéticos', color: '#9b6ce0', colorSec: '#4fd2e0',
    bono: 'Empiezan con la Edad Eléctrica investigada a mitad de precio; los edificios se autorreparan desde la Atómica.',
    unica: { clave: 'nucleo_movil', nombre: 'Núcleo Móvil', desc: 'Unidad-fábrica que ensambla drones en el campo de batalla.' },
    equipo: 'Los aliados investigan un 10% más rápido.',
    mod: (m) => { m.descuentoEdad = 0.5; } },
];

export const CIV_POR_CLAVE = new Map(CIVILIZACIONES.map((c, i) => [c.clave, i]));

/** Colores de jugador por defecto (compatibles con la paleta clásica del género). */
export const COLORES_JUGADOR = [
  '#3d8ee8', '#d8443c', '#3fae5a', '#e8c33c',
  '#4fd2e0', '#c05ce0', '#e8862e', '#c9ccd4',
];

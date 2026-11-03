/**
 * Los cuatro recursos y sus nodos en el mapa.
 * El nombre del recurso cambia de sabor según la edad, pero mecánicamente es el mismo.
 */
export const RECURSOS = [
  { clave: 'alimento', nombre: 'Alimento', icono: '🌾', color: '#e6c15a',
    porEdad: ['Grano', 'Ración', 'Cultivo', 'Biomasa', 'Proteína sintética'] },
  { clave: 'materiales', nombre: 'Materiales', icono: '🪵', color: '#a8794a',
    porEdad: ['Madera', 'Acero', 'Hormigón', 'Polímero', 'Nanofibra'] },
  { clave: 'capital', nombre: 'Capital', icono: '🪙', color: '#e0b23c',
    porEdad: ['Oro', 'Libras', 'Dólares', 'Crédito', 'Token'] },
  { clave: 'energia', nombre: 'Energía', icono: '⚡', color: '#6fd8e8',
    porEdad: ['Carbón', 'Petróleo', 'Uranio', 'Solar', 'Fusión'] },
];

export const IDX_RECURSO = { alimento: 0, materiales: 1, capital: 2, energia: 3 };
export const CLAVES_RECURSO = ['alimento', 'materiales', 'capital', 'energia'];

/** Nodos cosechables que se siembran en el mapa. */
export const NODOS = [
  { clave: 'arbol_pino', nombre: 'Pino', recurso: 'materiales', cantidad: 125, radio: 0.9, tiempoPorUnidad: 0.5, bioma: ['bosque', 'montana'] },
  { clave: 'arbol_roble', nombre: 'Roble', recurso: 'materiales', cantidad: 125, radio: 1.1, tiempoPorUnidad: 0.5, bioma: ['pradera', 'bosque'] },
  { clave: 'arbol_palmera', nombre: 'Palmera', recurso: 'materiales', cantidad: 100, radio: 0.8, tiempoPorUnidad: 0.5, bioma: ['playa', 'desierto'] },
  { clave: 'baya', nombre: 'Arbusto de Bayas', recurso: 'alimento', cantidad: 125, radio: 0.8, tiempoPorUnidad: 0.45, bioma: ['pradera', 'bosque'] },
  { clave: 'ciervo', nombre: 'Ciervo', recurso: 'alimento', cantidad: 140, radio: 0.7, tiempoPorUnidad: 0.4, huye: true, bioma: ['pradera', 'bosque'] },
  { clave: 'jabali', nombre: 'Jabalí', recurso: 'alimento', cantidad: 340, radio: 0.8, tiempoPorUnidad: 0.4, agresivo: true, bioma: ['pradera', 'bosque'] },
  { clave: 'pez', nombre: 'Banco de Peces', recurso: 'alimento', cantidad: 225, radio: 1.2, tiempoPorUnidad: 0.42, agua: true, bioma: ['agua'] },
  { clave: 'veta_oro', nombre: 'Veta de Oro', recurso: 'capital', cantidad: 800, radio: 1.0, tiempoPorUnidad: 0.55, bioma: ['montana', 'desierto', 'pradera'] },
  { clave: 'carbon', nombre: 'Filón de Carbón', recurso: 'energia', cantidad: 900, radio: 1.1, tiempoPorUnidad: 0.55, bioma: ['montana', 'bosque'] },
  { clave: 'pozo_petroleo', nombre: 'Pozo de Petróleo', recurso: 'energia', cantidad: 1400, radio: 1.4, tiempoPorUnidad: 0.5, edadMin: 1, bioma: ['desierto', 'pradera'] },
  { clave: 'reliquia', nombre: 'Patente', recurso: 'capital', cantidad: 0, radio: 0.6, reliquia: true, bioma: ['pradera', 'bosque', 'montana'] },
];

export const NODO_POR_CLAVE = new Map(NODOS.map((n, i) => [n.clave, i]));

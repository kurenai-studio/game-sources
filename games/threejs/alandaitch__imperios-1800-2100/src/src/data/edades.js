/**
 * Las cinco edades de Imperios 1800–2100.
 * Equivalencia con Age of Empires II: Oscura → Feudal → Castillos → Imperial (+1 extra).
 */
export const EDADES = [
  {
    id: 0, clave: 'vapor', nombre: 'Edad del Vapor', rango: '1800 – 1870',
    lema: 'Carbón, hierro y vapor. El mundo empieza a girar más rápido.',
    coste: null, tiempo: 0,
    paleta: { primario: '#8a6a44', secundario: '#3f3128', acento: '#c8a24a', humo: '#4a423a' },
    cielo: { turbiedad: 3.2, niebla: 0.010, tinteSol: '#ffd9a0', hora: 9.5 },
    bonos: 'Punto de partida. Aldeanos con pico y pala.',
  },
  {
    id: 1, clave: 'electrica', nombre: 'Edad Eléctrica', rango: '1870 – 1945',
    lema: 'La corriente alterna ilumina las fábricas y las trincheras.',
    coste: { alimento: 500, materiales: 0, capital: 0, energia: 0 }, tiempo: 100,
    paleta: { primario: '#7d7f86', secundario: '#2e3238', acento: '#e8c15a', humo: '#5b5f66' },
    cielo: { turbiedad: 4.6, niebla: 0.016, tinteSol: '#ffcf8a', hora: 10.5 },
    bonos: '+15% velocidad de recolección. Se habilitan la Fundición y el Polígono de Tiro.',
  },
  {
    id: 2, clave: 'atomica', nombre: 'Edad Atómica', rango: '1945 – 1991',
    lema: 'El átomo se parte y el mundo se divide en dos.',
    coste: { alimento: 800, materiales: 200, capital: 0, energia: 0 }, tiempo: 160,
    paleta: { primario: '#6d7a63', secundario: '#26302a', acento: '#d9e04f', humo: '#6a7264' },
    cielo: { turbiedad: 3.0, niebla: 0.012, tinteSol: '#fff0c8', hora: 12.0 },
    bonos: 'Ciudadela, Instituto y unidades blindadas. Los muros pasan a hormigón.',
  },
  {
    id: 3, clave: 'informacion', nombre: 'Edad de la Información', rango: '1991 – 2045',
    lema: 'La red lo conecta todo y la ventaja ya no se mide en acero.',
    coste: { alimento: 1000, materiales: 400, capital: 300, energia: 0 }, tiempo: 200,
    paleta: { primario: '#5f7f95', secundario: '#1c2733', acento: '#4fd2e0', humo: '#7e8f9c' },
    cielo: { turbiedad: 2.2, niebla: 0.008, tinteSol: '#eaf4ff', hora: 14.5 },
    bonos: 'Drones, guerra electrónica y comercio global. +2 de visión a todas las unidades.',
  },
  {
    id: 4, clave: 'sintetica', nombre: 'Edad Sintética', rango: '2045 – 2100',
    lema: 'Las máquinas ya no obedecen: colaboran.',
    coste: { alimento: 1200, materiales: 600, capital: 600, energia: 400 }, tiempo: 240,
    paleta: { primario: '#8e7fb8', secundario: '#171326', acento: '#b48bff', humo: '#a99cc7' },
    cielo: { turbiedad: 1.6, niebla: 0.006, tinteSol: '#ffe6ff', hora: 18.4 },
    bonos: 'Autómatas, enjambres y fusión. Los edificios se autorreparan.',
  },
];

export const NOMBRE_EDAD = EDADES.map((e) => e.nombre);

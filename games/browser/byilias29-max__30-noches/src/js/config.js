/* ==========================================================================
   30 NOCHES - config.js
   Central de constantes de balance, mundo, tiempos y modos de desarrollo.
   Todo numero "magico" del juego deberia vivir aqui.
   ========================================================================== */
window.TN = window.TN || {};

TN.Config = {
  GAME_NAME: '30 NOCHES',
  SCHEMA_VERSION: 1,

  WORLD: {
    width: 2400,
    height: 2400,
    tile: 32,
    seedBase: 1337
  },

  BASE: {
    x: 1200,
    y: 1200,
    clearRadius: 200,      // radio sin obstaculos alrededor de la base
    baseRadius: 260        // radio "seguro" (no aparecen enemigos dentro)
  },

  TIME: {
    day: 70,               // segundos reales de luz
    night: 55,             // segundos reales de oscuridad
    dawn: 8,               // transicion visual amanecer
    dusk: 8                // transicion visual atardecer
  },

  PLAYER: {
    radius: 11,
    speed: 168,
    maxHp: 100,
    invulnTime: 0.65,
    interactRange: 64,
    harvestCd: 0.34,
    startWeapon: 'pipe'
  },

  GENERATOR: {
    hp: 600,
    maxHp: 600,
    w: 60, h: 42,
    repairCost: { wood: 2, scrap: 1 },
    repairAmount: 45
  },

  ANTENNA: {
    repairCost: { scrap: 20, stone: 10 },
    radius: 26
  },

  FLASHLIGHT: {
    batteryMax: 100,
    drainPerSecond: 1.7,
    radius: 300,
    rechargeAmount: 100,
    rechargeCost: { scrap: 1 }
  },

  WAVES: {
    maxEnemies: 46,
    minSpawnDistance: 560,
    spawnTryLimit: 70      // intentos para encontrar un punto de aparicion libre
  },

  CAMPAIGN_DAYS: 30,
  BOSS_DAYS: [5, 10, 15, 20, 25, 30],

  CAMERA: {
    lerp: 6.5,
    shakeDecay: 6
  },

  STORAGE_KEYS: {
    save: 'tn30.save.v1',
    meta: 'tn30.meta.v1'
  },

  // Modo desarrollo: se activa con ?debug=1 o desde Opciones.
  DEBUG: {
    enabled: false,
    showCoords: false,
    godMode: false,
    cycleScale: 1        // 1 = duracion normal de campana (ver CYCLE_SCALES)
  },

  CYCLE_SCALES: {
    normal: 1,
    short: 0.25,
    tiny: 0.08
  }
};

/* --------------------------------------------------------------------------
   Puntos de interés de la campana. Coordenadas en mundo 2400x2400.
   -------------------------------------------------------------------------- */
TN.Config.POIS = [
  {
    id: 'wreck',
    name: 'Vehiculo accidentado',
    hint: 'Un furgoneta volcada junto a la carretera del bosque.',
    component: 'battery',
    componentName: 'Bateria de emergencia',
    x: 520, y: 640, w: 120, h: 78, rot: 0.18
  },
  {
    id: 'bunker',
    name: 'Bunker abandonado',
    hint: 'Un laboratorio semienterrado bajo la colina.',
    component: 'circuit',
    componentName: 'Circuito de comunicaciones',
    x: 1880, y: 820, w: 150, h: 110, rot: 0
  },
  {
    id: 'tower',
    name: 'Torre de vigilancia',
    hint: 'Una torre de madera con un transmisor oxidado.',
    component: 'transmitter',
    componentName: 'Transmisor de senal',
    x: 1780, y: 1900, w: 96, h: 96, rot: 0
  }
];

/* --------------------------------------------------------------------------
   Curva de dificultad de las 30 noches.
   difficultyFor(day) devuelve el plan de ataque de esa noche.
   -------------------------------------------------------------------------- */
TN.Config.difficultyFor = function (day) {
  const d = Math.max(1, Math.min(TN.Config.CAMPAIGN_DAYS, day | 0));
  const types = ['stalker'];
  // Cada tipo base aparece UNA sola vez: si un tipo se repitia, la tabla de
  // spawn aleatorio (game.spawnWave) le daba el doble de peso.
  if (d >= 3) types.push('runner');
  if (d >= 8) types.push('brute');
  if (d >= 10) types.push('spitter');
  if (d >= 14) types.push('lightHunter');
  if (d >= 19) types.push('eliteStalker');
  if (d >= 22) types.push('eliteRunner');
  if (d >= 24) types.push('eliteBrute');
  if (d >= 26) types.push('eliteSpitter');

  return {
    day: d,
    hpMul: 1 + (d - 1) * 0.085,
    dmgMul: 1 + (d - 1) * 0.055,
    waveSize: Math.round(3 + d * 0.85),
    waveInterval: Math.max(7, 26 - d * 0.45),
    types: types,
    eliteChance: d >= 19 ? Math.min(0.35, (d - 18) * 0.05) : 0,
    isBossNight: TN.Config.BOSS_DAYS.indexOf(d) !== -1,
    stormChance: d >= 6 ? Math.min(0.55, (d - 5) * 0.05) : 0,
    name: d >= 26 ? 'Ultima resistencia' :
      d >= 20 ? 'Asedio pesado' :
        d >= 15 ? 'Cacerias coordinadas' :
          d >= 10 ? 'Presion constante' :
            d >= 5 ? 'Criaturas mayores' : 'Amenazas basicas'
  };
};

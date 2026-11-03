/**
 * Fábrica procedural de vegetación y roca.
 *
 * Todo lo que sale de acá está pensado para instanciarse: una sola geometría
 * fusionada por especie/variante, un solo material compartido por familia y un
 * atlas único (canvas 2D) con cortezas, racimos de hojas, frondas y pasto.
 * Nada de assets externos, nada de texturas por objeto.
 *
 * Por qué un atlas y no una textura por especie: el árbol se dibuja con UNA
 * llamada de dibujo (tronco + hojas comparten material), y a 70–90 m de cámara
 * el detalle de la corteza no se lee — lo que se lee es la silueta y el color.
 * Por eso el presupuesto de triángulos se gasta en ramas y cards, no en UVs.
 */
import * as THREE from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';
import { mulberry32, Ruido, clamp, lerp, smoothstep } from '../core/RNG.js';

export const TIPOS_ARBOL = ['pino', 'roble', 'palmera', 'sauce', 'abedul', 'muerto', 'cipres'];

/* ══════════════════════════════ atlas ══════════════════════════════ */

export const TILE = {
  CORTEZA_RUGOSA: 0, CORTEZA_PINO: 1, CORTEZA_ABEDUL: 2, CORTEZA_PALMERA: 3,
  CORTEZA_MUERTA: 4, HOJA_ROBLE: 5, HOJA_ABEDUL: 6, HOJA_SAUCE: 7,
  AGUJA_PINO: 8, FRONDA: 9, HOJA_SECA: 10, ESCAMA_CIPRES: 11,
  PASTO: 12, FLOR: 13, MATA: 14, BAYA: 15,
};

const ATLAS_LADO = 1024, ATLAS_COLS = 4, TILE_PX = ATLAS_LADO / ATLAS_COLS;

// Retranqueo de los tiles OPACOS (cortezas): no pueden llevar marco vacío porque
// el tubo del tronco recorre el tile entero y un marco transparente le abriría
// agujeros. Con medio téxel alcanza para que el filtro bilineal no cruce.
const INSET_OPACO = 5 / ATLAS_LADO;

// PADDING REAL para los tiles CON ALFA. El dibujo se reencuadra dentro del cell
// dejando un marco vacío de PAD_ALFA_PX, y las UV apuntan sólo al interior.
// Por qué: sin marco, el mipmap promedia con el tile de al lado y el billboard
// lejano termina mostrando pedazos del vecino (el "bleed" que se leía como
// paralelogramos blanquecinos flotando sobre el agua). 16 px de marco siguen
// siendo 2 téxeles en el nivel 3 de mip, que es donde se resuelve el LOD lejano.
const PAD_ALFA_PX = 16;
const PAD_ALFA = PAD_ALFA_PX / ATLAS_LADO;
const MEDIO_TEXEL = 0.5 / ATLAS_LADO;

// Primer tile con canal alfa: de acá en adelante todo lleva marco (ver TILE).
const PRIMER_TILE_ALFA = 5; // TILE.HOJA_ROBLE

/** Rectángulo UV de un tile del atlas. Pura, sirve sin ctx. */
export function rectTile(i) {
  const col = i % ATLAS_COLS, fila = Math.floor(i / ATLAS_COLS);
  const p = 1 / ATLAS_COLS;
  // los tiles con alfa se contraen hasta el borde interior del marco + medio
  // téxel; los opacos sólo se retranquean
  const m = i >= PRIMER_TILE_ALFA ? PAD_ALFA + MEDIO_TEXEL : INSET_OPACO;
  return {
    u0: col * p + m, v0: 1 - (fila + 1) * p + m,
    du: p - m * 2, dv: p - m * 2,
  };
}

const lienzo = (n) => {
  const c = document.createElement('canvas');
  c.width = c.height = n;
  return c;
};

/** Parsea 'rgb(r,g,b)' a números. Sólo se usa al construir el atlas. */
function leerRGB(s) {
  const m = /(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/.exec(s);
  return m ? [+m[1], +m[2], +m[3]] : [128, 128, 128];
}

/**
 * Dibuja el tile sobre transparente y lo reencuadra dentro del cell dejando el
 * marco vacío de `pad`. Devuelve el lienzo junto con su color medio ya parseado,
 * porque la dilatación de color NO se puede hacer acá (ver atlasNaturaleza).
 */
function tileConAlfa(colorMedio, dibujar, pad = PAD_ALFA_PX) {
  const crudo = lienzo(TILE_PX);
  dibujar(crudo.getContext('2d'));
  const dest = lienzo(TILE_PX);
  const interior = TILE_PX - pad * 2;
  dest.getContext('2d').drawImage(crudo, pad, pad, interior, interior);
  return { lienzo: dest, medio: leerRGB(colorMedio) };
}

const rgb = (r, g, b) => `rgb(${r | 0},${g | 0},${b | 0})`;
const mezclaHex = (c1, c2, t) => rgb(
  lerp(c1[0], c2[0], t), lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t));

/* ---- pinceles ---- */

function pintarCorteza(g, r, base, oscuro, claro, opts = {}) {
  g.fillStyle = rgb(...base); g.fillRect(0, 0, TILE_PX, TILE_PX);
  const anillos = opts.anillos || 0;
  // fibra vertical: la corteza real es un manojo de tiras, no ruido blanco
  for (let i = 0; i < 520; i++) {
    const x = r() * TILE_PX, y = r() * TILE_PX;
    const h = 30 + r() * 190, w = 0.8 + r() * 3.4;
    g.globalAlpha = 0.05 + r() * 0.28;
    g.strokeStyle = rgb(...(r() < 0.52 ? oscuro : claro));
    g.lineWidth = w; g.lineCap = 'round';
    g.beginPath(); g.moveTo(x, y);
    g.bezierCurveTo(x + (r() - 0.5) * 9, y + h * 0.34, x + (r() - 0.5) * 9, y + h * 0.68, x + (r() - 0.5) * 7, y + h);
    g.stroke();
  }
  // grietas profundas
  g.globalAlpha = 1;
  for (let i = 0; i < 26; i++) {
    const x = r() * TILE_PX;
    g.strokeStyle = `rgba(${oscuro[0] * 0.5 | 0},${oscuro[1] * 0.5 | 0},${oscuro[2] * 0.5 | 0},0.55)`;
    g.lineWidth = 1 + r() * 2.6;
    g.beginPath(); g.moveTo(x, -10);
    let y = -10, cx = x;
    while (y < TILE_PX + 10) { y += 24 + r() * 34; cx += (r() - 0.5) * 16; g.lineTo(cx, y); }
    g.stroke();
  }
  for (let i = 0; i < anillos; i++) {
    const y = (i + r() * 0.6) * (TILE_PX / anillos);
    g.globalAlpha = 0.35 + r() * 0.3;
    g.strokeStyle = rgb(...oscuro); g.lineWidth = 2 + r() * 4;
    g.beginPath(); g.moveTo(0, y); g.bezierCurveTo(TILE_PX * 0.3, y + (r() - 0.5) * 9, TILE_PX * 0.7, y + (r() - 0.5) * 9, TILE_PX, y); g.stroke();
  }
  if (opts.lenticelas) { // abedul: marcas horizontales cortas
    g.globalAlpha = 1;
    for (let i = 0; i < 90; i++) {
      const x = r() * TILE_PX, y = r() * TILE_PX, w = 6 + r() * 34, h = 1.5 + r() * 4;
      g.fillStyle = `rgba(30,26,24,${0.35 + r() * 0.5})`;
      g.beginPath(); g.ellipse(x, y, w, h, 0, 0, Math.PI * 2); g.fill();
    }
  }
  g.globalAlpha = 1;
}

function hojaOvalo(g, x, y, ang, l, a, col, veta) {
  g.save(); g.translate(x, y); g.rotate(ang);
  g.fillStyle = col;
  g.beginPath(); g.ellipse(0, 0, a, l, 0, 0, Math.PI * 2); g.fill();
  if (veta) { g.strokeStyle = veta; g.lineWidth = 1.1; g.beginPath(); g.moveTo(0, -l); g.lineTo(0, l); g.stroke(); }
  g.restore();
}

function hojaLobulada(g, x, y, ang, l, a, col, veta) {
  g.save(); g.translate(x, y); g.rotate(ang);
  g.fillStyle = col; g.beginPath(); g.moveTo(0, -l);
  const lob = 3;
  for (let s = -1; s <= 1; s += 2) {
    for (let i = 0; i < lob; i++) {
      const t0 = i / lob, t1 = (i + 1) / lob;
      const y0 = lerp(-l, l, s > 0 ? t0 : 1 - t0), y1 = lerp(-l, l, s > 0 ? t1 : 1 - t1);
      const w = a * (0.45 + 0.55 * Math.sin((i + 0.5) / lob * Math.PI));
      g.quadraticCurveTo(s * w, (y0 + y1) * 0.5, s * w * 0.3, y1);
    }
  }
  g.closePath(); g.fill();
  if (veta) { g.strokeStyle = veta; g.lineWidth = 1; g.beginPath(); g.moveTo(0, -l * 0.9); g.lineTo(0, l * 0.9); g.stroke(); }
  g.restore();
}

function hojaLanza(g, x, y, ang, l, a, col) {
  g.save(); g.translate(x, y); g.rotate(ang);
  g.fillStyle = col; g.beginPath(); g.moveTo(0, -l);
  g.quadraticCurveTo(a, -l * 0.1, 0, l);
  g.quadraticCurveTo(-a, -l * 0.1, 0, -l);
  g.fill(); g.restore();
}

/** Racimo: hojas densas al centro, ralas al borde, para que la card no sea un cuadrado. */
function pintarRacimo(g, r, paleta, forma, cantidad, escala) {
  const C = TILE_PX * 0.5;
  for (let i = 0; i < cantidad; i++) {
    const ang = r() * Math.PI * 2;
    const rad = Math.pow(r(), 0.62) * TILE_PX * 0.47;
    const x = C + Math.cos(ang) * rad, y = C + Math.sin(ang) * rad * 0.92;
    const t = rad / (TILE_PX * 0.47);
    if (r() < t * 0.55) continue; // deshilacha el borde
    const c = paleta[(r() * paleta.length) | 0];
    const s = escala * TILE_PX * (0.055 + r() * 0.055) * (1 - t * 0.25);
    const rot = r() * Math.PI * 2;
    // la veta ya no baja a 0.55: en lineal ese 0.55 sRGB es un 0.26, o sea que
    // cada nervadura metía un surco casi negro dentro de la copa
    const sombra = `rgba(${c[0] * 0.66 | 0},${c[1] * 0.66 | 0},${c[2] * 0.66 | 0},1)`;
    const cara = rgb(c[0] * (0.86 + r() * 0.42), c[1] * (0.86 + r() * 0.42), c[2] * (0.86 + r() * 0.42));
    if (forma === 'lobulada') hojaLobulada(g, x, y, rot, s, s * 0.62, cara, sombra);
    else if (forma === 'lanza') hojaLanza(g, x, y, rot, s * 1.5, s * 0.3, cara);
    else hojaOvalo(g, x, y, rot, s, s * 0.66, cara, sombra);
  }
}

function pintarAgujas(g, r, paleta) {
  const C = TILE_PX * 0.5;
  for (let i = 0; i < 190; i++) {
    const ang = r() * Math.PI * 2;
    const rad = Math.pow(r(), 0.5) * TILE_PX * 0.48;
    const x = C + Math.cos(ang) * rad, y = C + Math.sin(ang) * rad;
    if (r() < (rad / (TILE_PX * 0.48)) * 0.5) continue;
    const c = paleta[(r() * paleta.length) | 0];
    g.strokeStyle = rgb(c[0] * (0.86 + r() * 0.5), c[1] * (0.86 + r() * 0.5), c[2] * (0.86 + r() * 0.5));
    g.lineWidth = 1.4 + r() * 1.8; g.lineCap = 'round';
    const dir = r() * Math.PI * 2, largo = 10 + r() * 26;
    for (let k = -3; k <= 3; k++) {
      const a2 = dir + k * 0.34;
      g.beginPath(); g.moveTo(x, y);
      g.lineTo(x + Math.cos(a2) * largo, y + Math.sin(a2) * largo);
      g.stroke();
    }
  }
}

/**
 * Fronda de palmera (también la usa el helecho del sotobosque).
 *
 * DOS CAMBIOS CONTRA EL "BLOB VERDE NEÓN":
 *
 * 1. CROMA. La paleta anterior tenía G casi al doble de R (72,134,60) y encima
 *    subida 1,45x. Multiplicada por el color de especie y por el horneado de luz
 *    quedaba el verde MÁS SATURADO del cuadro con diferencia — y como la fronda
 *    es una cinta sólida vista de plano desde la cámara cenital, no había alfa
 *    que promediara nada: entraba entera, a tope, y se leía como fosforescente.
 *    Ahora la paleta es OLIVA (G/R ≈ 1,25, con amarillo adentro), que además es
 *    el color real de una hoja de palmera al sol y la mete en la gama del resto.
 *
 * 2. SIMETRÍA. El raquis era una recta vertical exacta y los dos folíolos de
 *    cada nivel salían con el MISMO largo. Superponer dos frondas así daba
 *    interferencia perfecta: de ahí las bandas concéntricas. Acá el raquis se
 *    arquea, cada lado tiene su largo y su caída, y faltan folíolos sueltos.
 */
function pintarFronda(g, r) {
  const verde = [[104, 130, 68], [126, 154, 84], [88, 112, 58], [142, 164, 96]];
  // el raquis se arquea: sin eje de simetría, dos frondas encimadas no calzan
  const arco = (t) => TILE_PX * (0.5 + Math.sin(t * 2.3 + 0.4) * 0.035);
  g.strokeStyle = 'rgb(146,136,86)'; g.lineWidth = 7; g.lineCap = 'round';
  g.beginPath(); g.moveTo(arco(0), TILE_PX);
  for (let s = 1; s <= 8; s++) { const t = s / 8; g.lineTo(arco(t), lerp(TILE_PX, 6, t)); }
  g.stroke();
  for (let i = 0; i < 46; i++) {
    const t = i / 45;
    const y = lerp(TILE_PX * 0.98, 12, t);
    const cx = arco(t);
    const base = TILE_PX * 0.46 * Math.sin(Math.pow(t, 0.7) * Math.PI);
    for (let s = -1; s <= 1; s += 2) {
      if (r() < 0.07) continue;                     // folíolos faltantes: hoja usada
      const l = base * (0.58 + r() * 0.66);         // cada ala con su propio largo
      const c = verde[(r() * verde.length) | 0];
      g.strokeStyle = rgb(c[0] * (0.82 + r() * 0.40), c[1] * (0.82 + r() * 0.40), c[2] * (0.82 + r() * 0.40));
      g.lineWidth = 3.0 + r() * 3.4;
      g.beginPath(); g.moveTo(cx, y);
      g.quadraticCurveTo(cx + s * l * 0.6, y + 4 + r() * 9, cx + s * l, y + 14 + r() * 24);
      g.stroke();
    }
  }
}

function pintarPasto(g, r, opts = {}) {
  const base = opts.paleta || [[86, 122, 52], [110, 148, 64], [70, 104, 46], [130, 156, 74]];
  for (let i = 0; i < 150; i++) {
    const x = 12 + r() * (TILE_PX - 24);
    const alto = TILE_PX * (0.32 + r() * 0.62);
    const c = base[(r() * base.length) | 0];
    const g2 = g.createLinearGradient(0, TILE_PX, 0, TILE_PX - alto);
    g2.addColorStop(0, rgb(c[0] * 0.45, c[1] * 0.5, c[2] * 0.42));
    g2.addColorStop(1, rgb(c[0] * 1.15, c[1] * 1.12, c[2] * 1.0));
    g.strokeStyle = g2;
    g.lineWidth = 2.2 + r() * 3.2; g.lineCap = 'round';
    const dob = (r() - 0.5) * TILE_PX * 0.42;
    g.beginPath(); g.moveTo(x, TILE_PX + 4);
    g.quadraticCurveTo(x + dob * 0.35, TILE_PX - alto * 0.55, x + dob, TILE_PX - alto);
    g.stroke();
  }
  if (opts.flores) {
    for (let i = 0; i < 22; i++) {
      const x = 16 + r() * (TILE_PX - 32), y = TILE_PX * (0.18 + r() * 0.55);
      const c = opts.flores[(r() * opts.flores.length) | 0];
      g.fillStyle = rgb(...c);
      for (let p = 0; p < 5; p++) {
        const a = p / 5 * Math.PI * 2;
        g.beginPath(); g.ellipse(x + Math.cos(a) * 4.5, y + Math.sin(a) * 4.5, 3.6, 3.6, 0, 0, Math.PI * 2); g.fill();
      }
      g.fillStyle = 'rgb(240,214,110)';
      g.beginPath(); g.arc(x, y, 2.6, 0, Math.PI * 2); g.fill();
    }
  }
  if (opts.bayas) {
    for (let i = 0; i < 26; i++) {
      const x = 20 + r() * (TILE_PX - 40), y = TILE_PX * (0.3 + r() * 0.55);
      g.fillStyle = `rgb(${170 + r() * 60 | 0},${28 + r() * 34 | 0},${34 + r() * 26 | 0})`;
      g.beginPath(); g.arc(x, y, 4 + r() * 3, 0, Math.PI * 2); g.fill();
      g.fillStyle = 'rgba(255,190,180,0.6)';
      g.beginPath(); g.arc(x - 1.5, y - 1.8, 1.5, 0, Math.PI * 2); g.fill();
    }
  }
}

let _atlas = null;
/**
 * Atlas único (1024²) con corteza, hojas, frondas y pasto. Se construye una vez.
 *
 * NOTA DE BRILLO (vale para todas las paletas de abajo). La textura se declara
 * SRGBColorSpace, así que lo que pintamos en el canvas se decodifica a lineal
 * antes de multiplicar por el color de vértice. Un verde de hoja "clásico" como
 * rgb(74,108,44) es (0,065 · 0,146 · 0,025) en lineal; multiplicado por el color
 * de especie (~0,7) y por el horneado de copa (~0,88) quedaba en un albedo de
 * 0,04–0,09, o sea TRES veces más oscuro que el suelo que pisa. De ahí que el
 * cuadro no tuviera altas luces: no había en pantalla ninguna superficie clara.
 * Las paletas están subidas ~1,3–1,5x y los rangos de luz de copa se abrieron
 * (interior más oscuro, corona bastante más clara) para que la copa al sol
 * aporte el punto más brillante del follaje en vez de una masa plana y sucia.
 */
export function atlasNaturaleza(ctx) {
  if (_atlas) return _atlas;
  const c = lienzo(ATLAS_LADO);
  const g = c.getContext('2d');
  g.clearRect(0, 0, ATLAS_LADO, ATLAS_LADO);
  const medios = new Array(ATLAS_COLS * ATLAS_COLS).fill(null);
  const poner = (idx, sub) => {
    const col = idx % ATLAS_COLS, fila = Math.floor(idx / ATLAS_COLS);
    if (sub.medio) medios[idx] = sub.medio;
    g.drawImage(sub.lienzo || sub, col * TILE_PX, fila * TILE_PX);
  };
  const corteza = (semilla, base, osc, cla, opts) => {
    const l = lienzo(TILE_PX); pintarCorteza(l.getContext('2d'), mulberry32(semilla), base, osc, cla, opts); return l;
  };

  poner(TILE.CORTEZA_RUGOSA, corteza(11, [117, 90, 63], [54, 39, 29], [181, 149, 112]));
  poner(TILE.CORTEZA_PINO, corteza(12, [151, 93, 59], [71, 39, 27], [227, 156, 100], { anillos: 3 }));
  // el abedul es la corteza más clara de la biblioteca: es, literalmente, la
  // única alta luz garantizada del bosque, así que se lo empuja hasta casi blanco
  poner(TILE.CORTEZA_ABEDUL, corteza(13, [228, 222, 208], [146, 136, 122], [251, 250, 246], { lenticelas: true }));
  poner(TILE.CORTEZA_PALMERA, corteza(14, [156, 129, 90], [80, 63, 41], [214, 185, 136], { anillos: 9 }));
  poner(TILE.CORTEZA_MUERTA, corteza(15, [144, 134, 120], [63, 59, 51], [202, 193, 178]));

  poner(TILE.HOJA_ROBLE, tileConAlfa('rgb(88,126,54)', (gg) => {
    pintarRacimo(gg, mulberry32(21), [[96, 138, 58], [118, 160, 68], [76, 112, 50], [140, 176, 78]], 'lobulada', 90, 1.15);
  }));
  poner(TILE.HOJA_ABEDUL, tileConAlfa('rgb(128,162,74)', (gg) => {
    pintarRacimo(gg, mulberry32(22), [[140, 176, 80], [166, 200, 92], [116, 152, 66], [186, 212, 102]], 'ovalo', 120, 0.85);
  }));
  poner(TILE.HOJA_SAUCE, tileConAlfa('rgb(118,150,72)', (gg) => {
    pintarRacimo(gg, mulberry32(23), [[130, 162, 76], [152, 182, 90], [106, 140, 64]], 'lanza', 110, 0.9);
  }));
  poner(TILE.AGUJA_PINO, tileConAlfa('rgb(60,100,56)', (gg) => {
    pintarAgujas(gg, mulberry32(24), [[64, 110, 60], [82, 130, 68], [48, 88, 50], [102, 148, 76]]);
  }));
  // el color medio baja con la paleta: es el que se dilata sobre el alfa cero, y
  // si quedara el verde viejo el mip lejano volvería a teñir la fronda de neón
  poner(TILE.FRONDA, tileConAlfa('rgb(112,134,74)', (gg) => pintarFronda(gg, mulberry32(25))));
  poner(TILE.HOJA_SECA, tileConAlfa('rgb(190,138,58)', (gg) => {
    pintarRacimo(gg, mulberry32(26), [[206, 146, 60], [228, 172, 76], [172, 110, 48], [236, 204, 104]], 'lobulada', 80, 1.05);
  }));
  poner(TILE.ESCAMA_CIPRES, tileConAlfa('rgb(66,102,64)', (gg) => {
    pintarRacimo(gg, mulberry32(27), [[70, 108, 68], [88, 126, 78], [54, 88, 58]], 'lanza', 150, 0.62);
  }));
  // OJO: PASTO y FLOR NO se tocan de color. Foliaje.js tiene cableada la media
  // lineal de este tile (MEDIA_PASTO) para despejar el tinte por instancia que
  // iguala la brizna con el suelo; si acá lo aclaro, el pasto deja de coincidir
  // con el terreno y flota como una alfombra ajena.
  poner(TILE.PASTO, tileConAlfa('rgb(92,124,56)', (gg) => pintarPasto(gg, mulberry32(28))));
  poner(TILE.FLOR, tileConAlfa('rgb(96,128,58)', (gg) => pintarPasto(gg, mulberry32(29), {
    // los pétalos sí van casi a blanco: son motas chiquitas (no mueven la media
    // del tile) y son la única alta luz que puede tener el suelo abierto
    flores: [[248, 246, 238], [246, 214, 108], [206, 178, 236], [240, 150, 162]],
  })));
  poner(TILE.MATA, tileConAlfa('rgb(106,138,62)', (gg) => {
    pintarRacimo(gg, mulberry32(30), [[118, 152, 66], [140, 176, 80], [96, 126, 58]], 'ovalo', 120, 0.8);
  }));
  poner(TILE.BAYA, tileConAlfa('rgb(102,134,58)', (gg) => {
    pintarRacimo(gg, mulberry32(31), [[112, 146, 62], [134, 168, 74], [90, 120, 54]], 'ovalo', 100, 0.85);
    pintarPasto(gg, mulberry32(32), { bayas: true, paleta: [[112, 146, 62]] });
  }));

  /*
   * DILATACIÓN DE COLOR, fuera del canvas y a mano.
   *
   * El problema: el mipmap promedia RGB y ALFA por separado. Donde el alfa es 0
   * el canvas guarda el RGB en negro (su backing store es premultiplicado, y eso
   * no hay truco de composición que lo evite: destination-in, putImageData con
   * alfa 0, todo termina en 0,0,0,0). Resultado: cada hoja quedaba rodeada de
   * negro en los niveles lejanos, la copa entera se ensuciaba a distancia y el
   * bosque se hundía todavía más en la parte baja del histograma.
   *
   * La solución: leer el atlas UNA vez, llevar el RGB de las zonas translúcidas
   * al color medio de SU tile (por eso `medios` va indexado por tile: la
   * dilatación no puede cruzar de un tile al vecino) y subir el resultado como
   * DataTexture. Una DataTexture no pasa por el backing premultiplicado del
   * canvas, así que "color con alfa cero" sobrevive hasta la GPU.
   *
   * Como DataTexture ignora flipY (no existe UNPACK_FLIP_Y para ArrayBufferView),
   * volcamos las filas invertidas acá mismo y así rectTile sigue valiendo igual.
   */
  const px = g.getImageData(0, 0, ATLAS_LADO, ATLAS_LADO).data;
  const datos = new Uint8Array(ATLAS_LADO * ATLAS_LADO * 4);
  for (let y = 0; y < ATLAS_LADO; y++) {
    const fila = (y / TILE_PX) | 0;
    const destY = ATLAS_LADO - 1 - y; // volteo vertical: reemplaza a flipY
    for (let x = 0; x < ATLAS_LADO; x++) {
      const s = (y * ATLAS_LADO + x) * 4;
      const d = (destY * ATLAS_LADO + x) * 4;
      const a = px[s + 3];
      const medio = medios[fila * ATLAS_COLS + ((x / TILE_PX) | 0)];
      if (a === 255 || !medio) {
        datos[d] = px[s]; datos[d + 1] = px[s + 1]; datos[d + 2] = px[s + 2];
      } else {
        const k = a / 255, inv = 1 - k;
        datos[d] = px[s] * k + medio[0] * inv;
        datos[d + 1] = px[s + 1] * k + medio[1] * inv;
        datos[d + 2] = px[s + 2] * k + medio[2] * inv;
      }
      datos[d + 3] = a;
    }
  }

  const t = new THREE.DataTexture(datos, ATLAS_LADO, ATLAS_LADO, THREE.RGBAFormat, THREE.UnsignedByteType);
  t.colorSpace = THREE.SRGBColorSpace;
  t.wrapS = t.wrapT = THREE.ClampToEdgeWrapping;
  t.magFilter = THREE.LinearFilter;
  t.minFilter = THREE.LinearMipmapLinearFilter;
  t.generateMipmaps = true;
  t.anisotropy = ctx?.renderer?.capabilities?.getMaxAnisotropy?.() ?? 4;
  t.needsUpdate = true;
  _atlas = t;
  return t;
}

let _texRoca = null;
/** Granito para triplanar: mancha de worley + poros. */
export function texturaRoca(ctx) {
  if (_texRoca) return _texRoca;
  const N = 512, c = lienzo(N), g = c.getContext('2d');
  const r = mulberry32(7717);
  // El granito venía en 140 sRGB = 0,26 lineal, y con el color de vértice de la
  // roca terminaba en un albedo de 0,13: piedra color carbón. Un granito real
  // ronda 0,3–0,4, y además es la superficie que más rápido devuelve una alta luz
  // cuando le pega el sol de frente. Por eso sube toda la rampa.
  g.fillStyle = 'rgb(178,174,166)'; g.fillRect(0, 0, N, N);
  for (let i = 0; i < 2600; i++) {
    const x = r() * N, y = r() * N, s = 2 + r() * 16;
    const v = 0.66 + r() * 0.68;
    g.fillStyle = `rgba(${196 * v | 0},${192 * v | 0},${184 * v | 0},${0.25 + r() * 0.5})`;
    g.beginPath(); g.ellipse(x, y, s, s * (0.5 + r() * 0.8), r() * 3.14, 0, Math.PI * 2); g.fill();
  }
  for (let i = 0; i < 320; i++) { // vetas
    g.strokeStyle = `rgba(${116 + r() * 52 | 0},${114 + r() * 52 | 0},${110 + r() * 52 | 0},${0.15 + r() * 0.3})`;
    g.lineWidth = 0.6 + r() * 2.4;
    let x = r() * N, y = r() * N;
    g.beginPath(); g.moveTo(x, y);
    for (let k = 0; k < 6; k++) { x += (r() - 0.5) * 90; y += (r() - 0.5) * 90; g.lineTo(x, y); }
    g.stroke();
  }
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  t.wrapS = t.wrapT = THREE.RepeatWrapping;
  t.anisotropy = ctx?.renderer?.capabilities?.getMaxAnisotropy?.() ?? 4;
  _texRoca = t;
  return t;
}

/* ═══════════════════════ viento + LOD (shaders) ═══════════════════════ */

/** Uniformes globales: una sola actualización por frame mueve todo el foliaje. */
export const uniformesViento = {
  uTiempoFol: { value: 0 },
  uDirViento: { value: new THREE.Vector2(0.86, 0.51) },
  uFuerzaViento: { value: 1.0 },
};

const CAB_V = /* glsl */`
attribute float aViento;
attribute float aHoja;
varying float vDistFol;
uniform float uTiempoFol, uAmpViento, uVelViento, uFlameoViento, uFuerzaViento;
uniform vec2 uDirViento;
`;

const CAB_F = /* glsl */`
varying float vDistFol;
uniform vec4 uBandaFol;

/**
 * Umbral de recorte para el fundido de LOD.
 *
 * POR QUÉ NO ES BAYER. Acá había una matriz ordenada 2x2 elevada a 4x4. Una
 * matriz ordenada aplicada sobre la pantalla entera, encima de follaje y agua,
 * se lee EXACTAMENTE como lo que se veía: un damero, con parches de contorno
 * casi rectangular ahí donde la banda de LOD corta un grupo de instancias. El
 * ojo detecta la periodicidad de 4 px muchísimo antes que el fundido que la
 * matriz estaba tratando de disimular.
 *
 * Esto es interleaved gradient noise (Jimenez): una sola línea, sin tabla ni
 * textura, y con un espectro parecido al del ruido azul — el recorte se lee como
 * grano fino y no como patrón. Es estable en espacio de pantalla (depende sólo
 * de gl_FragCoord), así que no titila con la cámara quieta.
 *
 * RANGO: termina en fract(), o sea estrictamente [0,1). Eso importa: garantiza
 * que con visFol = 1.0 NINGÚN fragmento se descarte, y por lo tanto que no queden
 * agujeros permanentes en geometría que debería ser opaca.
 */
float ditherFol(vec2 fc){
  return fract(52.9829189 * fract(dot(fc, vec2(0.06711056, 0.00583715))));
}
`;

// Muestreo del atlas con sesgo de mip negativo. El atlas mete 16 tiles en 1024²,
// así que a partir del nivel 4 un tile mide 16 téxeles y el filtro ya promedia
// con el vecino. Medio nivel largo de sesgo mantiene la hoja nítida y, sobre
// todo, impide que el alfa promediada de todo el atlas haga pasar el alphaTest
// al CUADRILÁTERO ENTERO del billboard lejano.
const MAPA_F = /* glsl */`
#ifdef USE_MAP
  diffuseColor *= texture2D( map, vMapUv, -0.65 );
#endif
`;

const CUERPO_V = /* glsl */`
#include <begin_vertex>
vec3 origenInst = vec3(0.0);
#ifdef USE_INSTANCING
  origenInst = instanceMatrix[3].xyz;
#endif
vec3 mundoInst = (modelMatrix * vec4(origenInst, 1.0)).xyz;
vDistFol = distance(cameraPosition, mundoInst);
float faseFol = mundoInst.x * 0.41 + mundoInst.z * 0.27;
float rafagaFol = 0.55 + 0.45 * sin(uTiempoFol * 0.23 + mundoInst.x * 0.011 + mundoInst.z * 0.015);
float ondaFol = sin(uTiempoFol * uVelViento + faseFol) + 0.42 * sin(uTiempoFol * uVelViento * 2.3 + faseFol * 1.7);
float ampFol = uAmpViento * aViento * rafagaFol * uFuerzaViento;
transformed.x += uDirViento.x * ondaFol * ampFol;
transformed.z += uDirViento.y * ondaFol * ampFol;
float flameoFol = sin(uTiempoFol * 4.7 + transformed.x * 2.7 + transformed.y * 1.3 + faseFol * 3.1);
transformed.x += flameoFol * uFlameoViento * aViento;
transformed.y -= abs(flameoFol) * uFlameoViento * aViento * 0.6;
`;

// OJO: en three r185 vColor SIEMPRE se declara vec4 (ver color_pars_vertex).
// Asumirlo vec3 rompe la compilación del shader, y three cae a un programa de
// respaldo: los árboles pasan a ser cuadrones pálidos que tapan la pantalla.
// Replicamos color_vertex tal cual, modulando solo el aporte por instancia.
const COLOR_V = /* glsl */`
vColor = vec4(1.0);
#ifdef USE_COLOR_ALPHA
  vColor *= color;
#elif defined( USE_COLOR )
  vColor.rgb *= color;
#endif
#ifdef USE_INSTANCING_COLOR
  vColor.rgb *= mix(vec3(1.0), instanceColor.rgb, aHoja);
#endif
`;

const RECORTE_F = /* glsl */`
#include <clipping_planes_fragment>
{
  float visFol = smoothstep(uBandaFol.x, uBandaFol.y, vDistFol) * (1.0 - smoothstep(uBandaFol.z, uBandaFol.w, vDistFol));
  // Fuera de la banda no hay nada que dibujar. Dentro, el dither SÓLO se paga en
  // el cruce (visFol < 1), que es donde el LOD de verdad se está fundiendo: en el
  // 95% del cuadro el nivel está a plena visibilidad y ni se evalúa el ruido, así
  // que no queda un solo píxel recortado sobre geometría opaca.
  if (visFol <= 0.0) discard;
  if (visFol < 1.0 && visFol < ditherFol(gl_FragCoord.xy)) discard;
}
`;

/**
 * Parchea un MeshStandardMaterial (o MeshDepthMaterial) con viento + fundido
 * por distancia. Se hace sobre el material estándar a propósito: así el foliaje
 * sigue recibiendo y proyectando sombras del pipeline normal.
 */
export function parcharFoliaje(mat, opciones = {}) {
  const u = mat.userData.uFol = {
    uAmpViento: { value: opciones.amplitud ?? 0.16 },
    uVelViento: { value: opciones.velocidad ?? 1.25 },
    uFlameoViento: { value: opciones.flameo ?? 0.035 },
    uBandaFol: { value: new THREE.Vector4(...(opciones.banda ?? [-2, -1, 1e5, 1e6])) },
  };
  mat.onBeforeCompile = (shader) => {
    Object.assign(shader.uniforms, uniformesViento, u);
    shader.vertexShader = CAB_V + shader.vertexShader
      .replace('#include <begin_vertex>', CUERPO_V)
      .replace('#include <color_vertex>', COLOR_V);
    shader.fragmentShader = CAB_F + shader.fragmentShader
      .replace('#include <clipping_planes_fragment>', RECORTE_F)
      .replace('#include <map_fragment>', MAPA_F);
  };
  mat.customProgramCacheKey = () => 'foliaje-v2';
  return mat;
}

/* ═══════════════════════════ materiales ═══════════════════════════ */

const _cacheMat = new Map();

/** Claves cuyo material dibuja los billboards del LOD lejano. */
const RE_LEJANO = /lejos|lejano|billboard|lod2/;

export function materialFoliaje(ctx, clave, opciones = {}) {
  const k = `${clave}`;
  if (_cacheMat.has(k)) return _cacheMat.get(k);
  // Piso duro de alphaTest para el LOD lejano. Venía en 0,30 (el más permisivo
  // de la biblioteca, contra 0,42–0,5 del resto) y con un umbral así el fondo
  // semitransparente del tile del atlas pasaba el test: en vez de una copa se
  // dibujaba el CUADRILÁTERO entero de la cruz de billboards, esos paralelogramos
  // blanquecinos de borde recto apoyados sobre la orilla y el mar. A 0,5 sólo
  // sobrevive lo que en el atlas es hoja de verdad.
  const at = RE_LEJANO.test(k)
    ? Math.max(0.5, opciones.alphaTest ?? 0.5)
    : (opciones.alphaTest ?? 0.46);
  const m = new THREE.MeshStandardMaterial({
    map: atlasNaturaleza(ctx),
    color: 0xffffff,
    roughness: opciones.rugosidad ?? 0.92,
    metalness: 0,
    vertexColors: true,
    alphaTest: at,
    side: THREE.DoubleSide,
    shadowSide: THREE.DoubleSide,
    // OPACO a propósito, nunca transparent: así el billboard se ordena por
    // profundidad como geometría sólida, escribe en el z-buffer y no compite con
    // el agua. Un quad transparente sobre el mar se lee como una lámina flotando.
    transparent: false,
    depthWrite: true,
    // dithering: true FUERA. El fundido de LOD ya trae su propio ruido de
    // recorte; encimarle el dither de salida de three es ruido sobre ruido, y
    // además ese dither actúa sobre valores LINEALES HDR (OutputPass hace el
    // tone mapping después), donde su amplitud de 1/255 deja de ser invisible.
    dithering: false,
  });
  m.name = `fol_${clave}`;
  parcharFoliaje(m, opciones);
  ctx?.sombras?.registrarMaterial?.(m);
  _cacheMat.set(k, m);
  return m;
}

/** Material de profundidad gemelo: sin él, la sombra no acompaña al viento. */
export function materialProfundidadFoliaje(base) {
  const d = new THREE.MeshDepthMaterial({
    depthPacking: THREE.RGBADepthPacking,
    map: base.map, alphaTest: base.alphaTest, side: THREE.DoubleSide,
  });
  const o = base.userData.uFol;
  parcharFoliaje(d, {
    amplitud: o.uAmpViento.value, velocidad: o.uVelViento.value,
    flameo: o.uFlameoViento.value, banda: o.uBandaFol.value.toArray(),
  });
  return d;
}

const TRIPLANAR_V = /* glsl */`
#include <begin_vertex>
vec4 mundoTri = vec4(transformed, 1.0);
#ifdef USE_INSTANCING
  mundoTri = instanceMatrix * mundoTri;
#endif
vPosTri = (modelMatrix * mundoTri).xyz;
vNorTri = normalize(mat3(modelMatrix) * objectNormal);
`;

const TRIPLANAR_F = /* glsl */`
#ifdef USE_MAP
  vec3 pesoTri = pow(abs(vNorTri), vec3(4.0));
  pesoTri /= (pesoTri.x + pesoTri.y + pesoTri.z);
  vec4 triX = texture2D(map, vPosTri.zy * uEscalaTri);
  vec4 triY = texture2D(map, vPosTri.xz * uEscalaTri);
  vec4 triZ = texture2D(map, vPosTri.xy * uEscalaTri);
  vec4 sampledDiffuseColor = triX * pesoTri.x + triY * pesoTri.y + triZ * pesoTri.z;
  diffuseColor *= sampledDiffuseColor;
#endif
`;

let _matRoca = null;
/** Roca/acantilado: proyección triplanar en espacio de mundo, cero UVs que cuidar. */
export function materialRoca(ctx) {
  if (_matRoca) return _matRoca;
  const m = new THREE.MeshStandardMaterial({
    map: texturaRoca(ctx), color: 0xffffff, roughness: 0.96, metalness: 0,
    vertexColors: true, side: THREE.FrontSide,
  });
  m.name = 'roca';
  const u = { uEscalaTri: { value: 0.28 } };
  m.userData.uTri = u;
  m.onBeforeCompile = (shader) => {
    Object.assign(shader.uniforms, u);
    shader.vertexShader = 'varying vec3 vPosTri; varying vec3 vNorTri;\n' + shader.vertexShader
      .replace('#include <begin_vertex>', TRIPLANAR_V);
    shader.fragmentShader = 'varying vec3 vPosTri; varying vec3 vNorTri; uniform float uEscalaTri;\n'
      + shader.fragmentShader.replace('#include <map_fragment>', TRIPLANAR_F);
  };
  m.customProgramCacheKey = () => 'roca-triplanar-v1';
  ctx?.sombras?.registrarMaterial?.(m);
  _matRoca = m;
  return m;
}

/* ══════════════════════ acumulador de geometría ══════════════════════ */

class Malla {
  constructor() { this.p = []; this.n = []; this.u = []; this.c = []; this.h = []; this.w = []; this.i = []; }
  get vacia() { return this.i.length === 0; }
  v(px, py, pz, nx, ny, nz, u, vv, r, g, b, hoja, viento) {
    const k = this.p.length / 3;
    this.p.push(px, py, pz); this.n.push(nx, ny, nz); this.u.push(u, vv);
    this.c.push(r, g, b); this.h.push(hoja); this.w.push(viento);
    return k;
  }
  tri(a, b, c) { this.i.push(a, b, c); }
  quad(a, b, c, d) { this.i.push(a, b, c, a, c, d); }
  geo() {
    if (this.vacia) return null;
    const g = new THREE.BufferGeometry();
    g.setAttribute('position', new THREE.Float32BufferAttribute(this.p, 3));
    g.setAttribute('normal', new THREE.Float32BufferAttribute(this.n, 3));
    g.setAttribute('uv', new THREE.Float32BufferAttribute(this.u, 2));
    g.setAttribute('color', new THREE.Float32BufferAttribute(this.c, 3));
    g.setAttribute('aHoja', new THREE.Float32BufferAttribute(this.h, 1));
    g.setAttribute('aViento', new THREE.Float32BufferAttribute(this.w, 1));
    g.setIndex(this.i);
    g.computeBoundingSphere();
    return g;
  }
}

const _v1 = new THREE.Vector3(), _v2 = new THREE.Vector3(), _v3 = new THREE.Vector3();

function adaptar(rng) {
  if (rng && typeof rng.float === 'function') {
    return { f: (a, b) => rng.float(a, b), i: (a, b) => rng.int(a, b), p: (a) => rng.pick(a), b: (p) => rng.bool(p) };
  }
  const r = typeof rng === 'function' ? rng : mulberry32(1234);
  return {
    f: (a = 0, b = 1) => a + r() * (b - a),
    i: (a, b) => Math.floor(a + r() * (b - a + 1)),
    p: (arr) => arr[Math.floor(r() * arr.length)],
    b: (p = 0.5) => r() < p,
  };
}

/** Tubo con transporte paralelo: sin esto las ramas se retuercen al curvarse. */
function tubo(m, pts, radios, lados, rect, colorFn, vientoFn, raiz) {
  const n = pts.length;
  const anillos = [];
  let prev = null;
  for (let s = 0; s < n; s++) {
    const p = pts[s];
    const d = _v1.copy(s < n - 1 ? pts[s + 1] : p).sub(s < n - 1 ? p : pts[s - 1]).normalize();
    let nr;
    if (!prev) {
      nr = new THREE.Vector3(Math.abs(d.y) > 0.9 ? 1 : 0, Math.abs(d.y) > 0.9 ? 0 : 1, 0).cross(d).normalize();
      if (nr.lengthSq() < 1e-6) nr.set(1, 0, 0);
    } else {
      nr = prev.clone().addScaledVector(d, -prev.dot(d));
      if (nr.lengthSq() < 1e-8) nr.set(d.z, 0, -d.x);
      nr.normalize();
    }
    prev = nr;
    const bi = new THREE.Vector3().crossVectors(d, nr).normalize();
    const t = s / (n - 1);
    const fila = [];
    const vi = vientoFn(t);
    for (let k = 0; k < lados; k++) {
      const a = (k / lados) * Math.PI * 2;
      const co = Math.cos(a), si = Math.sin(a);
      let r = radios[s];
      if (raiz) r *= 1 + Math.max(0, 1 - s * 0.9) * (0.42 * Math.sin(a * 3.0 + 0.6) + 0.22 * Math.sin(a * 5.0));
      const nx = nr.x * co + bi.x * si, ny = nr.y * co + bi.y * si, nz = nr.z * co + bi.z * si;
      const col = colorFn(t, a);
      fila.push(m.v(
        p.x + nx * r, p.y + ny * r, p.z + nz * r,
        nx, ny, nz,
        rect.u0 + (k / lados) * rect.du, rect.v0 + t * rect.dv,
        col[0], col[1], col[2], 0, vi
      ));
    }
    anillos.push(fila);
  }
  for (let s = 0; s < n - 1; s++) {
    for (let k = 0; k < lados; k++) {
      const k2 = (k + 1) % lados;
      m.quad(anillos[s][k], anillos[s][k2], anillos[s + 1][k2], anillos[s + 1][k]);
    }
  }
  // tapa: el hueco se nota cuando la cámara baja
  const ult = anillos[n - 1];
  const pf = pts[n - 1];
  const col = colorFn(1, 0);
  const cima = m.v(pf.x, pf.y, pf.z, 0, 1, 0, rect.u0 + rect.du * 0.5, rect.v0 + rect.dv, col[0], col[1], col[2], 0, vientoFn(1));
  for (let k = 0; k < lados; k++) m.tri(ult[k], ult[(k + 1) % lados], cima);
}

/** Card de follaje: normales "esféricas" para que la copa se ilumine como un volumen. */
function carta(m, centro, salida, ancho, alto, rect, col, viento, sesgoNormal = 0.85) {
  const arriba = Math.abs(salida.y) > 0.94 ? _v2.set(1, 0, 0) : _v2.set(0, 1, 0);
  const tx = new THREE.Vector3().crossVectors(arriba, salida).normalize();
  const ty = new THREE.Vector3().crossVectors(salida, tx).normalize();
  const idx = [];
  const esq = [[-1, -1], [1, -1], [1, 1], [-1, 1]];
  for (let q = 0; q < 4; q++) {
    const [su, sv] = esq[q];
    const px = centro.x + tx.x * su * ancho + ty.x * sv * alto;
    const py = centro.y + tx.y * su * ancho + ty.y * sv * alto;
    const pz = centro.z + tx.z * su * ancho + ty.z * sv * alto;
    _v3.set(
      salida.x * sesgoNormal + tx.x * su * 0.45 + ty.x * sv * 0.35,
      salida.y * sesgoNormal + tx.y * su * 0.45 + ty.y * sv * 0.35,
      salida.z * sesgoNormal + tx.z * su * 0.45 + ty.z * sv * 0.35
    ).normalize();
    // el borde inferior va oscuro y el superior POR ENCIMA de 1: es AO barata
    // dentro de la copa y, del otro lado, el rebote de sol en la cara de arriba.
    // Sin ese extremo claro la copa entera queda en un único tono medio y el
    // cuadro se queda sin nada que sea "lo más claro".
    const k = sv < 0 ? 0.70 : 1.14;
    idx.push(m.v(px, py, pz, _v3.x, _v3.y, _v3.z,
      rect.u0 + (su > 0 ? rect.du : 0), rect.v0 + (sv > 0 ? rect.dv : 0),
      col[0] * k, col[1] * k, col[2] * k, 1, viento));
  }
  m.quad(idx[0], idx[1], idx[2], idx[3]);
}

function cartasCruzadas(m, centro, salida, ancho, alto, rect, col, viento) {
  carta(m, centro, salida, ancho, alto, rect, col, viento);
  const arriba = Math.abs(salida.y) > 0.94 ? _v2.set(1, 0, 0) : _v2.set(0, 1, 0);
  const tx = new THREE.Vector3().crossVectors(arriba, salida).normalize();
  carta(m, centro, tx, ancho * 0.92, alto, rect, col, viento, 0.6);
}

/* ══════════════════════════ especies ══════════════════════════ */

// colCorteza y colHoja son multiplicadores LINEALES sobre el tile del atlas
// (que ya viene decodificado de sRGB). Subidos ~1,25–1,45x respecto de la versión
// anterior por la misma razón que las paletas del atlas: el producto
// tile_lineal · colHoja · horneado_de_copa dejaba las copas en un albedo de 0,05
// contra un suelo de 0,24, y un bosque tres veces más oscuro que el pasto se lee
// como un agujero negro, no como un bosque.
const ESPECIES = {
  pino: {
    altura: [13, 19.5], radio: [0.026, 0.034], copa: 'conifera',
    corteza: TILE.CORTEZA_PINO, hoja: TILE.AGUJA_PINO,
    colCorteza: [0.87, 0.58, 0.41], colHoja: [0.56, 0.81, 0.49],
    niveles: 1, hijos: [3, 5], angulo: 1.35, escalaHijo: 0.20, radioHijo: 0.26, inicioHijos: 0.45,
    conicidad: 0.86, curva: 0.05, gravedad: -0.02, copaIni: 0.30, copaRadio: [0.17, 0.23],
  },
  roble: {
    altura: [8.5, 12.8], radio: [0.045, 0.060], copa: 'racimos',
    corteza: TILE.CORTEZA_RUGOSA, hoja: TILE.HOJA_ROBLE,
    colCorteza: [0.81, 0.64, 0.46], colHoja: [0.76, 1.00, 0.51],
    niveles: 3, hijos: [2, 3], angulo: 0.85, escalaHijo: 0.62, radioHijo: 0.56, inicioHijos: 0.45,
    conicidad: 0.62, curva: 0.16, gravedad: 0.04, copaIni: 0.42, copaRadio: [0.30, 0.40],
  },
  palmera: {
    altura: [7.5, 12], radio: [0.028, 0.036], copa: 'palma',
    corteza: TILE.CORTEZA_PALMERA, hoja: TILE.FRONDA,
    // colHoja bajado y desviado al oliva. La palmera sale en playa y desierto,
    // o sea SIEMPRE con masa de rodal ≈ 0, así que se comía el extremo alto del
    // tinte por instancia (×1,55) sin excepción; con una copa que además es
    // superficie sólida —sin los huecos de alfa que promedian una copa de
    // roble— el producto pasaba de albedo 1 y se leía como si fuera emisiva.
    colCorteza: [0.96, 0.81, 0.58], colHoja: [0.78, 0.88, 0.56],
    niveles: 0, hijos: [0, 0], angulo: 0, escalaHijo: 0, radioHijo: 0, inicioHijos: 1,
    conicidad: 0.40, curva: 0.30, gravedad: -0.10, copaIni: 0.98, copaRadio: [0.26, 0.34],
  },
  sauce: {
    altura: [7.5, 11.5], radio: [0.048, 0.062], copa: 'llorona',
    corteza: TILE.CORTEZA_RUGOSA, hoja: TILE.HOJA_SAUCE,
    colCorteza: [0.70, 0.58, 0.44], colHoja: [0.73, 0.98, 0.54],
    niveles: 2, hijos: [3, 4], angulo: 0.95, escalaHijo: 0.58, radioHijo: 0.52, inicioHijos: 0.32,
    conicidad: 0.66, curva: 0.20, gravedad: 0.02, copaIni: 0.40, copaRadio: [0.34, 0.44],
  },
  abedul: {
    altura: [10, 15], radio: [0.022, 0.030], copa: 'racimos',
    corteza: TILE.CORTEZA_ABEDUL, hoja: TILE.HOJA_ABEDUL,
    colCorteza: [1.02, 1.00, 0.94], colHoja: [0.83, 1.07, 0.56],
    niveles: 2, hijos: [2, 3], angulo: 0.62, escalaHijo: 0.56, radioHijo: 0.50, inicioHijos: 0.52,
    conicidad: 0.70, curva: 0.10, gravedad: 0.02, copaIni: 0.50, copaRadio: [0.17, 0.24],
  },
  muerto: {
    altura: [6.5, 10.5], radio: [0.038, 0.052], copa: 'ninguna',
    corteza: TILE.CORTEZA_MUERTA, hoja: TILE.HOJA_SECA,
    colCorteza: [0.90, 0.84, 0.75], colHoja: [0.98, 0.76, 0.37],
    niveles: 3, hijos: [2, 4], angulo: 1.05, escalaHijo: 0.60, radioHijo: 0.50, inicioHijos: 0.35,
    conicidad: 0.74, curva: 0.34, gravedad: 0.03, copaIni: 0.5, copaRadio: [0.24, 0.32],
  },
  cipres: {
    altura: [10, 16], radio: [0.024, 0.032], copa: 'columnar',
    corteza: TILE.CORTEZA_RUGOSA, hoja: TILE.ESCAMA_CIPRES,
    colCorteza: [0.67, 0.55, 0.44], colHoja: [0.54, 0.76, 0.51],
    niveles: 1, hijos: [2, 3], angulo: 0.5, escalaHijo: 0.30, radioHijo: 0.30, inicioHijos: 0.5,
    conicidad: 0.72, curva: 0.06, gravedad: -0.04, copaIni: 0.16, copaRadio: [0.075, 0.105],
  },
};

/** Paleta de hoja por especie, en lineal aproximado. La usa Foliaje para instanceColor. */
export const PALETA_HOJA = Object.fromEntries(
  Object.entries(ESPECIES).map(([k, v]) => [k, v.colHoja.slice()])
);

function girar(dir, azimut, angulo) {
  const eje = Math.abs(dir.y) > 0.94 ? _v2.set(1, 0, 0) : _v2.set(0, 1, 0);
  const tx = new THREE.Vector3().crossVectors(eje, dir).normalize();
  const ty = new THREE.Vector3().crossVectors(dir, tx).normalize();
  const s = Math.sin(angulo), c = Math.cos(angulo);
  return new THREE.Vector3(
    dir.x * c + (tx.x * Math.cos(azimut) + ty.x * Math.sin(azimut)) * s,
    dir.y * c + (tx.y * Math.cos(azimut) + ty.y * Math.sin(azimut)) * s,
    dir.z * c + (tx.z * Math.cos(azimut) + ty.z * Math.sin(azimut)) * s
  ).normalize();
}

function puntoEn(pts, t) {
  const f = clamp(t, 0, 0.999) * (pts.length - 1);
  const i = Math.floor(f), fr = f - i;
  const a = pts[i], b = pts[Math.min(i + 1, pts.length - 1)];
  return {
    pos: new THREE.Vector3(lerp(a.x, b.x, fr), lerp(a.y, b.y, fr), lerp(a.z, b.z, fr)),
    tan: new THREE.Vector3(b.x - a.x, b.y - a.y, b.z - a.z).normalize(),
  };
}

function ramificar(m, cfg, R, ruido, rect, origen, dir, largo, radio, nivel, puntas, detalle) {
  const seg = nivel === 0 ? (detalle > 0.6 ? 5 : 3) : (detalle > 0.6 ? 3 : 2);
  const lados = nivel === 0 ? (detalle > 0.6 ? 7 : 5) : (nivel === 1 ? 5 : 4);
  const pts = [origen.clone()], radios = [radio];
  let p = origen.clone(), d = dir.clone().normalize();
  for (let s = 1; s <= seg; s++) {
    const t = s / seg;
    d.x += ruido.simplex2(p.x * 0.55 + nivel * 13.7, p.z * 0.55 - nivel * 6.1) * cfg.curva;
    d.z += ruido.simplex2(p.z * 0.55 + nivel * 29.3, p.x * 0.55 + 4.9) * cfg.curva;
    d.y += cfg.gravedad * (nivel > 0 ? 1.6 : 0.35);
    d.normalize();
    p = p.clone().addScaledVector(d, largo / seg);
    pts.push(p);
    radios.push(Math.max(0.012, radio * Math.pow(1 - t * cfg.conicidad, 1.15)));
  }
  const cc = cfg.colCorteza;
  const colorFn = (t, a) => {
    // sombreado lateral horneado + oscurecimiento en la base (contacto con el
    // suelo). El rango se abre: la cara al sol del tronco pasa de 1.08 y ahí es
    // donde el tronco deja de leerse como un palo negro recortado contra el pasto
    const lat = 0.72 + 0.46 * Math.cos(a - 0.8);
    const base = nivel === 0 ? lerp(0.66, 1.06, smoothstep(0, 0.30, t)) : 0.98;
    const k = lat * base;
    return [cc[0] * k, cc[1] * k, cc[2] * k];
  };
  const vientoFn = (t) => {
    const alturaRel = clamp((lerp(pts[0].y, pts[pts.length - 1].y, t)) / 14, 0, 1);
    return nivel === 0 ? 0.10 * alturaRel * alturaRel : clamp(0.16 + nivel * 0.20 + t * 0.22, 0, 0.62);
  };
  tubo(m, pts, radios, lados, rect, colorFn, vientoFn, nivel === 0);

  if (nivel < cfg.niveles && radio > 0.02) {
    const n = R.i(cfg.hijos[0], cfg.hijos[1]);
    let az = R.f(0, Math.PI * 2);
    for (let h = 0; h < n; h++) {
      az += 2.3999632 + R.f(-0.45, 0.45); // ángulo áureo: ramas que no se pisan
      const t = cfg.inicioHijos + (n > 1 ? (h / (n - 1)) : 0.5) * (0.97 - cfg.inicioHijos) + R.f(-0.05, 0.05);
      const { pos, tan } = puntoEn(pts, t);
      const nd = girar(tan, az, cfg.angulo * R.f(0.72, 1.28));
      ramificar(m, cfg, R, ruido, rect, pos, nd,
        largo * cfg.escalaHijo * R.f(0.82, 1.15), radio * cfg.radioHijo, nivel + 1, puntas, detalle);
    }
  }
  if (nivel >= cfg.niveles || radio <= 0.02) {
    puntas.push({ p: pts[pts.length - 1].clone(), d: d.clone(), r: radio, nivel });
  }
}

function copaRacimos(mh, R, ruido, cfg, altura, radioCopa, puntas, rectHoja, colHoja, detalle, llorona) {
  const centro = new THREE.Vector3(0, altura * (llorona ? 0.72 : 0.70), 0);
  const cuenta = Math.max(8, Math.round((llorona ? 34 : 30) * detalle));
  const usarPuntas = puntas.filter((q) => q.p.y > altura * 0.35);
  const tamCard = (llorona ? 0.30 : 0.34) * radioCopa * (detalle > 0.6 ? 1 : 1.7);
  for (let i = 0; i < cuenta; i++) {
    let c, salida;
    if (usarPuntas.length && i < usarPuntas.length * 1.6) {
      const q = usarPuntas[i % usarPuntas.length];
      c = q.p.clone().addScaledVector(q.d, radioCopa * R.f(0.06, 0.30));
      c.x += R.f(-0.35, 0.35) * radioCopa; c.z += R.f(-0.35, 0.35) * radioCopa;
      c.y += R.f(-0.25, 0.30) * radioCopa;
    } else {
      const th = R.f(0, Math.PI * 2), ph = Math.acos(R.f(-0.75, 1));
      const rr = radioCopa * (0.55 + 0.45 * Math.pow(R.f(0, 1), 0.4));
      c = new THREE.Vector3(
        centro.x + Math.sin(ph) * Math.cos(th) * rr,
        centro.y + Math.cos(ph) * rr * (llorona ? 0.72 : 0.82),
        centro.z + Math.sin(ph) * Math.sin(th) * rr
      );
    }
    // deformación de la copa con ruido: nada de esferas perfectas
    const def = 1 + 0.30 * ruido.fbm(c.x * 0.45, c.z * 0.45, 3);
    c.x *= def; c.z *= def;
    salida = c.clone().sub(centro);
    if (salida.lengthSq() < 1e-5) salida.set(0, 1, 0);
    salida.normalize();
    const prof = clamp(c.clone().sub(centro).length() / radioCopa, 0, 1);
    // rango abierto a propósito: el interior de la copa baja a 0.55 y la corona
    // al cielo sube a 1.34. La media casi no se mueve, pero aparece un gradiente
    // dentro del árbol — que es lo que separa una copa con volumen de una mancha
    const luz = lerp(0.55, 1.34, prof * 0.6 + smoothstep(centro.y - radioCopa, centro.y + radioCopa, c.y) * 0.4);
    const col = [colHoja[0] * luz, colHoja[1] * luz, colHoja[2] * luz];
    const s = tamCard * R.f(0.78, 1.30);
    cartasCruzadas(mh, c, salida, s, s * 0.86, rectHoja, col, 0.62 + prof * 0.38);
    if (llorona && prof > 0.55 && R.b(0.75)) {
      // cortinas colgantes: la firma del sauce
      const largo = radioCopa * R.f(0.7, 1.5);
      const cc = c.clone(); cc.y -= largo * 0.5;
      carta(mh, cc, salida, s * 0.55, largo * 0.6, rectHoja,
        [col[0] * 0.95, col[1] * 0.95, col[2] * 0.95], 1.0, 0.5);
    }
  }
}

function copaConifera(mh, R, ruido, cfg, altura, radioCopa, rectHoja, colHoja, detalle) {
  const n = Math.max(4, Math.round(R.i(7, 9) * clamp(detalle, 0.5, 1)));
  const yIni = altura * cfg.copaIni;
  const lados = detalle > 0.6 ? 9 : 6;
  for (let i = 0; i < n; i++) {
    const t = i / (n - 1);
    const y0 = lerp(yIni, altura * 0.90, t);
    const alto = (altura - yIni) / n * R.f(1.5, 2.1);
    const r = radioCopa * (1 - Math.pow(t, 1.15) * 0.90) * R.f(0.88, 1.08);
    const cx = R.f(-0.06, 0.06) * radioCopa, cz = R.f(-0.06, 0.06) * radioCopa;
    const luzP = lerp(0.58, 1.36, t); // faldón bajo en sombra, punta al sol
    const cima = mh.v(cx, y0 + alto, cz, 0, 1, 0, rectHoja.u0 + rectHoja.du * 0.5, rectHoja.v0 + rectHoja.dv,
      colHoja[0] * luzP * 1.22, colHoja[1] * luzP * 1.22, colHoja[2] * luzP * 1.22, 1, 0.35 + t * 0.4);
    const aro = [];
    for (let k = 0; k < lados; k++) {
      const a = (k / lados) * Math.PI * 2;
      const rr = r * (0.82 + 0.34 * (0.5 + 0.5 * ruido.simplex2(Math.cos(a) * 2 + i * 3.3, Math.sin(a) * 2)));
      const px = cx + Math.cos(a) * rr, pz = cz + Math.sin(a) * rr;
      const py = y0 - rr * 0.20; // la falda cae en el borde
      const luz = luzP * 0.66; // el borde del faldón es lo que se autosombrea
      aro.push(mh.v(px, py, pz, Math.cos(a) * 0.45, 0.86, Math.sin(a) * 0.45,
        rectHoja.u0 + (k / lados) * rectHoja.du, rectHoja.v0,
        colHoja[0] * luz, colHoja[1] * luz, colHoja[2] * luz, 1, 0.30 + t * 0.45));
    }
    for (let k = 0; k < lados; k++) mh.tri(cima, aro[k], aro[(k + 1) % lados]);
    if (detalle > 0.6) { // cards en el borde: rompen la silueta cónica perfecta
      const nc = 3;
      for (let k = 0; k < nc; k++) {
        const a = R.f(0, Math.PI * 2);
        const rr = r * R.f(0.75, 1.05);
        const c = new THREE.Vector3(cx + Math.cos(a) * rr, y0 + alto * R.f(0.1, 0.5), cz + Math.sin(a) * rr);
        const sal = new THREE.Vector3(Math.cos(a), 0.35, Math.sin(a)).normalize();
        const s = r * R.f(0.28, 0.44);
        carta(mh, c, sal, s, s * 0.8, rectHoja,
          [colHoja[0] * luzP, colHoja[1] * luzP, colHoja[2] * luzP], 0.55 + t * 0.4);
      }
    }
  }
}

function copaColumnar(mh, R, ruido, cfg, altura, radioCopa, rectHoja, colHoja, detalle) {
  const cuenta = Math.max(10, Math.round(44 * detalle));
  const y0 = altura * cfg.copaIni, y1 = altura * 1.0;
  for (let i = 0; i < cuenta; i++) {
    const t = R.f(0, 1);
    const y = lerp(y0, y1, Math.pow(t, 0.85));
    const perfil = Math.sin(Math.pow(t, 0.75) * Math.PI * 0.92) * 0.75 + 0.32;
    const a = R.f(0, Math.PI * 2);
    const rr = radioCopa * perfil * R.f(0.7, 1.12) * (1 + 0.2 * ruido.simplex2(y * 0.7, a));
    const c = new THREE.Vector3(Math.cos(a) * rr, y, Math.sin(a) * rr);
    const sal = new THREE.Vector3(Math.cos(a), 0.22, Math.sin(a)).normalize();
    const luz = lerp(0.55, 1.32, t);
    const s = radioCopa * R.f(0.85, 1.5) * (detalle > 0.6 ? 1 : 1.6);
    cartasCruzadas(mh, c, sal, s, s * 1.15, rectHoja,
      [colHoja[0] * luz, colHoja[1] * luz, colHoja[2] * luz], 0.35 + t * 0.5);
  }
}

const _frTg = new THREE.Vector3(), _frLat = new THREE.Vector3(), _frNor = new THREE.Vector3();
const _frNI = new THREE.Vector3(), _frND = new THREE.Vector3(), _frDh = new THREE.Vector3();
const _frPts = [];
for (let i = 0; i < 9; i++) _frPts.push(new THREE.Vector3());
const _palDir = new THREE.Vector3(), _palBase = new THREE.Vector3();

/**
 * Una fronda: cinta PLEGADA EN V sobre su raquis, curvada en planta y vencida.
 *
 * La versión anterior era un rectángulo plano con UNA normal única para toda la
 * hoja (`up` mezclada con la dirección). Con la cámara cenital y el sol alto eso
 * significa que los cientos de píxeles de la fronda comparten exactamente el
 * mismo N·L: la hoja no tiene gradiente, no tiene borde en sombra, no tiene
 * nada — se lee PLANA, que es la mitad del defecto "verde neón sin iluminar".
 *
 * Ahora se emiten tres columnas de vértices (ala izquierda, raquis, ala derecha)
 * y cada una lleva su propia normal sacada del pliegue real. Con el sol de
 * costado un ala queda clara y la otra en sombra dentro de la MISMA hoja, y la
 * quilla del raquis dibuja una línea de luz. Cuesta el doble de triángulos que
 * la cinta plana (20 por fronda) y es lo que la convierte en volumen.
 *
 * `op.barrido` curva la fronda en planta (deja de ser un radio de rueda),
 * `op.vIni/vFin` le dan a cada hoja su propia ventana del tile —sin eso los 46
 * folíolos caen al mismo radio en todas y ESO son las bandas concéntricas— y
 * `op.espejo` invierte la U, que con DoubleSide sale gratis.
 */
function fronda(mh, base, dirH, largo, ancho, rect, col, viento, op = {}) {
  const seg = Math.min(8, op.segmentos ?? 5);
  const barrido = op.barrido ?? 0;
  const caida = op.caida ?? 0.62;
  const pliegue = clamp(op.pliegue ?? 0.55, 0.05, 1.1);
  const vIni = op.vIni ?? 0, vFin = op.vFin ?? 1;
  const luzIni = op.luzIni ?? 1.06, luzFin = op.luzFin ?? 0.62;
  const sesgo = op.sesgo ?? 0;                 // asimetría horneada entre alas
  const uIzq = rect.u0 + (op.espejo ? rect.du : 0);
  const uDer = rect.u0 + (op.espejo ? 0 : rect.du);

  // dirección horizontal y pendiente inicial van por separado: la pendiente se
  // gasta a lo largo de la hoja (la punta cuelga), el rumbo no
  _frDh.set(dirH.x, 0, dirH.z);
  if (_frDh.lengthSq() < 1e-8) _frDh.set(1, 0, 0);
  _frDh.normalize();
  const subida = dirH.y;
  const latX = -_frDh.z, latZ = _frDh.x;

  for (let s = 0; s <= seg; s++) {
    const t = s / seg;
    const ang = barrido * t * t;               // la punta barre, la base sale recta
    const c = Math.cos(ang), sn = Math.sin(ang);
    const av = largo * t;
    _frPts[s].set(
      base.x + (_frDh.x * c + latX * sn) * av,
      base.y + subida * av - Math.pow(t, 1.9) * largo * caida,
      base.z + (_frDh.z * c + latZ * sn) * av,
    );
  }

  let aI = -1, aC = -1, aD = -1;
  for (let s = 0; s <= seg; s++) {
    const t = s / seg;
    const p = _frPts[s];
    _frTg.copy(s < seg ? _frPts[s + 1] : p).sub(s < seg ? p : _frPts[s - 1]);
    if (_frTg.lengthSq() < 1e-10) _frTg.set(_frDh.x, 0, _frDh.z);
    _frTg.normalize();
    _frLat.set(-_frTg.z, 0, _frTg.x);
    if (_frLat.lengthSq() < 1e-8) _frLat.set(1, 0, 0);
    _frLat.normalize();
    _frNor.crossVectors(_frLat, _frTg).normalize();   // normal de la superficie

    const w = ancho * Math.sin(Math.pow(t, 0.65) * Math.PI * 0.98) * (1 - t * 0.15) + 0.02;
    const cai = w * pliegue;                   // las alas cuelgan del raquis
    _frNI.copy(_frNor).addScaledVector(_frLat, pliegue * 1.15).normalize();
    _frND.copy(_frNor).addScaledVector(_frLat, -pliegue * 1.15).normalize();

    const luz = lerp(luzIni, luzFin, t);
    const kC = luz * 1.08, kI = luz * (0.84 + sesgo), kD = luz * (0.84 - sesgo);
    const vt = rect.v0 + lerp(vIni, vFin, t) * rect.dv;
    const vie = viento * (0.35 + t * 0.65);

    const iC = mh.v(p.x, p.y, p.z, _frNor.x, _frNor.y, _frNor.z,
      rect.u0 + rect.du * 0.5, vt, col[0] * kC, col[1] * kC, col[2] * kC, 1, vie);
    const iI = mh.v(p.x + _frLat.x * w, p.y - cai, p.z + _frLat.z * w,
      _frNI.x, _frNI.y, _frNI.z, uIzq, vt, col[0] * kI, col[1] * kI, col[2] * kI, 1, vie * 1.18);
    const iD = mh.v(p.x - _frLat.x * w, p.y - cai, p.z - _frLat.z * w,
      _frND.x, _frND.y, _frND.z, uDer, vt, col[0] * kD, col[1] * kD, col[2] * kD, 1, vie * 1.18);
    if (s > 0) { mh.quad(aI, aC, iC, iI); mh.quad(aC, aD, iD, iC); }
    aI = iI; aC = iC; aD = iD;
  }
}

/**
 * Geometría de un árbol. `opciones.detalle` 1 = completo, ~0.45 = copa simplificada.
 * Devuelve dos BufferGeometry ya fusionadas (tronco + ramas / copa).
 */
export function crearGeometriaArbol(tipo, rng, opciones = {}) {
  const cfg = { ...(ESPECIES[tipo] || ESPECIES.roble), ...(opciones.cfg || {}) };
  const R = adaptar(rng);
  const detalle = opciones.detalle ?? 1;
  const ruido = new Ruido((R.i(1, 1e6) ^ 0x2f6b) >>> 0);
  const altura = opciones.altura ?? R.f(cfg.altura[0], cfg.altura[1]);
  const radioTronco = altura * R.f(cfg.radio[0], cfg.radio[1]);
  const radioCopa = altura * R.f(cfg.copaRadio[0], cfg.copaRadio[1]);

  const mt = new Malla(), mh = new Malla();
  const rectC = rectTile(cfg.corteza), rectH = rectTile(cfg.hoja);
  const puntas = [];
  const nivelesEfectivos = detalle > 0.6 ? cfg.niveles : Math.max(0, cfg.niveles - 1);

  if (cfg.copa === 'palma') {
    // el tronco de la palmera es un arco, no un árbol ramificado
    const pts = [], radios = [];
    const inc = new THREE.Vector3(R.f(-1, 1), 0, R.f(-1, 1)).normalize().multiplyScalar(altura * R.f(0.05, 0.16));
    const nseg = detalle > 0.6 ? 7 : 4;
    for (let s = 0; s <= nseg; s++) {
      const t = s / nseg;
      pts.push(new THREE.Vector3(inc.x * t * t, altura * t, inc.z * t * t));
      radios.push(radioTronco * (1 - t * 0.42) * (s === 0 ? 1.5 : 1));
    }
    const cc = cfg.colCorteza;
    tubo(mt, pts, radios, detalle > 0.6 ? 8 : 6, rectC,
      (t, a) => { const k = (0.82 + 0.26 * Math.cos(a - 0.8)) * lerp(0.66, 1.0, smoothstep(0, 0.2, t)); return [cc[0] * k, cc[1] * k, cc[2] * k]; },
      (t) => 0.05 + t * t * 0.26, true);
    const cima = pts[pts.length - 1];
    /*
     * CORONA ASIMÉTRICA. Lo que el jurado marcó cuatro veces como "blob verde
     * neón con bandas concéntricas" era esta corona vista desde arriba: ocho a
     * once frondas repartidas en ángulos casi exactos (±0,18 rad de jitter sobre
     * un paso de 0,7), todas del mismo largo, la misma inclinación, la misma
     * ventana de UV y un brillo que ciclaba cada 3 hojas. Vista cenital, eso es
     * una rueda de rayos con interferencia perfecta.
     *
     * Acá TODO lo que puede desigualarse se desigualó: ángulos con jitter de
     * medio paso, un "peinado" que vence la corona entera hacia un lado (el
     * viento dominante del sitio), largos que van de 0,6 a 1,3 del radio de copa,
     * frondas jóvenes cortas y empinadas contra viejas largas y horizontales,
     * barrido lateral con signo propio, plegado propio y un faldón de una a tres
     * frondas secas color paja, que es lo que más rápido mata el verde único.
     */
    const nf = Math.max(7, Math.round(R.i(10, 14) * clamp(detalle, 0.55, 1)));
    const peine = R.f(0, Math.PI * 2);        // hacia dónde se vence la corona
    const asim = R.f(0.16, 0.42);
    const nSecas = R.i(1, 3);
    const a0 = R.f(0, Math.PI * 2);
    const paso = Math.PI * 2 / nf;
    const radioCima = radioTronco * 0.58;
    for (let i = 0; i < nf; i++) {
      const a = a0 + i * paso + R.f(-0.62, 0.62) * paso;
      const vieja = i < nSecas;
      // `t3` correlaciona todo lo que distingue una fronda joven de una vieja:
      // corta, empinada y tiesa contra larga, horizontal y vencida
      const t3 = vieja ? R.f(0.84, 1.0) : R.f(0, 0.92);
      const inclina = lerp(0.76, 0.02, t3) - (vieja ? R.f(0.20, 0.44) : 0)
        + asim * Math.cos(a - peine) * 0.45;
      const seca = vieja ? R.f(0.45, 0.85) : 0;
      const tono = R.f(0.86, 1.10);
      // temporales propios: `_v1`/`_v2` los pisan `carta` y `girar`, y acá el
      // rumbo tiene que sobrevivir a toda la construcción de la hoja
      _palDir.set(Math.cos(a), inclina, Math.sin(a)).normalize();
      _palBase.set(cima.x + Math.cos(a) * radioCima * R.f(0.4, 1.6),
        cima.y - R.f(0.02, 0.30) * radioCopa,
        cima.z + Math.sin(a) * radioCima * R.f(0.4, 1.6));
      fronda(mh, _palBase, _palDir,
        radioCopa * lerp(0.62, 1.34, t3) * R.f(0.90, 1.10),
        radioCopa * R.f(0.11, 0.18) * lerp(0.86, 1.14, t3),
        rectH, [
          lerp(cfg.colHoja[0], 1.04, seca) * tono,
          lerp(cfg.colHoja[1], 0.80, seca) * tono,
          lerp(cfg.colHoja[2], 0.38, seca) * tono,
        ], 0.85, {
          segmentos: detalle > 0.6 ? 5 : 3,
          barrido: R.f(-0.72, 0.72),
          caida: lerp(0.26, 0.92, t3) + (vieja ? 0.34 : 0),
          pliegue: R.f(0.38, 0.88),
          vIni: R.f(0, 0.22), vFin: R.f(0.80, 1.0),
          espejo: R.b(0.5),
          luzIni: R.f(0.90, 1.14), luzFin: R.f(0.48, 0.72),
          sesgo: R.f(-0.18, 0.18),
        });
    }
    // cocos / racimo bajo la corona
    if (R.b(0.4)) {
      for (let i = 0; i < 4; i++) {
        const a = R.f(0, Math.PI * 2);
        const c = new THREE.Vector3(cima.x + Math.cos(a) * 0.3, cima.y - 0.35, cima.z + Math.sin(a) * 0.3);
        carta(mh, c, new THREE.Vector3(Math.cos(a), -0.3, Math.sin(a)).normalize(), 0.22, 0.22,
          rectTile(TILE.MATA), [0.62, 0.50, 0.30], 0.3);
      }
    }
  } else {
    const cfgR = { ...cfg, niveles: nivelesEfectivos };
    ramificar(mt, cfgR, R, ruido, rectC, new THREE.Vector3(0, 0, 0),
      new THREE.Vector3(R.f(-0.06, 0.06), 1, R.f(-0.06, 0.06)).normalize(),
      altura * (cfg.copa === 'conifera' || cfg.copa === 'columnar' ? 0.96 : 0.62),
      radioTronco, 0, puntas, detalle);

    if (cfg.copa === 'conifera') copaConifera(mh, R, ruido, cfg, altura, radioCopa, rectH, cfg.colHoja, detalle);
    else if (cfg.copa === 'columnar') copaColumnar(mh, R, ruido, cfg, altura, radioCopa, rectH, cfg.colHoja, detalle);
    else if (cfg.copa === 'racimos') copaRacimos(mh, R, ruido, cfg, altura, radioCopa, puntas, rectH, cfg.colHoja, detalle, false);
    else if (cfg.copa === 'llorona') copaRacimos(mh, R, ruido, cfg, altura, radioCopa, puntas, rectH, cfg.colHoja, detalle, true);
    else if (cfg.copa === 'ninguna' && R.b(0.45)) {
      // el árbol muerto conserva algún jirón seco: rompe la simetría de palo pelado
      for (let i = 0; i < 5; i++) {
        const q = puntas[(R.i(0, Math.max(0, puntas.length - 1)))];
        if (!q) break;
        const sal = q.d.clone();
        carta(mh, q.p, sal, 0.34, 0.30, rectTile(TILE.HOJA_SECA), cfg.colHoja, 0.9);
      }
    }
  }

  return {
    tronco: mt.geo(), hojas: mh.geo(),
    altura, radio: cfg.copa === 'ninguna' ? radioCopa * 0.6 : radioCopa,
  };
}

/** Árbol suelto (no instanciado): útil para previsualización o props únicos. */
export function crearArbol(tipo, rng, ctx) {
  const { tronco, hojas, altura, radio } = crearGeometriaArbol(tipo, rng, {});
  const mat = materialFoliaje(ctx, 'arbol_cerca', { amplitud: 0.16, velocidad: 1.25, flameo: 0.04 });
  const g = new THREE.Group();
  g.name = `arbol_${tipo}`;
  const partes = hojas ? [tronco, hojas] : [tronco];
  const fusion = partes.length > 1 ? mergeGeometries(partes, false) : tronco;
  const malla = new THREE.Mesh(fusion, mat);
  malla.castShadow = true; malla.receiveShadow = true;
  g.add(malla);
  g.userData = { altura, radio, tipo };
  return g;
}

/* ═══════════════════════════ rocas ═══════════════════════════ */

/** Icosaedro deformado con fbm + planos de corte; normales duras por cara. */
export function crearGeometriaRoca(tamano = 1, rng, opciones = {}) {
  const R = adaptar(rng);
  const ruido = new Ruido((R.i(1, 1e6) ^ 0x9c17) >>> 0);
  const g = new THREE.IcosahedronGeometry(1, opciones.subdiv ?? 2);
  const pos = g.attributes.position;
  const n = pos.count;

  const planos = [];
  const nPlanos = R.i(2, 4);
  for (let i = 0; i < nPlanos; i++) {
    const v = new THREE.Vector3(R.f(-1, 1), R.f(-0.7, 1), R.f(-1, 1)).normalize();
    planos.push({ n: v, d: R.f(0.42, 0.80) });
  }

  const escY = opciones.escalaY ?? R.f(0.55, 0.92);
  const escX = R.f(0.82, 1.18), escZ = R.f(0.82, 1.18);
  const cols = new Float32Array(n * 3);
  const p = new THREE.Vector3();
  // piedra clara: a 0,60 sobre un granito ya oscuro las piedritas del sotobosque
  // se leían como motas negras del mismo tamaño que una unidad
  const base = opciones.color || [0.92, 0.89, 0.84];
  for (let i = 0; i < n; i++) {
    p.fromBufferAttribute(pos, i);
    const fr = 1 + 0.34 * ruido.fbm(p.x * 1.5, p.z * 1.5 + p.y * 0.9, 4) + 0.16 * ruido.fbm(p.x * 4.1 + 7, p.y * 4.1, 3);
    p.multiplyScalar(fr);
    for (const pl of planos) {
      const dd = p.dot(pl.n) - pl.d;
      if (dd > 0) p.addScaledVector(pl.n, -dd * 0.94); // aplanado = fractura
    }
    p.x *= escX; p.y *= escY; p.z *= escZ;
    p.multiplyScalar(tamano);
    pos.setXYZ(i, p.x, p.y, p.z);

    // liquen en las grietas: cavidad ≈ radio local menor + orientación al cielo
    const rad = p.length() / tamano;
    const cav = clamp(1.35 - rad, 0, 1);
    const arriba = clamp(p.y / (tamano * escY) * 0.5 + 0.5, 0, 1);
    const veta = 0.5 + 0.5 * ruido.fbm(p.x * 2.6 + 31, p.z * 2.6 - 12, 3);
    const liq = clamp(cav * 1.4 * veta * (0.35 + arriba * 0.9) - 0.18, 0, 1) * (opciones.liquen ?? 1);
    // la cara de arriba pasa de 1: una roca al sol tiene que ser de lo más claro
    // del cuadro, no un gris medio más
    const ao = lerp(0.48, 1.14, smoothstep(-0.9, 0.4, p.y / (tamano * escY)));
    const tono = (0.86 + veta * 0.32) * ao;
    cols[i * 3] = lerp(base[0] * tono, 0.42, liq * 0.75);
    cols[i * 3 + 1] = lerp(base[1] * tono, 0.56, liq * 0.75);
    cols[i * 3 + 2] = lerp(base[2] * tono, 0.28, liq * 0.75);
  }
  g.setAttribute('color', new THREE.BufferAttribute(cols, 3));
  g.deleteAttribute('uv');
  g.setAttribute('uv', new THREE.Float32BufferAttribute(new Float32Array(n * 2), 2));
  g.computeVertexNormals(); // no indexado ⇒ normales por cara ⇒ facetas duras
  g.computeBoundingSphere();
  return g;
}

export function crearRoca(tamano = 1, rng, ctx) {
  const m = new THREE.Mesh(crearGeometriaRoca(tamano, rng), materialRoca(ctx));
  m.castShadow = true; m.receiveShadow = true;
  m.name = 'roca';
  return m;
}

/** Prisma extruido sobre una polilínea, con estratos horizontales. */
export function crearAcantilado(largo = 20, alto = 6, rng, ctx) {
  const R = adaptar(rng);
  const ruido = new Ruido((R.i(1, 1e6) ^ 0x51a3) >>> 0);
  const n = Math.max(3, Math.round(largo / 4.5));
  const eje = [];
  for (let i = 0; i <= n; i++) {
    const t = i / n;
    eje.push(new THREE.Vector3(lerp(-largo / 2, largo / 2, t), 0, ruido.fbm(t * 3.1, 0.5, 3) * largo * 0.09));
  }
  // perfil: [desplazamiento lateral, altura relativa]
  const perfil = [[1.0, 0.0], [1.12, 0.30], [0.92, 0.62], [0.55, 0.86], [0.0, 1.0]];
  const m = new Malla();
  const rect = { u0: 0, v0: 0, du: 1, dv: 1 };
  const filas = [[], []];
  const grosor = alto * 0.55;
  for (let lado = 0; lado < 2; lado++) {
    const s = lado === 0 ? 1 : -1;
    for (let i = 0; i <= n; i++) {
      const p = eje[i];
      const dir = (i < n ? eje[i + 1].clone().sub(p) : p.clone().sub(eje[i - 1])).normalize();
      const lat = new THREE.Vector3(-dir.z, 0, dir.x);
      const fila = [];
      for (let k = 0; k < perfil.length; k++) {
        const [off, hy] = perfil[k];
        const estrato = 0.10 * Math.sin(hy * 11.0) + 0.06 * ruido.fbm(p.x * 0.4 + hy * 6.0, p.z * 0.4, 3);
        const rr = grosor * off * (1 + estrato) + ruido.fbm(p.x * 0.9 + k * 3.7, p.z * 0.9 + lado * 11, 3) * grosor * 0.10;
        const y = alto * hy + ruido.fbm(p.x * 0.7, p.z * 0.7 + k, 2) * alto * 0.05;
        const banda = 0.80 + 0.30 * (0.5 + 0.5 * Math.sin(hy * 13.0 + ruido.simplex2(p.x * 0.2, 0) * 2));
        const ao = lerp(0.50, 1.18, smoothstep(0, 0.45, hy));
        const c = banda * ao;
        fila.push(m.v(p.x + lat.x * rr * s, y, p.z + lat.z * rr * s,
          lat.x * s, 0.25, lat.z * s,
          rect.u0 + (k / (perfil.length - 1)) * rect.du, rect.v0 + (i / n) * rect.dv,
          0.94 * c, 0.91 * c, 0.85 * c, 0, 0));
      }
      filas[lado].push(fila);
    }
  }
  for (let lado = 0; lado < 2; lado++) {
    for (let i = 0; i < n; i++) {
      for (let k = 0; k < perfil.length - 1; k++) {
        const A = filas[lado][i][k], B = filas[lado][i][k + 1];
        const C = filas[lado][i + 1][k + 1], D = filas[lado][i + 1][k];
        if (lado === 0) m.quad(A, B, C, D); else m.quad(A, D, C, B);
      }
    }
  }
  // costuras de las puntas
  for (let i = 0; i < n; i++) {
    const a = filas[0][i][perfil.length - 1], b = filas[1][i][perfil.length - 1];
    const c = filas[1][i + 1][perfil.length - 1], d = filas[0][i + 1][perfil.length - 1];
    m.quad(a, b, c, d);
  }
  const geo = m.geo();
  geo.computeVertexNormals();
  const malla = new THREE.Mesh(geo, materialRoca(ctx));
  malla.castShadow = true; malla.receiveShadow = true;
  malla.name = 'acantilado';
  return malla;
}

/* ═══════════════════════════ arbustos y pasto ═══════════════════════════ */

// Los multiplicadores subieron ~1,7x. Motivo textual de un jurado: las unidades
// "se confunden con las motas negras del suelo". Con los valores viejos el
// albedo de una mata quedaba en 0,06 de luma contra un suelo de 0,24 — o sea que
// el sotobosque no era vegetación, eran agujeros del tamaño de un soldado.
const ARBUSTOS = {
  baya: { tile: TILE.BAYA, col: [1.00, 1.28, 0.72], alto: [0.75, 1.15], cards: 12, forma: 'domo' },
  matorral: { tile: TILE.MATA, col: [1.00, 1.24, 0.62], alto: [0.6, 1.0], cards: 10, forma: 'domo' },
  helecho: { tile: TILE.FRONDA, col: [0.78, 1.18, 0.60], alto: [0.5, 0.85], cards: 7, forma: 'abanico' },
  seco: { tile: TILE.HOJA_SECA, col: [1.20, 0.98, 0.56], alto: [0.45, 0.8], cards: 8, forma: 'domo' },
  cactus: { tile: TILE.MATA, col: [0.72, 1.02, 0.58], alto: [0.9, 1.8], cards: 0, forma: 'cactus' },
};

const _ARRIBA_MATA = new THREE.Vector3(0, 1, 0);

/**
 * Una mata: cards en domo alrededor de (ox, oz) más una card horizontal arriba.
 *
 * La card de arriba es la que convierte la calcomanía en planta: es la única
 * superficie del sotobosque cuya normal mira al sol, así que es la que devuelve
 * un tono claro y le dibuja un "techo" al volumen. Sin ella, un arbusto es un
 * manojo de láminas verticales que de perfil se apagan todas juntas.
 */
function matita(m, R, cfg, rect, alto, ox, oz, nc) {
  const rad = alto * R.f(0.5, 0.82);
  for (let i = 0; i < nc; i++) {
    const a = R.f(0, Math.PI * 2);
    const t = R.f(0, 1);
    const rr = rad * (cfg.forma === 'abanico' ? 0.45 : Math.sqrt(1 - t * 0.8)) * R.f(0.42, 1.0);
    const c = new THREE.Vector3(ox + Math.cos(a) * rr, alto * (0.22 + t * 0.62), oz + Math.sin(a) * rr);
    // cuanto más alta va la card, más se acuesta hacia arriba: el domo se
    // ilumina como un cuerpo y no como un mazo de naipes clavados en la tierra
    const incl = 1 - t * 0.45;
    const sal = new THREE.Vector3(Math.cos(a) * incl, 0.48 + t * 0.95, Math.sin(a) * incl).normalize();
    const luz = lerp(0.52, 1.34, t);
    const s = alto * R.f(0.30, 0.54);
    cartasCruzadas(m, c, sal, s, s * 0.82, rect,
      [cfg.col[0] * luz, cfg.col[1] * luz, cfg.col[2] * luz], 0.55 + t * 0.45);
  }
  const s = rad * R.f(0.75, 1.0);
  carta(m, new THREE.Vector3(ox, alto * 0.94, oz), _ARRIBA_MATA, s, s, rect,
    [cfg.col[0] * 1.38, cfg.col[1] * 1.38, cfg.col[2] * 1.38], 0.9, 1.0);
}

export function crearGeometriaArbusto(tipo = 'matorral', rng, opciones = {}) {
  const cfg = ARBUSTOS[tipo] || ARBUSTOS.matorral;
  const R = adaptar(rng);
  const m = new Malla();
  const rect = rectTile(cfg.tile);
  const alto = opciones.alto ?? R.f(cfg.alto[0], cfg.alto[1]);
  if (cfg.forma === 'cactus') {
    const rectC = rectTile(TILE.CORTEZA_RUGOSA);
    const col = [0.52, 0.76, 0.46];
    const brazos = R.i(0, 2);
    const cuerpo = [], rads = [];
    for (let s = 0; s <= 4; s++) {
      cuerpo.push(new THREE.Vector3(0, alto * (s / 4), 0));
      rads.push(alto * 0.13 * (1 - Math.pow(s / 4, 3) * 0.4));
    }
    tubo(m, cuerpo, rads, 7, rectC, (t, a) => {
      const k = (0.78 + 0.32 * Math.cos(a * 3.5)) * lerp(0.8, 1.05, t);
      return [col[0] * k, col[1] * k, col[2] * k];
    }, (t) => t * 0.06, false);
    for (let b = 0; b < brazos; b++) {
      const a = R.f(0, Math.PI * 2), y = alto * R.f(0.3, 0.55), l = alto * R.f(0.28, 0.45);
      const br = [], rr = [];
      for (let s = 0; s <= 4; s++) {
        const t = s / 4;
        br.push(new THREE.Vector3(Math.cos(a) * l * Math.sin(t * 1.5), y + l * t * 1.1, Math.sin(a) * l * Math.sin(t * 1.5)));
        rr.push(alto * 0.075 * (1 - t * 0.25));
      }
      tubo(m, br, rr, 6, rectC, (t, aa) => {
        const k = (0.78 + 0.32 * Math.cos(aa * 3.5));
        return [col[0] * k, col[1] * k, col[2] * k];
      }, (t) => 0.02 + t * 0.06, false);
    }
  } else {
    // MANCHÓN, no confeti. El sembrador (Foliaje.js) reparte las instancias con
    // una uniforme por celda y no es archivo mío, así que la única palanca desde
    // acá para romper el reparto parejo es que cada instancia YA sea un grupo:
    // una mata grande y una o dos satélites bastante más chicas, apiñadas dentro
    // de ~1,5 alturas. Resultado en pantalla: matorral apelmazado con claros de
    // suelo entre grupo y grupo, en vez de motas equidistantes del mismo tamaño.
    const detalle = opciones.detalle ?? 1;
    const grupos = opciones.grupos ?? R.i(2, 3);
    // el total de cards sube sólo 1,4x respecto de la mata suelta anterior: el
    // manchón se consigue repartiendo, no gastando más triángulos
    const total = Math.max(5, Math.round(cfg.cards * detalle * 1.4));
    const radioGrupo = alto * 1.5;
    let restantes = total;
    for (let gi = 0; gi < grupos; gi++) {
      const principal = gi === 0;
      const ultimo = gi === grupos - 1;
      const nc = ultimo ? restantes : Math.max(2, Math.round(total * (principal ? 0.52 : 0.26)));
      restantes -= nc;
      if (nc <= 0) continue;
      // escalas MUY dispares a propósito: si todas las matas miden lo mismo
      // vuelven a leerse como puntitos de un patrón
      const esc = principal ? 1 : R.f(0.36, 0.74);
      const ang = R.f(0, Math.PI * 2);
      const dist = principal ? 0 : radioGrupo * R.f(0.45, 1.0);
      matita(m, R, cfg, rect, alto * esc, Math.cos(ang) * dist, Math.sin(ang) * dist, nc);
    }
  }
  const g = m.geo();
  if (g) g.userData = { alto };
  return g;
}

export function crearArbusto(tipo, rng, ctx) {
  const geo = crearGeometriaArbusto(tipo, rng, {});
  const g = new THREE.Group();
  g.name = `arbusto_${tipo}`;
  if (geo) {
    const malla = new THREE.Mesh(geo, materialFoliaje(ctx, 'mata', {
      amplitud: 0.09, velocidad: 1.9, flameo: 0.03, banda: [-2, -1, 96, 112], alphaTest: 0.42,
    }));
    malla.castShadow = true; malla.receiveShadow = true;
    g.add(malla);
    g.userData = { alto: geo.userData?.alto ?? 1 };
  }
  return g;
}

/** Mata de pasto: 3 quads cruzados. Determinista por `variante` (no lleva rng). */
export function crearGeometriaPasto(variante = 0) {
  const r = mulberry32(0x9e37 + (variante | 0) * 7919);
  const m = new Malla();
  const rect = rectTile((variante | 0) % 4 === 3 ? TILE.FLOR : TILE.PASTO);
  const alto = 0.34 + r() * 0.30;
  const ancho = 0.30 + r() * 0.22;
  const base = [0.86, 0.94, 0.78];
  for (let q = 0; q < 3; q++) {
    const a = (q / 3) * Math.PI + r() * 0.4;
    const dx = Math.cos(a), dz = Math.sin(a);
    const inc = (r() - 0.5) * 0.24; // ninguna brizna perfectamente vertical
    const h = alto * (0.78 + r() * 0.45);
    const w = ancho * (0.8 + r() * 0.4);
    const idx = [];
    for (let k = 0; k < 4; k++) {
      const su = (k === 1 || k === 2) ? 1 : -1;
      const sv = (k >= 2) ? 1 : 0;
      const estrecha = sv ? 0.62 : 1.0; // trapecio: la punta afina
      const px = dx * su * w * estrecha + inc * sv * h;
      const pz = dz * su * w * estrecha + inc * sv * h * 0.6;
      const py = sv * h;
      const luz = sv ? 1.16 : 0.62;
      idx.push(m.v(px, py, pz, -dz * 0.35, 0.92, dx * 0.35,
        rect.u0 + (su > 0 ? rect.du : 0), rect.v0 + (sv ? rect.dv : 0),
        base[0] * luz, base[1] * luz, base[2] * luz, 1, sv ? 1.0 : 0.06));
    }
    m.quad(idx[0], idx[1], idx[2], idx[3]);
  }
  return m.geo();
}

/* ═════════════════ decorados menores (piedritas, troncos, flores) ═════════════════ */

export function crearGeometriaPiedrita(variante = 0) {
  const rng = mulberry32(0x51e2 + variante * 5147);
  return crearGeometriaRoca(1, rng, { subdiv: 1, escalaY: 0.45 + rng() * 0.3, liquen: 0.6 });
}

export function crearGeometriaTroncoCaido(variante = 0) {
  const r = mulberry32(0x7a11 + variante * 3313);
  const R = adaptar(r);
  const ruido = new Ruido(0x7a11 + variante);
  const m = new Malla();
  const rect = rectTile(TILE.CORTEZA_RUGOSA);
  const largo = 2.6 + r() * 2.8, rad = 0.22 + r() * 0.16;
  const pts = [], rads = [];
  const dir = new THREE.Vector3(1, 0, 0.1 * (r() - 0.5)).normalize();
  for (let s = 0; s <= 4; s++) {
    const t = s / 4;
    pts.push(new THREE.Vector3(dir.x * largo * t, rad * (0.9 + 0.12 * Math.sin(t * 5)), dir.z * largo * t));
    rads.push(rad * (1 - t * 0.35));
  }
  const col = [0.62, 0.50, 0.38];
  tubo(m, pts, rads, 7, rect, (t, a) => {
    const musgo = clamp(ruido.fbm(t * 5, a, 3) * 0.6 + 0.35, 0, 1) * clamp(Math.sin(a) * 0.5 + 0.5, 0, 1);
    const k = 0.78 + 0.3 * Math.cos(a - 0.9);
    return [lerp(col[0] * k, 0.42, musgo), lerp(col[1] * k, 0.58, musgo), lerp(col[2] * k, 0.28, musgo)];
  }, () => 0, false);
  // muñones de ramas cortadas
  for (let i = 0; i < 3; i++) {
    const t = R.f(0.2, 0.85), a = R.f(0, Math.PI * 2);
    const p = new THREE.Vector3(dir.x * largo * t, rad, dir.z * largo * t);
    const d2 = new THREE.Vector3(Math.cos(a) * 0.5, 0.8, Math.sin(a) * 0.5).normalize();
    const pp = [p, p.clone().addScaledVector(d2, 0.35 + R.f(0, 0.3))];
    tubo(m, pp, [rad * 0.34, rad * 0.2], 5, rect, () => [col[0] * 0.8, col[1] * 0.8, col[2] * 0.8], () => 0.03, false);
  }
  return m.geo();
}

export function crearGeometriaTocon(variante = 0) {
  const r = mulberry32(0x30c0 + variante * 977);
  const m = new Malla();
  const rect = rectTile(TILE.CORTEZA_RUGOSA);
  const alto = 0.45 + r() * 0.3, rad = 0.34 + r() * 0.14;
  const pts = [new THREE.Vector3(0, 0, 0), new THREE.Vector3(0, alto * 0.6, 0), new THREE.Vector3(0, alto, 0)];
  tubo(m, pts, [rad * 1.5, rad * 1.05, rad], 8, rect, (t, a) => {
    const k = (0.76 + 0.3 * Math.cos(a - 0.8)) * lerp(0.7, 1, t);
    // la cara del corte va clara: se lee como madera fresca
    return t > 0.96 ? [1.06, 0.88, 0.60] : [0.64 * k, 0.50 * k, 0.37 * k];
  }, () => 0, true);
  return m.geo();
}

export function crearGeometriaFlor(variante = 0) {
  const r = mulberry32(0xf10a + variante * 4111);
  const R = adaptar(r);
  const m = new Malla();
  const rect = rectTile(TILE.FLOR);
  // Cada instancia es un manojo de tres matitas de alturas muy distintas dentro
  // de ~0,8 m, con las cards inclinadas hacia arriba para que tengan cara al sol.
  //
  // EL TINTE BAJÓ de 1,34–1,52 a ~1,0. Iba por encima de 1 para meterle altas
  // luces al suelo abierto, pero el efecto en pantalla fue el contrario del
  // buscado: al ser lo más CLARO del piso y estar sembrado por todos lados, el
  // manojo de flores se convirtió en la mota crema que los doce votos leyeron
  // como confeti. La alta luz la ponen los pétalos del tile, que ya van casi a
  // blanco; el follaje de la mata tiene que valer lo mismo que el pasto vecino,
  // si no se lee como una calcomanía pegada encima del suelo.
  const base = 0.26 + r() * 0.20;
  const tintes = [[1.02, 1.06, 0.92], [0.86, 0.92, 0.80], [1.14, 1.16, 1.00]];
  for (let i = 0; i < 3; i++) {
    const alto = base * (i === 0 ? 1 : R.f(0.42, 0.82));
    const ang = R.f(0, Math.PI * 2);
    const dist = i === 0 ? 0 : base * R.f(1.1, 2.2);
    const ox = Math.cos(ang) * dist, oz = Math.sin(ang) * dist;
    for (let q = 0; q < 2; q++) {
      const a = q * Math.PI * 0.5 + R.f(0, 0.6);
      const c = new THREE.Vector3(ox, alto * 0.52, oz);
      // 0.34 de componente vertical: la card se acuesta lo justo para captar sol
      const sal = new THREE.Vector3(Math.cos(a), 0.34, Math.sin(a)).normalize();
      carta(m, c, sal, alto * 0.52, alto * 0.5, rect, tintes[i], 0.9);
    }
  }
  return m.geo();
}

export function crearGeometriaMata(variante = 0) {
  const r = mulberry32(0x3a7a + variante * 8093);
  return crearGeometriaArbusto(variante % 2 ? 'helecho' : 'matorral', r, { alto: 0.35 + r() * 0.35, detalle: 0.55 });
}

/** Cruz de billboards (2 quads) para el LOD lejano. Alto 1, ancho `aspecto`. */
export function geometriaBillboardCruz(aspecto = 0.72) {
  const g = new THREE.BufferGeometry();
  const w = aspecto * 0.5;
  const pos = [], uv = [], nor = [], idx = [], col = [], hoja = [], vie = [];
  for (let q = 0; q < 2; q++) {
    const dx = q === 0 ? 1 : 0, dz = q === 0 ? 0 : 1;
    const nx = q === 0 ? 0 : 1, nz = q === 0 ? 1 : 0;
    const b = pos.length / 3;
    for (let k = 0; k < 4; k++) {
      const su = (k === 1 || k === 2) ? 1 : -1;
      const sv = (k >= 2) ? 1 : 0;
      pos.push(dx * su * w, sv, dz * su * w);
      uv.push(su > 0 ? 1 : 0, sv);
      // normal mezclada hacia arriba: el billboard responde al sol sin apagarse de perfil
      const n = new THREE.Vector3(nx * su * 0.5, 0.85, nz * su * 0.5).normalize();
      nor.push(n.x, n.y, n.z);
      col.push(1, 1, 1);
      hoja.push(1);
      vie.push(sv ? 0.5 : 0.05);
    }
    idx.push(b, b + 1, b + 2, b, b + 2, b + 3);
  }
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute('normal', new THREE.Float32BufferAttribute(nor, 3));
  g.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2));
  g.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
  g.setAttribute('aHoja', new THREE.Float32BufferAttribute(hoja, 1));
  g.setAttribute('aViento', new THREE.Float32BufferAttribute(vie, 1));
  g.setIndex(idx);
  g.computeBoundingSphere();
  return g;
}

/* ══════════════════════════════════════════════════════════════════════════
 * NODOS DE RECURSO Y FAUNA
 *
 * `VistaEntidades` los pide para toda entidad de TIPO.RECURSO con este patrón:
 *     crearNodo(clave, rng, ctx) ?? crearAnimal(clave, rng, ctx) ?? crearArbol(...)
 * de modo que cada función DEBE devolver null para las claves que no le tocan:
 * si devolviera un objeto vacío cortaría la cadena y el siguiente candidato
 * nunca correría.
 *
 * Escala: el juego usa escala de JUEGO, no de mundo (un colono equivale a ~3,5 m).
 * Un ciervo realista de 1,4 m a la cruz sería un punto al lado; acá va a ~2,6 m.
 * ══════════════════════════════════════════════════════════════════════════ */

const _matNodo = new Map();

/** Materiales compartidos por clave. Nunca se crean por instancia. */
function matNodo(clave, ctx, def) {
  if (_matNodo.has(clave)) return _matNodo.get(clave);
  const m = new THREE.MeshStandardMaterial({
    color: def.color, roughness: def.rug ?? 0.85, metalness: def.met ?? 0,
    emissive: def.emisivo ?? 0x000000, emissiveIntensity: def.emisivoInt ?? 0,
    flatShading: !!def.facetado, side: def.doble ? THREE.DoubleSide : THREE.FrontSide,
  });
  m.name = `nodo_${clave}`;
  ctx?.sombras?.registrarMaterial?.(m);
  _matNodo.set(clave, m);
  return m;
}

/** Elipsoide facetado: la primitiva de todo cuerpo animal. */
function _bulto(rx, ry, rz, subdiv = 1) {
  const g = new THREE.IcosahedronGeometry(1, subdiv);
  g.scale(rx, ry, rz);
  return g;
}

/** Cono truncado a lo largo de Y, útil para patas, cuellos y cuernos. */
function _tronco(r0, r1, h, seg = 6) {
  const g = new THREE.CylinderGeometry(r1, r0, h, seg, 1);
  g.translate(0, h * 0.5, 0);
  return g;
}

/**
 * Cuadrúpedo paramétrico. Devuelve las partes por separado porque la animación
 * necesita rotarlas: fusionarlas acá ahorraría llamadas de dibujo pero mataría
 * el paso, y un ciervo quieto como estatua se nota más que una llamada de más.
 */
function _cuadrupedo(p, mat, matSec) {
  const g = new THREE.Group();
  const cuerpo = new THREE.Mesh(_bulto(p.largo * 0.5, p.alto * 0.42, p.ancho * 0.5, 2), mat);
  cuerpo.position.set(0, p.patas + p.alto * 0.42, 0);
  cuerpo.scale.set(1, 1, 1);
  g.add(cuerpo);

  // la cruz: el lomo no es plano, y en el jabalí es lo que define la silueta
  if (p.joroba > 0) {
    const j = new THREE.Mesh(_bulto(p.largo * 0.20, p.joroba, p.ancho * 0.42, 1), mat);
    j.position.set(p.largo * 0.18, p.patas + p.alto * 0.66, 0);
    g.add(j);
  }

  const cuello = new THREE.Mesh(_tronco(p.ancho * 0.30, p.ancho * 0.20, p.cuello, 6), mat);
  cuello.position.set(p.largo * 0.40, p.patas + p.alto * 0.52, 0);
  cuello.rotation.z = -p.anguloCuello;
  g.add(cuello);

  const cabeza = new THREE.Group();
  const craneo = new THREE.Mesh(_bulto(p.hocico * 0.55, p.ancho * 0.22, p.ancho * 0.22, 1), mat);
  craneo.position.x = p.hocico * 0.35;
  cabeza.add(craneo);
  cabeza.position.set(0, p.cuello, 0);
  cuello.add(cabeza);

  // orejas: dos triangulitos que a 80 m son lo único que dice "animal" y no "roca"
  for (const s of [-1, 1]) {
    const o = new THREE.Mesh(_bulto(p.ancho * 0.05, p.ancho * 0.16, p.ancho * 0.09, 0), mat);
    o.position.set(-p.hocico * 0.05, p.ancho * 0.16, s * p.ancho * 0.17);
    o.rotation.x = s * 0.5;
    cabeza.add(o);
  }

  if (p.cuernos) {
    // La cornamenta iba en el material claro de las pezuñas y salía finita:
    // a distancia de juego se leía como dos plumas blancas clavadas de costado.
    // Va en su propio material óseo, más gruesa, y abriéndose hacia ARRIBA y
    // hacia atrás, que es lo que hace la silueta reconocible de un ciervo.
    const matAsta = matNodo('asta', null, { color: 0x6b563a, rug: 0.86, facetado: true });
    for (const s of [-1, 1]) {
      const asta = new THREE.Group();
      asta.add(new THREE.Mesh(_tronco(0.085, 0.055, p.cuernos * 0.70, 5), matAsta));
      for (let i = 0; i < 3; i++) {
        const punta = new THREE.Mesh(_tronco(0.055, 0.018, p.cuernos * (0.42 - i * 0.08), 4), matAsta);
        punta.position.set(0, p.cuernos * (0.22 + i * 0.18), 0);
        punta.rotation.z = -0.62 - i * 0.16;   // las puntas barren hacia adelante
        asta.add(punta);
      }
      asta.position.set(-p.hocico * 0.08, p.ancho * 0.19, s * p.ancho * 0.12);
      asta.rotation.x = s * 0.46;              // abre en V vista de frente
      asta.rotation.z = 0.18;                  // e inclina hacia atrás
      cabeza.add(asta);
    }
  }

  if (p.colmillos) {
    for (const s of [-1, 1]) {
      const c = new THREE.Mesh(_tronco(0.028, 0.006, p.hocico * 0.42, 4), matSec);
      c.position.set(p.hocico * 0.62, -p.ancho * 0.04, s * p.ancho * 0.11);
      c.rotation.z = 1.25; c.rotation.x = s * 0.3;
      cabeza.add(c);
    }
  }

  // Las patas se arman con geometría que YA crece hacia abajo (se rota la
  // geometría una vez, no el objeto). Encadenar dos rotaciones de PI sobre los
  // objetos, como estaba antes, mandaba la caña de vuelta hacia arriba y dejaba
  // la pezuña flotando por encima del cuerpo: cuatro patas sueltas en el aire.
  const patas = [];
  const dx = p.largo * 0.34, dz = p.ancho * 0.34;
  const lMuslo = p.patas * 0.56, lCaña = p.patas * 0.48;
  const gMuslo = _tronco(p.ancho * 0.15, p.ancho * 0.095, lMuslo, 6); gMuslo.rotateX(Math.PI);
  const gCaña = _tronco(p.ancho * 0.095, p.ancho * 0.055, lCaña, 5); gCaña.rotateX(Math.PI);
  const gPezuña = _bulto(p.ancho * 0.085, p.ancho * 0.055, p.ancho * 0.075, 0);
  for (const [sx, sz] of [[1, -1], [1, 1], [-1, -1], [-1, 1]]) {
    const pata = new THREE.Group();
    pata.position.set(sx * dx, p.patas, sz * dz);
    pata.add(new THREE.Mesh(gMuslo, mat));
    const rodilla = new THREE.Group();
    rodilla.position.y = -lMuslo;
    rodilla.add(new THREE.Mesh(gCaña, mat));
    const pezuña = new THREE.Mesh(gPezuña, matSec);
    pezuña.position.y = -lCaña;
    rodilla.add(pezuña);
    pata.add(rodilla);
    // las traseras quiebran la rodilla hacia atrás: es lo que da la grupa alta
    rodilla.rotation.x = sx < 0 ? -0.34 : 0.12;
    pata.rotation.x = sx < 0 ? 0.22 : -0.08;
    g.add(pata);
    patas.push(pata);
  }

  const cola = new THREE.Mesh(_tronco(p.ancho * 0.07, p.ancho * 0.02, p.cola, 4), mat);
  cola.position.set(-p.largo * 0.46, p.patas + p.alto * 0.44, 0);
  cola.rotation.z = 1.9;
  g.add(cola);

  g.traverse((o) => { if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; } });
  // el reposo de cada pata se guarda: la animación oscila ALREDEDOR de él, si no
  // el ciclo de trote borra el quiebre de rodilla y el animal camina en cuclillas
  const reposo = patas.map((q) => q.rotation.x);
  return { grupo: g, cuerpo, cuello, cabeza, patas, cola, reposo };
}

const _PERFIL_ANIMAL = {
  ciervo: {
    largo: 2.05, alto: 1.15, ancho: 0.86, patas: 1.35, cuello: 0.86, anguloCuello: 0.55,
    hocico: 0.52, cola: 0.30, joroba: 0, cuernos: 0.80, colmillos: false,
    color: 0x8a6236, colorSec: 0xd8cbb2, altura: 2.6,
  },
  jabali: {
    largo: 1.85, alto: 1.02, ancho: 0.92, patas: 0.78, cuello: 0.38, anguloCuello: 1.05,
    hocico: 0.68, cola: 0.22, joroba: 0.30, cuernos: 0, colmillos: true,
    color: 0x4a3d33, colorSec: 0xd6cdb8, altura: 1.9,
  },
};

/**
 * Fauna cazable. `animar(fase, estado, dt)` sigue la misma firma que
 * `UnidadFabrica.crearMallaUnidad`, así `VistaEntidades` los mueve con el
 * mismo código que a las unidades.
 */
export function crearAnimal(clave, rng, ctx) {
  const p = _PERFIL_ANIMAL[clave];
  if (!p) return null;
  const R = adaptar(rng);

  const mat = matNodo(`${clave}_cuerpo`, ctx, { color: p.color, rug: 0.92, facetado: true });
  const matSec = matNodo(`${clave}_duro`, ctx, { color: p.colorSec, rug: 0.72, facetado: true });
  const partes = _cuadrupedo(p, mat, matSec);

  // variación por individuo: sin esto una manada son cuatro calcos
  const s = R.f(0.90, 1.12);
  partes.grupo.scale.setScalar(s);
  partes.grupo.rotation.y = R.f(0, Math.PI * 2);

  const faseProp = R.f(0, Math.PI * 2);
  let pastando = R.f(0, 1);

  return {
    grupo: partes.grupo,
    partes,
    altura: p.altura * s,
    animar(fase, estado, dt) {
      const t = fase + faseProp;
      if (estado === 1 || estado === 5) {
        // trote: diagonales opuestas en contrafase, cadera que rebota al doble
        for (let i = 0; i < 4; i++) {
          const diag = (i === 0 || i === 3) ? 0 : Math.PI;
          partes.patas[i].rotation.x = partes.reposo[i] + Math.sin(t * 2 + diag) * 0.62;
        }
        partes.grupo.position.y = Math.abs(Math.sin(t * 2)) * 0.09 * s;
        partes.cuello.rotation.z = -p.anguloCuello + Math.sin(t * 2) * 0.10;
        partes.cola.rotation.z = 1.9 + Math.sin(t * 3) * 0.25;
        pastando = 0;
      } else if (estado === 6) {
        partes.grupo.rotation.z = Math.min(Math.PI * 0.5, (partes.grupo.rotation.z || 0) + dt * 2.4);
      } else {
        // pastoreo: baja la cabeza, mastica, la levanta a mirar, repite
        pastando += dt * 0.32;
        const ciclo = (Math.sin(pastando) + 1) * 0.5;
        partes.cuello.rotation.z = -p.anguloCuello - ciclo * 0.92;
        partes.cabeza.rotation.z = ciclo * 0.35 + Math.sin(t * 6) * 0.04 * ciclo;
        for (let i = 0; i < 4; i++) partes.patas[i].rotation.x = partes.reposo[i];
        partes.grupo.position.y = 0;
        partes.cola.rotation.z = 1.9 + Math.sin(t * 1.6) * 0.16;
      }
    },
    setColorJugador() {},
    dispose() {
      partes.grupo.traverse((o) => { if (o.isMesh) o.geometry.dispose(); });
    },
  };
}

/* ─────────────────────────── nodos cosechables ─────────────────────────── */

/** Afloramiento rocoso con mineral incrustado. Base común de vetas y filones. */
function _afloramiento(R, ctx, opciones) {
  const g = new THREE.Group();
  const matPiedra = matNodo(opciones.clavePiedra, ctx, { color: opciones.piedra, rug: 0.95, facetado: true });
  const matVeta = matNodo(opciones.claveVeta, ctx, {
    color: opciones.mineral, rug: opciones.rugMineral ?? 0.30, met: opciones.metMineral ?? 0.75,
    emisivo: opciones.emisivo ?? 0x000000, emisivoInt: opciones.emisivoInt ?? 0, facetado: true,
  });

  // tres bloques de piedra desiguales: uno solo se lee como una pelota
  const bloques = [];
  for (let i = 0; i < 3; i++) {
    const e = R.f(0.62, 1.0) * (i === 0 ? 1.25 : 0.8);
    const geo = crearGeometriaRoca(e * opciones.escala, rngDe(R), { subdiv: 1, rugosidad: 1.1 });
    const m = new THREE.Mesh(geo, matPiedra);
    const a = R.f(0, Math.PI * 2), r = i === 0 ? 0 : R.f(0.5, 0.95) * opciones.escala;
    m.position.set(Math.cos(a) * r, R.f(-0.1, 0.12) * opciones.escala, Math.sin(a) * r);
    m.rotation.set(R.f(0, 0.4), R.f(0, 6.28), R.f(0, 0.4));
    g.add(m); bloques.push(m);
  }

  // cristales asomando: son la señal de "esto se puede minar"
  const n = opciones.cristales ?? 7;
  for (let i = 0; i < n; i++) {
    const h = R.f(0.22, 0.52) * opciones.escala;
    const geo = new THREE.OctahedronGeometry(h * 0.42, 0);
    geo.scale(1, 1.9, 1);
    const c = new THREE.Mesh(geo, matVeta);
    const b = bloques[R.i(0, bloques.length - 1)];
    const a = R.f(0, Math.PI * 2), r = R.f(0.15, 0.62) * opciones.escala;
    c.position.set(b.position.x + Math.cos(a) * r, b.position.y + R.f(0.25, 0.62) * opciones.escala, b.position.z + Math.sin(a) * r);
    c.rotation.set(R.f(-0.5, 0.5), R.f(0, 6.28), R.f(-0.5, 0.5));
    g.add(c);
  }

  g.traverse((o) => { if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; } });
  return g;
}

/** Envuelve el adaptador en algo que `crearGeometriaRoca` acepte como rng. */
function rngDe(R) {
  return { float: (a, b) => R.f(a, b), int: (a, b) => R.i(a, b), pick: (arr) => R.p(arr), bool: (p) => R.b(p) };
}

/**
 * Nodos de recurso del mapa. Devuelve null si la clave no es de las suyas para
 * que `VistaEntidades` siga probando con `crearAnimal` y `crearArbol`.
 */
export function crearNodo(clave, rng, ctx) {
  const R = adaptar(rng);

  if (clave === 'arbol_pino' || clave === 'arbol_roble' || clave === 'arbol_palmera') {
    const tipo = clave === 'arbol_pino' ? 'pino' : clave === 'arbol_roble' ? 'roble' : 'palmera';
    return crearArbol(tipo, rng, ctx);
  }

  if (clave === 'baya') {
    const g = new THREE.Group();
    const matHoja = matNodo('baya_hoja', ctx, { color: 0x3f6b2c, rug: 0.9, doble: true, facetado: true });
    const matFruto = matNodo('baya_fruto', ctx, { color: 0xb51f28, rug: 0.42 });
    for (let i = 0; i < 5; i++) {
      const r = R.f(0.36, 0.62);
      const m = new THREE.Mesh(_bulto(r, r * 0.72, r, 1), matHoja);
      const a = R.f(0, 6.28), d = R.f(0, 0.42);
      m.position.set(Math.cos(a) * d, r * 0.62 + R.f(0, 0.12), Math.sin(a) * d);
      g.add(m);
    }
    // los racimos van ARRIBA y bien saturados: a distancia de juego el rojo es
    // lo único que distingue un arbusto de comida de una mata cualquiera
    for (let i = 0; i < 16; i++) {
      const b = new THREE.Mesh(new THREE.IcosahedronGeometry(R.f(0.055, 0.085), 0), matFruto);
      const a = R.f(0, 6.28), d = R.f(0.06, 0.52);
      b.position.set(Math.cos(a) * d, R.f(0.42, 0.92), Math.sin(a) * d);
      g.add(b);
    }
    g.rotation.y = R.f(0, 6.28);
    g.traverse((o) => { if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; } });
    return { grupo: g, altura: 1.0 };
  }

  if (clave === 'veta_oro') {
    return {
      grupo: _afloramiento(R, ctx, {
        clavePiedra: 'veta_piedra', claveVeta: 'veta_oro_mineral', escala: 1.15,
        piedra: 0x6d6559, mineral: 0xd8a326, rugMineral: 0.24, metMineral: 0.85,
        emisivo: 0x3a2400, emisivoInt: 0.28, cristales: 9,
      }),
      altura: 1.5,
    };
  }

  if (clave === 'carbon') {
    return {
      grupo: _afloramiento(R, ctx, {
        clavePiedra: 'carbon_piedra', claveVeta: 'carbon_mineral', escala: 1.2,
        piedra: 0x4b4a48, mineral: 0x141416, rugMineral: 0.16, metMineral: 0.25, cristales: 8,
      }),
      altura: 1.5,
    };
  }

  if (clave === 'pozo_petroleo') {
    const g = new THREE.Group();
    const matAcero = matNodo('pozo_acero', ctx, { color: 0x6a5a4a, rug: 0.72, met: 0.55, facetado: true });
    const matCrudo = matNodo('pozo_crudo', ctx, { color: 0x0d0b0a, rug: 0.18, met: 0.1 });

    // torre de celosía: cuatro montantes que convergen, con travesaños
    const alto = 4.6, base = 0.95, top = 0.30;
    for (const [sx, sz] of [[1, 1], [1, -1], [-1, 1], [-1, -1]]) {
      const p = new THREE.Mesh(_tronco(0.075, 0.05, alto, 4), matAcero);
      p.position.set(sx * base, 0, sz * base);
      p.lookAt(sx * top, alto, sz * top);
      p.rotateX(Math.PI * 0.5);
      g.add(p);
    }
    for (let i = 1; i <= 4; i++) {
      const y = (i / 5) * alto, e = base + (top - base) * (y / alto);
      const anillo = new THREE.Mesh(new THREE.TorusGeometry(e * 1.35, 0.035, 4, 4), matAcero);
      anillo.rotation.x = Math.PI * 0.5; anillo.position.y = y;
      g.add(anillo);
    }
    // balancín: el elemento que dice "petróleo" de un vistazo
    const viga = new THREE.Mesh(new THREE.BoxGeometry(3.2, 0.24, 0.30), matAcero);
    viga.position.set(0.4, alto * 0.62, 0);
    g.add(viga);
    const contrapeso = new THREE.Mesh(new THREE.CylinderGeometry(0.42, 0.42, 0.26, 8), matAcero);
    contrapeso.rotation.z = Math.PI * 0.5;
    contrapeso.position.set(-1.5, 0, 0);
    viga.add(contrapeso);

    const charco = new THREE.Mesh(new THREE.CircleGeometry(1.85, 16), matCrudo);
    charco.rotation.x = -Math.PI * 0.5; charco.position.y = 0.03;
    g.add(charco);
    for (let i = 0; i < 4; i++) {
      const b = new THREE.Mesh(new THREE.CylinderGeometry(0.28, 0.28, 0.68, 8), matAcero);
      const a = R.f(0, 6.28);
      b.position.set(Math.cos(a) * R.f(1.9, 2.5), 0.34, Math.sin(a) * R.f(1.9, 2.5));
      b.rotation.z = R.b(0.3) ? Math.PI * 0.5 : 0;
      g.add(b);
    }
    g.rotation.y = R.f(0, 6.28);
    g.traverse((o) => { if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; } });

    const balanceo = { viga };
    return {
      grupo: g, altura: alto,
      animar(fase) { balanceo.viga.rotation.z = Math.sin(fase * 0.8) * 0.22; },
    };
  }

  if (clave === 'reliquia') {
    const g = new THREE.Group();
    const matPiedra = matNodo('rel_piedra', ctx, { color: 0x8d8577, rug: 0.88, facetado: true });
    const matOro = matNodo('rel_oro', ctx, {
      color: 0xe8bd4a, rug: 0.22, met: 0.9, emisivo: 0x6a4a08, emisivoInt: 0.9,
    });
    const pedestal = new THREE.Mesh(new THREE.CylinderGeometry(0.62, 0.82, 0.72, 8), matPiedra);
    pedestal.position.y = 0.36;
    g.add(pedestal);
    const placa = new THREE.Mesh(new THREE.BoxGeometry(0.72, 0.96, 0.08), matOro);
    placa.position.y = 1.55;
    g.add(placa);
    // halo: el anillo es lo que la hace leer como "objetivo" y no como decorado
    const halo = new THREE.Mesh(new THREE.TorusGeometry(0.62, 0.045, 6, 20), matOro);
    halo.position.y = 1.55; halo.rotation.x = Math.PI * 0.5;
    g.add(halo);
    g.traverse((o) => { if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; } });
    return {
      grupo: g, altura: 2.1,
      animar(fase) { placa.rotation.y = fase * 0.4; halo.rotation.z = -fase * 0.6; placa.position.y = 1.55 + Math.sin(fase) * 0.07; },
    };
  }

  if (clave === 'pez') {
    // no se modela el pez: se modela la SEÑAL en el agua, que es lo que se ve
    // desde la cámara de juego a través de la superficie
    const g = new THREE.Group();
    const matSombra = matNodo('pez_sombra', ctx, { color: 0x102a2e, rug: 1, doble: true });
    matSombra.transparent = true; matSombra.opacity = 0.62; matSombra.depthWrite = false;
    const matAleta = matNodo('pez_aleta', ctx, { color: 0x5b7d84, rug: 0.55, doble: true });
    const bancos = [];
    for (let i = 0; i < 9; i++) {
      const geo = _bulto(R.f(0.28, 0.46), 0.02, R.f(0.09, 0.15), 0);
      const m = new THREE.Mesh(geo, matSombra);
      const a = R.f(0, 6.28), d = R.f(0.2, 1.3);
      m.position.set(Math.cos(a) * d, 0.04, Math.sin(a) * d);
      m.rotation.y = R.f(0, 6.28);
      g.add(m);
      bancos.push({ m, a: R.f(0, 6.28), v: R.f(0.4, 0.9), r: d });
      if (i % 3 === 0) {
        const al = new THREE.Mesh(_bulto(0.10, 0.13, 0.02, 0), matAleta);
        al.position.set(0, 0.1, 0);
        m.add(al);
      }
    }
    return {
      grupo: g, altura: 0.2,
      animar(fase) {
        for (const b of bancos) {
          const t = fase * b.v + b.a;
          b.m.position.x = Math.cos(t) * b.r;
          b.m.position.z = Math.sin(t) * b.r;
          b.m.rotation.y = -t + Math.PI * 0.5;
        }
      },
    };
  }

  return null;
}

/**
 * Versión estática y fusionada, para instanciar a distancia. Se cachea por clave
 * porque `VistaEntidades` la pide una vez por tipo, no por entidad.
 */
const _geoNodoCache = new Map();
export function geometriaFusionadaNodo(clave, ctx) {
  if (_geoNodoCache.has(clave)) return _geoNodoCache.get(clave);
  const api = crearNodo(clave, ctx?.rng, ctx) ?? crearAnimal(clave, ctx?.rng, ctx);
  const grupo = api?.grupo ?? (api?.isObject3D ? api : null);
  if (!grupo) { _geoNodoCache.set(clave, null); return null; }

  grupo.updateMatrixWorld(true);
  const partes = [];
  grupo.traverse((o) => {
    if (!o.isMesh || !o.geometry) return;
    // mergeGeometries exige que TODAS traigan índice o NINGUNA. Los poliedros
    // de three (Icosahedron, Octahedron) salen sin índice y los de revolución
    // (Cylinder, Torus, Circle) con índice, así que hay que uniformar o la
    // fusión falla entera y el nodo se queda sin representación lejana.
    let g = o.geometry.clone();
    if (g.index) g = g.toNonIndexed();
    g.applyMatrix4(o.matrixWorld);
    // el LOD lejano se dibuja con un material único: el color viaja por vértice
    const col = o.material?.color ?? new THREE.Color(0xffffff);
    const n = g.attributes.position.count;
    const arr = new Float32Array(n * 3);
    for (let i = 0; i < n; i++) { arr[i * 3] = col.r; arr[i * 3 + 1] = col.g; arr[i * 3 + 2] = col.b; }
    for (const k of Object.keys(g.attributes)) if (k !== 'position' && k !== 'normal') g.deleteAttribute(k);
    g.setAttribute('color', new THREE.BufferAttribute(arr, 3));
    // El material de instancias lejanas de VistaEntidades declara
    // `attribute float aMascara` y con él decide cuánto color de jugador mezcla.
    // Si la geometría no lo trae, el atributo queda sin enlazar y el shader lee
    // lo que haya quedado en ese slot: de ahí salen manchas de color puro sobre
    // vegetación que no tiene dueño. Los nodos de recurso son de gaia: 0 siempre.
    g.setAttribute('aMascara', new THREE.BufferAttribute(new Float32Array(n), 1));
    partes.push(g);
  });
  const fusion = partes.length ? mergeGeometries(partes, false) : null;
  fusion?.computeBoundingSphere();
  _geoNodoCache.set(clave, fusion);
  return fusion;
}

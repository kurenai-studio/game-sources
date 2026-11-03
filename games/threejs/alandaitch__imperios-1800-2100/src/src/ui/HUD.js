/**
 * HUD — toda la interfaz del juego, en HTML sobre el canvas.
 *
 * Filosofía: la interfaz es la mitad de la percepción de calidad de un RTS, así
 * que acá no hay nada improvisado. El marco EVOLUCIONA con la edad (lo maneja
 * styles.css a través de `body[data-edad]`), los retratos y los iconos se dibujan
 * en canvas procedural y se cachean, y el DOM se recicla: nada se recrea por
 * frame.
 *
 * Reparto del trabajo:
 *   · por frame        → sólo el minimapa (un blit) y el reloj interno
 *   · 10 Hz            → recursos, población, vida, colas, progreso
 *   · por evento       → panel de selección, grilla de acciones, avisos
 *
 * Todo lo que este módulo pide se lo pide a `ctx`: Ordenes, Economia, Edades,
 * Combate, Seleccion, Niebla. Si alguno todavía no existe, degrada con `?.` y
 * el HUD sigue en pie.
 */

import { ORDEN } from '../core/Ctx.js';
import { TIPO, ESTADO } from '../core/World.js';
import { bus } from '../core/EventBus.js';
import { UNIDADES, UNIDAD_POR_CLAVE } from '../data/unidades.js';
import { EDIFICIOS, EDIFICIO_POR_CLAVE } from '../data/edificios.js';
import { TECNOLOGIAS, TECNO_POR_CLAVE } from '../data/tecnologias.js';
import { EDADES } from '../data/edades.js';
import { RECURSOS, CLAVES_RECURSO, IDX_RECURSO } from '../data/recursos.js';
import { CIVILIZACIONES, CIV_POR_CLAVE, COLORES_JUGADOR } from '../data/civilizaciones.js';
import { Minimapa } from './Minimapa.js';

/* ══════════════════════════════════════════════════════════════════════════
 *  Constantes de interfaz
 * ══════════════════════════════════════════════════════════════════════════ */

const RANURAS = 15;
const TECLAS = ['Q', 'W', 'E', 'R', 'T', 'A', 'S', 'D', 'F', 'G', 'Z', 'X', 'C', 'V', 'B'];
const PERIODO_LENTO = 0.1;          // 10 Hz para los valores numéricos
const VIDA_AVISO = 5.0;
const MAX_AVISOS = 5;
const MAX_REGISTRO = 80;

const NOMBRE_CLASE = {
  infanteria: 'Infantería', tirador: 'Tiradores', caballeria: 'Blindados',
  asedio: 'Artillería', aereo: 'Aeronaves', nave: 'Naves',
  edificio: 'Edificios', aldeano: 'Colonos', apoyo: 'Apoyo',
};

const EDIFICIOS_CIVILES = [
  'vivienda', 'granja', 'molino', 'aserradero', 'mina', 'empalizada',
  'muro_hormigon', 'astillero', 'mercado', 'instituto', 'ministerio',
  'central', 'sede', 'maravilla',
];
const EDIFICIOS_MILITARES = ['cuartel', 'poligono', 'establo', 'taller', 'torreta', 'ciudadela', 'aerodromo'];

const POSTURAS = [
  { modo: 'agresiva', nombre: 'Postura agresiva', glifo: 'espada', desc: 'Persigue a cualquier enemigo que entre en su visión.' },
  { modo: 'defensiva', nombre: 'Postura defensiva', glifo: 'escudo', desc: 'Ataca lo que se acerque, pero vuelve siempre a su puesto.' },
  { modo: 'quieta', nombre: 'Mantener posición', glifo: 'ancla', desc: 'Dispara sin moverse un centímetro. Ideal para artillería y líneas.' },
  { modo: 'no_atacar', nombre: 'Sin ataque', glifo: 'escudo_no', desc: 'No responde al fuego. Para retirar heridos sin que se enganchen.' },
];

const FORMACIONES = [
  { clave: 'linea', nombre: 'Formación en línea', glifo: 'f_linea', desc: 'Frente ancho de dos filas. Máximo fuego al frente.' },
  { clave: 'caja', nombre: 'Formación en caja', glifo: 'f_caja', desc: 'Bloque compacto: protege lo que va adentro.' },
  { clave: 'cuna', nombre: 'Formación en cuña', glifo: 'f_cuna', desc: 'Punta de lanza para romper una línea enemiga.' },
  { clave: 'dispersa', nombre: 'Formación dispersa', glifo: 'f_dispersa', desc: 'Abre las distancias: menos bajas por daño de área.' },
];

/** Qué unidades tienen bono contra cada clase (para el «débil contra» del tooltip). */
const AMENAZAS = (() => {
  const m = new Map();
  for (const u of UNIDADES) {
    if (!u.bonos) continue;
    for (const clase in u.bonos) {
      if (u.bonos[clase] < 8) continue;
      let porLinea = m.get(clase);
      if (!porLinea) { porLinea = new Map(); m.set(clase, porLinea); }
      const prev = porLinea.get(u.linea);
      if (!prev || u.edad < prev.edad) porLinea.set(u.linea, u);
    }
  }
  return m;
})();

/* Red de seguridad: `roundRect` es reciente y todos los iconos la usan. */
if (typeof CanvasRenderingContext2D !== 'undefined' && !CanvasRenderingContext2D.prototype.roundRect) {
  CanvasRenderingContext2D.prototype.roundRect = function (x, y, an, al, r) {
    const rr = Math.min(typeof r === 'number' ? r : 0, Math.abs(an) / 2, Math.abs(al) / 2);
    this.moveTo(x + rr, y);
    this.arcTo(x + an, y, x + an, y + al, rr);
    this.arcTo(x + an, y + al, x, y + al, rr);
    this.arcTo(x, y + al, x, y, rr);
    this.arcTo(x, y, x + an, y, rr);
    this.closePath();
    return this;
  };
}

/* ── utilidades DOM ── */
const el = (tag, clase, texto) => {
  const d = document.createElement(tag);
  if (clase) d.className = clase;
  if (texto != null) d.textContent = texto;
  return d;
};
const fijarTexto = (nodo, txt) => { if (nodo && nodo.textContent !== txt) nodo.textContent = txt; };
const reloj = (s) => {
  const t = Math.max(0, s | 0);
  const h = (t / 3600) | 0, m = ((t / 60) | 0) % 60, g = t % 60;
  const dd = (n) => (n < 10 ? '0' + n : String(n));
  return h ? `${h}:${dd(m)}:${dd(g)}` : `${dd(m)}:${dd(g)}`;
};
const defUnidad = (clave) => UNIDADES[UNIDAD_POR_CLAVE.get(clave)];
const defEdificio = (clave) => EDIFICIOS[EDIFICIO_POR_CLAVE.get(clave)];

/* ══════════════════════════════════════════════════════════════════════════
 *  Iconografía procedural (cacheada como data-URL)
 * ══════════════════════════════════════════════════════════════════════════ */

const _cacheImg = new Map();

function lienzo(lado) {
  const c = document.createElement('canvas');
  c.width = lado; c.height = lado;
  return c;
}

/** Icono redondo de recurso: espiga, tablón, moneda y rayo. */
function iconoRecurso(indice, lado = 34) {
  const clave = `rec${indice}_${lado}`;
  if (_cacheImg.has(clave)) return _cacheImg.get(clave);
  const c = lienzo(lado), g = c.getContext('2d');
  const s = lado / 34;
  const def = RECURSOS[indice];

  g.save();
  g.translate(lado / 2, lado / 2);
  // disco de fondo con brillo superior
  const grad = g.createLinearGradient(0, -lado / 2, 0, lado / 2);
  grad.addColorStop(0, 'rgba(255,255,255,0.20)');
  grad.addColorStop(1, 'rgba(0,0,0,0.42)');
  g.beginPath(); g.arc(0, 0, 15.5 * s, 0, Math.PI * 2);
  g.fillStyle = '#181310'; g.fill();
  g.fillStyle = grad; g.fill();
  g.lineWidth = 1.4 * s; g.strokeStyle = 'rgba(0,0,0,0.65)'; g.stroke();

  g.fillStyle = def.color; g.strokeStyle = def.color;
  g.lineCap = 'round'; g.lineJoin = 'round';
  g.scale(s, s);

  if (indice === 0) {          // espiga
    g.lineWidth = 1.7;
    g.beginPath(); g.moveTo(0, 9); g.lineTo(0, -8); g.stroke();
    for (let i = 0; i < 4; i++) {
      const y = -7 + i * 3.6;
      g.beginPath();
      g.moveTo(0, y + 2.2); g.quadraticCurveTo(-5.4, y + 1.4, -5.8, y - 2.2);
      g.quadraticCurveTo(-2.4, y - 1.4, 0, y + 0.4);
      g.fill();
      g.beginPath();
      g.moveTo(0, y + 2.2); g.quadraticCurveTo(5.4, y + 1.4, 5.8, y - 2.2);
      g.quadraticCurveTo(2.4, y - 1.4, 0, y + 0.4);
      g.fill();
    }
  } else if (indice === 1) {   // tablones apilados
    g.lineWidth = 1;
    for (let i = 0; i < 3; i++) {
      const y = -6 + i * 5.2;
      g.fillStyle = i === 1 ? '#c08e56' : def.color;
      g.beginPath(); g.roundRect(-9, y, 18, 4.2, 1.2); g.fill();
      g.strokeStyle = 'rgba(0,0,0,0.45)'; g.stroke();
    }
  } else if (indice === 2) {   // moneda con canto
    g.beginPath(); g.ellipse(0, 2.4, 8.6, 6.4, 0, 0, Math.PI * 2);
    g.fillStyle = '#8a6a12'; g.fill();
    g.beginPath(); g.ellipse(0, -0.6, 8.6, 6.4, 0, 0, Math.PI * 2);
    g.fillStyle = def.color; g.fill();
    g.beginPath(); g.ellipse(0, -0.6, 5.2, 3.6, 0, 0, Math.PI * 2);
    g.strokeStyle = 'rgba(0,0,0,0.35)'; g.lineWidth = 1.2; g.stroke();
  } else {                     // rayo
    g.beginPath();
    g.moveTo(2.2, -10); g.lineTo(-6.4, 1.6); g.lineTo(-0.6, 1.6);
    g.lineTo(-2.6, 10.4); g.lineTo(6.6, -2.2); g.lineTo(0.6, -2.2);
    g.closePath();
    g.fill();
    g.lineWidth = 1; g.strokeStyle = 'rgba(0,0,0,0.5)'; g.stroke();
  }
  g.restore();

  const url = c.toDataURL();
  _cacheImg.set(clave, url);
  return url;
}

/** Escudo de civilización: color de jugador + banda secundaria + emblema. */
function escudoCiv(indiceCiv, colorJugador, ancho = 60) {
  const clave = `civ${indiceCiv}_${colorJugador}_${ancho}`;
  if (_cacheImg.has(clave)) return _cacheImg.get(clave);
  const alto = Math.round(ancho * 1.14);
  const c = document.createElement('canvas');
  c.width = ancho; c.height = alto;
  const g = c.getContext('2d');
  const def = CIVILIZACIONES[indiceCiv] || CIVILIZACIONES[0];
  const s = ancho / 60;

  const contorno = () => {
    g.beginPath();
    g.moveTo(4 * s, 4 * s);
    g.lineTo(56 * s, 4 * s);
    g.lineTo(56 * s, 40 * s);
    g.quadraticCurveTo(56 * s, 58 * s, 30 * s, 66 * s);
    g.quadraticCurveTo(4 * s, 58 * s, 4 * s, 40 * s);
    g.closePath();
  };

  g.save();
  contorno();
  g.fillStyle = colorJugador || def.color;
  g.fill();
  // banda diagonal con el color secundario de la civilización
  g.save(); g.clip();
  g.fillStyle = def.colorSec;
  g.globalAlpha = 0.92;
  g.beginPath();
  g.moveTo(-6 * s, 30 * s); g.lineTo(30 * s, -6 * s);
  g.lineTo(48 * s, -6 * s); g.lineTo(-6 * s, 48 * s);
  g.closePath(); g.fill();
  g.restore();
  // brillo y sombra interior
  g.save(); contorno(); g.clip();
  const gr = g.createLinearGradient(0, 0, 0, alto);
  gr.addColorStop(0, 'rgba(255,255,255,0.34)');
  gr.addColorStop(0.55, 'rgba(255,255,255,0)');
  gr.addColorStop(1, 'rgba(0,0,0,0.42)');
  g.fillStyle = gr; g.fillRect(0, 0, ancho, alto);
  g.restore();
  contorno();
  g.lineWidth = 2.4 * s; g.strokeStyle = 'rgba(20,14,8,0.85)'; g.stroke();
  g.lineWidth = 1 * s; g.strokeStyle = 'rgba(255,255,255,0.28)'; g.stroke();
  g.restore();

  const url = c.toDataURL();
  _cacheImg.set(clave, url);
  return url;
}

/* ── retratos de unidades y edificios ── */

function fondoRetrato(g, lado, edad, colorJug) {
  const pal = (EDADES[edad] || EDADES[0]).paleta;
  const gr = g.createLinearGradient(0, 0, 0, lado);
  gr.addColorStop(0, pal.primario);
  gr.addColorStop(1, pal.secundario);
  g.fillStyle = gr; g.fillRect(0, 0, lado, lado);

  // trama diagonal muy tenue
  g.save();
  g.globalAlpha = 0.10;
  g.strokeStyle = '#ffffff'; g.lineWidth = 1;
  for (let i = -lado; i < lado * 2; i += 7) {
    g.beginPath(); g.moveTo(i, 0); g.lineTo(i - lado, lado); g.stroke();
  }
  g.restore();

  // viñeta
  const v = g.createRadialGradient(lado * 0.42, lado * 0.34, lado * 0.12, lado * 0.5, lado * 0.5, lado * 0.78);
  v.addColorStop(0, 'rgba(255,255,255,0.16)');
  v.addColorStop(1, 'rgba(0,0,0,0.55)');
  g.fillStyle = v; g.fillRect(0, 0, lado, lado);

  // esquina con el color del jugador
  g.save();
  g.fillStyle = colorJug;
  g.beginPath();
  g.moveTo(0, lado); g.lineTo(0, lado * 0.74); g.lineTo(lado * 0.3, lado);
  g.closePath(); g.fill();
  g.restore();
}

function marcoRetrato(g, lado) {
  g.save();
  g.strokeStyle = 'rgba(0,0,0,0.6)'; g.lineWidth = 2;
  g.strokeRect(1, 1, lado - 2, lado - 2);
  g.strokeStyle = 'rgba(255,255,255,0.16)'; g.lineWidth = 1;
  g.strokeRect(2.5, 2.5, lado - 5, lado - 5);
  g.restore();
}

/** Silueta de unidad. Trabajamos en una caja 100×100 y escalamos. */
function siluetaUnidad(g, def, edad) {
  const clase = def.clase;
  const linea = def.linea;
  g.save();
  g.translate(50, 52);
  g.lineJoin = 'round'; g.lineCap = 'round';

  const oscuro = 'rgba(14,10,7,0.92)';
  const luz = 'rgba(255,236,196,0.85)';

  const pintar = (trazo) => {
    // sombra suelta + cuerpo + filo de luz: da volumen sin texturas
    g.save(); g.translate(3, 3); g.globalAlpha = 0.35; g.fillStyle = '#000'; trazo(g); g.fill(); g.restore();
    g.fillStyle = oscuro; trazo(g); g.fill();
    g.save(); g.globalAlpha = 0.55; g.strokeStyle = luz; g.lineWidth = 2; g.translate(-1.6, -1.6); trazo(g); g.stroke(); g.restore();
  };

  const humano = (casco) => pintar((c) => {
    c.beginPath();
    c.arc(0, -26, 9, 0, Math.PI * 2);                        // cabeza
    c.moveTo(-13, -12);
    c.quadraticCurveTo(0, -19, 13, -12);                     // hombros
    c.lineTo(15, 14); c.lineTo(9, 36); c.lineTo(2, 36);
    c.lineTo(0, 16); c.lineTo(-3, 36); c.lineTo(-10, 36);
    c.lineTo(-15, 14); c.closePath();
    if (casco === 'sombrero') { c.moveTo(-17, -31); c.lineTo(17, -31); c.lineTo(13, -36); c.lineTo(-13, -36); c.closePath(); }
    if (casco === 'casco') { c.moveTo(-11, -30); c.quadraticCurveTo(0, -42, 11, -30); c.lineTo(13, -26); c.lineTo(-13, -26); c.closePath(); }
    if (casco === 'exo') { c.moveTo(-12, -34); c.lineTo(12, -34); c.lineTo(15, -22); c.lineTo(-15, -22); c.closePath(); }
  });

  if (clase === 'aldeano') {
    humano('sombrero');
    pintar((c) => { c.beginPath(); c.moveTo(-20, 22); c.lineTo(16, -30); c.lineTo(20, -27); c.lineTo(-16, 25); c.closePath(); });   // mango
    pintar((c) => { c.beginPath(); c.moveTo(10, -34); c.quadraticCurveTo(22, -38, 26, -26); c.lineTo(21, -25); c.quadraticCurveTo(19, -32, 11, -30); c.closePath(); });
  } else if (clase === 'infanteria') {
    humano(edad >= 4 ? 'exo' : 'casco');
    if (linea === 'antiblindaje' && edad >= 1) {
      pintar((c) => { c.beginPath(); c.roundRect(-26, -14, 50, 7, 3); });        // tubo lanzacohetes
      pintar((c) => { c.beginPath(); c.moveTo(22, -18); c.lineTo(34, -10.5); c.lineTo(22, -3); c.closePath(); });
    } else if (linea === 'antiblindaje') {
      pintar((c) => { c.beginPath(); c.moveTo(-24, 30); c.lineTo(18, -40); c.lineTo(22, -38); c.lineTo(-20, 32); c.closePath(); });  // pica
      pintar((c) => { c.beginPath(); c.moveTo(18, -40); c.lineTo(26, -50); c.lineTo(28, -38); c.closePath(); });
    } else {
      pintar((c) => { c.beginPath(); c.moveTo(-22, 20); c.lineTo(20, -26); c.lineTo(24, -22); c.lineTo(-18, 24); c.closePath(); }); // fusil
      pintar((c) => { c.beginPath(); c.moveTo(20, -26); c.lineTo(30, -36); c.lineTo(32, -33); c.lineTo(24, -22); c.closePath(); }); // bayoneta
    }
  } else if (clase === 'tirador') {
    humano('casco');
    pintar((c) => { c.beginPath(); c.moveTo(-30, 4); c.lineTo(30, -14); c.lineTo(32, -8); c.lineTo(-28, 10); c.closePath(); });     // rifle largo
    pintar((c) => { c.beginPath(); c.roundRect(2, -16, 16, 6, 2); });                                                              // mira
  } else if (clase === 'caballeria') {
    if (edad <= 1) {
      pintar((c) => {                                                          // caballo
        c.beginPath();
        c.moveTo(-32, 12); c.quadraticCurveTo(-30, -8, -10, -10);
        c.quadraticCurveTo(10, -12, 22, -22); c.lineTo(30, -30);
        c.lineTo(34, -22); c.lineTo(26, -12); c.quadraticCurveTo(30, 2, 24, 14);
        c.lineTo(18, 34); c.lineTo(12, 34); c.lineTo(15, 12);
        c.lineTo(-12, 12); c.lineTo(-14, 34); c.lineTo(-20, 34);
        c.lineTo(-20, 10); c.quadraticCurveTo(-34, 22, -32, 12); c.closePath();
      });
      pintar((c) => { c.beginPath(); c.arc(-2, -26, 7, 0, Math.PI * 2); c.moveTo(-12, -14); c.quadraticCurveTo(-2, -20, 8, -14); c.lineTo(6, 0); c.lineTo(-12, 0); c.closePath(); });
      pintar((c) => { c.beginPath(); c.moveTo(6, -22); c.lineTo(30, -46); c.lineTo(33, -42); c.lineTo(9, -18); c.closePath(); });
    } else {
      pintar((c) => {                                                          // casco de blindado
        c.beginPath();
        c.moveTo(-34, 6); c.lineTo(-28, -6); c.lineTo(26, -6); c.lineTo(34, 6);
        c.lineTo(32, 18); c.lineTo(-32, 18); c.closePath();
      });
      pintar((c) => { c.beginPath(); c.moveTo(-14, -8); c.lineTo(-10, -22); c.lineTo(10, -22); c.lineTo(16, -8); c.closePath(); });
      pintar((c) => { c.beginPath(); c.roundRect(8, -20, 34, 6, 2); });
      g.save(); g.fillStyle = 'rgba(20,14,10,0.85)';
      for (let i = -3; i <= 3; i++) { g.beginPath(); g.arc(i * 9.5, 20, 6, 0, Math.PI * 2); g.fill(); }
      g.restore();
    }
  } else if (clase === 'asedio') {
    pintar((c) => { c.beginPath(); c.moveTo(-30, 14); c.lineTo(-22, 2); c.lineTo(14, 2); c.lineTo(20, 14); c.closePath(); });
    pintar((c) => { c.beginPath(); c.moveTo(-6, 2); c.lineTo(-2, -12); c.lineTo(34, -26); c.lineTo(38, -16); c.lineTo(4, 2); c.closePath(); });
    g.save(); g.fillStyle = 'rgba(14,10,7,0.92)';
    g.beginPath(); g.arc(-16, 20, 15, 0, Math.PI * 2); g.fill();
    g.beginPath(); g.arc(14, 22, 11, 0, Math.PI * 2); g.fill();
    g.restore();
    g.save(); g.strokeStyle = 'rgba(255,236,196,0.6)'; g.lineWidth = 2;
    g.beginPath(); g.arc(-16, 20, 9, 0, Math.PI * 2); g.stroke(); g.restore();
  } else if (clase === 'aereo') {
    pintar((c) => { c.beginPath(); c.roundRect(-13, -8, 26, 14, 5); });
    for (const bx of [-26, 26]) {
      for (const by of [-22, 10]) {
        pintar((c) => { c.beginPath(); c.moveTo(0, -1); c.lineTo(bx, by); c.lineTo(bx * 0.94, by + 4); c.closePath(); });
        g.save(); g.globalAlpha = 0.55; g.strokeStyle = 'rgba(255,236,196,0.8)'; g.lineWidth = 2.4;
        g.beginPath(); g.ellipse(bx, by, 13, 3.4, 0, 0, Math.PI * 2); g.stroke(); g.restore();
      }
    }
  } else if (clase === 'nave') {
    pintar((c) => { c.beginPath(); c.moveTo(-36, 6); c.lineTo(34, 6); c.lineTo(26, 24); c.lineTo(-28, 24); c.closePath(); });
    pintar((c) => { c.beginPath(); c.roundRect(-12, -14, 24, 20, 3); });
    pintar((c) => { c.beginPath(); c.roundRect(-2, -42, 5, 30, 2); });
    g.save(); g.globalAlpha = 0.35; g.fillStyle = '#7fd4e8';
    g.beginPath(); g.moveTo(-40, 26); g.quadraticCurveTo(0, 34, 40, 26); g.lineTo(40, 34); g.lineTo(-40, 34); g.closePath(); g.fill();
    g.restore();
  } else {  // apoyo / comercio
    if (linea === 'comercio') {
      pintar((c) => { c.beginPath(); c.moveTo(-28, -6); c.lineTo(20, -6); c.lineTo(24, 12); c.lineTo(-28, 12); c.closePath(); });
      g.save(); g.fillStyle = 'rgba(14,10,7,0.92)';
      g.beginPath(); g.arc(-16, 20, 11, 0, Math.PI * 2); g.fill();
      g.beginPath(); g.arc(14, 20, 11, 0, Math.PI * 2); g.fill(); g.restore();
    } else {
      humano('');
      pintar((c) => { c.beginPath(); c.moveTo(10, -18); c.lineTo(34, -30); c.lineTo(34, -6); c.closePath(); });   // megáfono
      pintar((c) => { c.beginPath(); c.roundRect(4, -21, 8, 6, 2); });
    }
  }
  g.restore();
}

/** Silueta de edificio, con techo, chimenea o antena según la edad. */
function siluetaEdificio(g, def, edad, colorJug) {
  g.save();
  g.translate(50, 56);
  const oscuro = 'rgba(16,11,8,0.92)';
  const pintar = (trazo, relleno) => {
    g.save(); g.translate(3, 3); g.globalAlpha = 0.32; g.fillStyle = '#000'; trazo(g); g.fill(); g.restore();
    g.fillStyle = relleno || oscuro; trazo(g); g.fill();
    g.save(); g.globalAlpha = 0.5; g.strokeStyle = 'rgba(255,236,196,0.8)'; g.lineWidth = 1.8; g.translate(-1.4, -1.4); trazo(g); g.stroke(); g.restore();
  };

  const ancho = def.muro ? 22 : (def.celdas && def.celdas[0] >= 5 ? 40 : 32);

  if (def.muro) {
    pintar((c) => { c.beginPath(); c.rect(-30, -6, 60, 30); });
    for (let i = -2; i <= 2; i++) pintar((c) => { c.beginPath(); c.rect(i * 12 - 4, -18, 9, 12); });
  } else if (def.maravilla) {
    pintar((c) => { c.beginPath(); c.moveTo(-34, 26); c.lineTo(-18, -30); c.lineTo(18, -30); c.lineTo(34, 26); c.closePath(); });
    pintar((c) => { c.beginPath(); c.moveTo(0, -56); c.lineTo(10, -30); c.lineTo(-10, -30); c.closePath(); });
    g.save(); g.globalAlpha = 0.7; g.fillStyle = colorJug;
    g.beginPath(); g.arc(0, -46, 5, 0, Math.PI * 2); g.fill(); g.restore();
  } else {
    // cuerpo
    pintar((c) => { c.beginPath(); c.rect(-ancho, -12, ancho * 2, 36); });
    // techo: a dos aguas en Vapor/Eléctrica, plano después
    if (edad <= 1) {
      pintar((c) => { c.beginPath(); c.moveTo(-ancho - 6, -12); c.lineTo(0, -38); c.lineTo(ancho + 6, -12); c.closePath(); });
    } else {
      pintar((c) => { c.beginPath(); c.rect(-ancho - 5, -19, ancho * 2 + 10, 8); });
    }
    // detalle silueteado por edad
    if (edad === 0) pintar((c) => { c.beginPath(); c.rect(ancho * 0.42, -46, 9, 26); });                          // chimenea
    else if (edad === 1) { pintar((c) => { c.beginPath(); c.rect(-3, -46, 6, 28); }); pintar((c) => { c.beginPath(); c.rect(-14, -44, 28, 5); }); }
    else if (edad === 2) pintar((c) => { c.beginPath(); c.moveTo(-16, -19); c.lineTo(16, -19); c.lineTo(10, -34); c.lineTo(-10, -34); c.closePath(); });
    else if (edad === 3) { pintar((c) => { c.beginPath(); c.rect(-1.5, -50, 3, 32); }); pintar((c) => { c.beginPath(); c.arc(0, -50, 6, Math.PI, 0); }); }
    else { pintar((c) => { c.beginPath(); c.roundRect(-13, -40, 26, 8, 4); }); }
    // puerta y ventanas
    g.save(); g.fillStyle = 'rgba(255,214,140,0.55)';
    g.fillRect(-6, 6, 12, 18);
    for (const vx of [-ancho * 0.6, ancho * 0.6 - 8]) g.fillRect(vx, -4, 8, 8);
    g.restore();
    // banderín con el color del jugador
    g.save();
    g.fillStyle = colorJug;
    g.beginPath();
    g.moveTo(-ancho - 2, -12); g.lineTo(-ancho - 2, 24); g.lineTo(-ancho + 8, 24);
    g.lineTo(-ancho + 8, -12); g.closePath(); g.fill();
    g.globalAlpha = 0.35; g.fillStyle = '#000';
    g.fillRect(-ancho + 3, -12, 5, 36);
    g.restore();
  }
  g.restore();
}

/** Icono de tecnología: engranaje con el emblema del área. */
function siluetaTecno(g, def) {
  g.save();
  g.translate(50, 50);
  const oscuro = 'rgba(14,10,7,0.9)';
  g.save(); g.translate(3, 3); g.globalAlpha = 0.3; g.fillStyle = '#000';
  dientes(g, 30, 9); g.fill(); g.restore();
  g.fillStyle = oscuro; dientes(g, 30, 9); g.fill();
  g.strokeStyle = 'rgba(255,236,196,0.7)'; g.lineWidth = 2;
  g.save(); g.translate(-1.4, -1.4); dientes(g, 30, 9); g.stroke(); g.restore();
  g.beginPath(); g.arc(0, 0, 12, 0, Math.PI * 2);
  g.fillStyle = 'rgba(255,236,196,0.20)'; g.fill();
  g.strokeStyle = 'rgba(255,236,196,0.7)'; g.lineWidth = 2; g.stroke();

  // marca del área en el centro
  g.fillStyle = 'rgba(255,240,206,0.92)';
  const area = def.en;
  if (area === 'fundicion') { g.beginPath(); g.moveTo(-5, 6); g.lineTo(4, -7); g.lineTo(6, -5); g.lineTo(-3, 8); g.closePath(); g.fill(); }
  else if (area === 'instituto') { g.beginPath(); g.arc(0, 0, 4.5, 0, Math.PI * 2); g.fill(); g.strokeStyle = 'rgba(255,240,206,0.9)'; g.lineWidth = 1.4; g.beginPath(); g.ellipse(0, 0, 9, 4, 0.6, 0, Math.PI * 2); g.stroke(); }
  else if (area === 'mercado') { g.beginPath(); g.arc(0, 0, 5.5, 0, Math.PI * 2); g.fill(); }
  else { g.beginPath(); g.moveTo(0, -6); g.lineTo(5, 5); g.lineTo(-5, 5); g.closePath(); g.fill(); }
  g.restore();

  function dientes(c, r, n) {
    c.beginPath();
    for (let i = 0; i < n * 2; i++) {
      const a = (i / (n * 2)) * Math.PI * 2;
      const rr = i % 2 === 0 ? r : r * 0.78;
      const x = Math.cos(a) * rr, y = Math.sin(a) * rr;
      if (i === 0) c.moveTo(x, y); else c.lineTo(x, y);
    }
    c.closePath();
  }
}

/** Glifos de acciones abstractas (posturas, formaciones, órdenes). */
function glifo(g, nombre) {
  g.save();
  g.translate(50, 50);
  g.strokeStyle = 'rgba(255,240,210,0.95)';
  g.fillStyle = 'rgba(255,240,210,0.95)';
  g.lineWidth = 5; g.lineCap = 'round'; g.lineJoin = 'round';
  g.shadowColor = 'rgba(0,0,0,0.75)'; g.shadowBlur = 6; g.shadowOffsetY = 2;
  const P = (pts, cerrar = true) => {
    g.beginPath();
    for (let i = 0; i < pts.length; i += 2) (i ? g.lineTo : g.moveTo).call(g, pts[i], pts[i + 1]);
    if (cerrar) g.closePath();
  };
  const puntos = (lista, r = 5) => { for (const [x, y] of lista) { g.beginPath(); g.arc(x, y, r, 0, Math.PI * 2); g.fill(); } };

  switch (nombre) {
    case 'espada': P([-4, 22, -14, 12, 14, -22, 22, -14]); g.fill(); P([-16, 6, -6, 16, -18, 24, -24, 18]); g.fill(); break;
    case 'escudo': P([0, -26, 24, -16, 24, 6, 0, 28, -24, 6, -24, -16]); g.fill(); break;
    case 'escudo_no':
      g.globalAlpha = 0.5; P([0, -26, 24, -16, 24, 6, 0, 28, -24, 6, -24, -16]); g.fill(); g.globalAlpha = 1;
      g.strokeStyle = '#ff8a7a'; g.lineWidth = 6; P([-24, -24, 24, 24], false); g.stroke(); break;
    case 'ancla': P([-22, 18, 22, 18, 22, 26, -22, 26]); g.fill(); P([-6, -24, 6, -24, 6, 12, -6, 12]); g.fill(); break;
    case 'casa': P([0, -26, 26, -2, 18, -2, 18, 24, -18, 24, -18, -2, -26, -2]); g.fill(); break;
    case 'espadas':
      P([-2, 20, -12, 10, 12, -22, 20, -14]); g.fill();
      P([2, 20, 12, 10, -12, -22, -20, -14]); g.fill(); break;
    case 'atras': P([6, -22, -18, 0, 6, 22, 6, 10, 22, 10, 22, -10, 6, -10]); g.fill(); break;
    case 'detener': g.beginPath(); g.roundRect(-18, -18, 36, 36, 5); g.fill(); break;
    case 'bandera':
      P([-14, -26, -14, 26], false); g.lineWidth = 6; g.stroke();
      P([-14, -24, 20, -14, -14, -4]); g.fill(); break;
    case 'patrulla':
      g.lineWidth = 5; P([-22, 10, 0, -14, 22, 10], false); g.stroke();
      puntos([[-22, 10], [22, 10]], 6); break;
    case 'salir':
      g.lineWidth = 5; g.beginPath(); g.roundRect(-24, -20, 26, 40, 4); g.stroke();
      P([2, 0, 24, 0], false); g.stroke(); P([14, -10, 26, 0, 14, 10]); g.fill(); break;
    case 'edad':
      P([0, -28, 20, -6, 9, -6, 9, 12, -9, 12, -9, -6, -20, -6]); g.fill();
      g.fillRect(-18, 18, 36, 8); break;
    case 'reparar':
      g.lineWidth = 8; P([-16, 16, 12, -12], false); g.stroke();
      g.beginPath(); g.arc(-20, 20, 8, 0, Math.PI * 2); g.fill();
      g.beginPath(); g.arc(18, -18, 11, 0.6, 5.4); g.lineWidth = 7; g.stroke(); break;
    case 'cancelar': g.lineWidth = 8; P([-18, -18, 18, 18], false); g.stroke(); P([18, -18, -18, 18], false); g.stroke(); break;
    case 'f_linea': puntos([[-20, 0], [-7, 0], [7, 0], [20, 0]]); puntos([[-13, 15], [0, 15], [13, 15]], 4); break;
    case 'f_caja': puntos([[-13, -13], [0, -13], [13, -13], [-13, 0], [13, 0], [-13, 13], [0, 13], [13, 13]]); break;
    case 'f_cuna': puntos([[0, -18], [-11, -4], [11, -4], [-22, 10], [0, 10], [22, 10]]); break;
    case 'f_dispersa': puntos([[-20, -14], [8, -20], [20, 2], [-6, 4], [-18, 18], [12, 18]], 4.5); break;
    case 'arbol':
      g.lineWidth = 4;
      P([0, -22, 0, -6], false); g.stroke(); P([-16, -6, 16, -6], false); g.stroke();
      P([-16, -6, -16, 6], false); g.stroke(); P([16, -6, 16, 6], false); g.stroke();
      puntos([[0, -24], [-16, 12], [16, 12], [0, 12]], 6); break;
    default: g.beginPath(); g.arc(0, 0, 16, 0, Math.PI * 2); g.fill();
  }
  g.restore();
}

/**
 * Retrato cacheado. `spec` = { tipo:'unidad'|'edificio'|'tecno'|'glifo', clave, edad, color }
 */
function retrato(spec, lado = 96) {
  const clave = `${spec.tipo}:${spec.clave}:${spec.edad | 0}:${spec.color || ''}:${lado}`;
  if (_cacheImg.has(clave)) return _cacheImg.get(clave);
  const c = lienzo(lado), g = c.getContext('2d');
  const edad = spec.edad | 0;
  const color = spec.color || '#8a8a8a';

  fondoRetrato(g, lado, edad, color);
  g.save();
  g.scale(lado / 100, lado / 100);
  if (spec.tipo === 'unidad') {
    const def = defUnidad(spec.clave);
    if (def) siluetaUnidad(g, def, edad);
  } else if (spec.tipo === 'edificio') {
    const def = defEdificio(spec.clave);
    if (def) siluetaEdificio(g, def, edad, color);
  } else if (spec.tipo === 'tecno') {
    const def = TECNOLOGIAS[TECNO_POR_CLAVE.get(spec.clave)];
    if (def) siluetaTecno(g, def);
  } else {
    glifo(g, spec.clave);
  }
  g.restore();
  marcoRetrato(g, lado);

  const url = c.toDataURL();
  _cacheImg.set(clave, url);
  return url;
}

/* ══════════════════════════════════════════════════════════════════════════
 *  HUD
 * ══════════════════════════════════════════════════════════════════════════ */

export class HUD {
  constructor(ctx) {
    this.nombre = 'ui';
    this.orden = ORDEN.UI;
    this.ctx = ctx;

    this.raiz = document.getElementById('hud') || document.body;
    this.jug = ctx.jugadorLocal | 0;
    this.edad = 0;
    this.pagina = null;           // null | 'civil' | 'militar'
    this.menu = null;             // null | 'pausa' | 'opciones' | 'arbol' | 'fin'
    this.seleccionados = [];
    this.grupos = [];
    this.acciones = new Array(RANURAS).fill(null);
    this.terminada = false;

    this._acumLento = PERIODO_LENTO;
    this._avisos = [];
    this._registro = [];
    this._ultAviso = { texto: '', t: 0 };
    this._diagVisible = false;
    this._arbolArmado = false;
    this._nodosArbol = new Map();
    this._marcaSel = -1;
    this._marcaCola = -1;

    this.conteo = { entrenadas: 0, construidos: 0, perdidas: 0, bajas: 0, tecnos: 0 };

    this._construirDOM();
    this.minimapa = new Minimapa(ctx, this.marcoMini);
    this._conectarBus();
    this._instalarTeclado();

    this._aplicarEdad(ctx.edades?.edad?.[this.jug] ?? 0, true);
    this._refrescarCiv();
    this.setPanelSeleccion(null);
    this._refrescarValores(true);
  }

  /* ================================================================== *
   *  Bucle
   * ================================================================== */

  cada(dtReal) {
    this.minimapa?.actualizar(dtReal);

    this._acumLento += dtReal;
    if (this._acumLento >= PERIODO_LENTO) {
      this._acumLento = 0;
      this._refrescarValores(false);
      this._refrescarFichaViva();
      this._refrescarCostes();
      this._vigilarFin();
    }
    this._caducarAvisos(dtReal);
  }

  /* ================================================================== *
   *  API pública
   * ================================================================== */

  /** Toast con jerarquía + entrada en el registro de eventos. */
  aviso(texto, tipo = 'info', extra = null) {
    if (!texto) return;
    const ahora = performance.now();
    if (texto === this._ultAviso.texto && ahora - this._ultAviso.t < 900) return;
    this._ultAviso.texto = texto; this._ultAviso.t = ahora;

    const nodo = el('div', `aviso ${tipo === 'info' ? '' : tipo}`.trim());
    nodo.appendChild(el('i', 'pip'));
    nodo.appendChild(el('span', null, texto));
    if (extra && extra.x !== undefined) {
      nodo.classList.add('clic');
      nodo.style.cursor = 'pointer';
      nodo.title = 'Ir al lugar del aviso';
      nodo.addEventListener('click', () => this.ctx.camCtrl?.enfocar?.(extra.x, extra.z));
    }
    this.cajaAvisos.appendChild(nodo);
    this._avisos.push({ nodo, t: VIDA_AVISO });
    while (this._avisos.length > MAX_AVISOS) {
      const v = this._avisos.shift();
      v.nodo.remove();
    }

    const linea = el('div', tipo === 'info' ? '' : tipo);
    linea.appendChild(el('time', null, reloj(this.ctx.mundo?.tiempo || 0)));
    linea.appendChild(el('b', null, texto));
    this.listaRegistro.appendChild(linea);
    this._registro.push(linea);
    if (this._registro.length > MAX_REGISTRO) this._registro.shift().remove();
    this.listaRegistro.scrollTop = this.listaRegistro.scrollHeight;

    if (tipo === 'alerta' && extra && extra.x !== undefined) this.minimapa?.alerta(extra.x, extra.z);
    if (tipo === 'error' && extra && extra.x !== undefined) this.minimapa?.alerta(extra.x, extra.z);
  }

  /** 'pausa' | 'opciones' | 'arbol' | 'fin' */
  abrirMenu(clave) {
    if (clave === 'arbol') this._armarArbol();
    this.menu = clave;
    for (const k in this.modales) this.modales[k].classList.toggle('on', k === clave);
    this.velo.classList.add('on');
    if (clave === 'pausa' || clave === 'opciones') this._pausarJuego(true);
    if (clave === 'opciones') this._sincronizarOpciones();
    const foco = this.modales[clave]?.querySelector('button, select, input');
    foco?.focus?.();
  }

  cerrarMenu() {
    if (this.menu === 'fin') return;      // la pantalla de fin no se cierra
    this.menu = null;
    for (const k in this.modales) this.modales[k].classList.remove('on');
    this.velo.classList.remove('on');
    this._pausarJuego(false);
  }

  /** Rearma el panel central con lo que haya seleccionado. */
  setPanelSeleccion(ids) {
    const w = this.ctx.mundo;
    const lista = [];
    if (ids) for (const id of ids) if (w?.vivo?.[id]) lista.push(id);
    this.seleccionados = lista;

    if (!lista.length) {
      this.pagina = null;
      this.panelSel.classList.add('vacio');
      this.fichaUno.classList.remove('on');
      this.gridVarios.classList.remove('on');
      this.tituloSel.style.display = 'none';
      this.cajaCola.classList.remove('on');
      this.hueco.style.display = '';
      this._reconstruirAcciones();
      return;
    }

    this.panelSel.classList.remove('vacio');
    this.hueco.style.display = 'none';

    if (lista.length === 1) {
      this.gridVarios.classList.remove('on');
      this.tituloSel.style.display = 'none';
      this.fichaUno.classList.add('on');
      this._pintarFicha(lista[0]);
    } else {
      this.fichaUno.classList.remove('on');
      this.cajaCola.classList.remove('on');
      this.gridVarios.classList.add('on');
      this.tituloSel.style.display = '';
      this._pintarGrupos(lista);
    }
    this._reconstruirAcciones();
  }

  /* ================================================================== *
   *  Construcción del DOM
   * ================================================================== */

  _construirDOM() {
    const R = this.raiz;
    if (R.id === 'hud') R.textContent = '';   // nunca vaciar el body si falta #hud

    /* ── barra superior ── */
    const barra = el('div', 'panel remaches clic');
    barra.id = 'barra-sup';
    this.recursoNodo = [];
    for (let i = 0; i < 4; i++) {
      const caja = el('div', 'recurso');
      caja.id = `rec-${CLAVES_RECURSO[i]}`;
      const ico = el('img', 'ico');
      ico.src = iconoRecurso(i);
      ico.alt = RECURSOS[i].nombre;
      ico.draggable = false;
      const col = el('div', 'col');
      const cant = el('div', 'cant', '0');
      const tasa = el('div', 'tasa', '0/min');
      col.append(cant, tasa);
      caja.append(ico, col);
      this._tooltipEn(caja, () => this._ttRecurso(i));
      barra.appendChild(caja);
      this.recursoNodo.push({ caja, cant, tasa });
    }

    barra.appendChild(el('div', 'sep-v'));

    this.pobCaja = el('div', 'recurso');
    this.pobCaja.id = 'pob';
    const pobCol = el('div', 'col');
    this.pobCant = el('div', 'cant', '0/0');
    this.pobTasa = el('div', 'tasa', 'Población');
    pobCol.append(this.pobCant, this.pobTasa);
    this.pobCaja.append(pobCol);
    this._tooltipEn(this.pobCaja, () => this._ttPoblacion());
    barra.appendChild(this.pobCaja);

    barra.appendChild(el('div', 'sep-v'));

    const bloqueEdad = el('div', null);
    bloqueEdad.id = 'bloque-edad';
    this.escudo = el('img');
    this.escudo.id = 'escudo-civ';
    this.escudo.draggable = false;
    const colEdad = el('div', 'col');
    this.nombreEdad = el('div', null, EDADES[0].nombre);
    this.nombreEdad.id = 'nombre-edad';
    this.rangoEdad = el('div', null, EDADES[0].rango);
    this.rangoEdad.id = 'rango-edad';
    colEdad.append(this.nombreEdad, this.rangoEdad);
    bloqueEdad.append(this.escudo, colEdad);
    this._tooltipEn(bloqueEdad, () => this._ttCivilizacion());
    barra.appendChild(bloqueEdad);

    barra.appendChild(el('div', 'sep-v'));

    this.relojNodo = el('div', null, '00:00');
    this.relojNodo.id = 'reloj';
    this._tooltipEn(this.relojNodo, () => ({ titulo: 'Reloj de partida', desc: 'Tiempo transcurrido desde el primer amanecer.' }));
    barra.appendChild(this.relojNodo);

    this.diag = el('div', null);
    this.diag.id = 'diag';
    this.diagFps = el('div');
    this.diagDib = el('div');
    this.diag.append(this.diagFps, this.diagDib);
    barra.appendChild(this.diag);

    const btnArbol = el('button', 'btn-sup', 'Árbol ');
    btnArbol.appendChild(el('kbd', null, 'T'));
    btnArbol.addEventListener('click', () => this.abrirMenu('arbol'));
    this._tooltipEn(btnArbol, () => ({ titulo: 'Árbol tecnológico', desc: 'Todo lo que podés llegar a tener, edad por edad, y lo que ya conseguiste.' }));
    const btnMenu = el('button', 'btn-sup', 'Menú ');
    btnMenu.appendChild(el('kbd', null, 'Esc'));
    btnMenu.addEventListener('click', () => this.abrirMenu('pausa'));
    barra.append(btnArbol, btnMenu);
    R.appendChild(barra);

    /* ── avisos y registro ── */
    this.cajaAvisos = el('div');
    this.cajaAvisos.id = 'avisos';
    R.appendChild(this.cajaAvisos);

    const reg = el('div', 'clic');
    reg.id = 'registro';
    const cab = el('div');
    cab.id = 'registro-cab';
    cab.appendChild(el('span', 'flecha', '›'));
    cab.appendChild(el('span', null, 'Registro de sucesos'));
    cab.addEventListener('click', () => reg.classList.toggle('abierto'));
    this.listaRegistro = el('div');
    this.listaRegistro.id = 'registro-lista';
    reg.append(cab, this.listaRegistro);
    R.appendChild(reg);
    this.registro = reg;

    /* ── panel inferior ── */
    const inf = el('div', 'panel remaches clic');
    inf.id = 'panel-inf';

    this.marcoMini = el('div');
    this.marcoMini.id = 'marco-minimapa';
    const rosa = el('div', null, 'N');
    rosa.id = 'rosa-viento';
    this.marcoMini.appendChild(rosa);
    this._tooltipEn(this.marcoMini, () => ({
      titulo: 'Mapa del imperio',
      desc: 'Izquierdo: llevá la vista. Derecho: mandá a la selección a ese punto. El recuadro blanco es lo que estás mirando.',
    }));
    inf.appendChild(this.marcoMini);

    this.panelSel = el('div', 'vacio');
    this.panelSel.id = 'panel-sel';

    this.hueco = el('div', null, 'Sin selección\nElegí una unidad o un edificio');
    this.hueco.id = 'sel-hueco';
    this.hueco.style.whiteSpace = 'pre-line';
    this.panelSel.appendChild(this.hueco);

    this.fichaUno = el('div');
    this.fichaUno.id = 'sel-uno';
    this.retratoUno = el('div', 'retrato');
    this.retratoUno.id = 'sel-retrato';
    const datos = el('div');
    datos.id = 'sel-datos';
    this.selNombre = el('div');
    this.selNombre.id = 'sel-nombre';
    this.selSub = el('div');
    this.selSub.id = 'sel-sub';
    this.barraVida = el('div', 'barra-vida');
    this.barraVidaFill = el('i');
    this.barraVidaTxt = el('span');
    this.barraVida.append(this.barraVidaFill, this.barraVidaTxt);
    this.selStats = el('div');
    this.selStats.id = 'sel-stats';
    this.selDesc = el('div');
    this.selDesc.id = 'sel-desc';
    datos.append(this.selNombre, this.selSub, this.barraVida, this.selStats, this.selDesc);

    // Columna derecha de la ficha: cola de producción o comportamiento de la
    // unidad. Es lo que evita que un panel ancho se vea vacío.
    this.selExtra = el('div');
    this.selExtra.id = 'sel-extra';
    this.extraTit = el('div', null, 'Producción');
    this.extraTit.id = 'sel-extra-tit';
    this.chips = el('div');
    this.chips.id = 'sel-chips';
    this.selExtra.append(this.extraTit, this.chips);

    this.fichaUno.append(this.retratoUno, datos, this.selExtra);
    this.panelSel.appendChild(this.fichaUno);

    this.cajaCola = el('div');
    this.cajaCola.id = 'sel-cola';
    this.colaItems = [];
    for (let i = 0; i < 8; i++) {
      const it = el('div', 'cola-item');
      it.style.display = 'none';
      const p = el('i', 'prog');
      it.appendChild(p);
      it.addEventListener('contextmenu', (e) => { e.preventDefault(); this._cancelarCola(i); });
      it.addEventListener('click', (e) => { if (e.shiftKey) this._cancelarCola(i); });
      this.cajaCola.appendChild(it);
      this.colaItems.push({ nodo: it, prog: p });
    }
    this.colaBarra = el('div');
    this.colaBarra.id = 'cola-barra';
    this.colaBarraFill = el('i');
    this.colaBarra.appendChild(this.colaBarraFill);
    this.colaTxt = el('div');
    this.colaTxt.id = 'cola-txt';
    this.cajaCola.append(this.colaBarra, this.colaTxt);
    this.selExtra.appendChild(this.cajaCola);

    this.tituloSel = el('div', null, 'Selección');
    this.tituloSel.id = 'sel-titulo';
    this.tituloSel.style.display = 'none';
    this.gridVarios = el('div');
    this.gridVarios.id = 'sel-varios';
    this.panelSel.append(this.tituloSel, this.gridVarios);
    inf.appendChild(this.panelSel);

    this.grilla = el('div');
    this.grilla.id = 'grilla-acciones';
    this.botones = [];
    for (let i = 0; i < RANURAS; i++) {
      const b = el('button', 'accion oculto');
      b.type = 'button';
      b.tabIndex = -1;
      const tecla = el('span', 'tecla', TECLAS[i]);
      const costes = el('span', 'costes');
      const pastilla = el('span', 'pastilla');
      const prog = el('i', 'marco-prog');
      b.append(tecla, costes, pastilla, prog);
      b.addEventListener('click', (e) => this._activarRanura(i, e.shiftKey));
      b.addEventListener('contextmenu', (e) => { e.preventDefault(); this._activarRanura(i, false, true); });
      this._tooltipEn(b, () => this._ttAccion(i));
      this.grilla.appendChild(b);
      this.botones.push({ nodo: b, costes, pastilla, prog, tecla });
    }
    inf.appendChild(this.grilla);
    R.appendChild(inf);

    /* ── tooltip flotante ── */
    this.tooltip = el('div');
    this.tooltip.id = 'tooltip';
    document.body.appendChild(this.tooltip);

    /* ── modales ── */
    this._construirModales();

    /* Los clicks y las teclas que caen sobre el HUD no deben llegar al mundo. */
    for (const ev of ['pointerdown', 'pointerup', 'wheel', 'contextmenu', 'dblclick']) {
      R.addEventListener(ev, (e) => {
        if (e.target === R) return;                       // el hueco central deja pasar
        if (ev === 'contextmenu') e.preventDefault();
        e.stopPropagation();
      });
    }
  }

  _construirModales() {
    const velo = el('div');
    velo.id = 'velo-modal';
    velo.addEventListener('pointerdown', (e) => { if (e.target === velo && this.menu !== 'fin') this.cerrarMenu(); });
    this.velo = velo;
    this.modales = {};

    /* pausa */
    const pausa = el('div', 'modal panel');
    pausa.id = 'modal-pausa';
    pausa.append(el('h2', null, 'Partida en pausa'));
    pausa.append(el('div', 'lema', 'El mundo espera. Vos decidís cuándo sigue.'));
    pausa.append(el('div', 'filete'));
    const bReanudar = el('button', 'btn', 'Reanudar');
    bReanudar.addEventListener('click', () => this.cerrarMenu());
    const bOpc = el('button', 'btn', 'Opciones');
    bOpc.addEventListener('click', () => this.abrirMenu('opciones'));
    const bRein = el('button', 'btn', 'Reiniciar partida');
    bRein.addEventListener('click', () => location.reload());
    const bSalir = el('button', 'btn peligro', 'Rendirse y salir');
    bSalir.addEventListener('click', () => this._terminar(false, 'Te rendiste.'));
    pausa.append(bReanudar, bOpc, bRein, bSalir);
    velo.appendChild(pausa);
    this.modales.pausa = pausa;

    /* opciones */
    const opc = el('div', 'modal panel');
    opc.id = 'modal-opciones';
    opc.append(el('h2', null, 'Opciones'));
    opc.append(el('div', 'lema', 'Ajustá el motor a tu máquina y el ritmo a tu paciencia.'));
    opc.append(el('div', 'filete'));

    this.segCalidad = this._segmentado(opc, 'Calidad gráfica',
      [['baja', 'Baja'], ['media', 'Media'], ['alta', 'Alta'], ['ultra', 'Ultra']],
      (v) => { this.ctx.render?.setCalidad?.(v); this.ctx.calidad = v; this.aviso(`Calidad gráfica: ${v}`, 'info'); });

    this.desVelocidad = this._deslizador(opc, 'Velocidad de juego', 0.5, 3, 0.25, 1,
      (v) => { if (this.ctx.motor) this.ctx.motor.velocidad = v; }, (v) => `${v.toFixed(2)}×`);

    this.desVolumen = this._deslizador(opc, 'Volumen general', 0, 100, 5, 70,
      (v) => this._fijarVolumen(v / 100), (v) => `${v | 0}%`);

    this.segCiclo = this._segmentado(opc, 'Ciclo día/noche',
      [['si', 'Activado'], ['no', 'Hora fija']],
      (v) => {
        this.ctx.cicloDia = v === 'si';
        this.filaHora.style.display = v === 'si' ? 'none' : '';
        this.aviso(v === 'si' ? 'El sol vuelve a moverse.' : 'Hora del día congelada.', 'info');
      });

    this.desHora = this._deslizador(opc, 'Hora del día', 0, 24, 0.5, 10,
      (v) => { if (this.ctx.cielo) this.ctx.cielo.horaDelDia = v; },
      (v) => `${String(Math.floor(v)).padStart(2, '0')}:${v % 1 ? '30' : '00'}`);
    this.filaHora = this.desHora.fila;
    this.filaHora.style.display = 'none';

    const bVolver = el('button', 'btn', 'Volver');
    bVolver.style.marginTop = '1rem';
    bVolver.addEventListener('click', () => this.abrirMenu('pausa'));
    opc.appendChild(bVolver);
    velo.appendChild(opc);
    this.modales.opciones = opc;

    /* fin de partida */
    const fin = el('div', 'modal panel');
    fin.id = 'modal-fin';
    this.finTitulo = el('h2', null, 'Victoria');
    this.finLema = el('div', 'lema', '');
    fin.append(this.finTitulo, this.finLema, el('div', 'filete'));
    this.tablaFin = el('table');
    this.tablaFin.id = 'tabla-fin';
    fin.appendChild(this.tablaFin);
    const bFin = el('button', 'btn', 'Jugar de nuevo');
    bFin.style.marginTop = '1.1rem';
    bFin.addEventListener('click', () => location.reload());
    fin.appendChild(bFin);
    velo.appendChild(fin);
    this.modales.fin = fin;

    /* árbol tecnológico */
    const arbol = el('div', 'modal panel');
    arbol.id = 'modal-arbol';
    arbol.append(el('h2', null, 'Árbol tecnológico'));
    arbol.append(el('div', 'lema', 'Dos siglos de progreso, de la caldera al enjambre.'));
    arbol.append(el('div', 'filete'));
    this.arbolCuerpo = el('div');
    this.arbolCuerpo.id = 'arbol-cuerpo';
    arbol.appendChild(this.arbolCuerpo);
    const ley = el('div');
    ley.id = 'arbol-leyenda';
    for (const [c, t] of [['hecho', 'Ya lo tenés'], ['disp', 'Disponible ahora'], ['no', 'Todavía no']]) {
      const s = el('span');
      s.appendChild(el('i', c));
      s.appendChild(el('span', null, t));
      ley.appendChild(s);
    }
    arbol.appendChild(ley);
    const bCerrar = el('button', 'btn', 'Cerrar');
    bCerrar.style.marginTop = '0.8rem';
    bCerrar.addEventListener('click', () => this.cerrarMenu());
    arbol.appendChild(bCerrar);
    velo.appendChild(arbol);
    this.modales.arbol = arbol;

    (document.getElementById('app') || document.body).appendChild(velo);
  }

  _segmentado(padre, etiqueta, opciones, alCambiar) {
    const fila = el('div', 'opcion');
    fila.appendChild(el('label', null, etiqueta));
    const caja = el('div', 'segmentado');
    const botones = [];
    for (const [valor, texto] of opciones) {
      const b = el('button', null, texto);
      b.type = 'button';
      b.addEventListener('click', () => {
        for (const o of botones) o.classList.toggle('on', o === b);
        alCambiar(valor);
      });
      b.dataset.valor = valor;
      caja.appendChild(b);
      botones.push(b);
    }
    fila.appendChild(caja);
    fila.appendChild(el('div', 'valor', ''));
    padre.appendChild(fila);
    return { fila, botones, fijar: (v) => { for (const o of botones) o.classList.toggle('on', o.dataset.valor === v); } };
  }

  _deslizador(padre, etiqueta, min, max, paso, valor, alCambiar, formato) {
    const fila = el('div', 'opcion');
    fila.appendChild(el('label', null, etiqueta));
    const inp = document.createElement('input');
    inp.type = 'range';
    inp.min = min; inp.max = max; inp.step = paso; inp.value = valor;
    const val = el('div', 'valor', formato(valor));
    inp.addEventListener('input', () => {
      const v = Number(inp.value);
      val.textContent = formato(v);
      alCambiar(v);
    });
    fila.append(inp, val);
    padre.appendChild(fila);
    return { fila, inp, val, fijar: (v) => { inp.value = v; val.textContent = formato(v); } };
  }

  /* ================================================================== *
   *  Bus y teclado
   * ================================================================== */

  _conectarBus() {
    const b = this.ctx.bus || bus;
    const refrescaGrilla = () => this._reconstruirAcciones();

    b.on('seleccion:cambio', (ids) => this.setPanelSeleccion(ids));
    b.on('aviso', (c) => this.aviso(c?.texto, c?.tipo || 'info', c));
    b.on('edad:avanzada', (c) => {
      if (c?.jugador === this.jug) { this._aplicarEdad(c.edad); refrescaGrilla(); }
    });
    b.on('civ:asignada', (c) => { if (c?.jugador === this.jug) this._refrescarCiv(); });
    b.on('cola:cambio', (c) => { if (this._esSeleccionado(c?.edificioId)) this._refrescarCola(); });
    b.on('produccion:cambio', (c) => { if (this._esSeleccionado(c?.id)) this._refrescarCola(); refrescaGrilla(); });
    b.on('tecno:iniciada', refrescaGrilla);
    b.on('tecno:cancelada', refrescaGrilla);
    b.on('edad:iniciada', refrescaGrilla);
    b.on('tecno:completada', (c) => {
      if (c?.jugador === this.jug) { this.conteo.tecnos++; this._marcarArbol(); }
      refrescaGrilla();
    });
    b.on('unidad:entrenada', (c) => { if (c?.jugador === this.jug) this.conteo.entrenadas++; });
    b.on('edificio:terminado', (c) => { if (c?.jugador === this.jug) { this.conteo.construidos++; this._marcarArbol(); } refrescaGrilla(); });
    b.on('obra:terminada', (c) => { if (c?.jugador === this.jug) { this.conteo.construidos++; this._marcarArbol(); } });
    b.on('entidad:muerta', (c) => {
      const w = this.ctx.mundo;
      const id = typeof c === 'number' ? c : c?.id;
      const de = id != null && w ? w.jugador[id] : 255;
      if (de === this.jug) this.conteo.perdidas++;
      else if (c?.porJugador === this.jug) this.conteo.bajas++;
    });
    b.on('construccion:salida', () => { if (this.pagina) { this.pagina = null; refrescaGrilla(); } });
    b.on('combate:postura', refrescaGrilla);
    b.on('partida:fin', (c) => this._terminar(c?.ganador === this.jug, c?.motivo || ''));
  }

  _instalarTeclado() {
    // Capturamos en window ANTES que Seleccion: si la tecla es nuestra, se corta.
    window.addEventListener('keydown', (e) => {
      const t = e.target;
      if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.isContentEditable)) return;
      if (e.repeat) return;

      const code = e.code;

      if (code === 'F3') { this._alternarDiag(); e.preventDefault(); e.stopPropagation(); return; }

      if (this.menu) {
        if (code === 'Escape') {
          if (this.menu === 'opciones') this.abrirMenu('pausa');
          else this.cerrarMenu();
        }
        e.stopPropagation();
        if (code !== 'Tab') e.preventDefault();
        return;
      }

      if (code === 'Escape') {
        // Escape pertenece a Seleccion mientras haya algo que cancelar.
        if (this.pagina) { this.pagina = null; this._reconstruirAcciones(); e.stopPropagation(); return; }
        if (this.ctx.seleccion?.construccion) return;
        if (this.ctx.seleccion?.ids?.size) return;
        this.abrirMenu('pausa');
        e.stopPropagation(); e.preventDefault();
        return;
      }
      if (code === 'F10') { this.abrirMenu('pausa'); e.preventDefault(); e.stopPropagation(); return; }
      if (code === 'KeyP' && !e.ctrlKey && !e.metaKey) {
        this._pausarJuego(!this.ctx.motor?.pausado);
        this.aviso(this.ctx.motor?.pausado ? 'Juego en pausa' : 'Juego reanudado', 'info');
        e.stopPropagation(); return;
      }
      if (code === 'Pause') { this._pausarJuego(!this.ctx.motor?.pausado); e.preventDefault(); return; }
      if (code === 'KeyT' && (e.ctrlKey || e.metaKey)) { this.abrirMenu('arbol'); e.preventDefault(); e.stopPropagation(); return; }

      if (e.ctrlKey || e.metaKey || e.altKey) return;
      if (this.ctx.seleccion?.construccion) return;      // el emplazado manda

      const letra = code.startsWith('Key') ? code.slice(3) : '';
      if (!letra) return;
      const ranura = TECLAS.indexOf(letra);
      if (ranura >= 0 && this.acciones[ranura]) {
        this._activarRanura(ranura, e.shiftKey);
        this._parpadeo(ranura);
        e.preventDefault(); e.stopPropagation();
        return;
      }
      if (letra === 'T') { this.abrirMenu('arbol'); e.preventDefault(); e.stopPropagation(); }
    }, true);

    window.addEventListener('blur', () => this._ocultarTooltip());
    window.addEventListener('resize', () => this._ocultarTooltip());
  }

  /* ================================================================== *
   *  Barra superior
   * ================================================================== */

  _refrescarValores(forzar) {
    const ctx = this.ctx;
    const j = this.jug;
    const r = ctx.eco?.recursos?.[j];
    const stats = ctx.eco?.estadisticas?.(j);

    for (let i = 0; i < 4; i++) {
      const k = CLAVES_RECURSO[i];
      const n = this.recursoNodo[i];
      const v = r ? Math.floor(r[k]) : 0;
      fijarTexto(n.cant, String(v));
      const tasa = stats?.tasaPorMinuto?.[k] ?? 0;
      fijarTexto(n.tasa, `${tasa > 0 ? '+' : ''}${tasa}/min`);
      n.tasa.classList.toggle('sube', tasa > 0);
      n.caja.classList.toggle('escaso', v < 40);
    }

    const pob = ctx.eco?.pob?.[j];
    if (pob) {
      fijarTexto(this.pobCant, `${pob.actual | 0}/${pob.tope | 0}`);
      this.pobCaja.classList.toggle('topado', pob.actual >= pob.tope && pob.tope > 0);
    }

    fijarTexto(this.relojNodo, reloj(ctx.mundo?.tiempo || 0));

    if (this._diagVisible || forzar) {
      const s = ctx.motor?.stats;
      if (s) {
        fijarTexto(this.diagFps, `${s.fps | 0} FPS · ${s.ms.toFixed(1)} ms`);
        fijarTexto(this.diagDib, `${s.dibujos | 0} draws · ${(s.triangulos / 1000) | 0}k tri`);
      }
    }

    const edadActual = ctx.edades?.edad?.[j];
    if (edadActual != null && edadActual !== this.edad) this._aplicarEdad(edadActual);
  }

  _alternarDiag() {
    this._diagVisible = !this._diagVisible;
    this.diag.classList.toggle('visible', this._diagVisible);
  }

  _aplicarEdad(n, inmediato = false) {
    const e = EDADES[n] || EDADES[0];
    this.edad = n | 0;
    document.body.dataset.edad = String(this.edad);
    fijarTexto(this.nombreEdad, e.nombre);
    fijarTexto(this.rangoEdad, e.rango);
    if (inmediato) {
      document.body.classList.add('sin-trans');
      requestAnimationFrame(() => document.body.classList.remove('sin-trans'));
    }
    this._refrescarCiv();
    if (this._arbolArmado) this._marcarArbol();
  }

  _refrescarCiv() {
    const clave = this.ctx.edades?.civDe?.(this.jug);
    const idx = clave != null ? (CIV_POR_CLAVE.get(clave) ?? 0) : 0;
    this.escudo.src = escudoCiv(idx, this._colorJugador(this.jug));
    this.escudo.alt = CIVILIZACIONES[idx]?.nombre || '';
  }

  _colorJugador(j) {
    const civ = this.ctx.edades?.defCiv?.(j);
    return COLORES_JUGADOR[j % COLORES_JUGADOR.length] || civ?.color || '#8a8a8a';
  }

  /* ================================================================== *
   *  Panel de selección
   * ================================================================== */

  _pintarFicha(id) {
    const w = this.ctx.mundo;
    const esEd = w.tipo[id] === TIPO.EDIFICIO;
    const def = esEd ? EDIFICIOS[w.defId[id]] : UNIDADES[w.defId[id]];
    if (!def) return;
    const j = w.jugador[id];
    const color = j === 255 ? '#b8b0a0' : this._colorJugador(j);

    this._marcaSel = id;
    this.retratoUno.style.backgroundImage = `url(${retrato({ tipo: esEd ? 'edificio' : 'unidad', clave: def.clave, edad: this.edad, color })})`;
    fijarTexto(this.selNombre, def.nombre);

    let sub;
    if (j === this.jug) sub = esEd ? 'Tu edificio' : (NOMBRE_CLASE[def.clase] || 'Unidad');
    else if (j === 255) sub = 'Neutral';
    else sub = `Jugador ${j + 1} · ${NOMBRE_CLASE[def.clase] || 'Edificio'}`;
    if (esEd && w.estado[id] === ESTADO.CONSTRUYENDO) sub = `En obra · ${Math.round((w.progreso[id] || 0) * 100)}%`;
    fijarTexto(this.selSub, sub);

    this.selStats.textContent = '';
    const estad = (etiqueta, valor) => {
      if (valor === null || valor === undefined || valor === '') return;
      const d = el('div', 'est');
      d.appendChild(el('u', null, etiqueta));
      d.appendChild(el('b', null, String(valor)));
      this.selStats.appendChild(d);
    };
    const mods = this.ctx.eco?.mods?.[j];
    const bono = (grupo, clave) => (mods && mods[grupo] && mods[grupo][clave]) || 0;
    if (esEd) {
      if (def.ataque) estad('Ataque', def.ataque + bono('ataque', 'edificio'));
      if (def.alcance) estad('Alcance', def.alcance + bono('alcance', 'edificio'));
      estad('Armadura', `${def.armadura}/${def.armaduraPerf}`);
      estad('Visión', def.vision);
      if (def.pop) estad('Población', `+${def.pop}`);
    } else {
      const fam = def.clase === 'aldeano' ? 'aldeano' : (def.clase === 'tirador' ? 'tirador' : (def.clase === 'caballeria' ? 'caballeria' : (def.clase === 'asedio' ? 'asedio' : 'infanteria')));
      if (def.ataque) estad('Ataque', def.ataque + bono('ataque', fam));
      if (def.alcance >= 2) estad('Alcance', (def.alcance + bono('alcance', fam)).toFixed(1));
      estad('Armadura', `${def.armadura + bono('armadura', fam)}/${def.armaduraPerf + bono('armaduraPerf', fam)}`);
      estad('Velocidad', `${def.velocidad.toFixed(1)} m/s`);
      estad('Visión', def.vision);
    }
    fijarTexto(this.selDesc, def.descripcion || '');

    this._pintarExtra(id, def, esEd);
    this._refrescarFichaViva();
    this._refrescarCola();
  }

  /** Columna derecha: cola de producción (edificios) o comportamiento (unidades). */
  _pintarExtra(id, def, esEd) {
    const w = this.ctx.mundo;
    const propio = w.jugador[id] === this.jug;
    this.chips.textContent = '';

    if (esEd && propio) {
      fijarTexto(this.extraTit, 'Producción');
      this.cajaCola.style.display = '';
      const r = this.ctx.ordenes?.reunionDe?.(id);
      this._chip('Reunión', r ? `${Math.round(r.x)}, ${Math.round(r.z)}` : 'sin fijar');
      if (def.deposito?.length) {
        this._chip('Deposita', def.deposito.map((k) => RECURSOS[IDX_RECURSO[k]]?.nombre || k).join(', '));
      }
      if (def.entrena?.length) {
        const dis = this._entrenables(def).map((u) => u.nombre).join(', ');
        this._chip('Entrena', dis || 'nada todavía');
      }
      if (def.guarnicion) this._chip('Refugia', `hasta ${def.guarnicion}`);
      return;
    }

    this.cajaCola.style.display = 'none';
    fijarTexto(this.extraTit, esEd ? 'Ficha del edificio' : 'Comportamiento');

    if (esEd) {
      this._chip('Tamaño', `${def.celdas[0] * 2} × ${def.celdas[1] * 2} m`);
      if (def.pop) this._chip('Población', `+${def.pop}`);
      if (def.entrena?.length) this._chip('Entrena', this._entrenables(def).map((u) => u.nombre).join(', ') || '—');
      return;
    }

    if (propio) {
      const p = this.ctx.combate?.posturaDe?.(id);
      if (p) this._chip('Postura', POSTURAS.find((x) => x.modo === p)?.nombre.replace('Postura ', '') || p);
      const f = w.meta.get(id)?.formacion;
      if (f) this._chip('Formación', FORMACIONES.find((x) => x.clave === f)?.nombre.replace('Formación en ', '') || f);
      if (def.clase === 'aldeano') {
        const carga = w.cargaCant[id] | 0;
        if (carga) this._chip('Carga', `${carga} de ${RECURSOS[w.cargaTipo[id]]?.nombre || '—'}`);
      }
    }
    const fuerte = this._fuerteContra(def);
    if (fuerte) this._chip('Fuerte contra', fuerte, 'ok');
    const debil = this._debilContra(def);
    if (debil) this._chip('Débil contra', debil, 'mal');
  }

  _chip(etiqueta, valor, tono) {
    const d = el('div', tono ? `chip ${tono}` : 'chip');
    d.appendChild(el('u', null, etiqueta));
    d.appendChild(el('b', null, valor));
    this.chips.appendChild(d);
  }

  /** Sólo los números que cambian solos: vida, obra y cola. */
  _refrescarFichaViva() {
    const w = this.ctx.mundo;
    const id = this._marcaSel;
    if (this.seleccionados.length === 1 && id >= 0 && w?.vivo?.[id]) {
      const vida = Math.max(0, Math.ceil(w.vida[id]));
      const max = Math.max(1, Math.ceil(w.vidaMax[id] || vida));
      const f = Math.max(0, Math.min(1, vida / max));
      this.barraVidaFill.style.width = `${(f * 100).toFixed(1)}%`;
      this.barraVida.classList.toggle('media', f <= 0.6 && f > 0.3);
      this.barraVida.classList.toggle('baja', f <= 0.3);
      fijarTexto(this.barraVidaTxt, `${vida} / ${max}`);
      if (w.tipo[id] === TIPO.EDIFICIO) this._refrescarCola();
    } else if (this.seleccionados.length > 1) {
      for (const g of this.grupos) {
        if (!g.barra) continue;
        let suma = 0, tope = 0;
        for (const e of g.ids) { if (!w.vivo[e]) continue; suma += w.vida[e]; tope += w.vidaMax[e] || 1; }
        g.barra.style.width = `${tope ? Math.max(0, Math.min(100, (suma / tope) * 100)).toFixed(0) : 0}%`;
      }
    }
  }

  _pintarGrupos(lista) {
    const w = this.ctx.mundo;
    const mapa = new Map();
    for (const id of lista) {
      const esEd = w.tipo[id] === TIPO.EDIFICIO;
      const clave = `${esEd ? 'e' : 'u'}${w.defId[id]}`;
      let g = mapa.get(clave);
      if (!g) {
        const def = esEd ? EDIFICIOS[w.defId[id]] : UNIDADES[w.defId[id]];
        if (!def) continue;
        g = { def, esEd, ids: [], jugador: w.jugador[id] };
        mapa.set(clave, g);
      }
      g.ids.push(id);
    }

    this.grupos = [...mapa.values()].sort((a, b) => b.ids.length - a.ids.length);
    fijarTexto(this.tituloSel, `Selección · ${lista.length} · ${this.grupos.length} tipo${this.grupos.length > 1 ? 's' : ''}`);
    this.gridVarios.textContent = '';

    for (const g of this.grupos) {
      const color = g.jugador === 255 ? '#b8b0a0' : this._colorJugador(g.jugador);
      const t = el('button', 'tarjeta-tipo');
      t.type = 'button';
      t.tabIndex = -1;
      t.style.backgroundImage = `url(${retrato({ tipo: g.esEd ? 'edificio' : 'unidad', clave: g.def.clave, edad: this.edad, color }, 96)})`;
      t.appendChild(el('span', 'n', String(g.ids.length)));
      const v = el('span', 'vida');
      const vi = el('i');
      v.appendChild(vi);
      t.appendChild(v);
      g.barra = vi;
      t.addEventListener('click', (e) => {
        if (e.shiftKey) {
          const resto = this.seleccionados.filter((id) => !g.ids.includes(id));
          this.ctx.seleccion?.seleccionar?.(resto.length ? resto : g.ids, false);
        } else {
          this.ctx.seleccion?.seleccionar?.(g.ids, false);
        }
      });
      this._tooltipEn(t, () => ({
        titulo: g.def.nombre,
        subtitulo: `${g.ids.length} en la selección`,
        desc: g.def.descripcion,
        nota: 'Click: quedarte sólo con este tipo · Shift+click: sacarlo de la selección',
      }));
      this.gridVarios.appendChild(t);
    }
    this._refrescarFichaViva();
  }

  _esSeleccionado(id) { return id != null && this.seleccionados.length === 1 && this.seleccionados[0] === id; }

  _refrescarCola() {
    const w = this.ctx.mundo;
    const id = this.seleccionados.length === 1 ? this.seleccionados[0] : -1;
    if (id < 0 || !w?.vivo?.[id] || w.tipo[id] !== TIPO.EDIFICIO || w.jugador[id] !== this.jug) {
      this.cajaCola.classList.remove('on');
      return;
    }

    const cola = this._colaDe(id);
    const invest = this.ctx.edades?.enProgreso?.(id);
    const enObra = w.estado[id] === ESTADO.CONSTRUYENDO;

    if (!cola.length && !invest && !enObra) { this.cajaCola.classList.remove('on'); return; }
    this.cajaCola.classList.add('on');

    const items = [];
    if (invest) items.push({ tipo: 'tecno', clave: invest.clave, progreso: invest.progreso });
    for (const it of cola) items.push(it);

    for (let i = 0; i < this.colaItems.length; i++) {
      const slot = this.colaItems[i];
      const it = items[i];
      if (!it) { slot.nodo.style.display = 'none'; continue; }
      slot.nodo.style.display = '';
      const url = retrato({ tipo: it.tipo === 'tecno' ? 'tecno' : 'unidad', clave: it.clave, edad: this.edad, color: this._colorJugador(this.jug) }, 64);
      if (slot.nodo.dataset.k !== url) { slot.nodo.style.backgroundImage = `url(${url})`; slot.nodo.dataset.k = url; }
      const p = it.progreso != null ? it.progreso : (it.total ? 1 - it.restante / it.total : 0);
      slot.prog.style.width = `${Math.max(0, Math.min(1, p)) * 100}%`;
      slot.nodo.classList.toggle('act', i === 0);
      slot.nodo.title = 'Click derecho para cancelar';
    }

    let progreso = 0, texto = '';
    if (enObra) {
      progreso = w.progreso[id] || 0;
      texto = `En obra · ${Math.round(progreso * 100)}%`;
    } else if (items.length) {
      const it = items[0];
      progreso = it.progreso != null ? it.progreso : (it.total ? 1 - it.restante / it.total : (w.progreso[id] || 0));
      const nombre = it.tipo === 'tecno'
        ? (TECNOLOGIAS[TECNO_POR_CLAVE.get(it.clave)]?.nombre || it.clave)
        : (defUnidad(it.clave)?.nombre || it.clave);
      const resta = it.restante != null ? ` · ${Math.max(0, it.restante).toFixed(0)} s` : '';
      texto = `${nombre}${resta}${items.length > 1 ? ` (+${items.length - 1})` : ''}`;
    }
    this.colaBarraFill.style.width = `${Math.max(0, Math.min(1, progreso)) * 100}%`;
    fijarTexto(this.colaTxt, texto);
  }

  _colaDe(id) {
    const meta = this.ctx.mundo?.meta?.get(id);
    if (meta?.cola?.length) return meta.cola;
    const propia = this.ctx.ordenes?.produccionPropia?.get?.(id);
    if (propia?.length) return propia;
    return [];
  }

  _cancelarCola(indice) {
    const id = this.seleccionados.length === 1 ? this.seleccionados[0] : -1;
    if (id < 0) return;
    const invest = this.ctx.edades?.enProgreso?.(id);
    if (invest && indice === 0) { this.aviso('La investigación en curso no se puede cancelar.', 'alerta'); return; }
    const i = invest ? indice - 1 : indice;
    if (this.ctx.produccion?.cancelar) this.ctx.produccion.cancelar(id, i);
    else this.ctx.ordenes?.cancelarProduccion?.(id, i);
    this._refrescarCola();
  }

  /* ================================================================== *
   *  Grilla de acciones
   * ================================================================== */

  _reconstruirAcciones() {
    const lista = this._armarAcciones();
    for (let i = 0; i < RANURAS; i++) {
      const acc = lista[i] || null;
      this.acciones[i] = acc;
      const b = this.botones[i];
      if (!acc) {
        b.nodo.classList.add('oculto');
        b.nodo.classList.remove('on', 'no');
        b.nodo.style.backgroundImage = '';
        b.nodo.dataset.k = '';
        b.nodo.tabIndex = -1;
        b.costes.textContent = '';
        b.pastilla.textContent = '';
        b.prog.style.width = '0';
        continue;
      }
      b.nodo.classList.remove('oculto');
      const url = retrato(acc.icono, 96);
      if (b.nodo.dataset.k !== url) { b.nodo.style.backgroundImage = `url(${url})`; b.nodo.dataset.k = url; }
      b.nodo.classList.toggle('on', !!acc.activo);
      b.pastilla.textContent = acc.pastilla || '';
      b.prog.style.width = acc.progreso ? `${acc.progreso * 100}%` : '0';
      b.nodo.setAttribute('aria-label', acc.nombre);
      b.nodo.tabIndex = 0;
      this._pintarCostesBoton(b, acc);
    }
    this._refrescarCostes();
  }

  _pintarCostesBoton(b, acc) {
    b.costes.textContent = '';
    if (!acc.coste) return;
    for (let i = 0; i < 4; i++) {
      const k = CLAVES_RECURSO[i];
      const v = acc.coste[k] | 0;
      if (!v) continue;
      const s = el('span');
      const pip = el('i');
      pip.style.background = RECURSOS[i].color;
      s.append(pip, document.createTextNode(String(v)));
      b.costes.appendChild(s);
    }
  }

  /** Repinta en rojo lo que no podés pagar, sin rearmar la grilla. */
  _refrescarCostes() {
    const eco = this.ctx.eco;
    if (!eco) return;
    const r = eco.recursos?.[this.jug];
    if (!r) return;
    for (let i = 0; i < RANURAS; i++) {
      const acc = this.acciones[i];
      const b = this.botones[i];
      if (!acc) continue;
      let bloqueado = !!acc.bloqueado;
      if (acc.coste) {
        const hijos = b.costes.children;
        let k = 0;
        for (let n = 0; n < 4; n++) {
          const clave = CLAVES_RECURSO[n];
          const v = acc.coste[clave] | 0;
          if (!v) continue;
          const nodo = hijos[k++];
          if (!nodo) continue;
          const falta = r[clave] < v;
          nodo.classList.toggle('falta', falta);
          if (falta) bloqueado = true;
        }
      }
      b.nodo.classList.toggle('no', bloqueado);
    }
  }

  _armarAcciones() {
    const ctx = this.ctx, w = ctx.mundo;
    const lista = this.seleccionados.filter((id) => w.vivo[id] && w.jugador[id] === this.jug);
    if (!lista.length) return [];

    /* páginas de construcción */
    if (this.pagina) {
      const claves = this.pagina === 'civil' ? EDIFICIOS_CIVILES : EDIFICIOS_MILITARES;
      const salida = [];
      for (const clave of claves) {
        const def = defEdificio(clave);
        if (!def || def.edad > this.edad) continue;
        salida.push(this._accEdificio(def));
        if (salida.length >= RANURAS - 1) break;
      }
      while (salida.length < RANURAS - 1) salida.push(null);
      salida[RANURAS - 1] = {
        nombre: 'Volver', icono: { tipo: 'glifo', clave: 'atras', edad: this.edad },
        tt: { titulo: 'Volver', desc: 'Salir del menú de construcción.' },
        ejecutar: () => { this.pagina = null; ctx.seleccion?.modoConstruccion?.(null); this._reconstruirAcciones(); },
      };
      return salida;
    }

    const unicos = lista[0];
    const soloUno = lista.length === 1;

    /* un edificio */
    if (soloUno && w.tipo[unicos] === TIPO.EDIFICIO) return this._accionesEdificio(unicos);

    /* unidades */
    const salida = [];
    const hayColono = lista.some((id) => w.tipo[id] === TIPO.UNIDAD && UNIDADES[w.defId[id]]?.clase === 'aldeano');
    const hayMilitar = lista.some((id) => {
      const d = w.tipo[id] === TIPO.UNIDAD ? UNIDADES[w.defId[id]] : null;
      return d && d.clase !== 'aldeano' && d.ataque > 0;
    });

    if (hayColono) {
      salida.push({
        nombre: 'Edificios civiles', icono: { tipo: 'glifo', clave: 'casa', edad: this.edad },
        tt: { titulo: 'Edificios civiles', desc: 'Viviendas, granjas, acopios, mercado, instituto. Todo lo que hace crecer al imperio.', tecla: 'Q' },
        ejecutar: () => { this.pagina = 'civil'; this._reconstruirAcciones(); },
      });
      salida.push({
        nombre: 'Edificios militares', icono: { tipo: 'glifo', clave: 'espadas', edad: this.edad },
        tt: { titulo: 'Edificios militares', desc: 'Cuartel, polígono, establo, taller, torretas y ciudadela.', tecla: 'W' },
        ejecutar: () => { this.pagina = 'militar'; this._reconstruirAcciones(); },
      });
    }

    salida.push({
      nombre: 'Detener', icono: { tipo: 'glifo', clave: 'detener', edad: this.edad },
      tt: { titulo: 'Detener', desc: 'Cancela todas las órdenes pendientes y planta a la unidad donde está.' },
      ejecutar: () => { ctx.ordenes?.cancelar?.(lista); this.aviso('Órdenes canceladas', 'info'); },
    });

    if (hayMilitar) {
      salida.push({
        nombre: 'Patrullar', icono: { tipo: 'glifo', clave: 'patrulla', edad: this.edad },
        tt: { titulo: 'Patrullar', desc: 'Ida y vuelta entre su posición y el centro de la vista. Movés la cámara al destino y apretás.' },
        ejecutar: () => {
          const f = ctx.camCtrl?.foco;
          if (!f) return;
          ctx.ordenes?.patrullar?.(lista, f.x, f.z);
          this.aviso('Patrulla en marcha', 'info');
        },
      });

      const posturaActual = ctx.combate?.posturaDe?.(lista[0]);
      for (const p of POSTURAS) {
        salida.push({
          nombre: p.nombre, icono: { tipo: 'glifo', clave: p.glifo, edad: this.edad },
          activo: posturaActual === p.modo,
          tt: { titulo: p.nombre, desc: p.desc, etiqueta: 'Postura' },
          ejecutar: () => {
            if (ctx.combate?.postura) ctx.combate.postura(lista, p.modo);
            else if (p.modo === 'quieta') ctx.ordenes?.mantenerPosicion?.(lista);
            this._reconstruirAcciones();
          },
        });
      }

      const formaActual = ctx.mundo.meta.get(lista[0])?.formacion;
      for (const f of FORMACIONES) {
        salida.push({
          nombre: f.nombre, icono: { tipo: 'glifo', clave: f.glifo, edad: this.edad },
          activo: formaActual === f.clave,
          tt: { titulo: f.nombre, desc: f.desc, etiqueta: 'Formación' },
          ejecutar: () => this._formar(lista, f.clave),
        });
      }
    }

    return salida;
  }

  _accionesEdificio(id) {
    const ctx = this.ctx, w = ctx.mundo;
    const def = EDIFICIOS[w.defId[id]];
    if (!def) return [];
    const salida = [];

    if (w.estado[id] === ESTADO.CONSTRUYENDO) {
      salida.push({
        nombre: 'Obra en curso', icono: { tipo: 'glifo', clave: 'reparar', edad: this.edad },
        bloqueado: true, progreso: w.progreso[id] || 0,
        tt: { titulo: def.nombre, subtitulo: 'En construcción', desc: 'Mandá más colonos para que termine antes.' },
        ejecutar: () => {},
      });
      return salida;
    }

    for (const u of this._entrenables(def)) salida.push(this._accUnidad(id, u));

    const tecnos = ctx.edades?.tecnosDe?.(this.jug, def.clave) || [];
    for (const t of tecnos) {
      if (t.edad > this.edad) continue;
      salida.push(this._accTecno(id, t));
    }

    if (def.clave === 'sede' && this.edad < EDADES.length - 1) {
      const prox = EDADES[this.edad + 1];
      const coste = ctx.edades?.costeAvance?.(this.jug) || prox.coste;
      const enCurso = (ctx.edades?.progresoAvance?.[this.jug] || 0) > 0;
      salida.push({
        nombre: `Avanzar a la ${prox.nombre}`,
        icono: { tipo: 'glifo', clave: 'edad', edad: this.edad },
        coste, activo: enCurso,
        progreso: enCurso ? ctx.edades.progresoAvance[this.jug] : 0,
        tt: {
          titulo: `Avanzar a la ${prox.nombre}`, subtitulo: prox.rango,
          coste, tiempo: prox.tiempo, desc: prox.bonos,
          extra: prox.lema,
        },
        ejecutar: () => ctx.edades?.avanzar?.(this.jug),
      });
    }

    salida.push({
      nombre: 'Punto de reunión', icono: { tipo: 'glifo', clave: 'bandera', edad: this.edad },
      tt: { titulo: 'Punto de reunión', desc: 'Todo lo que salga de acá se junta en el centro de la vista. También podés fijarlo con click derecho en el mapa.' },
      ejecutar: () => {
        const f = ctx.camCtrl?.foco;
        if (!f) return;
        ctx.ordenes?.puntoReunion?.(id, f.x, f.z);
        this.aviso('Punto de reunión fijado', 'info');
      },
    });

    const dentro = ctx.ordenes?.guarnicionDe?.(id) || 0;
    if (dentro > 0) {
      salida.push({
        nombre: 'Desalojar', icono: { tipo: 'glifo', clave: 'salir', edad: this.edad },
        pastilla: String(dentro),
        tt: { titulo: 'Desalojar', desc: `Sacá afuera a las ${dentro} unidad(es) refugiadas adentro.` },
        ejecutar: () => ctx.ordenes?.desalojar?.(id),
      });
    }

    return salida;
  }

  /** De cada línea de unidades, sólo la mejor que ya tengas habilitada. */
  _entrenables(defEd) {
    const porLinea = new Map();
    for (const clave of defEd.entrena || []) {
      const u = defUnidad(clave);
      if (!u || u.edad > this.edad) continue;
      const k = u.linea || clave;
      const prev = porLinea.get(k);
      if (!prev || u.edad > prev.edad) porLinea.set(k, u);
    }
    return [...porLinea.values()];
  }

  _accUnidad(edificioId, def) {
    const ctx = this.ctx;
    const coste = ctx.eco?.costeUnidad?.(this.jug, def) || def.coste;
    return {
      nombre: def.nombre,
      icono: { tipo: 'unidad', clave: def.clave, edad: this.edad, color: this._colorJugador(this.jug) },
      coste,
      tt: {
        titulo: def.nombre, subtitulo: NOMBRE_CLASE[def.clase] || '',
        coste, tiempo: def.tiempo, pop: def.pop, desc: def.descripcion,
        unidad: def,
      },
      ejecutar: (shift) => ctx.ordenes?.entrenar?.(edificioId, def.clave, shift ? 5 : 1),
    };
  }

  _accTecno(edificioId, def) {
    const ctx = this.ctx;
    const coste = ctx.edades?.costeTecno?.(this.jug, def.clave) || def.coste;
    const curso = ctx.edades?.enProgreso?.(edificioId);
    const activa = curso && curso.clave === def.clave;
    return {
      nombre: def.nombre,
      icono: { tipo: 'tecno', clave: def.clave, edad: this.edad },
      coste: activa ? null : coste,
      activo: !!activa,
      progreso: activa ? curso.progreso : 0,
      tt: {
        titulo: def.nombre, subtitulo: 'Tecnología',
        coste, tiempo: def.tiempo, desc: def.descripcion,
        extra: activa ? `Investigando… faltan ${Math.ceil(curso.restante)} s` : null,
      },
      ejecutar: () => {
        if (activa) return;
        if (ctx.edades?.investigar) ctx.edades.investigar(this.jug, def.clave, edificioId);
        else ctx.ordenes?.investigar?.(edificioId, def.clave);
      },
    };
  }

  _accEdificio(def) {
    const ctx = this.ctx;
    const coste = ctx.eco?.costeEdificio?.(this.jug, def.clave) || def.coste;
    return {
      nombre: def.nombre,
      icono: { tipo: 'edificio', clave: def.clave, edad: this.edad, color: this._colorJugador(this.jug) },
      coste,
      tt: {
        titulo: def.nombre, subtitulo: `Edificio · ${def.celdas[0] * 2}×${def.celdas[1] * 2} m`,
        coste, tiempo: def.tiempo, desc: def.descripcion, edificio: def,
      },
      ejecutar: () => {
        if (ctx.seleccion?.modoConstruccion?.(def.clave)) this.pagina = null;
        this._reconstruirAcciones();
      },
    };
  }

  _activarRanura(i, shift = false, derecho = false) {
    const acc = this.acciones[i];
    if (!acc || acc.bloqueado) return;
    if (derecho) {
      // click derecho sobre un entrenamiento = cancelar el último de la cola
      const id = this.seleccionados.length === 1 ? this.seleccionados[0] : -1;
      if (id >= 0) this._cancelarCola(this._colaDe(id).length - 1 + (this.ctx.edades?.enProgreso?.(id) ? 1 : 0));
      return;
    }
    acc.ejecutar?.(shift);
    this.ctx.audio?.sfx?.('ui_click');
    if (acc.coste) this._refrescarCostes();
  }

  _parpadeo(i) {
    const n = this.botones[i]?.nodo;
    if (!n) return;
    n.style.transform = 'translateY(-3px)';
    setTimeout(() => { n.style.transform = ''; }, 110);
  }

  /** Reparte a las unidades en la forma elegida alrededor de su centro. */
  _formar(ids, forma) {
    const ctx = this.ctx, w = ctx.mundo;
    const vivos = ids.filter((id) => w.vivo[id] && w.tipo[id] === TIPO.UNIDAD);
    if (!vivos.length) return;
    let cx = 0, cz = 0;
    for (const id of vivos) { cx += w.px[id]; cz += w.pz[id]; }
    cx /= vivos.length; cz /= vivos.length;

    const ang = ctx.camCtrl?.azimut ?? 0;
    const ca = Math.cos(ang), sa = Math.sin(ang);
    const paso = forma === 'dispersa' ? 4.2 : 2.3;
    const n = vivos.length;
    const cols = forma === 'linea' ? Math.ceil(n / 2) : Math.ceil(Math.sqrt(n));

    for (let i = 0; i < n; i++) {
      let ox = 0, oz = 0;
      if (forma === 'cuna') {
        const fila = Math.floor((Math.sqrt(8 * i + 1) - 1) / 2);
        const enFila = i - (fila * (fila + 1)) / 2;
        ox = (enFila - fila / 2) * paso;
        oz = fila * paso * 0.9;
      } else {
        const fila = Math.floor(i / cols);
        const col = i % cols;
        ox = (col - (cols - 1) / 2) * paso;
        oz = (fila - Math.floor((n - 1) / cols) / 2) * paso;
      }
      const x = cx + ox * ca - oz * sa;
      const z = cz + ox * sa + oz * ca;
      const meta = w.meta.get(vivos[i]) || (w.meta.set(vivos[i], {}), w.meta.get(vivos[i]));
      meta.formacion = forma;
      ctx.ordenes?.mover?.([vivos[i]], x, z, false);
    }
    bus.emit('formacion:cambio', { ids: vivos, formacion: forma });
    this.aviso(FORMACIONES.find((f) => f.clave === forma)?.nombre || 'Formación', 'info');
    this._reconstruirAcciones();
  }

  /* ================================================================== *
   *  Tooltips
   * ================================================================== */

  _tooltipEn(nodo, generar) {
    nodo.addEventListener('pointerenter', () => {
      this._ttNodo = nodo;
      this._mostrarTooltip(nodo, generar());
    });
    nodo.addEventListener('pointerleave', () => {
      if (this._ttNodo === nodo) this._ocultarTooltip();
    });
    nodo.addEventListener('focus', () => this._mostrarTooltip(nodo, generar()));
    nodo.addEventListener('blur', () => this._ocultarTooltip());
  }

  _ttAccion(i) {
    const acc = this.acciones[i];
    if (!acc) return null;
    const t = Object.assign({}, acc.tt || { titulo: acc.nombre });
    t.tecla = t.tecla || TECLAS[i];
    if (!t.coste && acc.coste) t.coste = acc.coste;
    return t;
  }

  _ttRecurso(i) {
    const def = RECURSOS[i];
    const j = this.jug;
    const stats = this.ctx.eco?.estadisticas?.(j);
    const nombreEdad = def.porEdad?.[this.edad] || def.nombre;
    return {
      titulo: def.nombre,
      subtitulo: `En esta edad: ${nombreEdad}`,
      desc: `Recolectado en total: ${Math.round(stats?.recolectado?.[def.clave] || 0)}. Gastado: ${Math.round(stats?.gastado?.[def.clave] || 0)}.`,
      extra: `Ritmo actual: ${stats?.tasaPorMinuto?.[def.clave] || 0} por minuto.`,
    };
  }

  _ttPoblacion() {
    const pob = this.ctx.eco?.pob?.[this.jug];
    const ociosos = this.ctx.eco?.colonosOciosos?.(this.jug) ?? 0;
    return {
      titulo: 'Población',
      subtitulo: pob ? `${pob.actual | 0} de ${pob.tope | 0}` : '',
      desc: 'Cada Vivienda suma 5 y la Sede Municipal, 5 más. Si te topás, no entrenás nada.',
      extra: `Colonos ociosos: ${ociosos}. Con «.» saltás de uno a otro.`,
    };
  }

  _ttCivilizacion() {
    const civ = this.ctx.edades?.defCiv?.(this.jug) || CIVILIZACIONES[0];
    const e = EDADES[this.edad];
    return {
      titulo: civ.nombre,
      subtitulo: `${e.nombre} · ${e.rango}`,
      desc: civ.bono,
      extra: `Unidad única: ${civ.unica?.nombre}. Bono de equipo: ${civ.equipo}`,
    };
  }

  _mostrarTooltip(nodo, datos) {
    if (!datos) return;
    const t = this.tooltip;
    t.textContent = '';

    const tit = el('div', 'tt-tit');
    tit.appendChild(el('span', null, datos.titulo || ''));
    if (datos.tecla) tit.appendChild(el('em', null, `Tecla ${datos.tecla}`));
    else if (datos.etiqueta) tit.appendChild(el('em', null, datos.etiqueta));
    t.appendChild(tit);
    if (datos.subtitulo) {
      const s = el('div', 'tt-tag');
      s.style.color = 'var(--c-tenue)';
      s.textContent = datos.subtitulo;
      t.appendChild(s);
    }

    if (datos.coste) {
      const r = this.ctx.eco?.recursos?.[this.jug];
      const caja = el('div', 'tt-costes');
      let algo = false;
      for (let i = 0; i < 4; i++) {
        const k = CLAVES_RECURSO[i];
        const v = datos.coste[k] | 0;
        if (!v) continue;
        algo = true;
        const s = el('span', r && r[k] < v ? 'falta' : null);
        const pip = el('i');
        pip.style.background = RECURSOS[i].color;
        s.append(pip, el('span', null, `${v} ${RECURSOS[i].nombre}`));
        caja.appendChild(s);
      }
      if (datos.tiempo) { caja.appendChild(el('span', null, `⏱ ${datos.tiempo} s`)); algo = true; }
      if (datos.pop) caja.appendChild(el('span', null, `Población ${datos.pop}`));
      if (algo) t.appendChild(caja);
    } else if (datos.tiempo) {
      const caja = el('div', 'tt-costes');
      caja.appendChild(el('span', null, `⏱ ${datos.tiempo} s`));
      t.appendChild(caja);
    }

    if (datos.desc) t.appendChild(el('div', 'tt-desc', datos.desc));

    const u = datos.unidad;
    if (u) {
      t.appendChild(el('div', 'tt-linea'));
      const st = el('div', 'tt-stats');
      const par = (a, b) => { const d = el('span'); d.append(document.createTextNode(a + ' '), el('b', null, String(b))); st.appendChild(d); };
      par('Vida', u.vida);
      if (u.ataque) par('Ataque', u.ataque);
      if (u.alcance >= 2) par('Alcance', u.alcance);
      par('Armadura', `${u.armadura}/${u.armaduraPerf}`);
      par('Velocidad', u.velocidad);
      t.appendChild(st);

      const fuerte = this._fuerteContra(u);
      if (fuerte) {
        const f = el('div', 'tt-tag');
        f.append(document.createTextNode('Fuerte contra: '), el('b', null, fuerte));
        t.appendChild(f);
      }
      const debil = this._debilContra(u);
      if (debil) {
        const d = el('div', 'tt-tag mal');
        d.append(document.createTextNode('Débil contra: '), el('b', null, debil));
        t.appendChild(d);
      }
    }

    const ed = datos.edificio;
    if (ed) {
      t.appendChild(el('div', 'tt-linea'));
      const st = el('div', 'tt-stats');
      const par = (a, b) => { const d = el('span'); d.append(document.createTextNode(a + ' '), el('b', null, String(b))); st.appendChild(d); };
      par('Vida', ed.vida);
      par('Armadura', `${ed.armadura}/${ed.armaduraPerf}`);
      par('Visión', ed.vision);
      if (ed.pop) par('Población', `+${ed.pop}`);
      if (ed.ataque) par('Ataque', ed.ataque);
      t.appendChild(st);
      if (ed.entrena?.length) {
        const dis = this._entrenables(ed).map((x) => x.nombre).join(', ');
        if (dis) {
          const f = el('div', 'tt-tag');
          f.append(document.createTextNode('Entrena: '), el('b', null, dis));
          t.appendChild(f);
        }
      }
    }

    if (datos.extra) t.appendChild(el('div', 'tt-nota', datos.extra));
    if (datos.nota) t.appendChild(el('div', 'tt-nota', datos.nota));

    t.classList.add('on');
    this._ubicarTooltip(nodo);
  }

  _ubicarTooltip(nodo) {
    const t = this.tooltip;
    const r = nodo.getBoundingClientRect();
    t.style.left = '0px'; t.style.top = '0px';
    const b = t.getBoundingClientRect();
    let x = r.left + r.width / 2 - b.width / 2;
    let y = r.top - b.height - 10;
    if (y < 8) y = r.bottom + 10;
    x = Math.max(8, Math.min(window.innerWidth - b.width - 8, x));
    y = Math.max(8, Math.min(window.innerHeight - b.height - 8, y));
    t.style.left = `${Math.round(x)}px`;
    t.style.top = `${Math.round(y)}px`;
  }

  _ocultarTooltip() {
    this._ttNodo = null;
    this.tooltip.classList.remove('on');
  }

  _fuerteContra(u) {
    if (!u.bonos) return '';
    const claves = Object.keys(u.bonos).filter((k) => u.bonos[k] >= 6);
    if (!claves.length) return '';
    return claves.map((k) => NOMBRE_CLASE[k] || k).join(', ');
  }

  _debilContra(u) {
    const porLinea = AMENAZAS.get(u.clase);
    if (!porLinea) return '';
    const nombres = [];
    for (const [, def] of porLinea) {
      if (def.linea === u.linea) continue;
      // mostramos el escalón que corresponde a la edad del jugador
      let mejor = def;
      for (const otra of UNIDADES) {
        if (otra.linea !== def.linea || otra.edad > this.edad) continue;
        if (otra.edad >= mejor.edad) mejor = otra;
      }
      nombres.push(mejor.nombre);
      if (nombres.length >= 3) break;
    }
    return nombres.join(', ');
  }

  /* ================================================================== *
   *  Árbol tecnológico
   * ================================================================== */

  _armarArbol() {
    if (this._arbolArmado) { this._marcarArbol(); return; }
    this._arbolArmado = true;
    this.arbolCuerpo.textContent = '';
    this._nodosArbol.clear();

    for (let e = 0; e < EDADES.length; e++) {
      const col = el('div', 'arbol-col');
      col.dataset.edad = String(e);
      const h = el('h3', null, EDADES[e].nombre);
      h.appendChild(el('em', null, EDADES[e].rango));
      col.appendChild(h);

      const bloque = (titulo, items, tipo) => {
        if (!items.length) return;
        col.appendChild(el('div', 'arbol-grupo', titulo));
        const fila = el('div', 'arbol-fila');
        for (const def of items) {
          const n = el('div', 'nodo-arbol');
          n.style.backgroundImage = `url(${retrato({ tipo, clave: def.clave, edad: e, color: this._colorJugador(this.jug) }, 96)})`;
          this._tooltipEn(n, () => ({
            titulo: def.nombre,
            subtitulo: tipo === 'unidad' ? (NOMBRE_CLASE[def.clase] || '') : (tipo === 'edificio' ? 'Edificio' : 'Tecnología'),
            coste: def.coste, tiempo: def.tiempo, desc: def.descripcion,
            unidad: tipo === 'unidad' ? def : null,
            edificio: tipo === 'edificio' ? def : null,
          }));
          fila.appendChild(n);
          this._nodosArbol.set(`${tipo}:${def.clave}`, { nodo: n, def, tipo, edad: e });
        }
        col.appendChild(fila);
      };

      bloque('Edificios', EDIFICIOS.filter((d) => d.edad === e), 'edificio');
      bloque('Unidades', UNIDADES.filter((d) => d.edad === e), 'unidad');
      bloque('Tecnologías', TECNOLOGIAS.filter((d) => d.edad === e), 'tecno');

      this.arbolCuerpo.appendChild(col);
    }
    this._marcarArbol();
  }

  _marcarArbol() {
    if (!this._arbolArmado) return;
    const ctx = this.ctx;
    const hechas = ctx.edades?.investigadas?.[this.jug];
    const tengo = new Set();
    const w = ctx.mundo;
    if (w) {
      for (let id = 0; id < w.maxUsado; id++) {
        if (!w.vivo[id] || w.jugador[id] !== this.jug) continue;
        if (w.tipo[id] === TIPO.EDIFICIO) tengo.add('edificio:' + (EDIFICIOS[w.defId[id]]?.clave || ''));
        else if (w.tipo[id] === TIPO.UNIDAD) tengo.add('unidad:' + (UNIDADES[w.defId[id]]?.clave || ''));
      }
    }
    for (const [clave, reg] of this._nodosArbol) {
      const disponible = reg.edad <= this.edad;
      let hecho = false;
      if (reg.tipo === 'tecno') hecho = !!hechas?.has?.(reg.def.clave);
      else hecho = tengo.has(clave);
      reg.nodo.classList.toggle('disp', disponible && !hecho);
      reg.nodo.classList.toggle('hecho', hecho);
    }
    for (const col of this.arbolCuerpo.children) {
      col.classList.toggle('actual', Number(col.dataset.edad) === this.edad);
    }
  }

  /* ================================================================== *
   *  Pausa, opciones y final
   * ================================================================== */

  _pausarJuego(v) {
    if (this.ctx.motor) this.ctx.motor.pausado = !!v;
  }

  _fijarVolumen(v) {
    const a = this.ctx.audio;
    if (!a) return;
    if (typeof a.setVolumen === 'function') a.setVolumen(v);
    else if (typeof a.volumen === 'number') a.volumen = v;
    else if (a.maestro?.gain) a.maestro.gain.value = v;
  }

  _sincronizarOpciones() {
    this.segCalidad.fijar(this.ctx.render?.calidad || this.ctx.calidad || 'alta');
    this.desVelocidad.fijar(this.ctx.motor?.velocidad ?? 1);
    this.segCiclo.fijar(this.ctx.cicloDia === false ? 'no' : 'si');
    this.filaHora.style.display = this.ctx.cicloDia === false ? '' : 'none';
    if (this.ctx.cielo) this.desHora.fijar(this.ctx.cielo.horaDelDia ?? 10);
  }

  /** Chequeo barato de condición de victoria/derrota (10 Hz, sin recorrer todo). */
  _vigilarFin() {
    if (this.terminada) return;
    const w = this.ctx.mundo;
    if (!w || (w.tiempo || 0) < 25) return;
    let mios = 0, ajenos = 0;
    for (let id = 0; id < w.maxUsado; id++) {
      if (!w.vivo[id] || w.tipo[id] !== TIPO.EDIFICIO) continue;
      const j = w.jugador[id];
      if (j === this.jug) { mios++; if (ajenos) break; }
      else if (j !== 255) { ajenos++; if (mios) break; }
    }
    // Sólo se puede perder lo que alguna vez se tuvo: si el mapa todavía no
    // pobló nada, el HUD no declara una derrota fantasma.
    if (mios) this._tuvoBase = true;
    if (ajenos) this._huboRival = true;
    if (this._tuvoBase && !mios) this._terminar(false, 'Perdiste todos tus edificios.');
    else if (this._huboRival && !ajenos) this._terminar(true, 'No queda un solo edificio enemigo en pie.');
  }

  _terminar(victoria, motivo) {
    if (this.terminada) return;
    this.terminada = true;
    this._pausarJuego(true);

    this.modales.fin.classList.toggle('derrota', !victoria);
    fijarTexto(this.finTitulo, victoria ? 'Victoria' : 'Derrota');
    fijarTexto(this.finLema, motivo || (victoria ? 'El imperio es tuyo.' : 'Otro escribirá esta historia.'));

    this.tablaFin.textContent = '';
    const th = el('thead');
    const trh = el('tr');
    for (const t of ['Imperio', 'Edad', 'Recolectado', 'Unidades', 'Edificios', 'Bajas', 'Perdidas']) trh.appendChild(el('th', null, t));
    th.appendChild(trh);
    this.tablaFin.appendChild(th);

    const tb = el('tbody');
    const total = this.ctx.mapa?.inicios?.length || 2;
    for (let j = 0; j < total; j++) {
      const civ = this.ctx.edades?.defCiv?.(j) || CIVILIZACIONES[j % CIVILIZACIONES.length];
      const st = this.ctx.eco?.estadisticas?.(j);
      let rec = 0;
      if (st?.recolectado) for (const k of CLAVES_RECURSO) rec += st.recolectado[k] || 0;
      const edadJ = this.ctx.edades?.edad?.[j] ?? 0;
      const tr = el('tr');
      const td0 = el('td');
      const pip = el('span', 'pip-jug');
      pip.style.background = this._colorJugador(j);
      td0.append(pip, document.createTextNode(`${j === this.jug ? 'Vos' : `Jugador ${j + 1}`} · ${civ?.nombre || ''}`));
      tr.appendChild(td0);
      tr.appendChild(el('td', null, EDADES[edadJ]?.nombre || '—'));
      tr.appendChild(el('td', null, String(Math.round(rec))));
      tr.appendChild(el('td', null, j === this.jug ? String(this.conteo.entrenadas) : '—'));
      tr.appendChild(el('td', null, j === this.jug ? String(this.conteo.construidos) : '—'));
      tr.appendChild(el('td', null, j === this.jug ? String(this.conteo.bajas) : '—'));
      tr.appendChild(el('td', null, j === this.jug ? String(this.conteo.perdidas) : '—'));
      tb.appendChild(tr);
    }
    this.tablaFin.appendChild(tb);

    this.menu = 'fin';
    for (const k in this.modales) this.modales[k].classList.toggle('on', k === 'fin');
    this.velo.classList.add('on');
  }

  /* ================================================================== *
   *  Avisos
   * ================================================================== */

  _caducarAvisos(dt) {
    if (!this._avisos.length) return;
    for (let i = this._avisos.length - 1; i >= 0; i--) {
      const a = this._avisos[i];
      a.t -= dt;
      if (a.t <= 0.35 && !a.saliendo) { a.saliendo = true; a.nodo.classList.add('sale'); }
      if (a.t <= 0) { a.nodo.remove(); this._avisos.splice(i, 1); }
    }
  }
}

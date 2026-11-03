/**
 * CIELO — atmósfera, iluminación y ciclo día/noche.
 *
 * Todo el cielo es UNA sola cúpula con un shader que resuelve, en este orden:
 *   dispersión analítica (Preetham) → estrellas + Vía Láctea → sol y luna →
 *   nubes volumétricas (raymarch corto) → cirros 2.5D → bruma de horizonte.
 *
 * Va todo junto en un solo material a propósito: si las nubes fueran una malla
 * transparente aparte caerían en la cola de transparentes (después del terreno)
 * y habría que pelearse con el orden de dibujo. Una cúpula opaca con
 * renderOrder mínimo se resuelve en una sola pasada y sin ordenar nada.
 *
 * ---------------------------------------------------------------------------
 * UNIFORMS GLOBALES COMPARTIDOS  (ver `uniformesCielo` más abajo)
 * ---------------------------------------------------------------------------
 * Cualquier módulo puede meter estos uniforms POR REFERENCIA en su propio
 * ShaderMaterial y quedan sincronizados solos, sin tocar nada por frame:
 *
 *   import { uniformesCielo, GLSL_NIEBLA_ALTURA } from '../render/Cielo.js';
 *   const mat = new THREE.ShaderMaterial({
 *     uniforms: { ...uniformesCielo, miCosa: { value: 1 } },
 *     fragmentShader: GLSL_NIEBLA_ALTURA + `...`,
 *   });
 *
 *   uNieblaAltura : vec3 — niebla por altura, complementa a THREE.FogExp2.
 *                   x = Y donde la niebla es máxima (metros)
 *                   y = 1 / altura de caída (1/metros)
 *                   z = fuerza 0..1
 *                   factor = z * exp(-max(y_mundo - x, 0) * y)
 *                   Usalo así:  color = mix(color, uNieblaColor, nieblaAltura(p));
 *   uNieblaColor  : vec3 — color LINEAL de la niebla, recalculado cada frame
 *                   desde el propio cielo cerca del horizonte.
 *   uDirSol       : vec3 — unitario que apunta HACIA el sol (no es "hacia dónde
 *                   viaja la luz": para eso usá -uDirSol).
 *   uColorLuz     : vec3 — color lineal de la luz dominante (sol de día, luna de noche).
 *   uTiempoCielo  : float — segundos acumulados; sirve para animar agua/foliaje
 *                   en fase con las nubes.
 * ---------------------------------------------------------------------------
 */
import * as THREE from 'three';
import { ORDEN } from '../core/Ctx.js';
import { clamp, lerp, smoothstep } from '../core/RNG.js';
import { EDADES } from '../data/edades.js';
// Tabla de exposición: una sola fuente de verdad. Cielo tenía su propio
// EXPOSICION_DIA = 1.05 y lo escribía cada frame, así que pisaba en silencio el
// valor medido del Renderer y el día salía a 146 de luma en vez de 133.
import { EXPOSICION } from './Renderer.js';

/* ═══════════════════════════ uniforms compartidos ═══════════════════════════ */

export const uniformesCielo = {
  uNieblaAltura: { value: new THREE.Vector3(0.0, 1 / 38, 0.55) },
  uNieblaColor: { value: new THREE.Color(0.62, 0.72, 0.86) },
  uDirSol: { value: new THREE.Vector3(0.4, 0.8, 0.45).normalize() },
  uColorLuz: { value: new THREE.Color(1.0, 0.95, 0.86) },
  uTiempoCielo: { value: 0 },
};

/** Snippet listo para pegar arriba de cualquier fragment shader que quiera niebla por altura. */
export const GLSL_NIEBLA_ALTURA = /* glsl */`
uniform vec3 uNieblaAltura;
uniform vec3 uNieblaColor;
float nieblaAltura(vec3 pMundo){
  return uNieblaAltura.z * exp(-max(pMundo.y - uNieblaAltura.x, 0.0) * uNieblaAltura.y);
}
`;

/* ═══════════════════════════ constantes del modelo ══════════════════════════ */

// Preetham: dispersión total de Rayleigh por canal (680/550/450 nm) y constante de Mie.
const RAYLEIGH_TOTAL = [5.804542996261093e-6, 1.3562911419845635e-5, 3.0265902468824876e-5];
const MIE_CONST = [1.8399918514433978e14, 2.7798023919660528e14, 4.0790479543861094e14];
const EE = 1000.0;                 // irradiancia solar de referencia
const ANGULO_CORTE = 1.6110731556870734;
const PENDIENTE_CORTE = 1.5;
const RAYLEIGH_ZENIT = 8.4e3;
const MIE_ZENIT = 1.25e3;

/**
 * Afinado visual por edad. NO vive en src/data/edades.js porque son parámetros
 * puramente de render (cobertura de nubes, suciedad del aire) que no afectan al
 * balance del juego; la paleta "de datos" sí sale de EDADES[n].cielo.
 */
const ATMOSFERA_EDAD = [
  { cobertura: 0.46, tinteNube: '#d8c6ab', bruma: 0.62, rayleigh: 1.9 }, // Vapor: aire cargado de hollín
  { cobertura: 0.52, tinteNube: '#cfd0d4', bruma: 0.70, rayleigh: 1.7 }, // Eléctrica: humo de fábrica
  { cobertura: 0.40, tinteNube: '#e2e6da', bruma: 0.50, rayleigh: 2.1 }, // Atómica
  { cobertura: 0.34, tinteNube: '#e8f1ff', bruma: 0.38, rayleigh: 2.4 }, // Información: aire limpio
  { cobertura: 0.28, tinteNube: '#f2e6ff', bruma: 0.30, rayleigh: 2.6 }, // Sintética
];

/**
 * ─────────────────────── LA NOCHE COMO CONVENCIÓN ───────────────────────
 * Todos estos números están en LINEAL HDR: viven antes del OutputPass, que es
 * quien aplica ACES (con toneMappingExposure/0.6) y la conversión a sRGB. Una
 * constante pensada para 0..1 de pantalla puesta acá hace desastres.
 *
 * POR QUÉ existe este bloque: la noche fotométricamente correcta ronda 1e-4 de
 * radiancia. Es exacta y es injugable —el cuadro se va a negro, no se ve ni el
 * terreno ni las unidades—. Los RTS clásicos nunca bajan de una luma media de
 * ~110 sobre 255 porque su noche NO es una simulación: es una convención de
 * color. Se lee por TINTE (azul frío y saturado) y por CONTRASTE (la luna
 * sobreexpuesta, las ventanas y los fuegos cálidos recortando), no por
 * oscuridad absoluta.
 *
 * Calibración medida (pasto del atlas, albedo lineal 0.175/0.287/0.051, ACES
 * con la exposición de acá abajo):
 *   luna alta   → 0.106..0.144 lineal → luma 112..134 sobre 255
 *   sin luna    → 0.088 lineal        → luma  99
 *   en sombra   → 0.065 lineal        → luma  80   (antes: 0 y 0)
 *   domo        → cenit (31,41,75), horizonte (61,80,127)
 * La irradiancia nocturna total (ambiente + luna) queda en ~33% de la de
 * mediodía: suficiente para leer el mapa, poco para confundirlo con el día.
 */
const NOCHE = {
  // Azul frío con algo de rojo: si el rojo va a 0 el pasto vira a teal. Pero
  // tampoco puede ser tan neutro como estaba, porque entonces la escena mide
  // como noche y se LEE como día nublado: el pasto seguía verde saturado y la
  // arena marrón cálida. De noche el ojo no distingue color (visión escotópica);
  // la convención del género es empujar todo hacia el azul y bajar la saturación.
  ambColor: [0.20, 0.30, 0.88],
  // 2.15 dejaba la noche PLANA: tanto ambiente que la luna no marcaba diferencia
  // y la escena se leía como un día nublado. Una noche se reconoce por el
  // CONTRASTE entre lo que toca la luna y lo que no, no solo por el tinte azul.
  ambIrradiancia: 1.30,
  sueloColor: [0.30, 0.30, 0.36], // rebote del terreno de noche: casi neutro, apenas frío
  sueloIrradiancia: 0.40,
  lunaColor: [0.36, 0.54, 1.00],  // la luna casi neutra devolvía una escena de día
  lunaIrradiancia: 1.55,          // sigue siendo una FUENTE de verdad, no el adorno de 0.30 original
  cieloPiso: [0.034, 0.049, 0.096], // piso aditivo del domo (ver uPisoNoche)
  niebla: [0.048, 0.066, 0.118],  // el aire de noche no es negro: sostiene el terreno lejano
};

/**
 * ──────────────────── PERSPECTIVA AÉREA (el aire tiene color) ────────────────
 *
 * DENSIDAD_AEREA es la constante que le da PROFUNDIDAD al cuadro, y hasta esta
 * ronda no existía: la niebla salía de `p.niebla · 0,10`, o sea 0,0006-0,0016,
 * y con FogExp2 —f = 1 − exp(−(d·z)²)— eso a 130 m (el fondo del cuadro con la
 * cámara canónica: 78 m de órbita, 49°, el suelo va de 62 a 131 m) se comía un
 * 2 % del contraste. Dos por ciento es cero. Por eso el panel veía "una sola
 * banda": el pasto de adelante y el de atrás tenían exactamente el mismo valor,
 * el mismo croma y el mismo micro-contraste, y sin gradiente de profundidad el
 * ojo no tiene dónde apoyarse.
 *
 * Medido sobre nuestras propias capturas: el micro-contraste por bandas de la
 * aldea del Vapor daba 45,1 arriba (lejos) contra 23,6 abajo (cerca). Al revés
 * de como debe ser. En un cuadro con aire, lo lejano es lo MÁS plano.
 *
 * Con z = 0,0023 la curva queda:
 *      80 m → 3 %   ·   200 m → 19 %   ·   300 m → 38 %   ·   400 m → 57 %
 * El primer plano —donde se juega— conserva todo su contraste; el fondo pierde
 * entre un cuarto y la mitad. El terreno además tiene su propia curva, más
 * fuerte, porque se lo mira a ras (ver uAire en src/world/TerrenoShader.js).
 *
 * ALBEDO_AIRE es lo que impide el desastre que ya cometimos una vez: el color
 * de niebla se leía del domo y salía en 0,65 de luma LINEAL, que después de
 * ACES y del gradeo mide 224 sobre 255 —más que el techo más claro de la
 * aldea—. Con una niebla así, cada píxel lejano SUMA luz: la escena se lava y
 * el fondo termina siendo lo más brillante del cuadro, justo al revés de lo que
 * uno quiere. La bruma no es una fuente: es la irradiancia del cielo dispersada
 * por el aire, así que su radiancia vale (irradiancia / π) · albedo del aire.
 * Anclarla ahí la deja por CONSTRUCCIÓN en 0,30/0,90 = un tercio del blanco
 * difuso, que es esa misma cuenta con albedo 0,9. Nunca puede pasarlo.
 */
const DENSIDAD_AEREA = 0.0023;
const ALBEDO_AIRE = 0.30;

const PRESET_CIELO = {
  baja: { pasosNube: 0, pasosLuz: 0, cirros: 1, estrellas: 1, segmentos: 32 },
  media: { pasosNube: 8, pasosLuz: 3, cirros: 1, estrellas: 1, segmentos: 40 },
  alta: { pasosNube: 11, pasosLuz: 4, cirros: 1, estrellas: 1, segmentos: 48 },
  ultra: { pasosNube: 15, pasosLuz: 5, cirros: 1, estrellas: 1, segmentos: 64 },
};

const TAU = Math.PI * 2;

/* ═══════════════════════ ruido volumétrico procedural ═══════════════════════ */

/** Ruido de valor con período exacto: imprescindible para que la textura 3D tile. */
function reticula(per, rng) {
  const a = new Float32Array(per * per * per);
  for (let i = 0; i < a.length; i++) a[i] = rng.float();
  return a;
}

function valorPeriodico(a, per, x, y, z) {
  const xi = Math.floor(x), yi = Math.floor(y), zi = Math.floor(z);
  const fx = x - xi, fy = y - yi, fz = z - zi;
  const u = fx * fx * fx * (fx * (fx * 6 - 15) + 10);
  const v = fy * fy * fy * (fy * (fy * 6 - 15) + 10);
  const w = fz * fz * fz * (fz * (fz * 6 - 15) + 10);
  const x0 = xi % per, y0 = yi % per, z0 = zi % per;
  const x1 = (x0 + 1) % per, y1 = (y0 + 1) % per, z1 = (z0 + 1) % per;
  const p2 = per * per;
  const c000 = a[z0 * p2 + y0 * per + x0], c100 = a[z0 * p2 + y0 * per + x1];
  const c010 = a[z0 * p2 + y1 * per + x0], c110 = a[z0 * p2 + y1 * per + x1];
  const c001 = a[z1 * p2 + y0 * per + x0], c101 = a[z1 * p2 + y0 * per + x1];
  const c011 = a[z1 * p2 + y1 * per + x0], c111 = a[z1 * p2 + y1 * per + x1];
  const a00 = c000 + (c100 - c000) * u, a10 = c010 + (c110 - c010) * u;
  const a01 = c001 + (c101 - c001) * u, a11 = c011 + (c111 - c011) * u;
  const b0 = a00 + (a10 - a00) * v, b1 = a01 + (a11 - a01) * v;
  return b0 + (b1 - b0) * w;
}

/**
 * Worley periódico precalculado a resolución `res`. Se muestrea después con
 * interpolación trilineal: a media resolución el detalle celular no se nota y
 * baja el coste de generación 8×.
 */
function volumenWorley(g, res, rng) {
  const pts = new Float32Array(g * g * g * 3);
  for (let i = 0; i < pts.length; i++) pts[i] = rng.float();
  const vol = new Float32Array(res * res * res);
  const g2 = g * g;
  for (let z = 0; z < res; z++) {
    const pz = (z / res) * g;
    const cz = Math.floor(pz);
    for (let y = 0; y < res; y++) {
      const py = (y / res) * g;
      const cy = Math.floor(py);
      for (let x = 0; x < res; x++) {
        const px = (x / res) * g;
        const cx = Math.floor(px);
        let mejor = 1e9;
        for (let oz = -1; oz <= 1; oz++) {
          const wz = (cz + oz + g) % g;
          for (let oy = -1; oy <= 1; oy++) {
            const wy = (cy + oy + g) % g;
            for (let ox = -1; ox <= 1; ox++) {
              const wx = (cx + ox + g) % g;
              const i3 = (wz * g2 + wy * g + wx) * 3;
              const dx = cx + ox + pts[i3] - px;
              const dy = cy + oy + pts[i3 + 1] - py;
              const dz = cz + oz + pts[i3 + 2] - pz;
              const d2 = dx * dx + dy * dy + dz * dz;
              if (d2 < mejor) mejor = d2;
            }
          }
        }
        // invertido: 1 en el centro de la celda → grumos tipo coliflor
        vol[z * res * res + y * res + x] = clamp(1 - Math.sqrt(mejor), 0, 1);
      }
    }
  }
  return vol;
}

function muestrear3D(vol, res, x, y, z) {
  const xi = Math.floor(x), yi = Math.floor(y), zi = Math.floor(z);
  const fx = x - xi, fy = y - yi, fz = z - zi;
  const x0 = ((xi % res) + res) % res, y0 = ((yi % res) + res) % res, z0 = ((zi % res) + res) % res;
  const x1 = (x0 + 1) % res, y1 = (y0 + 1) % res, z1 = (z0 + 1) % res;
  const r2 = res * res;
  const c000 = vol[z0 * r2 + y0 * res + x0], c100 = vol[z0 * r2 + y0 * res + x1];
  const c010 = vol[z0 * r2 + y1 * res + x0], c110 = vol[z0 * r2 + y1 * res + x1];
  const c001 = vol[z1 * r2 + y0 * res + x0], c101 = vol[z1 * r2 + y0 * res + x1];
  const c011 = vol[z1 * r2 + y1 * res + x0], c111 = vol[z1 * r2 + y1 * res + x1];
  const a00 = c000 + (c100 - c000) * fx, a10 = c010 + (c110 - c010) * fx;
  const a01 = c001 + (c101 - c001) * fx, a11 = c011 + (c111 - c011) * fx;
  const b0 = a00 + (a10 - a00) * fy, b1 = a01 + (a11 - a01) * fy;
  return b0 + (b1 - b0) * fz;
}

/**
 * Textura 3D tileable con la forma de las nubes:
 *   R = perlin-worley (forma base)   G = worley medio (erosión)
 *   B = worley fino (bordes)         A = fbm de baja frecuencia (clima/cobertura)
 */
function crearRuido3D(ctx, N = 64) {
  const rng = ctx.rng.fork(0xc1e10);
  const r4 = reticula(4, rng), r8 = reticula(8, rng), r16 = reticula(16, rng), r32 = reticula(32, rng);
  const wA = volumenWorley(6, 32, rng);
  const wB = volumenWorley(11, 32, rng);
  const wC = volumenWorley(19, 32, rng);

  const datos = new Uint8Array(N * N * N * 4);
  let i = 0;
  for (let z = 0; z < N; z++) {
    for (let y = 0; y < N; y++) {
      for (let x = 0; x < N; x++) {
        const u = x / N, v = y / N, w = z / N;
        const perlin =
          0.50 * valorPeriodico(r4, 4, u * 4, v * 4, w * 4) +
          0.26 * valorPeriodico(r8, 8, u * 8, v * 8, w * 8) +
          0.15 * valorPeriodico(r16, 16, u * 16, v * 16, w * 16) +
          0.09 * valorPeriodico(r32, 32, u * 32, v * 32, w * 32);
        const wa = muestrear3D(wA, 32, u * 32, v * 32, w * 32);
        const wb = muestrear3D(wB, 32, u * 32, v * 32, w * 32);
        const wc = muestrear3D(wC, 32, u * 32, v * 32, w * 32);
        // remap perlin→worley: le da el borde "coliflor" que distingue una nube
        // de una mancha de ruido.
        const pw = clamp((perlin - (1 - wa)) / Math.max(wa, 1e-3), 0, 1);
        const clima =
          0.65 * valorPeriodico(r4, 4, u * 2, v * 2, w * 2) +
          0.35 * valorPeriodico(r8, 8, u * 4, v * 4, w * 4);
        datos[i++] = (pw * 255) | 0;
        datos[i++] = (wb * 255) | 0;
        datos[i++] = (wc * 255) | 0;
        datos[i++] = (clamp(clima, 0, 1) * 255) | 0;
      }
    }
  }

  const tex = new THREE.Data3DTexture(datos, N, N, N);
  tex.format = THREE.RGBAFormat;
  tex.type = THREE.UnsignedByteType;
  tex.minFilter = THREE.LinearFilter;
  tex.magFilter = THREE.LinearFilter;
  tex.wrapS = tex.wrapT = tex.wrapR = THREE.RepeatWrapping;
  tex.unpackAlignment = 1;
  tex.needsUpdate = true;
  return tex;
}

/* ═════════════════════════════════ shaders ══════════════════════════════════ */

const VERTEX = /* glsl */`
varying vec3 vDirMundo;
void main(){
  vec4 pm = modelMatrix * vec4(position, 1.0);
  vDirMundo = pm.xyz - cameraPosition;
  gl_Position = projectionMatrix * viewMatrix * pm;
}
`;

const FRAGMENT = /* glsl */`
varying vec3 vDirMundo;

uniform vec3  uDirSol, uDirLuna, uDirLuz;
uniform vec3  uBetaR, uBetaM;
uniform float uSolE, uMieG, uRayleighZ, uMieZ, uExposicion;
uniform vec3  uColorSol, uColorLuz, uNieblaColor, uTinteNube, uPisoNoche;
uniform float uNoche, uTiempo, uBruma, uAngSideral, uFaseLuna;
uniform sampler3D uRuido3D;
uniform float uCobertura, uDensidadNube, uEscalaNube, uAbsorcion, uPowder;
uniform float uNubeBase, uNubeTecho, uRadioPlaneta, uLargoMax;
uniform vec3  uViento;
uniform float uCirros;

const float PI = 3.141592653589793;
const vec3  ARRIBA = vec3(0.0, 1.0, 0.0);
const vec3  EJE_GALAXIA = vec3(0.35, 0.62, -0.70);

/* ---------- dispersión analítica (Preetham) ---------- */
float faseRayleigh(float c){ return (3.0 / (16.0 * PI)) * (1.0 + c * c); }
float faseHG(float c, float g){
  float g2 = g * g;
  return (1.0 / (4.0 * PI)) * ((1.0 - g2) / pow(max(1.0 + g2 - 2.0 * g * c, 1e-4), 1.5));
}

vec3 cieloAnalitico(vec3 d, out vec3 extincion){
  float cosT = dot(d, uDirSol);
  float dyy = max(d.y, -0.03);
  float zen = acos(clamp(dyy, -1.0, 1.0));
  // camino óptico relativo al cenit; el término de Preetham evita el infinito
  // en el horizonte sin recurrir a una integral numérica.
  float denom = cos(zen) + 0.15 * pow(max(93.885 - zen * 180.0 / PI, 1e-3), -1.253);
  float inv = 1.0 / max(denom, 1e-3);
  vec3 Fex = exp(-(uBetaR * uRayleighZ * inv + uBetaM * uMieZ * inv));
  extincion = Fex;

  vec3 bR = uBetaR * faseRayleigh(cosT);
  vec3 bM = uBetaM * faseHG(cosT, uMieG);
  vec3 ratio = (bR + bM) / (uBetaR + uBetaM);
  vec3 Lin = pow(uSolE * ratio * (1.0 - Fex), vec3(1.5));
  Lin *= mix(vec3(1.0), pow(uSolE * ratio * Fex, vec3(0.5)),
             clamp(pow(1.0 - dot(ARRIBA, uDirSol), 5.0), 0.0, 1.0));
  return Lin * 0.04 * uExposicion;
}

/* ---------- estrellas ---------- */
float hash31(vec3 p){
  p = fract(p * 0.1031);
  p += dot(p, p.yzx + 33.33);
  return fract((p.x + p.y) * p.z);
}

vec3 estrellas(vec3 d){
  // rotación sideral: el cielo gira despacio alrededor de un eje inclinado
  float ca = cos(uAngSideral), sa = sin(uAngSideral);
  vec3 dr = vec3(d.x * ca - d.z * sa, d.y, d.x * sa + d.z * ca);

  // Vía Láctea: banda gaussiana alrededor del plano galáctico + polvo con fbm
  float b = dot(dr, EJE_GALAXIA);
  float banda = exp(-b * b * 22.0);
  float polvo = texture(uRuido3D, dr * 1.9 + 4.0).r;
  float veta  = texture(uRuido3D, dr * 5.3 + 9.0).g;
  float via = banda * (0.30 + 0.70 * polvo) * (1.0 - veta * 0.55);
  vec3 col = mix(vec3(0.62, 0.70, 1.00), vec3(1.00, 0.88, 0.72), polvo) * via * 0.085;

  // puntos: una celda por estrella, con el punto desplazado hacia el centro
  // para que nunca caiga sobre el borde de la celda (evita la rejilla visible).
  vec3 p = dr * 62.0;
  vec3 celda = floor(p), f = p - celda;
  vec3 j = vec3(hash31(celda + 11.3), hash31(celda + 23.7), hash31(celda + 37.1)) * 0.5 + 0.25;
  float mag = hash31(celda + 5.9);
  float umbral = 0.905 - banda * 0.10;              // el brazo galáctico junta más estrellas
  if (mag > umbral){
    float dd = length(f - j);
    float nucleo = pow(max(0.0, 1.0 - dd * 6.0), 11.0);
    float lum = mix(0.25, 1.6, pow((mag - umbral) / max(1.0 - umbral, 1e-3), 2.2));
    float centelleo = 0.78 + 0.22 * sin(uTiempo * 2.7 + mag * 97.0);
    vec3 tinte = mix(vec3(1.0, 0.80, 0.60), vec3(0.72, 0.84, 1.0), hash31(celda + 71.0));
    col += tinte * nucleo * lum * centelleo;
  }
  return col;
}

/* ---------- sol y luna ---------- */
vec3 discoSolar(vec3 d, vec3 Fex){
  float ang = acos(clamp(dot(d, uDirSol), -1.0, 1.0));
  float r = 0.0096;
  float disco = 1.0 - smoothstep(r * 0.93, r * 1.05, ang);
  // oscurecimiento del limbo: el borde del disco es más apagado que el centro
  float limbo = sqrt(max(0.0, 1.0 - pow(clamp(ang / r, 0.0, 1.0), 2.0)));
  disco *= mix(0.58, 1.0, pow(limbo, 0.42));
  // halo en shader (no depende del bloom): tres lóbulos exponenciales
  float halo = exp(-ang * 46.0) * 0.55 + exp(-ang * 9.0) * 0.16 + exp(-ang * 2.4) * 0.045;
  float bajoHorizonte = smoothstep(-0.045, 0.02, uDirSol.y);
  return uColorSol * Fex * bajoHorizonte * (disco * 20.0 + halo * 1.35);
}

vec3 discoLunar(vec3 d, vec3 Fex){
  float ang = acos(clamp(dot(d, uDirLuna), -1.0, 1.0));
  float r = 0.0135;
  if (ang > r * 8.0) return vec3(0.0);
  float visible = smoothstep(-0.03, 0.03, uDirLuna.y);
  if (visible <= 0.0) return vec3(0.0);

  vec3 ref = abs(uDirLuna.y) > 0.97 ? vec3(0.0, 0.0, 1.0) : ARRIBA;
  vec3 tu = normalize(cross(uDirLuna, ref));
  vec3 tv = cross(tu, uDirLuna);
  vec2 uv = vec2(dot(d, tu), dot(d, tv)) / r;
  float r2 = dot(uv, uv);

  vec3 res = uColorLuz * exp(-ang * 120.0) * 0.85;   // resplandor alrededor
  if (r2 < 1.0){
    vec3 n = normalize(vec3(uv, sqrt(max(0.0, 1.0 - r2))));
    vec3 nm = n.x * tu + n.y * tv + n.z * uDirLuna;
    // la fase sale sola: la luna la ilumina el mismo sol del modelo
    float lam = max(dot(nm, uDirSol), 0.0);
    float term = smoothstep(0.0, 0.10, lam);
    vec3 pm = nm * 1.4 + 3.0;
    float mares = texture(uRuido3D, pm).r;
    float crat  = texture(uRuido3D, nm * 5.2 + 7.0).b;
    float alb = mix(0.86, 0.44, smoothstep(0.42, 0.66, mares));
    alb *= 1.0 - crat * 0.34;
    float borde = 1.0 - smoothstep(0.92, 1.0, sqrt(r2));
    float luz = term * (0.25 + 0.75 * lam) + 0.035;  // el 0.035 es luz cenicienta
    // LA LUNA ES LA ALTA LUZ DE LA NOCHE. A 2.6 quedaba justo en el umbral del
    // bloom (2.2 lineal) y el cuadro nocturno no tenía NINGÚN píxel por encima
    // de 200: no existía "lo más claro de la imagen". A 5.6 el disco satura,
    // florece, y le da al ojo dónde anclar la exposición.
    res += vec3(1.0, 0.97, 0.92) * alb * luz * borde * 5.6;
  }
  return res * visible * Fex;
}

/* ---------- nubes volumétricas ---------- */
#if PASOS_NUBE > 0
float alturaShell(vec3 p){
  // distancia al centro del planeta ficticio, que está bajo la cámara
  vec3 c = p - vec3(0.0, -uRadioPlaneta, 0.0);
  return length(c) - uRadioPlaneta;
}

float salidaShell(vec3 rd, float radio){
  vec3 oc = vec3(0.0, uRadioPlaneta, 0.0);   // origen - centro (cámara en el origen local)
  float b = dot(oc, rd);
  float c = dot(oc, oc) - radio * radio;
  float h = b * b - c;
  if (h < 0.0) return -1.0;
  return -b + sqrt(h);
}

float densidadNube(vec3 p, float hn, float alturaAbs){
  vec3 desp = uViento * uTiempo;
  vec4 n = texture(uRuido3D, (p + desp) * uEscalaNube);
  // el canal A a escala grande hace de "mapa de clima": rompe el tileado
  float clima = texture(uRuido3D, (p + desp * 0.35) * uEscalaNube * 0.13).a;
  float cob = clamp(uCobertura * (0.45 + 1.25 * clima), 0.0, 1.0);

  float perfil = smoothstep(0.0, 0.20, hn) * smoothstep(1.0, 0.58, hn);
  float d = n.r * perfil - (1.0 - cob);
  if (d <= 0.0) return 0.0;
  d /= max(cob, 0.02);

  vec3 det = texture(uRuido3D, (p + desp * 2.6) * uEscalaNube * 7.5).gba;
  float er = det.x * 0.62 + det.y * 0.28 + det.z * 0.10;
  // la erosión muerde más abajo (base plana) que arriba (cima deshilachada)
  d -= er * 0.42 * (1.0 - hn * 0.55);
  return clamp(d, 0.0, 1.0) * uDensidadNube;
}

float opticaHaciaLuz(vec3 p, float paso, float espesor){
  float acc = 0.0;
  for (int i = 0; i < PASOS_LUZ; i++){
    float t = paso * (float(i) + 0.5);
    vec3 q = p + uDirLuz * t;
    float h = clamp((alturaShell(q) - uNubeBase) / espesor, 0.0, 1.0);
    acc += densidadNube(q, h, 0.0) * paso;
  }
  return acc;
}
#endif

/* ---------- cirros 2.5D con parallax de tres niveles ---------- */
#if CIRROS > 0
float capaCirros(vec3 d, float alt, float escala, float vel, float sem){
  float t = alt / max(d.y, 0.02);
  vec2 uv = (cameraPosition.xz + d.xz * t) * escala + uViento.xz * uTiempo * vel;
  float a = texture(uRuido3D, vec3(uv, sem)).r;
  float b = texture(uRuido3D, vec3(uv * 2.7 + 0.3, sem + 0.21)).g;
  return clamp(a * 0.72 + b * 0.42 - 0.42, 0.0, 1.0);
}
#endif

void main(){
  vec3 d = normalize(vDirMundo);

  vec3 Fex;
  vec3 color = cieloAnalitico(d, Fex);

  // noche: estrellas primero para que el sol/luna y las nubes las tapen
  if (uNoche > 0.001){
    float altoHorizonte = smoothstep(-0.02, 0.16, d.y);
    // las estrellas suben junto con el piso: si no, el piso se las come
    color += estrellas(d) * uNoche * altoHorizonte * 1.5;
    // PISO NOCTURNO: el modelo analítico con el sol bajo el horizonte devuelve
    // ~1e-4 y el cuadro entero colapsa a negro. Sumamos un azul frío con más
    // peso cerca del horizonte (donde la atmósfera dispersa lo poco que queda)
    // para que la noche se lea por COLOR y no por ausencia de señal. Va antes
    // de las nubes a propósito: las nubes tienen que taparlo.
    float gradNoche = mix(1.30, 0.58, smoothstep(0.0, 0.60, max(d.y, 0.0)));
    color += uPisoNoche * uNoche * gradNoche;
  }

  color += discoSolar(d, Fex);
  color += discoLunar(d, Fex);

  vec3 cieloDeFondo = color;

#if CIRROS > 0
  if (d.y > 0.015 && uCirros > 0.0){
    // tres alturas distintas ⇒ tres velocidades de parallax reales
    float c1 = capaCirros(d, 7600.0, 3.1e-5, 0.9, 0.11);
    float c2 = capaCirros(d, 8900.0, 2.2e-5, 1.5, 0.47);
    float c3 = capaCirros(d, 10600.0, 1.5e-5, 2.2, 0.83);
    float a = clamp(c1 * 0.55 + c2 * 0.32 + c3 * 0.22, 0.0, 1.0) * uCirros;
    a *= smoothstep(0.015, 0.20, d.y);
    float fase = faseHG(dot(d, uDirLuz), 0.55) * 3.4 + 0.55;
    vec3 colCirro = uColorLuz * fase * 0.55 + uNieblaColor * 0.45;
    color = mix(color, colCirro * uTinteNube, a * 0.72);
  }
#endif

#if PASOS_NUBE > 0
  if (d.y > 0.012){
    float espesor = uNubeTecho - uNubeBase;
    float t0 = salidaShell(d, uRadioPlaneta + uNubeBase);
    float t1 = salidaShell(d, uRadioPlaneta + uNubeTecho);
    if (t1 > t0 && t0 > 0.0){
      float largo = min(t1 - t0, uLargoMax);
      float paso = largo / float(PASOS_NUBE);
      // dither estable en pantalla: rompe el bandeo sin hervir entre frames
      float jit = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453);
      vec3 p = d * (t0 + paso * jit);

      float cosL = dot(d, uDirLuz);
      // doble lóbulo: hacia adelante da el borde plateado, hacia atrás la panza gris
      float fase = mix(faseHG(cosL, 0.76), faseHG(cosL, -0.32), 0.38) * 5.2 + 0.30;

      vec3 ambBase = uNieblaColor * 0.55 * uTinteNube;
      vec3 ambCima = (uNieblaColor * 0.35 + uColorLuz * 0.42) * uTinteNube;

      vec3 disperso = vec3(0.0);
      float trans = 1.0;
      float pasoLuz = espesor * 0.26;

      for (int i = 0; i < PASOS_NUBE; i++){
        float hn = clamp((alturaShell(p) - uNubeBase) / espesor, 0.0, 1.0);
        float dens = densidadNube(p, hn, 0.0);
        if (dens > 0.0035){
          float od = opticaHaciaLuz(p, pasoLuz, espesor);
          float sig = uAbsorcion;
          // Beer–Powder: Beer apaga, Powder devuelve el oscurecimiento de borde
          float beer = exp(-od * sig) + 0.30 * exp(-od * sig * 0.22);
          float powder = 1.0 - exp(-od * sig * 2.2);
          vec3 luz = uColorLuz * beer * mix(1.0, powder * 1.9, uPowder) * fase;
          vec3 amb = mix(ambBase, ambCima, hn);
          float ext = dens * sig * paso;
          float tr = exp(-ext);
          disperso += trans * (luz + amb) * dens * (1.0 - tr);
          trans *= tr;
          if (trans < 0.02) break;
        }
        p += d * paso;
      }

      // perspectiva aérea: lo que está a 15 km se come el color del horizonte
      float aer = exp(-t0 * 4.6e-5);
      disperso = mix(uNieblaColor * (1.0 - trans), disperso, aer);
      color = disperso + cieloDeFondo * trans;
    }
  }
#endif

  // bruma de horizonte: liga el cielo con la niebla del terreno para que los
  // cerros lejanos se derritan en el aire en lugar de recortarse.
  float bruma = exp(-max(d.y, 0.0) * 15.0) * uBruma;
  color = mix(color, uNieblaColor * 1.08, bruma);

  // por debajo del horizonte la cúpula sólo se ve en los bordes del mapa
  float bajo = smoothstep(0.0, -0.06, d.y);
  color = mix(color, uNieblaColor * 0.42, bajo);

  gl_FragColor = vec4(max(color, 0.0), 1.0);
}
`;

/* ═════════════════════════════ utilidades locales ═══════════════════════════ */

const _c1 = new THREE.Color();
const _c2 = new THREE.Color();
const _c3 = new THREE.Color();
const _v1 = new THREE.Vector3();
const _v2 = new THREE.Vector3();
const _betaR = [0, 0, 0];
const _betaM = [0, 0, 0];
const _fexTmp = [0, 0, 0];
const _rgbTmp = [0, 0, 0];
const _rgbAmb = [0, 0, 0];
/**
 * TINTE crudo del aire (sin magnitud): lo escribe `_actualizarAtmosfera` leyendo
 * el propio domo cerca del horizonte y lo consume `_actualizarLuces`, que es
 * quien recién ahí conoce el presupuesto de luz del frame y puede fijarle la
 * luma. Va acá afuera y no como campo del objeto porque hay un solo Cielo y así
 * el ciclo no asigna nada por frame.
 */
const _aire = [0.62, 0.72, 0.86];

/** Temperatura de color → RGB sRGB (aproximación de Tanner Helland). */
function cuerpoNegro(kelvin, salida) {
  const t = clamp(kelvin, 1000, 12000) / 100;
  let r, g, b;
  if (t <= 66) r = 255;
  else r = 329.698727446 * Math.pow(t - 60, -0.1332047592);
  if (t <= 66) g = 99.4708025861 * Math.log(t) - 161.1195681661;
  else g = 288.1221695283 * Math.pow(t - 60, -0.0755148492);
  if (t >= 66) b = 255;
  else if (t <= 19) b = 0;
  else b = 138.5177312231 * Math.log(t - 10) - 305.0447927307;
  salida.setRGB(clamp(r, 0, 255) / 255, clamp(g, 0, 255) / 255, clamp(b, 0, 255) / 255, THREE.SRGBColorSpace);
  return salida;
}

/* ═════════════════════════════════ la clase ═════════════════════════════════ */

export class Cielo {
  constructor(ctx) {
    this.nombre = 'cielo';
    this.orden = 99;
    this.ctx = ctx;

    const preset = PRESET_CIELO[ctx.calidad] || PRESET_CIELO.alta;
    this.preset = preset;

    /** Vector unitario que apunta HACIA el sol. */
    this.dirSol = new THREE.Vector3(0.4, 0.8, 0.45).normalize();
    /** Vector unitario que apunta HACIA la luna. */
    this.dirLuna = new THREE.Vector3(-0.4, 0.5, -0.45).normalize();
    /** Dirección de la luz que manda en este momento (sol de día, luna de noche). */
    this.dirLuzDominante = this.dirSol.clone();

    this._hora = 9.5;
    this.horasPorSegundo = 24 / (50 * 60);  // un día entero cada 50 minutos reales
    this.latitud = -34.6 * Math.PI / 180;   // hemisferio sur: el sol pasa por el norte
    this.declinacion = -0.21;               // verano austral
    this.faseLuna = 0.68;                   // gibosa creciente: sale después del atardecer
    this.tiempo = 0;

    // paleta atmosférica: se interpola en 2 s al cambiar de edad
    this.edad = 0;
    this._pal = this._paletaDe(0);
    this._palOrigen = { ...this._pal };
    this._palDestino = { ...this._pal };
    this._tEdad = 1;
    this._duracionEdad = 2.0;

    this.ruido3D = crearRuido3D(ctx, 64);
    this._construirCupula(preset);
    this._construirLuces();

    ctx.escena.background = null;
    this.niebla = new THREE.FogExp2(0x9fb4c8, 0.0035);
    ctx.escena.fog = this.niebla;

    this._actualizarAstros();
    this._actualizarAtmosfera();
    this._actualizarLuces();
  }

  /* ---------------------------------------------------------------- cúpula */

  _construirCupula(preset) {
    const geo = new THREE.SphereGeometry(1, preset.segmentos, Math.max(16, preset.segmentos >> 1));
    const u = {
      uDirSol: { value: this.dirSol },
      uDirLuna: { value: this.dirLuna },
      uDirLuz: { value: this.dirLuzDominante },
      uBetaR: { value: new THREE.Vector3() },
      uBetaM: { value: new THREE.Vector3() },
      uSolE: { value: 400 },
      uMieG: { value: 0.80 },
      uRayleighZ: { value: RAYLEIGH_ZENIT },
      uMieZ: { value: MIE_ZENIT },
      uExposicion: { value: 0.42 },
      uColorSol: { value: new THREE.Color(1, 1, 1) },
      uColorLuz: uniformesCielo.uColorLuz,
      uNieblaColor: uniformesCielo.uNieblaColor,
      uTinteNube: { value: new THREE.Color(1, 1, 1) },
      uPisoNoche: { value: new THREE.Color(NOCHE.cieloPiso[0], NOCHE.cieloPiso[1], NOCHE.cieloPiso[2]) },
      uNoche: { value: 0 },
      uTiempo: uniformesCielo.uTiempoCielo,
      uBruma: { value: 0.5 },
      uAngSideral: { value: 0 },
      uFaseLuna: { value: this.faseLuna },
      uRuido3D: { value: this.ruido3D },
      uCobertura: { value: 0.42 },
      uDensidadNube: { value: 1.0 },
      uEscalaNube: { value: 1 / 2600 },
      uAbsorcion: { value: 0.0125 },
      uPowder: { value: 0.7 },
      uNubeBase: { value: 1150 },
      uNubeTecho: { value: 2750 },
      uRadioPlaneta: { value: 62000 },
      uLargoMax: { value: 15000 },
      uViento: { value: new THREE.Vector3(11, 0, 5) },
      uCirros: { value: 0.55 },
    };
    this.uniformes = u;

    this.material = new THREE.ShaderMaterial({
      uniforms: u,
      vertexShader: VERTEX,
      fragmentShader: FRAGMENT,
      defines: {
        PASOS_NUBE: preset.pasosNube,
        PASOS_LUZ: preset.pasosLuz,
        CIRROS: preset.cirros,
      },
      side: THREE.BackSide,
      depthWrite: false,
      depthTest: true,
      fog: false,
      toneMapped: false,   // el composer tonemapea al final; acá va HDR lineal
    });

    this.cupula = new THREE.Mesh(geo, this.material);
    this.cupula.name = 'cupula-cielo';
    this.cupula.frustumCulled = false;
    this.cupula.renderOrder = -1000;
    this.cupula.matrixAutoUpdate = false;
    this.ctx.escena.add(this.cupula);
  }

  /* ---------------------------------------------------------------- luces */

  _construirLuces() {
    const esc = this.ctx.escena;

    this.sol = new THREE.DirectionalLight(0xfff3e0, 3.6);
    this.sol.name = 'luz-sol';
    this.sol.castShadow = true;
    this.sol.position.copy(this.dirSol).multiplyScalar(300);
    this.sol.target.position.set(0, 0, 0);
    esc.add(this.sol, this.sol.target);

    this.luna = new THREE.DirectionalLight(0x9fb6e8, 0.0);
    this.luna.name = 'luz-luna';
    this.luna.castShadow = false;
    this.luna.position.copy(this.dirLuna).multiplyScalar(300);
    this.luna.target.position.set(0, 0, 0);
    esc.add(this.luna, this.luna.target);
    /** Dirección desde la que ilumina la luna (puede NO coincidir con el disco). */
    this.dirLuzLuna = this.dirLuna.clone();
    /** Ídem para el sol: el disco puede rozar el horizonte, la luz no. */
    this.dirLuzSol = this.dirSol.clone();

    // El color de cielo arranca casi neutro y el de suelo francamente cálido: un
    // hemisférico con cielo azul puro (el 0x8fb6dd de antes) es la causa directa
    // de las sombras teal, porque en sombra plena el ambiente es lo ÚNICO que
    // queda y sobre pasto verde un azul saturado da turquesa. Igual se
    // recalculan por frame en _actualizarLuces.
    this.ambiental = new THREE.HemisphereLight(0xc2cbd2, 0x6e5c40, 1.0);
    this.ambiental.name = 'luz-ambiental';
    esc.add(this.ambiental);

    // relleno opuesto al sol: rescata la cara en sombra de las siluetas sin
    // aplanar el contraste (intensidad baja y tinte apenas frío).
    this.relleno = new THREE.DirectionalLight(0xa8bccc, 0.28);
    this.relleno.name = 'luz-relleno';
    this.relleno.castShadow = false;
    esc.add(this.relleno, this.relleno.target);

    // REBOTE: el suelo iluminado devuelve luz cálida hacia arriba. Entra desde
    // abajo y desde el lado del sol, así que sólo toca las caras que miran al
    // piso —las que el hemisférico nunca alcanza porque su peso ahí es el color
    // de suelo—. Sin esto, las panzas de unidades y aleros quedan azules.
    this.rebote = new THREE.DirectionalLight(0xffc98e, 0.0);
    this.rebote.name = 'luz-rebote';
    this.rebote.castShadow = false;
    esc.add(this.rebote, this.rebote.target);
  }

  /* ------------------------------------------------------------- paletas */

  _paletaDe(n) {
    const e = EDADES[clamp(n | 0, 0, EDADES.length - 1)];
    const a = ATMOSFERA_EDAD[clamp(n | 0, 0, ATMOSFERA_EDAD.length - 1)];
    const tinte = _c1.set(e.cielo.tinteSol);
    const nube = _c2.set(a.tinteNube);
    return {
      turbiedad: e.cielo.turbiedad,
      niebla: e.cielo.niebla,
      rayleigh: a.rayleigh,
      cobertura: a.cobertura,
      bruma: a.bruma,
      hora: e.cielo.hora,
      tinteR: tinte.r, tinteG: tinte.g, tinteB: tinte.b,
      nubeR: nube.r, nubeG: nube.g, nubeB: nube.b,
    };
  }

  /**
   * Cambia la paleta atmosférica de la edad `n`. Interpola en 2 s.
   * Si el ciclo día/noche está apagado (`ctx.cicloDia === false`) también lleva
   * la hora del día a la de la edad: así el juego "envejece" de la mañana del
   * Vapor al atardecer violeta de la Sintética.
   */
  setEdad(n, inmediato = false) {
    const destino = this._paletaDe(n);
    this.edad = clamp(n | 0, 0, EDADES.length - 1);
    this._palOrigen = { ...this._pal };
    this._palDestino = destino;
    this._tEdad = inmediato ? 1 : 0;
    if (inmediato) this._pal = { ...destino };
    if (this.ctx.cicloDia === false) {
      this._horaDestino = destino.hora;
      if (inmediato) this._hora = destino.hora;
    }
  }

  /* ---------------------------------------------------------- hora del día */

  get horaDelDia() { return this._hora; }
  set horaDelDia(h) {
    this._hora = ((h % 24) + 24) % 24;
    this._horaDestino = undefined;
    this._actualizarAstros();
    this._actualizarAtmosfera();
    this._actualizarLuces();
  }

  /* ------------------------------------------------------------- astros */

  _actualizarAstros() {
    const h = this._hora;
    const H = (h / 24) * TAU - Math.PI;           // ángulo horario (0 = mediodía)
    const sl = Math.sin(this.latitud), cl = Math.cos(this.latitud);

    const colocar = (angHorario, dec, salida) => {
      const sd = Math.sin(dec), cd = Math.cos(dec);
      const sH = Math.sin(angHorario), cH = Math.cos(angHorario);
      const U = sl * sd + cl * cd * cH;            // altura
      const N = sd * cl - cd * sl * cH;            // componente norte
      const E = -cd * sH;                          // componente este
      // +X = este, +Y = arriba, -Z = norte
      return salida.set(E, U, -N).normalize();
    };

    colocar(H, this.declinacion, this.dirSol);
    // la luna va retrasada respecto del sol según la fase: la fase del disco
    // sale sola porque la ilumina el mismo uDirSol del shader.
    colocar(H - TAU * this.faseLuna, this.declinacion * 0.4 + 0.09, this.dirLuna);

    const diurno = smoothstep(-0.08, 0.06, this.dirSol.y);
    this.dirLuzDominante.copy(this.dirSol).multiplyScalar(diurno)
      .addScaledVector(this.dirLuna, 1 - diurno);
    if (this.dirLuzDominante.lengthSq() < 1e-6) this.dirLuzDominante.copy(this.dirSol);
    this.dirLuzDominante.normalize();

    this.uniformes.uAngSideral.value = (h / 24) * TAU * 0.98;
    this.uniformes.uFaseLuna.value = this.faseLuna;
    uniformesCielo.uDirSol.value.copy(this.dirSol);
  }

  /* --------------------------------------------------------- atmósfera */

  /** Coeficientes de dispersión: sólo dependen de turbiedad y altura del sol. */
  _actualizarAtmosfera() {
    const p = this._pal;
    const u = this.uniformes;
    const altSol = this.dirSol.y;

    const desvanecido = smoothstep(-0.02, 0.30, altSol);
    const coefR = p.rayleigh - (1 - desvanecido);
    for (let i = 0; i < 3; i++) _betaR[i] = RAYLEIGH_TOTAL[i] * coefR;
    const c = (0.2 * p.turbiedad) * 1e-18;
    for (let i = 0; i < 3; i++) _betaM[i] = 0.434 * c * MIE_CONST[i] * 0.005;

    u.uBetaR.value.set(_betaR[0], _betaR[1], _betaR[2]);
    u.uBetaM.value.set(_betaM[0], _betaM[1], _betaM[2]);

    const zenitSol = Math.acos(clamp(altSol, -1, 1));
    u.uSolE.value = EE * Math.max(0, 1 - Math.exp(-((ANGULO_CORTE - zenitSol) / PENDIENTE_CORTE)));
    u.uMieG.value = 0.76 + (p.turbiedad - 2) * 0.012;

    const noche = 1 - smoothstep(-0.14, 0.05, altSol);
    u.uNoche.value = noche;
    u.uBruma.value = p.bruma * (0.55 + 0.45 * (1 - noche));
    u.uCobertura.value = p.cobertura;
    u.uCirros.value = 0.30 + p.cobertura * 0.7;
    u.uTinteNube.value.setRGB(p.nubeR, p.nubeG, p.nubeB);

    // color del sol: cuerpo negro 2900 K en el horizonte → 6500 K en el cenit,
    // multiplicado por el tinte narrativo de la edad.
    // POR QUÉ 2900 y no 1800: a 1800 K el cuerpo negro normalizado da (1, 0.21, 0)
    // en lineal, o sea AZUL CERO y luma 0.36. Sobre pasto (que casi no tiene
    // rojo) eso es prácticamente apagar la luz, y encima deja el canal azul del
    // cuadro entero en 15 sobre 255. La Edad Sintética, que arranca a las 18:24,
    // salía con luma media 5.5 sobre 255 justo por esto. A 2900 K sigue siendo
    // luz de atardecer, pero el azul no se muere.
    const kelvin = lerp(2900, 6500, smoothstep(-0.02, 0.32, altSol));
    cuerpoNegro(kelvin, _c1);
    _c1.setRGB(_c1.r * p.tinteR, _c1.g * p.tinteG, _c1.b * p.tinteB);
    // `cuerpoNegro` normaliza al canal más alto, así que ponerse cálido CUESTA
    // luminancia. Si además la intensidad ya cae con la altura del sol, el
    // atardecer se apaga dos veces. Devolvemos casi toda la luma perdida: el sol
    // se pone dorado, no negro; oscurecer es tarea de `intensidadSol`.
    const lumSol = _c1.r * 0.2126 + _c1.g * 0.7152 + _c1.b * 0.0722;
    const compensa = 1 / clamp(lerp(1, lumSol, 0.80), 0.30, 1);
    _c1.setRGB(_c1.r * compensa, _c1.g * compensa, _c1.b * compensa);
    u.uColorSol.value.copy(_c1);

    // Color de la niebla: se lee del propio modelo de cielo a ~4° del horizonte
    // en la dirección hacia la que mira la cámara. Así el terreno lejano y el
    // cielo comparten exactamente el mismo aire.
    const cam = this.ctx.camara;
    _v1.set(0, 0, -1).applyQuaternion(cam.quaternion);
    _v1.y = 0;
    if (_v1.lengthSq() < 1e-6) _v1.set(0, 0, -1);
    _v1.normalize().multiplyScalar(0.9985);
    _v1.y = 0.070;
    _v1.normalize();
    this._evaluarCielo(_v1, _rgbTmp);

    // PISO NOCTURNO DEL AIRE. El anterior (0.008 a 0.022 lineal) es cero
    // práctico: después de ACES da 3 sobre 255 y el terreno lejano se recortaba
    // contra la nada. Un aire nocturno creíble ronda 0.05-0.12 en lineal —la
    // luna, la dispersión y las luces de la ciudad lo sostienen— y hace que los
    // cerros del fondo se derritan en bruma azul en vez de desaparecer.
    const nr = Math.max(_rgbTmp[0], NOCHE.niebla[0] * noche);
    const ng = Math.max(_rgbTmp[1], NOCHE.niebla[1] * noche);
    const nb = Math.max(_rgbTmp[2], NOCHE.niebla[2] * noche);
    // la niebla se desatura un pelo: si copia el cielo tal cual, tiñe demasiado
    const lum = nr * 0.2126 + ng * 0.7152 + nb * 0.0722;
    let fr = lerp(lum, nr, 0.82), fg = lerp(lum, ng, 0.82), fb = lerp(lum, nb, 0.82);
    // El cielo es HDR: a mediodía el cenit pasa de 3.0 en lineal. Usado tal cual
    // como color de niebla, cada píxel lejano suma más luz de la que tenía y la
    // escena se lava a blanco. La perspectiva aérea real es luz DISPERSADA, más
    // tenue que el cielo: normalizamos al canal más alto y la dejamos por debajo
    // del blanco difuso para que tiña sin iluminar.
    const pico = Math.max(fr, fg, fb, 1e-4);
    const esc = Math.min(1, 0.78 / pico);
    fr *= esc; fg *= esc; fb *= esc;
    // Este sigue siendo el aire del DOMO —nubes, cirros, bruma de horizonte—, que
    // vive en el mismo rango que el cielo porque ES cielo. El aire que tiñe la
    // GEOMETRÍA es otra cosa y va bastante más abajo: se arma en
    // `_actualizarLuces`, que es donde se conoce la irradiancia del frame.
    uniformesCielo.uNieblaColor.value.setRGB(fr, fg, fb);
    _aire[0] = fr; _aire[1] = fg; _aire[2] = fb;

    // DENSIDAD. Los valores de src/data eran "densidad artística" y con el ×0,10
    // que tenían acá quedaban en 0,0006-0,0016: a 130 m —el fondo del cuadro con
    // la cámara canónica— la niebla se comía un 2 % del contraste, o sea que no
    // actuaba y el cuadro no tenía ni cerca ni lejos. Ahora la escala la fija
    // DENSIDAD_AEREA (ver su cabecera) y la edad sólo la corre ±13 %: el aire
    // sucio del Vapor y de la Eléctrica pesa más que el aire limpio de la
    // Sintética, pero ninguna edad puede volver a quedarse sin profundidad.
    this.niebla.density = DENSIDAD_AEREA * (0.74 + p.niebla * 20);

    uniformesCielo.uNieblaAltura.value.set(0.0, 1 / 38, 0.42 + p.bruma * 0.35);
  }

  /**
   * Misma dispersión que el shader, evaluada en CPU. Se usa para el color de la
   * niebla y para la luz ambiental: garantiza que cielo, niebla y rebote
   * ambiental sean literalmente el mismo modelo.
   */
  _evaluarCielo(dir, salida) {
    const u = this.uniformes;
    const bR = u.uBetaR.value, bM = u.uBetaM.value, solE = u.uSolE.value, g = u.uMieG.value;
    const cosT = dir.x * this.dirSol.x + dir.y * this.dirSol.y + dir.z * this.dirSol.z;
    const zen = Math.acos(clamp(Math.max(dir.y, -0.03), -1, 1));
    const denom = Math.cos(zen) + 0.15 * Math.pow(Math.max(93.885 - zen * 180 / Math.PI, 1e-3), -1.253);
    const inv = 1 / Math.max(denom, 1e-3);
    const rp = (3 / (16 * Math.PI)) * (1 + cosT * cosT);
    const g2 = g * g;
    const mp = (1 / (4 * Math.PI)) * ((1 - g2) / Math.pow(Math.max(1 + g2 - 2 * g * cosT, 1e-4), 1.5));
    const bRv = [bR.x, bR.y, bR.z], bMv = [bM.x, bM.y, bM.z];
    const antiSol = clamp(Math.pow(1 - this.dirSol.y, 5), 0, 1);
    for (let i = 0; i < 3; i++) {
      const fex = Math.exp(-(bRv[i] * RAYLEIGH_ZENIT * inv + bMv[i] * MIE_ZENIT * inv));
      _fexTmp[i] = fex;
      const ratio = (bRv[i] * rp + bMv[i] * mp) / (bRv[i] + bMv[i]);
      let lin = Math.pow(Math.max(solE * ratio * (1 - fex), 0), 1.5);
      const mezcla = Math.pow(Math.max(solE * ratio * fex, 0), 0.5);
      lin *= lerp(1, mezcla, antiSol);
      salida[i] = lin * 0.04 * u.uExposicion.value;
    }
    return salida;
  }

  /* ------------------------------------------------------------- luces */

  _actualizarLuces() {
    const altSol = this.dirSol.y;
    const u = this.uniformes;
    const p = this._pal;
    const noche = u.uNoche.value;          // 1 = noche cerrada; lo fija _actualizarAtmosfera
    const diurno = smoothstep(-0.06, 0.20, altSol);

    /* ------------------------------------------------------------------ sol */
    // El sol se apaga cuando TOCA el horizonte, no doce grados antes. Con la
    // rampa vieja un sol a 7° ya valía la mitad, y como encima el cuerpo negro
    // de 1800 K le comía la luminancia, el atardecer de la Sintética terminaba
    // en luma media 5.5 sobre 255.
    const solSobre = smoothstep(-0.055, 0.055, altSol);
    const intensidadSol = solSobre * lerp(2.15, 3.95, smoothstep(0.02, 0.50, altSol));

    // El sol rasante no LLEGA al piso: con el disco a 2° el coseno vale 0.03 y
    // el terreno se apaga aunque la luz esté encendida (es lo que mataba a la
    // Edad Sintética, que arranca 18:24). La DIRECCIÓN de la luz nunca baja de
    // ~13° aunque el disco sí lo haga: se conserva el azimut —que es lo único
    // que uno lee en una sombra— y se recupera el coseno. Convención de RTS,
    // igual que el sol fijo de Age of Empires.
    this.dirLuzSol.copy(this.dirSol);
    if (this.dirLuzSol.y < 0.23) { this.dirLuzSol.y = 0.23; this.dirLuzSol.normalize(); }

    /* ----------------------------------------------------------------- luna */
    // La luna es una FUENTE, no un adorno: con 0.30 de intensidad no llegaba a
    // marcar ni una silueta. Y si está bajo el horizonte no hay disco que
    // mirar, pero la escena SIGUE necesitando una key que dé volumen: espejamos
    // la altura conservando el azimut (nunca por debajo de 0.26) y bajamos un
    // poco la intensidad. Es la misma convención del sol fijo de un RTS
    // clásico, y nadie puede detectarla porque el disco no se ve.
    this.dirLuzLuna.copy(this.dirLuna);
    if (this.dirLuzLuna.y < 0.26) {
      this.dirLuzLuna.y = Math.max(Math.abs(this.dirLuzLuna.y), 0.26);
      this.dirLuzLuna.normalize();
    }
    const lunaReal = smoothstep(-0.06, 0.20, this.dirLuna.y);
    const intensidadLuna = noche * NOCHE.lunaIrradiancia * lerp(0.70, 1.0, lunaReal);

    /* -------------------------------------------------- dirección dominante */
    // Promedio ponderado por energía: en el crepúsculo la key rota del sol a la
    // luna sin saltos. El piso en Y evita que el CSM proyecte desde el subsuelo
    // cuando la única luz viva está rozando el horizonte.
    _v2.copy(this.dirLuzSol).multiplyScalar(intensidadSol)
      .addScaledVector(this.dirLuzLuna, intensidadLuna);
    if (_v2.lengthSq() < 1e-6) _v2.copy(this.dirSol);
    _v2.normalize();
    if (_v2.y < 0.10) { _v2.y = 0.10; _v2.normalize(); }
    this.dirLuzDominante.copy(_v2);

    /* ----------------------------------------------- reparto en las luces */
    // Sombras.js DELEGA el sol: apaga este DirectionalLight y le copia color e
    // intensidad a las cascadas del CSM, que apuntan a dirLuzDominante. Si de
    // noche dejáramos `sol` en cero, el CSM no proyectaría nada y la luna (que
    // no castea) daría una noche plana. Así que cuando hay delegación el "sol"
    // ES la luna de noche: mismo color, misma dirección, sombras incluidas.
    const delegado = !!this._solDelegado;
    _c1.copy(u.uColorSol.value);
    if (delegado && intensidadLuna > 0.001) {
      _c3.setRGB(NOCHE.lunaColor[0], NOCHE.lunaColor[1], NOCHE.lunaColor[2]);
      _c1.lerp(_c3, intensidadLuna / Math.max(intensidadSol + intensidadLuna, 1e-4));
    }
    this.sol.color.copy(_c1);
    this.sol.intensity = delegado ? intensidadSol + intensidadLuna : intensidadSol;
    this.sol.position.copy(delegado ? this.dirLuzDominante : this.dirLuzSol).multiplyScalar(320);
    this.sol.target.position.set(0, 0, 0);
    this.sol.visible = !delegado && intensidadSol > 0.004;

    this.luna.color.setRGB(NOCHE.lunaColor[0], NOCHE.lunaColor[1], NOCHE.lunaColor[2]);
    this.luna.intensity = delegado ? 0 : intensidadLuna;
    this.luna.position.copy(this.dirLuzLuna).multiplyScalar(320);
    this.luna.target.position.set(0, 0, 0);
    this.luna.visible = !delegado && intensidadLuna > 0.004;

    // color de luz dominante: alimenta las nubes y el uniform compartido
    _c1.copy(u.uColorSol.value).multiplyScalar(lerp(0.55, 1.0, diurno));
    _c3.setRGB(NOCHE.lunaColor[0] * 0.55, NOCHE.lunaColor[1] * 0.55, NOCHE.lunaColor[2] * 0.55);
    _c1.lerp(_c3, noche);
    uniformesCielo.uColorLuz.value.copy(_c1);

    /* ------------------------------------------------------------- ambiente */
    // AMBIENTE QUE NO TIÑE. El cenit del modelo es Rayleigh casi puro: rojo
    // ~0.02 contra azul ~0.9. Como en sombra plena el hemisférico es lo ÚNICO
    // que queda, sobre pasto verde eso daba sombras TEAL. Dos correcciones:
    //   1) mezclamos el cenit con el aire de cerca del horizonte del lado del
    //      sol, que es donde vive el cálido (y al atardecer es lo único
    //      encendido, así que además rescata el crepúsculo);
    //   2) desaturamos hacia la propia luminancia con un sesgo cálido, dejando
    //      sólo el toque frío que uno espera de una sombra.
    _v1.set(0, 1, 0);
    this._evaluarCielo(_v1, _rgbTmp);
    _v2.set(this.dirSol.x, 0.22, this.dirSol.z);
    if (_v2.lengthSq() < 1e-5) _v2.set(0, 1, 0);
    _v2.normalize();
    this._evaluarCielo(_v2, _rgbAmb);

    // kCielo cierra el presupuesto de sombra plena: a mediodía la irradiancia
    // ambiente queda en ~1.35 contra ~3.4 del sol, así que el pasto en sombra
    // vale 0.130 lineal contra 0.396 iluminado = 0.33 (el mínimo tolerable era
    // 0.18, y en pantalla son 104 contra 183). Subirlo aplana el día; bajarlo
    // vuelve a hundir las sombras.
    const kCielo = 1.45;
    let ar = (_rgbTmp[0] * 0.55 + _rgbAmb[0] * 0.45) * kCielo;
    let ag = (_rgbTmp[1] * 0.55 + _rgbAmb[1] * 0.45) * kCielo;
    let ab = (_rgbTmp[2] * 0.55 + _rgbAmb[2] * 0.45) * kCielo;
    const lumCielo = ar * 0.2126 + ag * 0.7152 + ab * 0.0722;
    ar = lerp(lumCielo * 1.12, ar, 0.48);
    ag = lerp(lumCielo * 1.00, ag, 0.48);
    ab = lerp(lumCielo * 0.90, ab, 0.48);

    // CREPÚSCULO: dos muestras (cenit + aire del lado del sol) subestiman el
    // domo justo cuando el domo ENTERO es la luz principal. Con el sol a 7° el
    // haz directo casi no llega al piso —el coseno se lo come— y la Sintética,
    // que arranca 18:24, quedaba en luma 60. Este término es la integral que
    // falta: aparece sólo con sol bajo y muere con sol alto.
    // Curva angosta a propósito: si empezara con el sol a 25° le comería el
    // contraste a toda la mañana; sólo tiene que rescatar el rasante.
    const crepusculo = smoothstep(0.26, 0.02, altSol) * solSobre * 1.05;
    ar += crepusculo * 1.10;
    ag += crepusculo * 1.00;
    ab += crepusculo * 0.92;
    // Piso nocturno: ADITIVO, no un max(), para que el crepúsculo no tenga un
    // bache entre "ya no hay sol" y "todavía no es noche cerrada".
    ar += NOCHE.ambColor[0] * NOCHE.ambIrradiancia * noche;
    ag += NOCHE.ambColor[1] * NOCHE.ambIrradiancia * noche;
    ab += NOCHE.ambColor[2] * NOCHE.ambIrradiancia * noche;

    // La magnitud va toda en el color (irradiancia lineal) y la intensidad
    // queda en 1: un solo lugar donde mirar cuando algo sale oscuro.
    this.ambiental.color.setRGB(ar, ag, ab);
    this.ambiental.intensity = 1.0;

    // El hemisferio de abajo es el REBOTE del terreno: cálido y proporcional a
    // lo que el sol le está pegando al piso (por eso entra el coseno). Los
    // pesos 0.42/0.30/0.17 son el albedo de una tierra con pasto.
    const eco = intensidadSol * clamp(this.dirLuzSol.y, 0, 1) * 0.15;
    this.ambiental.groundColor.setRGB(
      ar * 0.30 + u.uColorSol.value.r * eco * 0.42 * p.tinteR
        + NOCHE.sueloColor[0] * NOCHE.sueloIrradiancia * noche,
      ag * 0.30 + u.uColorSol.value.g * eco * 0.30 * p.tinteG
        + NOCHE.sueloColor[1] * NOCHE.sueloIrradiancia * noche,
      ab * 0.30 + u.uColorSol.value.b * eco * 0.17 * p.tinteB
        + NOCHE.sueloColor[2] * NOCHE.sueloIrradiancia * noche,
    );

    // Relleno opuesto al sol: da la vuelta a las siluetas. Antes iba con un
    // 0.42/0.52/0.75 (azul casi puro) que SUMABA al teal en vez de compensarlo;
    // ahora es el propio ambiente empujado apenas al frío, y su intensidad es
    // una fracción del ambiente para que no haya dos escalas peleando.
    const lumAmb = Math.max(ar * 0.2126 + ag * 0.7152 + ab * 0.0722, 1e-3);
    this.relleno.position.set(-this.dirSol.x * 300, Math.max(70, this.dirSol.y * 120), -this.dirSol.z * 300);
    this.relleno.target.position.set(0, 0, 0);
    this.relleno.color.setRGB(ar / lumAmb, ag / lumAmb, ab / lumAmb)
      .lerp(_c2.setRGB(0.80, 0.90, 1.06), 0.26);
    this.relleno.intensity = lumAmb * lerp(0.12, 0.22, diurno);

    // Rebote direccional: entra desde ABAJO y desde el lado del sol, así que
    // sólo toca las caras que miran al piso (las que el hemisférico no alcanza).
    // Es lo que saca del azul las panzas de unidades, carros y aleros.
    this.rebote.position.set(this.dirSol.x * 300, -150, this.dirSol.z * 300);
    this.rebote.target.position.set(0, 0, 0);
    this.rebote.color.copy(u.uColorSol.value).lerp(_c2.setRGB(1.0, 0.66, 0.36), 0.55);
    this.rebote.intensity = eco * 1.6;
    // De noche no hay rebote que valga la pena y una direccional invisible no
    // entra en la cuenta de luces del shader: apagarla es un permutación menos
    // y unas cuantas ALU por fragmento menos con 200+ unidades en pantalla.
    this.rebote.visible = this.rebote.intensity > 0.02;

    /* ---------------------------------------- perspectiva aérea (geometría) */
    // POR QUÉ EL COLOR DE LA NIEBLA SE ARMA ACÁ y no junto al resto de la
    // atmósfera: tiene que estar atado al PRESUPUESTO DE LUZ del frame, y el
    // presupuesto recién existe unas líneas más arriba.
    //
    // La bruma NO es una fuente de luz: es la irradiancia del cielo dispersada
    // por el aire hacia la cámara, así que su radiancia vale
    //     (irradiancia / π) · albedo del aire.
    // El blanco difuso de la escena es esa misma cuenta con albedo 0,9, o sea
    // que la bruma queda por construcción en 0,30/0,90 = un tercio del blanco
    // difuso y NUNCA puede pasarlo. Eso es exactamente lo que falló la vez que
    // se usó el color del domo tal cual: 0,65 de luma lineal, que por la cadena
    // real (ACES de three con exposición/0,6 + gradeo) mide 226 sobre 255, MÁS
    // que el techo más claro de la aldea (216 medido). Con una niebla más
    // brillante que el contenido, cada píxel lejano suma luz, la escena se lava y
    // el fondo pasa a ser lo más claro del cuadro. Con el ancla de acá abajo el
    // aire de mediodía mide 185: por encima del pasto (126) y por debajo de los
    // techos, que es donde tiene que estar para hundir el fondo sin encenderlo.
    //
    // El aire aporta a la irradiancia sólo una fracción del haz directo (0,30):
    // el sol atraviesa la columna de aire, no la ilumina de frente.
    const lumColorSol = u.uColorSol.value.r * 0.2126 + u.uColorSol.value.g * 0.7152
      + u.uColorSol.value.b * 0.0722;
    const lumColorLuna = NOCHE.lunaColor[0] * 0.2126 + NOCHE.lunaColor[1] * 0.7152
      + NOCHE.lunaColor[2] * 0.0722;
    const irradAire = lumAmb
      + lumColorSol * intensidadSol * clamp(this.dirLuzSol.y, 0, 1) * 0.30
      + lumColorLuna * intensidadLuna * 0.30;
    // Piso nocturno: el aire de noche no es negro (misma convención que
    // NOCHE.niebla), si no los cerros del fondo se recortan contra la nada.
    const lumaNoche = (NOCHE.niebla[0] * 0.2126 + NOCHE.niebla[1] * 0.7152
      + NOCHE.niebla[2] * 0.0722) * noche;
    const lumaNiebla = Math.max(irradAire * (1 / Math.PI) * ALBEDO_AIRE, lumaNoche);
    // El TINTE sale del domo (así el terreno lejano y el cielo comparten el
    // mismo aire) y la MAGNITUD sale de la cuenta de arriba: se reescala la luma
    // sin tocar el croma.
    const lumaAire = Math.max(_aire[0] * 0.2126 + _aire[1] * 0.7152 + _aire[2] * 0.0722, 1e-4);
    const kAire = lumaNiebla / lumaAire;
    this.niebla.color.setRGB(_aire[0] * kAire, _aire[1] * kAire, _aire[2] * kAire);

    /* ----------------------------------------------------------- exposición */
    // La noche se lee por color, pero tiene que ser JUGABLE: subimos la
    // exposición del tone mapping al caer el sol. `noche` ya es una rampa suave
    // sobre la altura solar, así que no hace falta filtrar en el tiempo.
    // Renderer puede exponer setExposicion(); si todavía no existe, dejamos el
    // objetivo escrito para que lo levante cuando esté.
    const render = this.ctx.render;
    if (render) {
      // rampa propia, más ancha que `noche`: si usara la misma, el cambio de
      // exposición se comería en 20 minutos de juego y se notaría el salto.
      // Tres tramos, no dos: el ocaso es donde la escena tiene menos radiancia
      // y donde una interpolación directa día→noche la deja hundida.
      const tNoche = smoothstep(0.16, -0.12, altSol);
      const tOcaso = smoothstep(0.34, 0.06, altSol) * (1 - tNoche);
      const expo = EXPOSICION.dia * (1 - tOcaso - tNoche)
        + EXPOSICION.ocaso * tOcaso
        + EXPOSICION.noche * tNoche;
      render.exposicionObjetivo = expo;
      render.setExposicion?.(expo);
    }
  }

  /* -------------------------------------------------------------- ciclo */

  /** Fija la hora sin disparar el recálculo completo (uso interno del ciclo). */
  setHora(h) { this.horaDelDia = h; }

  cada(dtReal, alfa, ctx) {
    const dt = Math.min(dtReal, 0.1);
    this.tiempo += dt;
    uniformesCielo.uTiempoCielo.value = this.tiempo;

    if (ctx.cicloDia !== false) {
      this._hora = (this._hora + dt * this.horasPorSegundo * 24 / 24) % 24;
      // la luna se atrasa ~50 min por día: la fase avanza sola
      this.faseLuna = (this.faseLuna + dt * this.horasPorSegundo / 24 / 29.53) % 1;
    } else if (this._horaDestino !== undefined) {
      this._hora = lerp(this._hora, this._horaDestino, 1 - Math.pow(0.08, dt));
    }

    if (this._tEdad < 1) {
      this._tEdad = Math.min(1, this._tEdad + dt / this._duracionEdad);
      const k = smoothstep(0, 1, this._tEdad);
      const a = this._palOrigen, b = this._palDestino, p = this._pal;
      for (const clave in b) p[clave] = lerp(a[clave], b[clave], k);
      if (this.ctx.cicloDia === false) this._horaDestino = b.hora;
    }

    this._actualizarAstros();
    this._actualizarAtmosfera();
    this._actualizarLuces();

    // la cúpula viaja con la cámara y se escala al plano lejano vigente: así
    // nunca la recorta el frustum por más que el zoom cambie near/far.
    const cam = ctx.camara;
    const r = Math.max(60, cam.far * 0.45);
    this.cupula.position.copy(cam.position);
    this.cupula.scale.setScalar(r);
    this.cupula.updateMatrix();
    this.cupula.matrixWorld.copy(this.cupula.matrix);

    // el viento arrastra las nubes despacio y la cobertura respira
    const u = this.uniformes;
    u.uDensidadNube.value = 0.85 + 0.30 * Math.sin(this.tiempo * 0.021) * Math.cos(this.tiempo * 0.0073);
  }

  /** Cambia el coste del cielo en caliente (lo llama Renderer.setCalidad). */
  setCalidad(calidad) {
    const p = PRESET_CIELO[calidad] || PRESET_CIELO.alta;
    if (p === this.preset) return;
    this.preset = p;
    this.material.defines.PASOS_NUBE = p.pasosNube;
    this.material.defines.PASOS_LUZ = p.pasosLuz;
    this.material.defines.CIRROS = p.cirros;
    this.material.needsUpdate = true;
  }

  dispose() {
    this.ctx.escena.remove(this.cupula);
    this.cupula.geometry.dispose();
    this.material.dispose();
    this.ruido3D.dispose();
  }
}

/**
 * Arnés de desarrollo. Se carga solo con ?arnes=1.
 *
 * Existe porque el panel del navegador corre la pestaña oculta: requestAnimationFrame
 * queda congelado y las capturas nativas salen negras. Acá manejamos el bucle a mano
 * y mandamos el PNG a tools/capturador.mjs, que lo escribe a disco.
 */
import { TIPO, ESTADO } from '../core/World.js';
import { UNIDAD_POR_CLAVE, UNIDADES } from '../data/unidades.js';
import { EDIFICIO_POR_CLAVE, EDIFICIOS } from '../data/edificios.js';

const PUERTO_CAPTURA = 'http://127.0.0.1:8912';

export function instalar(ctx) {
  const A = {};

  /** Corre n pasos de simulación y un frame de render lógico. Devuelve los errores únicos. */
  A.paso = (n = 1, dt = 1 / 20) => {
    const err = [];
    for (let k = 0; k < n; k++) {
      ctx.mundo.tick++; ctx.mundo.tiempo += dt; ctx.mundo.reconstruirRejilla();
      for (const s of ctx.motor.sistemas) {
        if (!s.fijo) continue;
        try { s.fijo(dt, ctx); } catch (e) { err.push(`${s.nombre}:fijo:${e.message}`); }
      }
      // cada() va dentro del lazo: varios sistemas (sombras, foliaje, vista)
      // hacen su trabajo perezoso acá y si lo llamamos una sola vez al final
      // el arnés miente sobre el estado real del juego.
      for (const s of ctx.motor.sistemas) {
        if (!s.cada) continue;
        try { s.cada(1 / 60, 0, ctx); } catch (e) { err.push(`${s.nombre}:cada:${e.message}`); }
      }
    }
    return [...new Set(err)];
  };

  /**
   * Histograma del cuadro + CONTRASTE LOCAL.
   *
   * La luma media global se saturó como métrica: las seis escenas entran en la
   * banda de la referencia (110-136) y el panel de arte igual sigue diciendo
   * "todo el cuadro en una sola banda verde-oliva". Un cuadro puede tener la
   * media perfecta y no tener NADA que mirar, porque lo que hace que una imagen
   * se lea es la diferencia LOCAL entre el suelo y lo que está encima.
   *
   * Por eso acá se mide, además:
   *  - `contrasteLocal`: desvío estándar de luma promediado sobre baldosas de
   *    32x32. Es lo que sube cuando un edificio se despega de su fondo y lo que
   *    NO sube cuando simplemente subís la exposición.
   *  - `rangoIntercuartil`: p75 - p25. Mide cuánto del rango se está usando de
   *    verdad, sin que un cielo brillante o una sombra profunda lo disfracen.
   *  - `croma`: saturación media. El panel se quejó de una sola banda de color,
   *    no solo de valor.
   * Referencia medida sobre Age of Empires II DE: contrasteLocal 26-34,
   * rangoIntercuartil 62-88.
   */
  A.medir = (lado = 480) => {
    const src = ctx.renderer.domElement;
    const alto = Math.round(lado * 9 / 16);
    const c = document.createElement('canvas');
    c.width = lado; c.height = alto;
    const g = c.getContext('2d');
    g.drawImage(src, 0, 0, lado, alto);
    const d = g.getImageData(0, 0, lado, alto).data;

    const luma = new Float32Array(lado * alto);
    let suma = 0, bajo = 0, alto200 = 0, croma = 0;
    const hist = new Uint32Array(256);
    for (let i = 0, p = 0; i < d.length; i += 4, p++) {
      const r = d[i], gg = d[i + 1], b = d[i + 2];
      const l = 0.2126 * r + 0.7152 * gg + 0.0722 * b;
      luma[p] = l; suma += l;
      if (l < 32) bajo++;
      if (l > 200) alto200++;
      hist[Math.min(255, Math.round(l))]++;
      const mx = Math.max(r, gg, b), mn = Math.min(r, gg, b);
      croma += mx ? (mx - mn) / mx : 0;
    }
    const n = luma.length;

    // desvío estándar por baldosa: contraste local
    const T = 32;
    let sumaDesvio = 0, baldosas = 0;
    for (let by = 0; by + T <= alto; by += T) {
      for (let bx = 0; bx + T <= lado; bx += T) {
        let s = 0, s2 = 0;
        for (let y = 0; y < T; y++) {
          const fila = (by + y) * lado + bx;
          for (let x = 0; x < T; x++) { const v = luma[fila + x]; s += v; s2 += v * v; }
        }
        const m = s / (T * T);
        sumaDesvio += Math.sqrt(Math.max(0, s2 / (T * T) - m * m));
        baldosas++;
      }
    }

    const cuantil = (q) => {
      let acum = 0; const meta = q * n;
      for (let i = 0; i < 256; i++) { acum += hist[i]; if (acum >= meta) return i; }
      return 255;
    };

    return {
      media: +(suma / n).toFixed(1),
      bajo: +(100 * bajo / n).toFixed(1),
      alto: +(100 * alto200 / n).toFixed(1),
      contrasteLocal: +(sumaDesvio / Math.max(1, baldosas)).toFixed(1),
      rangoIntercuartil: cuantil(0.75) - cuantil(0.25),
      croma: +(croma / n).toFixed(3),
    };
  };

  A.tirar = (nombre) => {
    ctx.render.composer.render(1 / 60);
    const url = ctx.renderer.domElement.toDataURL('image/png');
    return fetch(`${PUERTO_CAPTURA}/?nombre=${encodeURIComponent(nombre)}`, { method: 'POST', body: url })
      .then((r) => r.text());
  };

  /** Coloca la cámara en la vista de juego canónica. */
  A.mirar = (x, z, dist = 78, elev = 0.86, azi = Math.PI * 0.25) => {
    const c = ctx.camCtrl;
    c.enfocar(x, z, true);
    c.distancia = c.distanciaObjetivo = dist;
    c.elevacion = c.elevacionObjetivo = elev;
    c.azimut = c.azimutObjetivo = azi;
    c.cada(0.016);
  };

  A.hora = (h) => { ctx.cielo.horaDelDia = h; ctx.cielo.cada?.(0.016, 0, ctx); };
  A.edad = (n) => {
    ctx.edades.edad[0] = n;
    ctx.cielo.setEdad?.(n);
    ctx.agua?.setEdad?.(n);
    ctx.bus.emit('edad:avanzada', { jugador: 0, edad: n });
    ctx.bus.emit('edad:remodelar', { jugador: 0, edad: n });
  };
  A.niebla = (activa) => {
    ctx.niebla.activa = activa;
    if (ctx.niebla.malla) ctx.niebla.malla.visible = activa;
  };

  /** Suelta unidades alrededor de un punto, para poblar la escena. */
  A.tropa = (clave, cantidad, x, z, jugador = 0, radio = 8) => {
    const defId = UNIDAD_POR_CLAVE.get(clave);
    if (defId === undefined) return [];
    const def = UNIDADES[defId];
    const ids = [];
    for (let i = 0; i < cantidad; i++) {
      const a = (i / cantidad) * Math.PI * 2 + ctx.rng.float(-0.2, 0.2);
      const r = radio * Math.sqrt(ctx.rng.float(0.15, 1));
      const px = x + Math.cos(a) * r, pz = z + Math.sin(a) * r;
      const id = ctx.mundo.crear(TIPO.UNIDAD, defId, px, pz, jugador);
      ctx.mundo.vidaMax[id] = def.vida; ctx.mundo.vida[id] = def.vida;
      ctx.mundo.velocidad[id] = def.velocidad;
      ctx.mundo.radio[id] = def.clase === 'asedio' || def.clase === 'caballeria' ? 1.1 : 0.55;
      ctx.mundo.py[id] = ctx.terreno?.altura(px, pz) ?? 0;
      ctx.mundo.rot[id] = ctx.rng.float(0, Math.PI * 2);
      ids.push(id);
    }
    return ids;
  };

  A.edificio = (clave, x, z, jugador = 0, edad = null) => {
    const defId = EDIFICIO_POR_CLAVE.get(clave);
    if (defId === undefined) return -1;
    const def = EDIFICIOS[defId];
    if (edad !== null) ctx.edades.edad[jugador] = edad;
    const id = ctx.mundo.crear(TIPO.EDIFICIO, defId, x, z, jugador);
    ctx.mundo.vidaMax[id] = def.vida; ctx.mundo.vida[id] = def.vida;
    ctx.mundo.radio[id] = Math.max(def.celdas[0], def.celdas[1]);
    ctx.mundo.estado[id] = ESTADO.QUIETO;
    ctx.mundo.progreso[id] = 1;
    ctx.mundo.py[id] = ctx.terreno?.altura(x, z) ?? 0;
    ctx.terreno?.aplanar?.(x, z, def.celdas[0] * 2, def.celdas[1] * 2);
    ctx.foliaje?.despejar?.(x, z, def.celdas[0] * 2, def.celdas[1] * 2);
    return id;
  };

  /** Busca el punto del mapa que mejor represente un bioma, cerca de la base. */
  A.buscarBioma = (bioma, desdeX = 0, desdeZ = 0, radioMax = 180) => {
    for (let r = 12; r < radioMax; r += 6) {
      for (let a = 0; a < 24; a++) {
        const ang = (a / 24) * Math.PI * 2;
        const x = desdeX + Math.cos(ang) * r, z = desdeZ + Math.sin(ang) * r;
        if (ctx.terreno?.bioma(x, z) === bioma) return { x, z };
      }
    }
    return null;
  };

  window.__arnes = A;
  window.__juego = ctx;
  console.info('[arnés] instalado: window.__arnes {paso, tirar, mirar, hora, edad, niebla, tropa, edificio, buscarBioma}');
  return A;
}

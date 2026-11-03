/**
 * MOTOR DE AUDIO — Imperios 1800–2100
 * ---------------------------------------------------------------------------
 * Todo sintetizado en vivo con WebAudio: cero archivos, cero descargas.
 *
 *   ctx.audio.sfx(clave, { x, z, volumen, tono })   efecto espacializado
 *   ctx.audio.musicaEdad(n)                          cambia la cama musical
 *   ctx.audio.ambiente(bioma)                        fuerza un ambiente
 *   ctx.audio.setVolumen(maestro, musica, efectos, ambiente)
 *   ctx.audio.suspender() / reanudar()
 *
 * Arquitectura de mezcla:
 *
 *   voces sfx ─┐
 *              ├─► busEfectos ─┐
 *   ambiente ──┴─► busAmbiente ┤
 *   camas ─► duck ─► busMusica ┼─► compresor maestro ─► ganMaestro ─► salida
 *   envíos ─► convolvers ──────┘
 *
 * El AudioContext no se crea hasta el primer gesto del usuario (los navegadores
 * lo exigen). Hasta entonces todas las llamadas son inocuas.
 */

import * as THREE from 'three';
import { NODOS } from '../data/recursos.js';

/* =========================================================================
 * TABLAS
 * ========================================================================= */

/** Máximo de voces simultáneas de efectos. Se roba por prioridad y distancia. */
const MAX_VOCES = 24;

/** Modos (en semitonos desde la tónica). El sintético admite fracciones. */
const MODOS = {
  dorico: [0, 2, 3, 5, 7, 9, 10],
  eolico: [0, 2, 3, 5, 7, 8, 10],
  frigio: [0, 1, 3, 5, 7, 8, 10],
  lidio: [0, 2, 4, 6, 7, 9, 11],
  // micro-tonal: cuartos de tono, deliberadamente ajeno al temperamento igual
  sintetico: [0, 1.5, 3.5, 4.5, 6.5, 8, 9.5],
};

/**
 * Una "cama" musical por edad. Cada una define modo, tónica, tempo, frases
 * de acordes (grados de la escala) y el peso de cada familia tímbrica.
 */
const CAMAS = [
  {
    clave: 'vapor', modo: MODOS.dorico, tonica: 50, bpm: 84, percusion: 'yunque',
    frases: [[0, 5, 3, 4], [0, 3, 6, 5], [0, 4, 5, 0], [0, 6, 4, 3]],
    cuerdas: 0.60, metales: 0.26, pad: 0.10, arpegio: 0.00, dron: 0.06,
    bajo: 0.46, melodia: 0.32, reverb: 0.55, registro: 14, densidad: 0.62,
  },
  {
    clave: 'electrica', modo: MODOS.eolico, tonica: 45, bpm: 104, percusion: 'marcha',
    frases: [[0, 5, 3, 4], [0, 2, 5, 4], [0, 4, 5, 3], [0, 3, 4, 4]],
    cuerdas: 0.30, metales: 0.52, pad: 0.10, arpegio: 0.00, dron: 0.05,
    bajo: 0.52, melodia: 0.34, reverb: 0.42, registro: 14, densidad: 0.70,
  },
  {
    clave: 'atomica', modo: MODOS.frigio, tonica: 40, bpm: 72, percusion: 'pulso',
    frases: [[0, 1, 0, 6], [0, 4, 1, 0], [0, 1, 4, 3], [0, 6, 1, 0]],
    cuerdas: 0.44, metales: 0.20, pad: 0.24, arpegio: 0.00, dron: 0.22,
    bajo: 0.58, melodia: 0.26, reverb: 0.62, registro: 12, densidad: 0.48,
  },
  {
    clave: 'informacion', modo: MODOS.lidio, tonica: 53, bpm: 116, percusion: 'digital',
    frases: [[0, 4, 1, 5], [0, 3, 4, 1], [0, 5, 4, 0], [0, 1, 5, 4]],
    cuerdas: 0.14, metales: 0.06, pad: 0.34, arpegio: 0.46, dron: 0.08,
    bajo: 0.40, melodia: 0.28, reverb: 0.48, registro: 16, densidad: 0.78,
  },
  {
    clave: 'sintetica', modo: MODOS.sintetico, tonica: 48, bpm: 58, percusion: 'granular',
    frases: [[0, 3, 5, 2], [0, 2, 6, 4], [0, 4, 2, 5]],
    cuerdas: 0.10, metales: 0.04, pad: 0.30, arpegio: 0.16, dron: 0.46,
    bajo: 0.34, melodia: 0.20, reverb: 0.70, registro: 15, densidad: 0.40,
  },
];

/** Resonancias por material de impacto: [frecuencia, Q, caída, ruido, sub] */
const MATERIALES = {
  metal: { f: 2450, q: 14, caida: 0.42, ruido: 0.35, sub: 0.10, brillo: 5200 },
  chapa: { f: 1420, q: 9, caida: 0.26, ruido: 0.55, sub: 0.14, brillo: 4200 },
  madera: { f: 430, q: 6, caida: 0.13, ruido: 0.45, sub: 0.22, brillo: 2600 },
  piedra: { f: 880, q: 4, caida: 0.10, ruido: 0.70, sub: 0.34, brillo: 3000 },
  carne: { f: 168, q: 3, caida: 0.11, ruido: 0.50, sub: 0.55, brillo: 1200 },
  tierra: { f: 240, q: 2, caida: 0.16, ruido: 0.80, sub: 0.40, brillo: 900 },
  energia: { f: 3300, q: 20, caida: 0.30, ruido: 0.20, sub: 0.08, brillo: 7000 },
};

const TIPO_RECURSO = 3; // World.TIPO.RECURSO (no importamos módulos hermanos)

/* =========================================================================
 * MOTOR
 * ========================================================================= */

export class MotorAudio {
  constructor(ctx) {
    this.nombre = 'audio';
    this.orden = 90;
    this.ctx = ctx;

    /** @type {AudioContext|null} */
    this.ac = null;
    this.listo = false;
    this.mudo = false;

    // volúmenes (0..1)
    this.vol = { maestro: 0.85, musica: 0.42, efectos: 0.92, ambiente: 0.55 };

    // estado de escucha
    this._v = new THREE.Vector3();
    this._camX = 0; this._camY = 60; this._camZ = 0;
    this._derX = 1; this._derZ = 0;      // eje "derecha" de la cámara, en XZ
    this._radio = 70;                     // radio audible, sigue al zoom

    // voces
    this._voces = new Array(MAX_VOCES);
    for (let i = 0; i < MAX_VOCES; i++) {
      this._voces[i] = { activa: false, fin: 0, prio: 0, dist: 0, gan: null, fuentes: [] };
    }

    // anti-apilamiento por clave (evita muros de transitorios idénticos)
    this._ultima = new Map();
    this._pila = new Map();

    // música
    this.edadMusical = -1;
    this.camas = [];            // como mucho 2 (la que entra y la que sale)
    this.intensidad = 0;        // 0..1, combate reciente
    this._tIntensidad = 0;

    // ambiente
    this._bioma = 'pradera';
    this._biomaForzado = null;
    this._hora = 12;
    this._tAmb = 0;
    this._tPajaro = 3;
    this._tGrillo = 2;
    this._faseOla = 0;
    this._faseViento = 0;

    // trabajos audibles (hachazos, picos, martillos) alimentados por el bus
    this._trabajos = [];

    this._semilla = (ctx?.semilla ?? 20260727) >>> 0;
    this._rng = ctx?.rng?.fork ? ctx.rng.fork(0xa17d10) : null;

    this._suscribir();
    this._esperarGesto();
  }

  /* ---------------------------------------------------------------------
   * Arranque
   * ------------------------------------------------------------------- */

  _esperarGesto() {
    if (typeof window === 'undefined') return;
    const arrancar = () => {
      this._crear();
      if (this.ac && this.ac.state === 'suspended') this.ac.resume().catch(() => {});
    };
    const eventos = ['pointerdown', 'mousedown', 'keydown', 'touchstart', 'wheel'];
    const baja = () => { for (const e of eventos) window.removeEventListener(e, alGesto, true); };
    const alGesto = () => { baja(); arrancar(); };
    for (const e of eventos) window.addEventListener(e, alGesto, { capture: true, passive: true });

    document.addEventListener?.('visibilitychange', () => {
      if (!this.ac) return;
      if (document.hidden) this.suspender(); else this.reanudar();
    });
  }

  _crear() {
    if (this.ac) return;
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    let ac;
    try { ac = new AC({ latencyHint: 'interactive' }); } catch (e) { return; }
    this.ac = ac;

    /* --- cadena maestra --- */
    this.compresor = ac.createDynamicsCompressor();
    this.compresor.threshold.value = -11;
    this.compresor.knee.value = 22;
    this.compresor.ratio.value = 5.5;
    this.compresor.attack.value = 0.004;
    this.compresor.release.value = 0.20;

    this.ganMaestro = ac.createGain();
    this.ganMaestro.gain.value = this.vol.maestro;

    this.compresor.connect(this.ganMaestro).connect(ac.destination);

    /* --- buses --- */
    this.busEfectos = ac.createGain();
    this.busEfectos.gain.value = this.vol.efectos;
    this.busEfectos.connect(this.compresor);

    this.busAmbiente = ac.createGain();
    this.busAmbiente.gain.value = this.vol.ambiente;
    this.busAmbiente.connect(this.compresor);

    this.busMusica = ac.createGain();
    this.busMusica.gain.value = this.vol.musica;
    this.busMusica.connect(this.compresor);

    this.gDuck = ac.createGain();        // agacha la música cuando hay batalla
    this.gDuck.gain.value = 1;
    this.gDuck.connect(this.busMusica);

    /* --- reverberaciones (impulsos generados) --- */
    this.revCorta = ac.createConvolver();
    this.revCorta.buffer = this._impulso(0.55, 4.2, 0.55, 3);
    this.ganRevCorta = ac.createGain();
    this.ganRevCorta.gain.value = 0.9;
    this.revCorta.connect(this.ganRevCorta).connect(this.compresor);

    this.revLarga = ac.createConvolver();
    this.revLarga.buffer = this._impulso(2.6, 2.6, 0.30, 9);
    this.ganRevLarga = ac.createGain();
    this.ganRevLarga.gain.value = 0.85;
    const bajaRev = ac.createBiquadFilter();
    bajaRev.type = 'lowpass'; bajaRev.frequency.value = 3800;
    this.revLarga.connect(bajaRev).connect(this.ganRevLarga).connect(this.compresor);

    /* --- ruidos compartidos --- */
    this.bufBlanco = this._bufRuido(3.0, false);
    this.bufRosa = this._bufRuido(5.0, true);

    /* --- curvas de saturación compartidas --- */
    this.curvaSucia = this._curva(9);
    this.curvaDura = this._curva(45);

    this._crearAmbiente();
    this.listo = true;

    // si ya sabíamos la edad, arrancamos la música
    const n = this.edadMusical >= 0 ? this.edadMusical : (this.ctx?.edades?.edad?.[this.ctx.jugadorLocal] ?? 0);
    this.edadMusical = -1;
    this.musicaEdad(n);
  }

  /* ---------------------------------------------------------------------
   * Buffers y curvas
   * ------------------------------------------------------------------- */

  _az() { // aleatorio determinista, nunca Math.random
    return this._rng ? this._rng.float(0, 1) : ((this._semilla = (this._semilla * 1664525 + 1013904223) >>> 0) / 4294967296);
  }

  _bufRuido(seg, rosa) {
    const ac = this.ac, n = Math.floor(ac.sampleRate * seg);
    const buf = ac.createBuffer(2, n, ac.sampleRate);
    for (let c = 0; c < 2; c++) {
      const d = buf.getChannelData(c);
      let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
      for (let i = 0; i < n; i++) {
        const blanco = this._az() * 2 - 1;
        if (!rosa) { d[i] = blanco; continue; }
        // Paul Kellet: aproximación de ruido rosa
        b0 = 0.99886 * b0 + blanco * 0.0555179;
        b1 = 0.99332 * b1 + blanco * 0.0750759;
        b2 = 0.96900 * b2 + blanco * 0.1538520;
        b3 = 0.86650 * b3 + blanco * 0.3104856;
        b4 = 0.55000 * b4 + blanco * 0.5329522;
        b5 = -0.7616 * b5 - blanco * 0.0168980;
        d[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + blanco * 0.5362) * 0.16;
        b6 = blanco * 0.115926;
      }
    }
    return buf;
  }

  /** Impulso de reverberación: reflexiones tempranas + cola exponencial. */
  _impulso(seg, caida, brillo, taps) {
    const ac = this.ac, n = Math.floor(ac.sampleRate * seg);
    const buf = ac.createBuffer(2, n, ac.sampleRate);
    for (let c = 0; c < 2; c++) {
      const d = buf.getChannelData(c);
      let lp = 0;
      for (let i = 0; i < n; i++) {
        const t = i / n;
        const env = Math.pow(1 - t, caida);
        const v = this._az() * 2 - 1;
        lp += (v - lp) * brillo;
        d[i] = lp * env;
      }
      for (let k = 0; k < taps; k++) {
        const p = Math.floor((0.004 + this._az() * 0.09) * ac.sampleRate);
        if (p < n) d[p] += (this._az() * 2 - 1) * 0.55 * Math.pow(1 - p / n, 2);
      }
    }
    return buf;
  }

  _curva(cantidad) {
    const n = 1024, c = new Float32Array(n), k = cantidad;
    for (let i = 0; i < n; i++) {
      const x = (i * 2) / n - 1;
      c[i] = ((1 + k) * x) / (1 + k * Math.abs(x));
    }
    return c;
  }

  /* ---------------------------------------------------------------------
   * Primitivas de síntesis
   * ------------------------------------------------------------------- */

  _gan(v = 1) { const g = this.ac.createGain(); g.gain.value = v; return g; }

  _filtro(tipo, f, q = 1) {
    const b = this.ac.createBiquadFilter();
    b.type = tipo; b.frequency.value = f; b.Q.value = q;
    return b;
  }

  _osc(tipo, f, detune = 0) {
    const o = this.ac.createOscillator();
    o.type = tipo; o.frequency.value = f;
    if (detune) o.detune.value = detune;
    return o;
  }

  _ruido(rosa = false, tasa = 1) {
    const s = this.ac.createBufferSource();
    s.buffer = rosa ? this.bufRosa : this.bufBlanco;
    s.loop = true;
    if (tasa !== 1) s.playbackRate.value = tasa;
    return s;
  }

  _forma(curva) {
    const w = this.ac.createWaveShaper();
    w.curve = curva; w.oversample = '2x';
    return w;
  }

  /** Arranca una fuente y la registra en la voz para poder robarla. */
  _arrancar(voz, nodo, t, dur, offset) {
    if (nodo.buffer !== undefined) {
      const max = Math.max(0.001, nodo.buffer.duration - 0.05);
      nodo.start(t, offset !== undefined ? offset : this._az() * max);
    } else {
      nodo.start(t);
    }
    nodo.stop(t + dur);
    if (voz) voz.fuentes.push(nodo);
  }

  /** Envolvente percusiva sobre un AudioParam. */
  _envP(p, t, pico, ataque, caida) {
    const g = Math.max(0.0001, pico);
    p.setValueAtTime(0.0001, t);
    p.exponentialRampToValueAtTime(g, t + Math.max(0.0004, ataque));
    p.exponentialRampToValueAtTime(0.0001, t + ataque + Math.max(0.01, caida));
  }

  /** Envolvente con sostenido (para notas musicales). */
  _envM(p, t, pico, ataque, dec, sost, dur, rel) {
    const g = Math.max(0.0001, pico);
    p.setValueAtTime(0.0001, t);
    p.linearRampToValueAtTime(g, t + ataque);
    p.exponentialRampToValueAtTime(Math.max(0.0001, g * sost), t + ataque + dec);
    p.setValueAtTime(Math.max(0.0001, g * sost), t + Math.max(ataque + dec, dur));
    p.exponentialRampToValueAtTime(0.0001, t + Math.max(ataque + dec, dur) + rel);
  }

  _hz(midi) { return 440 * Math.pow(2, (midi - 69) / 12); }

  /* ---------------------------------------------------------------------
   * Espacialización y voces
   * ------------------------------------------------------------------- */

  _actualizarEscucha() {
    const c = this.ctx?.camara;
    if (!c) return;
    const p = c.position;
    this._camX = p.x; this._camY = p.y; this._camZ = p.z;
    const e = c.matrixWorld.elements;   // columna 0 = eje derecha
    const dx = e[0], dz = e[2];
    const l = Math.hypot(dx, dz) || 1;
    this._derX = dx / l; this._derZ = dz / l;
    const d = this.ctx?.camCtrl?.distancia || 78;
    this._radio = d * 0.95 + 20;
  }

  /**
   * Devuelve ganancia (0..1) y paneo (-1..1) para un punto del mundo.
   * Lo que queda fuera de la pantalla se atenúa fuerte.
   */
  _espacializar(x, z, res) {
    if (x === undefined || x === null) { res.gan = 1; res.pan = 0; res.dist = 0; return res; }
    const y = this.ctx?.terreno?.altura?.(x, z) || 0;
    const dx = x - this._camX, dy = y - this._camY, dz = z - this._camZ;
    const dist = Math.sqrt(dx * dx + dy * dy + dz * dz);
    res.dist = dist;

    // caída inversa cuadrática relativa al zoom
    const r = dist / (this._radio * 0.62);
    let g = 1 / (1 + r * r);

    // fuera de cuadro: se apaga
    const cam = this.ctx.camara;
    this._v.set(x, y + 1, z);
    if (cam) {
      this._v.project(cam);
      const ax = Math.abs(this._v.x), ay = Math.abs(this._v.y);
      if (this._v.z > 1) g *= 0.10;                       // detrás de la cámara
      if (ax > 1) g /= (1 + 6 * (ax - 1) * (ax - 1));
      if (ay > 1) g /= (1 + 4 * (ay - 1) * (ay - 1));
      res.pan = Math.max(-0.95, Math.min(0.95, this._v.x * 0.85));
    } else {
      const px = dx * this._derX + dz * this._derZ;
      res.pan = Math.max(-0.95, Math.min(0.95, px / (this._radio * 0.7)));
    }
    res.gan = g;
    return res;
  }

  /** Reserva una voz; si no hay, roba la peor (menos prioridad, más lejos). */
  _tomarVoz(prio, dist, ahora) {
    const V = this._voces;
    for (let i = 0; i < MAX_VOCES; i++) {
      const v = V[i];
      if (!v.activa || v.fin <= ahora) {
        if (v.activa) this._matarVoz(v, ahora, true);
        v.activa = true; v.prio = prio; v.dist = dist; v.fuentes.length = 0;
        return v;
      }
    }
    // robo
    const puntajeNuevo = prio * 1000 - dist;
    let peor = null, peorP = Infinity;
    for (let i = 0; i < MAX_VOCES; i++) {
      const v = V[i];
      const p = v.prio * 1000 - v.dist;
      if (p < peorP) { peorP = p; peor = v; }
    }
    if (!peor || peorP >= puntajeNuevo) return null;
    this._matarVoz(peor, ahora, false);
    peor.activa = true; peor.prio = prio; peor.dist = dist; peor.fuentes.length = 0;
    return peor;
  }

  _matarVoz(v, ahora, silencioso) {
    if (v.gan) {
      try {
        v.gan.gain.cancelScheduledValues(ahora);
        v.gan.gain.setTargetAtTime(0.0001, ahora, silencioso ? 0.002 : 0.010);
      } catch (e) { /* nada */ }
    }
    for (let i = 0; i < v.fuentes.length; i++) {
      try { v.fuentes[i].stop(ahora + 0.05); } catch (e) { /* ya parada */ }
    }
    v.fuentes.length = 0;
    v.activa = false;
    v.gan = null;
  }

  _liberarVoces(ahora) {
    const V = this._voces;
    for (let i = 0; i < MAX_VOCES; i++) {
      const v = V[i];
      if (v.activa && v.fin <= ahora) { v.activa = false; v.fuentes.length = 0; v.gan = null; }
    }
  }

  /* ---------------------------------------------------------------------
   * API pública de efectos
   * ------------------------------------------------------------------- */

  sfx(clave, opciones) {
    if (!this.ac || !this.listo || this.mudo) return;
    if (this.ac.state === 'suspended') return;
    let c = clave;
    if (c === 'disparo_bala') c = this._armaDeEdad();
    const def = SFX[c] || SFX[ALIAS[c]] || null;
    if (!def) return;

    const ac = this.ac;
    const ahora = ac.currentTime;
    const o = opciones || VACIO;

    // anti-apilamiento: dos disparos idénticos en el mismo frame no suenan igual
    const ult = this._ultima.get(c) || 0;
    const dt = ahora - ult;
    const minInt = def.min || 0.02;
    let apilado = this._pila.get(c) || 0;
    apilado = Math.max(0, apilado - dt * 6) + 1;
    if (dt < minInt * 0.5 && apilado > 3) return;
    this._pila.set(c, apilado);
    this._ultima.set(c, ahora);

    const esp = this._espacializar(o.x, o.z, TMP_ESP);
    let gan = esp.gan * (o.volumen !== undefined ? o.volumen : 1) * (def.gan || 1);
    if (apilado > 1) gan *= 1 / (1 + (apilado - 1) * 0.35);   // el enjambre no revienta
    if (gan < 0.0035) return;

    const voz = this._tomarVoz(def.prio || 1, esp.dist, ahora);
    if (!voz) return;

    // salida de la voz: gain -> pan -> bus (+ envíos a reverb)
    const g = this._gan(gan);
    const pan = ac.createStereoPanner ? ac.createStereoPanner() : null;
    if (pan) { pan.pan.value = esp.pan; g.connect(pan); } else { /* sin paneo */ }
    const destino = def.bus === 'amb' ? this.busAmbiente : this.busEfectos;
    (pan || g).connect(destino);

    if (def.rev) {
      const env = this._gan(def.rev * Math.min(1, 0.35 + esp.dist / 90));
      g.connect(env);
      env.connect(def.rev > 0.5 ? this.revLarga : this.revCorta);
    }
    voz.gan = g;

    // pequeño retardo aleatorio: descoordina las descargas cerradas
    const t = ahora + 0.012 + (def.disp ? this._az() * def.disp : 0);
    let dur = 0.4;
    try { dur = def.fn(this, t, g, o, voz) || 0.4; } catch (e) { dur = 0.4; }
    voz.fin = t + dur + 0.08;

    if (def.combate) this._sumarIntensidad(def.combate);
  }

  _armaDeEdad() {
    const e = this.ctx?.edades?.edad?.[this.ctx.jugadorLocal] ?? 0;
    if (e <= 0) return 'disparo_mosquete';
    if (e === 1) return 'disparo_fusil';
    return 'disparo_subfusil';
  }

  _sumarIntensidad(v) {
    this.intensidad = Math.min(1, this.intensidad + v);
    this._tIntensidad = 0;
  }

  /* ---------------------------------------------------------------------
   * MÚSICA
   * ------------------------------------------------------------------- */

  musicaEdad(n) {
    const idx = Math.max(0, Math.min(CAMAS.length - 1, n | 0));
    if (idx === this.edadMusical) return;
    this.edadMusical = idx;
    if (!this.ac || !this.listo) return;
    const ac = this.ac, t = ac.currentTime;

    // la cama vieja se desvanece
    for (const c of this.camas) {
      if (c.muriendo) continue;
      c.muriendo = true;
      c.hasta = t + 5.0;
      try {
        c.gan.gain.cancelScheduledValues(t);
        c.gan.gain.setValueAtTime(c.gan.gain.value, t);
        c.gan.gain.linearRampToValueAtTime(0.0001, t + 5.0);
      } catch (e) { /* nada */ }
    }
    this.camas.push(this._crearCama(CAMAS[idx], t + 0.35, this.camas.length > 0 ? 4.5 : 2.0));
  }

  _crearCama(cfg, t0, fundido) {
    const ac = this.ac;
    const gan = this._gan(0.0001);
    gan.connect(this.gDuck);
    gan.gain.setValueAtTime(0.0001, t0);
    gan.gain.linearRampToValueAtTime(1, t0 + fundido);

    // envío propio de reverb (la música vive en una sala más grande)
    const env = this._gan(cfg.reverb);
    gan.connect(env); env.connect(this.revLarga);

    // eco corto para arpegios digitales
    const eco = ac.createDelay(1.2);
    eco.delayTime.value = 60 / cfg.bpm / 2;
    const ecoG = this._gan(0.28);
    const ecoF = this._filtro('lowpass', 2600, 0.8);
    eco.connect(ecoF).connect(ecoG).connect(gan);
    ecoG.connect(eco);

    const semilla = ((this._semilla ^ (cfg.bpm * 2654435761)) >>> 0);
    const cama = {
      cfg, gan, eco, muriendo: false, hasta: Infinity,
      compas: 0, tProx: t0 + 0.05,
      duracion: (60 / cfg.bpm) * 4,
      frase: cfg.frases[0],
      registro: cfg.registro,
      densidad: cfg.densidad,
      calla: false,
      semilla,
      r() { this.semilla = (this.semilla * 1664525 + 1013904223) >>> 0; return this.semilla / 4294967296; },
    };
    return cama;
  }

  _programarMusica(ahora) {
    const horizonte = ahora + 0.45;
    for (let i = this.camas.length - 1; i >= 0; i--) {
      const c = this.camas[i];
      if (c.hasta < ahora) {
        try { c.gan.disconnect(); } catch (e) { /* nada */ }
        this.camas.splice(i, 1);
        continue;
      }
      let guardia = 0;
      while (c.tProx < horizonte && guardia++ < 8) {
        this._compas(c, c.tProx);
        c.tProx += c.duracion;
        c.compas++;
      }
    }
  }

  /** Construye un acorde diatónico (tríada + séptima opcional) sobre un grado. */
  _acorde(cfg, grado, octava, septima, salida) {
    const m = cfg.modo, L = m.length;
    salida.length = 0;
    const pasos = septima ? 4 : 3;
    for (let i = 0; i < pasos; i++) {
      const d = grado + i * 2;
      const oct = Math.floor(d / L);
      salida.push(cfg.tonica + 12 * (octava + oct) + m[((d % L) + L) % L]);
    }
    return salida;
  }

  _nota(cfg, grado, octava) {
    const m = cfg.modo, L = m.length;
    const oct = Math.floor(grado / L);
    return cfg.tonica + 12 * (octava + oct) + m[((grado % L) + L) % L];
  }

  /** Programa un compás completo de una cama. */
  _compas(c, t0) {
    const cfg = c.cfg;
    const beat = 60 / cfg.bpm;
    const largoFrase = c.frase.length;

    // cada 2 vueltas de frase: variación (frase nueva, registro, densidad, silencios)
    if (c.compas % (largoFrase * 2) === 0) {
      c.frase = cfg.frases[(c.r() * cfg.frases.length) | 0];
      c.registro = cfg.registro + ((c.r() * 3) | 0) - 1;
      c.densidad = Math.max(0.2, Math.min(0.95, cfg.densidad + (c.r() - 0.5) * 0.4));
      c.calla = c.r() < 0.22;          // un tramo sin melodía: deja respirar
    }

    const grado = c.frase[c.compas % largoFrase];
    const septima = c.r() < 0.45;
    const acorde = this._acorde(cfg, grado, 0, septima, TMP_ACORDE);
    const inten = this.intensidad;

    /* --- pad / cuerdas sostenidas --- */
    if (cfg.cuerdas > 0.02) {
      for (let i = 0; i < acorde.length; i++) {
        const oct = i === 0 ? -1 : 0;
        this._mCuerda(c, t0 + c.r() * 0.03, c.duracion * 0.98,
          this._hz(acorde[i] + 12 * oct), cfg.cuerdas * (i === 0 ? 0.9 : 0.62) * (1 + inten * 0.15));
      }
    }
    if (cfg.pad > 0.02) {
      for (let i = 0; i < acorde.length; i++) {
        this._mPad(c, t0, c.duracion * 1.4, this._hz(acorde[i] + 12), cfg.pad * 0.7);
      }
    }
    if (cfg.dron > 0.02) {
      this._mDron(c, t0, c.duracion * 1.1, this._hz(cfg.tonica - 12), cfg.dron);
      if (c.compas % 4 === 0) this._mDron(c, t0, c.duracion * 2.1, this._hz(acorde[1] - 12), cfg.dron * 0.5);
    }

    /* --- bajo --- */
    const raiz = this._hz(this._nota(cfg, grado, -2));
    if (cfg.percusion === 'marcha') {
      for (let b = 0; b < 4; b++) this._mBajo(c, t0 + b * beat, beat * 0.8, raiz * (b % 2 ? 1.0 : 1.0), cfg.bajo);
    } else if (cfg.percusion === 'digital') {
      this._mBajo(c, t0, beat * 1.5, raiz, cfg.bajo);
      this._mBajo(c, t0 + beat * 1.5, beat * 0.5, raiz * 1.5, cfg.bajo * 0.7);
      this._mBajo(c, t0 + beat * 2.5, beat * 1.4, raiz, cfg.bajo * 0.85);
    } else {
      this._mBajo(c, t0, beat * 1.9, raiz, cfg.bajo);
      if (c.r() < 0.6) this._mBajo(c, t0 + beat * 2, beat * 1.9, raiz * (c.r() < 0.5 ? 1 : 1.4983), cfg.bajo * 0.8);
    }

    /* --- metales --- */
    if (cfg.metales > 0.05) {
      const acentos = cfg.percusion === 'marcha' ? [0, 2] : [0];
      for (const b of acentos) {
        if (c.r() > 0.35 + inten * 0.3) continue;
        for (let i = 0; i < acorde.length; i++) {
          this._mMetal(c, t0 + b * beat, beat * (cfg.percusion === 'marcha' ? 0.9 : 1.8),
            this._hz(acorde[i]), cfg.metales * (0.55 + inten * 0.4));
        }
      }
    }

    /* --- melodía --- */
    if (!c.calla && cfg.melodia > 0.05) {
      const pasos = cfg.percusion === 'digital' ? 8 : 4;
      const dpaso = c.duracion / pasos;
      let g = c.registro;
      for (let p = 0; p < pasos; p++) {
        const fuerte = p === 0 || p === pasos / 2;
        const prob = (fuerte ? 0.92 : 0.52) * c.densidad * (1 - inten * 0.25);
        if (c.r() > prob) continue;
        if (fuerte) {
          // en tiempo fuerte cae sobre una nota del acorde
          const opciones = [grado, grado + 2, grado + 4];
          const base = opciones[(c.r() * 3) | 0];
          while (g - base > 4) g -= 7;
          while (base - g > 4) g += 7;
          g = base + 7 * Math.round((g - base) / 7);
        } else {
          g += ((c.r() * 5) | 0) - 2;
          const lim = c.registro;
          if (g > lim + 8) g -= 7;
          if (g < lim - 5) g += 7;
        }
        const dur = dpaso * (c.r() < 0.25 ? 1.85 : 0.92);
        this._mMelodia(c, t0 + p * dpaso, dur, this._hz(this._nota(cfg, g, 0)),
          cfg.melodia * (fuerte ? 1 : 0.72));
      }
    }

    /* --- arpegio digital --- */
    if (cfg.arpegio > 0.05) {
      const n = 8, d = c.duracion / n;
      for (let i = 0; i < n; i++) {
        if (c.r() > 0.75 * c.densidad + 0.2) continue;
        const nota = acorde[i % acorde.length] + 12 * ((i / acorde.length) | 0);
        this._mPluck(c, t0 + i * d, this._hz(nota + 12), cfg.arpegio * (i % 2 ? 0.6 : 1));
      }
    }

    /* --- percusión --- */
    this._percusion(c, t0, beat, inten);
  }

  _percusion(c, t0, beat, inten) {
    const tipo = c.cfg.percusion;
    if (tipo === 'yunque') {
      this._mYunque(c, t0, 0.34 + inten * 0.25);
      if (c.r() < 0.75) this._mYunque(c, t0 + beat * 2, 0.24 + inten * 0.2);
      if (inten > 0.35 && c.r() < 0.5) this._mYunque(c, t0 + beat * 3.5, 0.18);
      this._mBombo(c, t0, 0.4);
      if (c.r() < 0.5) this._mBombo(c, t0 + beat * 2.5, 0.26);
    } else if (tipo === 'marcha') {
      this._mBombo(c, t0, 0.46); this._mBombo(c, t0 + beat * 2, 0.40);
      this._mCaja(c, t0 + beat, 0.34); this._mCaja(c, t0 + beat * 3, 0.34);
      const redoble = c.r() < 0.3 + inten * 0.4;
      if (redoble) for (let i = 0; i < 4; i++) this._mCaja(c, t0 + beat * 3.5 + i * beat * 0.125, 0.14 + i * 0.03);
    } else if (tipo === 'pulso') {
      this._mSub(c, t0, 0.55 + inten * 0.3);
      this._mSub(c, t0 + beat * 2.5, 0.30);
      if (c.r() < 0.35) this._mYunque(c, t0 + beat * 3, 0.13);
    } else if (tipo === 'digital') {
      this._mBombo(c, t0, 0.34); this._mBombo(c, t0 + beat * 2, 0.30);
      for (let i = 0; i < 8; i++) if (c.r() < 0.55) this._mTic(c, t0 + i * beat * 0.5, 0.10 + (i % 2 ? 0 : 0.05));
      this._mCaja(c, t0 + beat * 2, 0.18);
    } else if (tipo === 'granular') {
      const n = 6 + ((c.r() * 8) | 0);
      for (let i = 0; i < n; i++) {
        this._mGrano(c, t0 + c.r() * c.duracion, 220 + c.r() * 2600, 0.10 + c.r() * 0.12);
      }
      if (c.r() < 0.5) this._mSub(c, t0 + c.r() * c.duracion, 0.28);
    }
  }

  /* ----- instrumentos ----- */

  _mCuerda(c, t, dur, f, gan) {
    const ac = this.ac;
    const g = this._gan(0.0001);
    const lp = this._filtro('lowpass', 900, 0.8);
    lp.frequency.setValueAtTime(600, t);
    lp.frequency.linearRampToValueAtTime(1500 + gan * 900, t + dur * 0.4);
    lp.frequency.linearRampToValueAtTime(800, t + dur);
    g.connect(lp).connect(c.gan);
    // vibrato lento compartido por las tres cuerdas del unísono
    const lfo = this._osc('sine', 4.6 + c.r() * 0.8);
    const lfoG = this._gan(4.5);
    lfo.connect(lfoG);
    for (let i = 0; i < 3; i++) {
      const o = this._osc('sawtooth', f, (i - 1) * 7 + (c.r() - 0.5) * 5);
      lfoG.connect(o.detune);
      o.connect(g); o.start(t); o.stop(t + dur + 0.5);
    }
    this._envM(g.gain, t, gan * 0.16, dur * 0.22, dur * 0.3, 0.8, dur, 0.45);
    lfo.start(t); lfo.stop(t + dur + 0.5);
  }

  _mPad(c, t, dur, f, gan) {
    const g = this._gan(0.0001);
    const lp = this._filtro('lowpass', 1800, 0.6);
    g.connect(lp).connect(c.gan);
    const o1 = this._osc('triangle', f, -6);
    const o2 = this._osc('sine', f * 2.002, 7);
    o1.connect(g); o2.connect(g);
    o1.start(t); o2.start(t);
    o1.stop(t + dur + 0.8); o2.stop(t + dur + 0.8);
    this._envM(g.gain, t, gan * 0.14, dur * 0.35, dur * 0.2, 0.85, dur, 0.9);
  }

  _mDron(c, t, dur, f, gan) {
    const g = this._gan(0.0001);
    const lp = this._filtro('lowpass', 520, 1.4);
    g.connect(lp).connect(c.gan);
    const o1 = this._osc('sawtooth', f, -9);
    const o2 = this._osc('sine', f * 0.5);
    const o3 = this._osc('sawtooth', f * 1.005, 11);
    o1.connect(g); o2.connect(g); o3.connect(g);
    for (const o of [o1, o2, o3]) { o.start(t); o.stop(t + dur + 1.2); }
    this._envM(g.gain, t, gan * 0.13, dur * 0.4, dur * 0.2, 0.9, dur, 1.1);
  }

  _mMetal(c, t, dur, f, gan) {
    const g = this._gan(0.0001);
    const bp = this._filtro('bandpass', f * 2, 1.6);
    bp.frequency.setValueAtTime(f * 1.1, t);
    bp.frequency.linearRampToValueAtTime(f * 3.4, t + 0.09);
    bp.frequency.linearRampToValueAtTime(f * 2.1, t + dur);
    const w = this._forma(this.curvaSucia);
    g.connect(w).connect(bp).connect(c.gan);
    const o1 = this._osc('sawtooth', f, -5);
    const o2 = this._osc('square', f, 6);
    o1.connect(g); o2.connect(g);
    o1.start(t); o2.start(t); o1.stop(t + dur + 0.3); o2.stop(t + dur + 0.3);
    this._envM(g.gain, t, gan * 0.13, 0.055, 0.12, 0.75, dur, 0.28);
  }

  _mBajo(c, t, dur, f, gan) {
    const g = this._gan(0.0001);
    const lp = this._filtro('lowpass', 320, 3);
    lp.frequency.setValueAtTime(700, t);
    lp.frequency.exponentialRampToValueAtTime(190, t + Math.min(0.35, dur));
    g.connect(lp).connect(c.gan);
    const o = this._osc('sawtooth', f);
    const s = this._osc('sine', f * 0.5);
    o.connect(g); s.connect(g);
    o.start(t); s.start(t); o.stop(t + dur + 0.2); s.stop(t + dur + 0.2);
    this._envM(g.gain, t, gan * 0.22, 0.012, 0.18, 0.55, dur * 0.85, 0.14);
  }

  _mMelodia(c, t, dur, f, gan) {
    const g = this._gan(0.0001);
    const lp = this._filtro('lowpass', 2600, 1.2);
    g.connect(lp).connect(c.gan);
    const o1 = this._osc('triangle', f);
    const o2 = this._osc('sawtooth', f, 5);
    const g2 = this._gan(0.35);
    o1.connect(g); o2.connect(g2); g2.connect(g);
    const vib = this._osc('sine', 5.2);
    const vibG = this._gan(f * 0.006);
    vib.connect(vibG); vibG.connect(o1.frequency); vibG.connect(o2.frequency);
    for (const o of [o1, o2, vib]) { o.start(t); o.stop(t + dur + 0.3); }
    this._envM(g.gain, t, gan * 0.15, 0.045, 0.12, 0.7, dur, 0.22);
  }

  _mPluck(c, t, f, gan) {
    const g = this._gan(0.0001);
    const bp = this._filtro('bandpass', f * 1.6, 3);
    g.connect(bp);
    bp.connect(c.gan);
    bp.connect(c.eco);
    const o = this._osc('square', f, (c.r() - 0.5) * 8);
    o.connect(g); o.start(t); o.stop(t + 0.4);
    this._envP(g.gain, t, gan * 0.12, 0.004, 0.22);
  }

  _mYunque(c, t, gan) {
    const g = this._gan(0.0001);
    const bp = this._filtro('bandpass', 2100, 6);
    g.connect(bp).connect(c.gan);
    const parciales = [1, 2.76, 5.4, 8.93];
    for (let i = 0; i < parciales.length; i++) {
      const o = this._osc('sine', 520 * parciales[i] * (0.98 + c.r() * 0.04));
      const gg = this._gan(1 / (1 + i * 1.6));
      o.connect(gg); gg.connect(g);
      o.start(t); o.stop(t + 0.9);
    }
    const n = this._ruido(false);
    const hp = this._filtro('highpass', 2600, 0.8);
    const ng = this._gan(0.0001);
    n.connect(hp).connect(ng); ng.connect(c.gan);
    this._envP(ng.gain, t, gan * 0.10, 0.001, 0.05);
    n.start(t, this._az() * 2); n.stop(t + 0.12);
    this._envP(g.gain, t, gan * 0.10, 0.002, 0.55);
  }

  _mBombo(c, t, gan) {
    const g = this._gan(0.0001);
    g.connect(c.gan);
    const o = this._osc('sine', 120);
    o.frequency.setValueAtTime(150, t);
    o.frequency.exponentialRampToValueAtTime(42, t + 0.12);
    o.connect(g); o.start(t); o.stop(t + 0.5);
    this._envP(g.gain, t, gan * 0.34, 0.004, 0.26);
  }

  _mCaja(c, t, gan) {
    const n = this._ruido(false);
    const bp = this._filtro('bandpass', 1900, 1.1);
    const g = this._gan(0.0001);
    n.connect(bp).connect(g); g.connect(c.gan);
    n.start(t, this._az() * 2); n.stop(t + 0.25);
    this._envP(g.gain, t, gan * 0.13, 0.002, 0.11);
    const o = this._osc('triangle', 210);
    const og = this._gan(0.0001);
    o.connect(og); og.connect(c.gan);
    o.start(t); o.stop(t + 0.12);
    this._envP(og.gain, t, gan * 0.05, 0.002, 0.06);
  }

  _mSub(c, t, gan) {
    const g = this._gan(0.0001);
    const o = this._osc('sine', 60);
    o.frequency.setValueAtTime(70, t);
    o.frequency.exponentialRampToValueAtTime(31, t + 0.5);
    o.connect(g); g.connect(c.gan);
    o.start(t); o.stop(t + 1.0);
    this._envP(g.gain, t, gan * 0.30, 0.02, 0.7);
  }

  _mTic(c, t, gan) {
    const n = this._ruido(false, 1.6);
    const hp = this._filtro('highpass', 6500, 0.7);
    const g = this._gan(0.0001);
    n.connect(hp).connect(g); g.connect(c.gan);
    n.start(t, this._az() * 2); n.stop(t + 0.06);
    this._envP(g.gain, t, gan * 0.07, 0.001, 0.035);
  }

  _mGrano(c, t, f, gan) {
    const g = this._gan(0.0001);
    const bp = this._filtro('bandpass', f, 8);
    g.connect(bp).connect(c.gan);
    const o = this._osc(c.r() < 0.5 ? 'sine' : 'triangle', f);
    o.connect(g); o.start(t); o.stop(t + 0.35);
    const dur = 0.04 + c.r() * 0.12;
    this._envP(g.gain, t, gan * 0.09, dur * 0.4, dur);
  }

  /* ---------------------------------------------------------------------
   * AMBIENTE
   * ------------------------------------------------------------------- */

  _crearAmbiente() {
    const ac = this.ac;

    // viento: ruido rosa por un pasabanda que respira
    this.vientoF = this._filtro('bandpass', 420, 0.55);
    this.vientoG = this._gan(0.0001);
    const vSrc = this._ruido(true, 0.85);
    vSrc.connect(this.vientoF).connect(this.vientoG).connect(this.busAmbiente);
    vSrc.start(0, this._az() * 4);
    this.vientoSrc = vSrc;

    // follaje: capa aguda que sólo aparece en bosque
    this.hojasF = this._filtro('bandpass', 3200, 0.9);
    this.hojasG = this._gan(0.0001);
    const hSrc = this._ruido(true, 1.4);
    hSrc.connect(this.hojasF).connect(this.hojasG).connect(this.busAmbiente);
    hSrc.start(0, this._az() * 4);

    // olas: ruido grave con oleaje
    this.olaF = this._filtro('lowpass', 520, 0.9);
    this.olaG = this._gan(0.0001);
    const oSrc = this._ruido(true, 0.55);
    oSrc.connect(this.olaF).connect(this.olaG).connect(this.busAmbiente);
    oSrc.start(0, this._az() * 4);

    // zumbido eléctrico de fondo (edades tardías), muy sutil
    this.zumbidoG = this._gan(0.0001);
    const z1 = this._osc('sine', 50), z2 = this._osc('sine', 100.4);
    const zg = this._gan(0.3);
    z1.connect(this.zumbidoG); z2.connect(zg); zg.connect(this.zumbidoG);
    this.zumbidoG.connect(this.busAmbiente);
    z1.start(0); z2.start(0);
  }

  ambiente(bioma) {
    this._biomaForzado = bioma || null;
  }

  _actualizarAmbiente(dt, ahora) {
    const ctx = this.ctx;
    this._hora = ctx?.cielo?.horaDelDia ?? 12;

    // bioma bajo la cámara (muestreo barato alrededor del foco)
    const foco = ctx?.camCtrl?.foco;
    if (this._biomaForzado) {
      this._bioma = this._biomaForzado;
    } else if (foco && ctx?.terreno?.bioma) {
      this._bioma = ctx.terreno.bioma(foco.x, foco.z) || 'pradera';
      this._aguaCerca =
        ctx.terreno.bioma(foco.x + 34, foco.z) === 'agua' ||
        ctx.terreno.bioma(foco.x - 34, foco.z) === 'agua' ||
        ctx.terreno.bioma(foco.x, foco.z + 34) === 'agua' ||
        ctx.terreno.bioma(foco.x, foco.z - 34) === 'agua' ||
        this._bioma === 'agua' || this._bioma === 'playa';
    }

    const b = this._bioma;
    const noche = this._hora < 6.2 || this._hora > 19.6;
    const amanecer = this._hora >= 5.5 && this._hora < 9;

    // viento: más fuerte en montaña y desierto, más grave de noche
    this._faseViento += dt * 0.11;
    const respiro = 0.5 + 0.5 * Math.sin(this._faseViento) * Math.sin(this._faseViento * 0.37 + 1.1);
    let vg = 0.10 + respiro * 0.10;
    if (b === 'montana') vg *= 2.0;
    else if (b === 'desierto') vg *= 1.55;
    else if (b === 'bosque') vg *= 0.85;
    if (noche) vg *= 0.8;
    this._suave(this.vientoG.gain, vg, ahora, 0.9);
    this._suave(this.vientoF.frequency, 260 + respiro * 520 + (b === 'montana' ? 320 : 0), ahora, 1.6);

    // hojas
    this._suave(this.hojasG.gain, b === 'bosque' ? 0.055 + respiro * 0.045 : 0.004, ahora, 1.2);

    // olas
    this._faseOla += dt * 0.28;
    const swell = 0.5 + 0.5 * Math.sin(this._faseOla);
    this._suave(this.olaG.gain, this._aguaCerca ? 0.07 + swell * 0.10 : 0.0001, ahora, 0.8);
    this._suave(this.olaF.frequency, 380 + swell * 460, ahora, 1.0);

    // zumbido de civilización según la edad
    const edad = this.edadMusical;
    this._suave(this.zumbidoG.gain, edad >= 2 ? 0.008 + edad * 0.004 : 0.0006, ahora, 2.0);

    // pájaros de día, grillos de noche
    const fx = foco ? foco.x : 0, fz = foco ? foco.z : 0;
    const hayVerde = b === 'pradera' || b === 'bosque' || b === 'playa';
    this._tPajaro -= dt;
    if (this._tPajaro <= 0) {
      const densidad = (b === 'bosque' ? 1 : b === 'pradera' ? 0.55 : 0.15) * (noche ? 0.05 : amanecer ? 1.3 : 0.8);
      this._tPajaro = 1.6 + this._az() * 5.5 / Math.max(0.12, densidad);
      if (hayVerde && this._az() < densidad) {
        const a = this._az() * Math.PI * 2, r = 10 + this._az() * 34;
        this.sfx('pajaro', { x: fx + Math.cos(a) * r, z: fz + Math.sin(a) * r, volumen: 0.5 + this._az() * 0.5 });
      }
    }
    this._tGrillo -= dt;
    if (this._tGrillo <= 0) {
      this._tGrillo = 0.8 + this._az() * 2.2;
      if (noche && hayVerde && this._az() < 0.7) {
        const a = this._az() * Math.PI * 2, r = 8 + this._az() * 30;
        this.sfx('grillo', { x: fx + Math.cos(a) * r, z: fz + Math.sin(a) * r, volumen: 0.4 + this._az() * 0.4 });
      }
    }
  }

  _suave(param, valor, ahora, tau) {
    try { param.setTargetAtTime(Math.max(0.00005, valor), ahora, tau); } catch (e) { /* nada */ }
  }

  /* ---------------------------------------------------------------------
   * Trabajos audibles (hachazos, picos, martillos) — vienen del bus
   * ------------------------------------------------------------------- */

  _registrarTrabajo(x, z, clave, vida) {
    if (x === undefined) return;
    for (const t of this._trabajos) {
      if (t.clave === clave && Math.abs(t.x - x) < 3 && Math.abs(t.z - z) < 3) { t.vida = vida; return; }
    }
    if (this._trabajos.length >= 6) this._trabajos.shift();
    this._trabajos.push({ x, z, clave, vida, prox: 0.2 + this._az() * 0.8 });
  }

  _actualizarTrabajos(dt) {
    const T = this._trabajos;
    for (let i = T.length - 1; i >= 0; i--) {
      const t = T[i];
      t.vida -= dt;
      if (t.vida <= 0) { T.splice(i, 1); continue; }
      t.prox -= dt;
      if (t.prox <= 0) {
        t.prox = 0.75 + this._az() * 0.9;
        this.sfx(t.clave, { x: t.x, z: t.z, volumen: 0.55, tono: 0.9 + this._az() * 0.25 });
      }
    }
  }

  _claveTrabajoDeNodo(nodo) {
    const m = this.ctx?.mundo;
    if (!m || nodo === undefined || !m.vivo?.[nodo]) return null;
    if (m.tipo[nodo] !== TIPO_RECURSO) return null;
    const def = NODOS[m.defId[nodo]];
    if (!def) return null;
    const c = def.clave;
    if (c.startsWith('arbol')) return this._az() < 0.25 ? 'sierra' : 'hacha';
    if (c === 'veta_oro' || c === 'carbon') return 'pico';
    if (c === 'pozo_petroleo') return 'bomba_petroleo';
    if (c === 'baya') return 'recoleccion';
    if (c === 'pez') return 'chapoteo';
    if (c === 'ciervo' || c === 'jabali') return 'recoleccion';
    return 'recoleccion';
  }

  _posDe(id) {
    const m = this.ctx?.mundo;
    if (!m || id === undefined || !m.px) return null;
    if (!m.vivo?.[id]) return null;
    TMP_POS.x = m.px[id]; TMP_POS.z = m.pz[id];
    return TMP_POS;
  }

  /* ---------------------------------------------------------------------
   * Bus de eventos
   * ------------------------------------------------------------------- */

  _suscribir() {
    const bus = this.ctx?.bus;
    if (!bus) return;

    bus.on('aviso', (a) => {
      if (!a) return;
      if (a.tipo === 'alerta') this.sfx('alerta_ataque', { volumen: 0.9 });
      else if (a.tipo === 'error') this.sfx('aviso_error');
      else this.sfx('aviso_info');
    });

    bus.on('combate:disparo', () => this._sumarIntensidad(0.05));
    bus.on('combate:impacto', (c) => {
      this._sumarIntensidad(0.07);
      if (c && c.tipo === 'cuerpo') return;      // Combate ya lo suena
    });
    bus.on('combate:muerte', () => this._sumarIntensidad(0.10));

    bus.on('edad:avanzada', (e) => {
      if (!e) return;
      if (e.jugador === this.ctx.jugadorLocal) this.musicaEdad(e.edad);
    });

    bus.on('economia:tarea', (t) => {
      if (!t || t.tipo !== 'recolectar') return;
      const clave = this._claveTrabajoDeNodo(t.nodo);
      const p = this._posDe(t.nodo);
      if (clave && p) this._registrarTrabajo(p.x, p.z, clave, 26);
    });

    bus.on('obra:iniciada', (o) => {
      const id = o?.id ?? o?.obra ?? o?.edificio ?? o?.entidad;
      const p = this._posDe(id);
      if (p) this._registrarTrabajo(p.x, p.z, 'martillo', 40);
    });
    bus.on('obra:terminada', (o) => {
      const id = o?.id ?? o?.obra ?? o?.edificio ?? o?.entidad;
      const p = this._posDe(id);
      if (!p) return;
      for (let i = this._trabajos.length - 1; i >= 0; i--) {
        const t = this._trabajos[i];
        if (t.clave === 'martillo' && Math.abs(t.x - p.x) < 6 && Math.abs(t.z - p.z) < 6) this._trabajos.splice(i, 1);
      }
    });
    bus.on('nodo:agotado', (n) => {
      const id = n?.id ?? n?.nodo ?? n;
      const m = this.ctx?.mundo;
      if (!m || typeof id !== 'number' || !m.px) return;
      const x = m.px[id], z = m.pz[id];
      for (let i = this._trabajos.length - 1; i >= 0; i--) {
        const t = this._trabajos[i];
        if (Math.abs(t.x - x) < 3 && Math.abs(t.z - z) < 3) this._trabajos.splice(i, 1);
      }
    });

    bus.on('juego:listo', () => {
      if (this.ac && this.ac.state === 'suspended') this.ac.resume().catch(() => {});
    });
  }

  /* ---------------------------------------------------------------------
   * Volumen y transporte
   * ------------------------------------------------------------------- */

  setVolumen(maestro, musica, efectos, ambiente) {
    if (maestro !== undefined && maestro !== null) this.vol.maestro = clamp01(maestro);
    if (musica !== undefined && musica !== null) this.vol.musica = clamp01(musica);
    if (efectos !== undefined && efectos !== null) this.vol.efectos = clamp01(efectos);
    if (ambiente !== undefined && ambiente !== null) this.vol.ambiente = clamp01(ambiente);
    if (!this.ac) return;
    const t = this.ac.currentTime;
    this._suave(this.ganMaestro.gain, this.vol.maestro, t, 0.05);
    this._suave(this.busMusica.gain, this.vol.musica, t, 0.05);
    this._suave(this.busEfectos.gain, this.vol.efectos, t, 0.05);
    this._suave(this.busAmbiente.gain, this.vol.ambiente, t, 0.05);
  }

  silenciar(v) {
    this.mudo = v === undefined ? !this.mudo : !!v;
    if (this.ac) this._suave(this.ganMaestro.gain, this.mudo ? 0.00005 : this.vol.maestro, this.ac.currentTime, 0.05);
    return this.mudo;
  }

  suspender() { if (this.ac && this.ac.state === 'running') this.ac.suspend().catch(() => {}); }
  reanudar() { if (this.ac && this.ac.state === 'suspended') this.ac.resume().catch(() => {}); }

  /* ---------------------------------------------------------------------
   * Bucle
   * ------------------------------------------------------------------- */

  cada(dtReal) {
    const ac = this.ac;
    if (!ac || !this.listo || ac.state !== 'running') return;
    const dt = dtReal > 0.1 ? 0.1 : (dtReal > 0 ? dtReal : 0.016);
    const ahora = ac.currentTime;

    this._actualizarEscucha();
    this._liberarVoces(ahora);
    this._programarMusica(ahora);
    this._actualizarTrabajos(dt);

    // ambiente a 5 Hz: nada de trabajo pesado por frame
    this._tAmb += dt;
    if (this._tAmb >= 0.2) {
      this._actualizarAmbiente(this._tAmb, ahora);
      this._tAmb = 0;
    }

    // intensidad de combate: sube por eventos, cae sola
    this._tIntensidad += dt;
    if (this._tIntensidad > 0.6) this.intensidad = Math.max(0, this.intensidad - dt * 0.22);
    const duck = 1 - 0.45 * this.intensidad;
    if (Math.abs(duck - this._duckAnt) > 0.01) {
      this._duckAnt = duck;
      this._suave(this.gDuck.gain, duck, ahora, 0.35);
    }
  }
}

MotorAudio.prototype._duckAnt = 1;
MotorAudio.prototype._aguaCerca = false;

/* =========================================================================
 * Utilidades
 * ========================================================================= */

const VACIO = {};
const TMP_ESP = { gan: 1, pan: 0, dist: 0 };
const TMP_ACORDE = [];
const TMP_POS = { x: 0, z: 0 };
const clamp01 = (v) => (v < 0 ? 0 : v > 1 ? 1 : v);

/* =========================================================================
 * SÍNTESIS DE EFECTOS
 * Cada función recibe (m = motor, t = instante, s = salida de la voz,
 * o = opciones, v = voz) y devuelve la duración estimada en segundos.
 * ========================================================================= */

/** Cuerpo de disparo: ruido con pasabajos que barre + onda cuadrada grave. */
function disparo(m, t, s, o, v, cfg) {
  const k = o.tono || 1;
  const ac = m.ac;

  // fogonazo de ruido
  const n = m._ruido(false, cfg.tasa || 1);
  const lp = m._filtro('lowpass', cfg.f0 * k, cfg.q);
  lp.frequency.setValueAtTime(cfg.f0 * k, t);
  lp.frequency.exponentialRampToValueAtTime(Math.max(90, cfg.f1 * k), t + cfg.barrido);
  const gn = m._gan(0.0001);
  const w = m._forma(cfg.sucio ? m.curvaSucia : m.curvaDura);
  n.connect(lp).connect(w).connect(gn); gn.connect(s);
  m._envP(gn.gain, t, cfg.gRuido, 0.0012, cfg.dRuido);
  m._arrancar(v, n, t, cfg.dRuido + 0.1);

  // cuerpo: cuadrada grave que cae
  const b = m._osc('square', cfg.cuerpo * k);
  b.frequency.setValueAtTime(cfg.cuerpo * k, t);
  b.frequency.exponentialRampToValueAtTime(Math.max(28, cfg.cuerpo * 0.55 * k), t + cfg.dCuerpo);
  const bg = m._gan(0.0001);
  const blp = m._filtro('lowpass', 700, 1.2);
  b.connect(blp).connect(bg); bg.connect(s);
  m._envP(bg.gain, t, cfg.gCuerpo, 0.002, cfg.dCuerpo);
  m._arrancar(v, b, t, cfg.dCuerpo + 0.08);

  // chasquido de aire (el "crack" seco)
  if (cfg.crack) {
    const c = m._ruido(false, 1.7);
    const hp = m._filtro('highpass', 3200, 0.7);
    const cg = m._gan(0.0001);
    c.connect(hp).connect(cg); cg.connect(s);
    m._envP(cg.gain, t, cfg.crack, 0.0006, 0.03);
    m._arrancar(v, c, t, 0.06);
  }

  // cola: aire que se aleja
  if (cfg.cola) {
    const c = m._ruido(true, 0.7);
    const bp = m._filtro('lowpass', 700, 0.7);
    bp.frequency.setValueAtTime(700, t);
    bp.frequency.exponentialRampToValueAtTime(160, t + cfg.cola);
    const cg = m._gan(0.0001);
    c.connect(bp).connect(cg); cg.connect(s);
    m._envP(cg.gain, t + 0.04, cfg.gCola || 0.25, 0.05, cfg.cola);
    m._arrancar(v, c, t, cfg.cola + 0.2);
  }
  return Math.max(cfg.dRuido, cfg.dCuerpo, cfg.cola || 0) + 0.2;
}

/** Explosión: ruido largo + sub que cae + cola. */
function explosion(m, t, s, o, v, escala) {
  const e = escala || 1;
  const k = o.tono || 1;
  const n = m._ruido(false, 0.85);
  const lp = m._filtro('lowpass', 2200 * k, 0.9);
  lp.frequency.setValueAtTime(2400 * k, t);
  lp.frequency.exponentialRampToValueAtTime(110, t + 0.9 * e);
  const w = m._forma(m.curvaSucia);
  const g = m._gan(0.0001);
  n.connect(lp).connect(w).connect(g); g.connect(s);
  m._envP(g.gain, t, 0.85 * e, 0.004, 1.15 * e);
  m._arrancar(v, n, t, 1.3 * e + 0.2);

  const sub = m._osc('sine', 95 * k);
  sub.frequency.setValueAtTime(105 * k, t);
  sub.frequency.exponentialRampToValueAtTime(24, t + 0.7 * e);
  const sg = m._gan(0.0001);
  sub.connect(sg); sg.connect(s);
  m._envP(sg.gain, t, 0.9 * e, 0.006, 0.85 * e);
  m._arrancar(v, sub, t, e + 0.2);

  const cr = m._ruido(false, 1.6);
  const hp = m._filtro('highpass', 2600, 0.6);
  const cg = m._gan(0.0001);
  cr.connect(hp).connect(cg); cg.connect(s);
  m._envP(cg.gain, t, 0.55 * e, 0.0008, 0.05);
  m._arrancar(v, cr, t, 0.1);

  // escombros
  const es = m._ruido(true, 1.2);
  const bp = m._filtro('bandpass', 1500, 0.8);
  const eg = m._gan(0.0001);
  es.connect(bp).connect(eg); eg.connect(s);
  m._envP(eg.gain, t + 0.12 * e, 0.20 * e, 0.08, 0.9 * e);
  m._arrancar(v, es, t, 1.2 * e);
  return 1.5 * e;
}

/** Impacto con resonancia según material. */
function impacto(m, t, s, o, v, mat, fuerza) {
  const M = MATERIALES[mat] || MATERIALES.madera;
  const f = (fuerza || 1) * (o.volumen === undefined ? 1 : 1);
  const k = o.tono || 1;

  const n = m._ruido(false, 1.2);
  const lp = m._filtro('lowpass', M.brillo, 0.8);
  const gn = m._gan(0.0001);
  n.connect(lp).connect(gn); gn.connect(s);
  m._envP(gn.gain, t, M.ruido * f, 0.0008, M.caida * 0.45);
  m._arrancar(v, n, t, M.caida + 0.1);

  const r = m._osc('triangle', M.f * k);
  const bp = m._filtro('bandpass', M.f * k, M.q);
  const rg = m._gan(0.0001);
  r.connect(bp).connect(rg); rg.connect(s);
  m._envP(rg.gain, t, 0.45 * f, 0.001, M.caida);
  m._arrancar(v, r, t, M.caida + 0.15);

  if (M.sub > 0.05) {
    const sub = m._osc('sine', M.f * 0.42 * k);
    sub.frequency.exponentialRampToValueAtTime(Math.max(26, M.f * 0.22 * k), t + 0.12);
    const sg = m._gan(0.0001);
    sub.connect(sg); sg.connect(s);
    m._envP(sg.gain, t, M.sub * f, 0.002, 0.16);
    m._arrancar(v, sub, t, 0.3);
  }
  return M.caida + 0.25;
}

/** Tono simple con envolvente (base de toda la interfaz). */
function tono(m, t, s, o, v, f, dur, tipo, gan, f2) {
  const k = o.tono || 1;
  const osc = m._osc(tipo || 'sine', f * k);
  if (f2) {
    osc.frequency.setValueAtTime(f * k, t);
    osc.frequency.exponentialRampToValueAtTime(f2 * k, t + dur * 0.85);
  }
  const g = m._gan(0.0001);
  osc.connect(g); g.connect(s);
  m._envP(g.gain, t, gan === undefined ? 0.35 : gan, Math.min(0.02, dur * 0.15), dur);
  m._arrancar(v, osc, t, dur + 0.1);
  return dur + 0.12;
}

/** Campana inarmónica (alertas, avisos de edad). */
function campana(m, t, s, o, v, base, gan, dur) {
  const k = o.tono || 1;
  const parciales = [1, 2.0, 2.98, 4.11, 5.43, 6.79];
  const pesos = [1, 0.5, 0.36, 0.24, 0.14, 0.09];
  for (let i = 0; i < parciales.length; i++) {
    const osc = m._osc('sine', base * parciales[i] * k);
    const g = m._gan(0.0001);
    osc.connect(g); g.connect(s);
    m._envP(g.gain, t, gan * pesos[i], 0.002, dur * (1 - i * 0.10));
    m._arrancar(v, osc, t, dur + 0.15);
  }
  return dur + 0.2;
}

/** Golpe de herramienta: transitorio + resonancia + roce. */
function herramienta(m, t, s, o, v, cfg) {
  impacto(m, t, s, o, v, cfg.mat, cfg.f);
  if (cfg.astilla) {
    const n = m._ruido(false, 1.4);
    const bp = m._filtro('bandpass', cfg.astilla, 3);
    const g = m._gan(0.0001);
    n.connect(bp).connect(g); g.connect(s);
    m._envP(g.gain, t + 0.012, 0.22, 0.003, 0.10);
    m._arrancar(v, n, t, 0.16);
  }
  return 0.55;
}

/* --- silbido / whoosh de proyectil --- */
function silbido(m, t, s, o, v, cfg) {
  const n = m._ruido(true, cfg.tasa || 1);
  const bp = m._filtro('bandpass', cfg.f0, cfg.q || 2.2);
  bp.frequency.setValueAtTime(cfg.f0, t);
  bp.frequency.exponentialRampToValueAtTime(cfg.f1, t + cfg.dur);
  const g = m._gan(0.0001);
  n.connect(bp).connect(g); g.connect(s);
  g.gain.setValueAtTime(0.0001, t);
  g.gain.exponentialRampToValueAtTime(cfg.gan, t + cfg.dur * 0.22);
  g.gain.exponentialRampToValueAtTime(0.0001, t + cfg.dur);
  m._arrancar(v, n, t, cfg.dur + 0.1);
  return cfg.dur + 0.1;
}

/* =========================================================================
 * CATÁLOGO DE EFECTOS
 * prio: 0 ambiente · 1 flavor · 2 normal · 3 combate · 4 crítico/interfaz
 * ========================================================================= */

const SFX = {
  /* ---------------- armas de fuego ---------------- */
  disparo_mosquete: {
    prio: 3, gan: 0.85, rev: 0.35, min: 0.03, disp: 0.035, combate: 0.05,
    fn: (m, t, s, o, v) => disparo(m, t, s, o, v, {
      f0: 3400, f1: 300, q: 2.2, barrido: 0.16, gRuido: 0.85, dRuido: 0.30,
      cuerpo: 92, gCuerpo: 0.55, dCuerpo: 0.16, cola: 0.55, gCola: 0.22, sucio: true,
    }),
  },
  disparo_fusil: {
    prio: 3, gan: 0.8, rev: 0.25, min: 0.025, disp: 0.02, combate: 0.05,
    fn: (m, t, s, o, v) => disparo(m, t, s, o, v, {
      f0: 6200, f1: 900, q: 1.6, barrido: 0.06, gRuido: 0.75, dRuido: 0.14,
      cuerpo: 150, gCuerpo: 0.40, dCuerpo: 0.07, crack: 0.55, cola: 0.30, gCola: 0.12,
    }),
  },
  disparo_subfusil: {
    prio: 3, gan: 0.7, rev: 0.2, min: 0.05, disp: 0.01, combate: 0.06,
    fn: (m, t, s, o, v) => {
      const n = 3 + ((m._az() * 2) | 0);
      for (let i = 0; i < n; i++) {
        disparo(m, t + i * 0.062, s, o, v, {
          f0: 5200, f1: 800, q: 1.4, barrido: 0.05, gRuido: 0.42 - i * 0.04, dRuido: 0.10,
          cuerpo: 168, gCuerpo: 0.22, dCuerpo: 0.05, crack: 0.30,
        });
      }
      return n * 0.062 + 0.25;
    },
  },
  disparo_canon: {
    prio: 4, gan: 1.0, rev: 0.85, min: 0.05, disp: 0.02, combate: 0.12,
    fn: (m, t, s, o, v) => {
      disparo(m, t, s, o, v, {
        f0: 1500, f1: 110, q: 1.1, barrido: 0.45, gRuido: 1.0, dRuido: 0.85,
        cuerpo: 68, gCuerpo: 0.95, dCuerpo: 0.55, cola: 1.5, gCola: 0.38, sucio: true, tasa: 0.7,
      });
      const sub = m._osc('sine', 46);
      sub.frequency.exponentialRampToValueAtTime(22, t + 0.9);
      const g = m._gan(0.0001);
      sub.connect(g); g.connect(s);
      m._envP(g.gain, t, 0.8, 0.01, 1.0);
      m._arrancar(v, sub, t, 1.2);
      return 1.7;
    },
  },
  disparo_misil: {
    prio: 3, gan: 0.85, rev: 0.5, min: 0.06, combate: 0.08,
    fn: (m, t, s, o, v) => {
      impacto(m, t, s, o, v, 'metal', 0.5);
      silbido(m, t, s, o, v, { f0: 500, f1: 2600, q: 1.2, dur: 1.1, gan: 0.55, tasa: 1.1 });
      const sub = m._osc('sine', 70);
      sub.frequency.exponentialRampToValueAtTime(150, t + 1.0);
      const g = m._gan(0.0001);
      sub.connect(g); g.connect(s);
      m._envP(g.gain, t, 0.35, 0.05, 1.0);
      m._arrancar(v, sub, t, 1.2);
      return 1.25;
    },
  },
  disparo_cohete: {
    prio: 3, gan: 0.85, rev: 0.45, min: 0.05, combate: 0.08,
    fn: (m, t, s, o, v) => {
      disparo(m, t, s, o, v, {
        f0: 2400, f1: 400, q: 1.3, barrido: 0.25, gRuido: 0.7, dRuido: 0.45,
        cuerpo: 110, gCuerpo: 0.45, dCuerpo: 0.2, sucio: true,
      });
      silbido(m, t + 0.05, s, o, v, { f0: 900, f1: 2200, q: 1.6, dur: 0.85, gan: 0.4 });
      return 1.0;
    },
  },
  disparo_enjambre: {
    prio: 3, gan: 0.7, rev: 0.4, min: 0.06, combate: 0.07,
    fn: (m, t, s, o, v) => {
      for (let i = 0; i < 4; i++) {
        silbido(m, t + i * 0.045, s, o, v, {
          f0: 1200 + m._az() * 900, f1: 3200 + m._az() * 1400, q: 3.5, dur: 0.55, gan: 0.28,
        });
      }
      tono(m, t, s, o, v, 1400, 0.18, 'sawtooth', 0.10, 620);
      return 0.8;
    },
  },
  disparo_riel: {
    prio: 4, gan: 0.9, rev: 0.55, min: 0.04, combate: 0.09,
    fn: (m, t, s, o, v) => {
      // chirrido metálico con doppler: sierra que cae de golpe
      const o1 = m._osc('sawtooth', 3200);
      o1.frequency.setValueAtTime(3400, t);
      o1.frequency.exponentialRampToValueAtTime(520, t + 0.32);
      const bp = m._filtro('bandpass', 2600, 7);
      bp.frequency.setValueAtTime(3000, t);
      bp.frequency.exponentialRampToValueAtTime(700, t + 0.3);
      const g = m._gan(0.0001);
      o1.connect(bp).connect(g); g.connect(s);
      m._envP(g.gain, t, 0.5, 0.002, 0.34);
      m._arrancar(v, o1, t, 0.45);

      // modulación en anillo: le da el filo eléctrico
      const o2 = m._osc('square', 137);
      const rg = m._gan(0.0001);
      o2.connect(rg); rg.connect(g.gain);
      m._envP(rg.gain, t, 0.18, 0.004, 0.25);
      m._arrancar(v, o2, t, 0.35);

      // descarga
      const n = m._ruido(false, 1.5);
      const hp = m._filtro('highpass', 4200, 0.8);
      const ng = m._gan(0.0001);
      n.connect(hp).connect(ng); ng.connect(s);
      m._envP(ng.gain, t, 0.5, 0.0008, 0.09);
      m._arrancar(v, n, t, 0.14);
      const sub = m._osc('sine', 120);
      sub.frequency.exponentialRampToValueAtTime(38, t + 0.4);
      const sg = m._gan(0.0001);
      sub.connect(sg); sg.connect(s);
      m._envP(sg.gain, t, 0.45, 0.004, 0.45);
      m._arrancar(v, sub, t, 0.6);
      return 0.7;
    },
  },

  /* ---------------- explosiones e impactos ---------------- */
  explosion: { prio: 4, gan: 1.0, rev: 0.9, min: 0.05, combate: 0.16, fn: (m, t, s, o, v) => explosion(m, t, s, o, v, 1) },
  impacto_bala: { prio: 2, gan: 0.55, rev: 0.2, min: 0.02, disp: 0.02, combate: 0.03, fn: (m, t, s, o, v) => impacto(m, t, s, o, v, 'chapa', 0.7) },
  impacto_obus: { prio: 4, gan: 0.95, rev: 0.85, min: 0.04, combate: 0.14, fn: (m, t, s, o, v) => explosion(m, t, s, o, v, 0.85) },
  impacto_misil: { prio: 4, gan: 1.0, rev: 0.85, min: 0.04, combate: 0.15, fn: (m, t, s, o, v) => explosion(m, t, s, o, v, 1.0) },
  impacto_cohete: { prio: 4, gan: 0.9, rev: 0.8, min: 0.04, combate: 0.13, fn: (m, t, s, o, v) => explosion(m, t, s, o, v, 0.8) },
  impacto_enjambre: { prio: 3, gan: 0.7, rev: 0.6, min: 0.04, combate: 0.10, fn: (m, t, s, o, v) => explosion(m, t, s, o, v, 0.45) },
  impacto_riel: {
    prio: 3, gan: 0.8, rev: 0.5, min: 0.03, combate: 0.09,
    fn: (m, t, s, o, v) => { impacto(m, t, s, o, v, 'metal', 1.1); return tono(m, t, s, o, v, 2600, 0.35, 'sine', 0.16, 900); },
  },
  golpe_cuerpo: {
    prio: 2, gan: 0.7, rev: 0.25, min: 0.03, disp: 0.02, combate: 0.04,
    fn: (m, t, s, o, v) => {
      impacto(m, t, s, o, v, 'carne', 1);
      // filo de acero de fondo
      if (m._az() < 0.5) impacto(m, t + 0.01, s, o, v, 'metal', 0.35);
      return 0.4;
    },
  },
  muerte_unidad: {
    prio: 2, gan: 0.6, rev: 0.35, min: 0.08, disp: 0.05,
    fn: (m, t, s, o, v) => {
      // quejido: formante que cae
      const osc = m._osc('sawtooth', 190 * (0.85 + m._az() * 0.35));
      osc.frequency.exponentialRampToValueAtTime(70, t + 0.5);
      const bp = m._filtro('bandpass', 620, 3.5);
      bp.frequency.exponentialRampToValueAtTime(280, t + 0.5);
      const g = m._gan(0.0001);
      osc.connect(bp).connect(g); g.connect(s);
      m._envP(g.gain, t, 0.32, 0.02, 0.45);
      m._arrancar(v, osc, t, 0.6);
      impacto(m, t + 0.28, s, o, v, 'tierra', 0.6);
      return 0.8;
    },
  },
  derrumbe: {
    prio: 4, gan: 1.0, rev: 0.9, min: 0.1,
    fn: (m, t, s, o, v) => {
      // rumor grave + madera que cruje + escombros
      const n = m._ruido(true, 0.6);
      const lp = m._filtro('lowpass', 700, 1.2);
      lp.frequency.setValueAtTime(900, t);
      lp.frequency.exponentialRampToValueAtTime(140, t + 1.6);
      const g = m._gan(0.0001);
      n.connect(lp).connect(g); g.connect(s);
      m._envP(g.gain, t, 0.85, 0.06, 1.7);
      m._arrancar(v, n, t, 2.0);
      for (let i = 0; i < 6; i++) {
        impacto(m, t + 0.1 + m._az() * 1.2, s, o, v, m._az() < 0.5 ? 'madera' : 'piedra', 0.5 + m._az() * 0.5);
      }
      const sub = m._osc('sine', 60);
      sub.frequency.exponentialRampToValueAtTime(26, t + 1.2);
      const sg = m._gan(0.0001);
      sub.connect(sg); sg.connect(s);
      m._envP(sg.gain, t, 0.7, 0.05, 1.3);
      m._arrancar(v, sub, t, 1.6);
      return 2.1;
    },
  },

  /* ---------------- trabajo ---------------- */
  hacha: {
    prio: 1, gan: 0.6, rev: 0.35, min: 0.08, disp: 0.03,
    fn: (m, t, s, o, v) => herramienta(m, t, s, o, v, { mat: 'madera', f: 1.1, astilla: 1800 }),
  },
  sierra: {
    prio: 1, gan: 0.5, rev: 0.3, min: 0.2,
    fn: (m, t, s, o, v) => {
      const n = m._ruido(false, 1.0);
      const bp = m._filtro('bandpass', 1500, 4);
      const g = m._gan(0.0001);
      n.connect(bp).connect(g); g.connect(s);
      // rasgado: tremolo rápido con el vaivén de la hoja
      const lfo = m._osc('sine', 7.5);
      const lg = m._gan(0.35);
      lfo.connect(lg); lg.connect(g.gain);
      m._arrancar(v, lfo, t, 0.9);
      g.gain.setValueAtTime(0.0001, t);
      g.gain.linearRampToValueAtTime(0.42, t + 0.08);
      g.gain.setValueAtTime(0.42, t + 0.55);
      g.gain.exponentialRampToValueAtTime(0.0001, t + 0.9);
      bp.frequency.setValueAtTime(1200, t);
      bp.frequency.linearRampToValueAtTime(2100, t + 0.85);
      m._arrancar(v, n, t, 0.95);
      return 1.0;
    },
  },
  pico: {
    prio: 1, gan: 0.6, rev: 0.4, min: 0.08, disp: 0.03,
    fn: (m, t, s, o, v) => herramienta(m, t, s, o, v, { mat: 'piedra', f: 1.1, astilla: 3200 }),
  },
  martillo: {
    prio: 1, gan: 0.6, rev: 0.4, min: 0.08, disp: 0.04,
    fn: (m, t, s, o, v) => {
      impacto(m, t, s, o, v, 'metal', 0.9);
      if (m._az() < 0.6) impacto(m, t + 0.13 + m._az() * 0.05, s, o, v, 'metal', 0.55);
      return 0.6;
    },
  },
  recoleccion: {
    prio: 1, gan: 0.4, rev: 0.2, min: 0.15,
    fn: (m, t, s, o, v) => {
      const n = m._ruido(true, 1.6);
      const bp = m._filtro('bandpass', 2600, 1.4);
      const g = m._gan(0.0001);
      n.connect(bp).connect(g); g.connect(s);
      m._envP(g.gain, t, 0.25, 0.03, 0.28);
      m._arrancar(v, n, t, 0.4);
      return 0.42;
    },
  },
  chapoteo: {
    prio: 1, gan: 0.5, rev: 0.35, min: 0.15,
    fn: (m, t, s, o, v) => {
      const n = m._ruido(false, 1.1);
      const bp = m._filtro('bandpass', 900, 0.9);
      bp.frequency.exponentialRampToValueAtTime(2600, t + 0.25);
      const g = m._gan(0.0001);
      n.connect(bp).connect(g); g.connect(s);
      m._envP(g.gain, t, 0.42, 0.006, 0.3);
      m._arrancar(v, n, t, 0.45);
      return 0.5;
    },
  },
  bomba_petroleo: {
    prio: 1, gan: 0.5, rev: 0.3, min: 0.4,
    fn: (m, t, s, o, v) => {
      tono(m, t, s, o, v, 88, 0.5, 'square', 0.16, 62);
      impacto(m, t + 0.5, s, o, v, 'metal', 0.5);
      return 0.9;
    },
  },
  granja: {
    prio: 1, gan: 0.45, rev: 0.25, min: 0.2,
    fn: (m, t, s, o, v) => {
      const n = m._ruido(true, 1.3);
      const bp = m._filtro('bandpass', 1800, 1.1);
      const g = m._gan(0.0001);
      n.connect(bp).connect(g); g.connect(s);
      m._envP(g.gain, t, 0.28, 0.05, 0.35);
      m._arrancar(v, n, t, 0.5);
      return 0.5;
    },
  },
  obra: {
    prio: 2, gan: 0.6, rev: 0.35, min: 0.06,
    fn: (m, t, s, o, v) => { impacto(m, t, s, o, v, 'madera', 1); impacto(m, t + 0.14, s, o, v, 'madera', 0.7); return 0.6; },
  },

  /* ---------------- economía ---------------- */
  deposito: {
    prio: 2, gan: 0.55, rev: 0.25, min: 0.05, disp: 0.02,
    fn: (m, t, s, o, v) => {
      impacto(m, t, s, o, v, 'madera', 0.7);
      tono(m, t + 0.02, s, o, v, 880, 0.16, 'sine', 0.10, 1320);
      return 0.4;
    },
  },
  moneda: {
    prio: 2, gan: 0.5, rev: 0.35, min: 0.04, disp: 0.02,
    fn: (m, t, s, o, v) => {
      campana(m, t, s, o, v, 1760, 0.16, 0.35);
      campana(m, t + 0.06, s, o, v, 2350, 0.10, 0.3);
      return 0.5;
    },
  },
  sin_recursos: {
    prio: 4, gan: 0.6, min: 0.6,
    fn: (m, t, s, o, v) => {
      tono(m, t, s, o, v, 420, 0.16, 'triangle', 0.28);
      tono(m, t + 0.14, s, o, v, 300, 0.26, 'triangle', 0.26);
      return 0.5;
    },
  },
  tope_poblacion: {
    prio: 4, gan: 0.6, min: 1.5,
    fn: (m, t, s, o, v) => {
      tono(m, t, s, o, v, 330, 0.3, 'triangle', 0.25);
      tono(m, t + 0.26, s, o, v, 330, 0.35, 'triangle', 0.22);
      return 0.7;
    },
  },

  /* ---------------- producción y progreso ---------------- */
  unidad_lista: {
    prio: 3, gan: 0.55, rev: 0.4, min: 0.08, disp: 0.03,
    fn: (m, t, s, o, v) => {
      tono(m, t, s, o, v, 392, 0.18, 'sawtooth', 0.14);
      tono(m, t + 0.10, s, o, v, 587, 0.26, 'sawtooth', 0.13);
      return 0.45;
    },
  },
  edificio_listo: {
    prio: 4, gan: 0.7, rev: 0.5, min: 0.2,
    fn: (m, t, s, o, v) => {
      impacto(m, t, s, o, v, 'madera', 1);
      campana(m, t + 0.06, s, o, v, 660, 0.20, 0.9);
      campana(m, t + 0.22, s, o, v, 990, 0.14, 0.8);
      return 1.2;
    },
  },
  construccion_fin: {
    prio: 4, gan: 0.7, rev: 0.5, min: 0.2,
    fn: (m, t, s, o, v) => {
      impacto(m, t, s, o, v, 'piedra', 1);
      campana(m, t + 0.05, s, o, v, 587, 0.18, 0.9);
      return 1.1;
    },
  },
  obra_lista: {
    prio: 4, gan: 0.7, rev: 0.5, min: 0.2,
    fn: (m, t, s, o, v) => { impacto(m, t, s, o, v, 'madera', 0.9); campana(m, t + 0.05, s, o, v, 784, 0.17, 0.8); return 1.0; },
  },
  tecno_inicia: {
    prio: 4, gan: 0.5, rev: 0.4, min: 0.15,
    fn: (m, t, s, o, v) => { tono(m, t, s, o, v, 523, 0.14, 'triangle', 0.16, 784); return 0.3; },
  },
  tecno_lista: {
    prio: 4, gan: 0.6, rev: 0.5, min: 0.2,
    fn: (m, t, s, o, v) => {
      campana(m, t, s, o, v, 523, 0.16, 1.0);
      campana(m, t + 0.10, s, o, v, 659, 0.14, 1.0);
      campana(m, t + 0.20, s, o, v, 784, 0.16, 1.2);
      return 1.5;
    },
  },
  edad_inicia: {
    prio: 4, gan: 0.7, rev: 0.6, min: 0.5,
    fn: (m, t, s, o, v) => {
      // acorde que crece: promesa de la edad que viene
      const notas = [110, 165, 220, 330];
      for (let i = 0; i < notas.length; i++) {
        const osc = m._osc('sawtooth', notas[i]);
        const lp = m._filtro('lowpass', 400, 1.2);
        lp.frequency.exponentialRampToValueAtTime(2600, t + 1.4);
        const g = m._gan(0.0001);
        osc.connect(lp).connect(g); g.connect(s);
        m._envM(g.gain, t + i * 0.08, 0.10, 0.5, 0.4, 0.7, 1.3, 0.5);
        m._arrancar(v, osc, t + i * 0.08, 1.9);
      }
      return 2.0;
    },
  },
  edad_lista: {
    prio: 4, gan: 0.9, rev: 0.75, min: 0.5,
    fn: (m, t, s, o, v) => {
      // fanfarria: metales + campana grande
      const notas = [261.6, 329.6, 392, 523.2];
      for (let i = 0; i < notas.length; i++) {
        const osc = m._osc('sawtooth', notas[i]);
        const bp = m._filtro('bandpass', notas[i] * 2.2, 1.4);
        const g = m._gan(0.0001);
        osc.connect(bp).connect(g); g.connect(s);
        m._envM(g.gain, t + i * 0.11, 0.16, 0.06, 0.2, 0.7, 1.1, 0.6);
        m._arrancar(v, osc, t + i * 0.11, 1.9);
      }
      campana(m, t + 0.05, s, o, v, 262, 0.22, 2.2);
      return 2.6;
    },
  },

  /* ---------------- órdenes e interfaz ---------------- */
  click: { prio: 4, gan: 0.35, min: 0.02, fn: (m, t, s, o, v) => tono(m, t, s, o, v, 1500, 0.035, 'sine', 0.20) },
  sel_unidad: {
    prio: 4, gan: 0.45, min: 0.04,
    fn: (m, t, s, o, v) => { tono(m, t, s, o, v, 740, 0.06, 'triangle', 0.16); return tono(m, t + 0.035, s, o, v, 1110, 0.09, 'triangle', 0.13); },
  },
  sel_edificio: {
    prio: 4, gan: 0.5, min: 0.04,
    fn: (m, t, s, o, v) => { impacto(m, t, s, o, v, 'madera', 0.5); return tono(m, t + 0.02, s, o, v, 330, 0.10, 'triangle', 0.10); },
  },
  orden: {
    prio: 4, gan: 0.45, rev: 0.15, min: 0.04,
    fn: (m, t, s, o, v) => { tono(m, t, s, o, v, 880, 0.05, 'sine', 0.15); return tono(m, t + 0.045, s, o, v, 1320, 0.10, 'sine', 0.12); },
  },
  orden_ataque: {
    prio: 4, gan: 0.55, rev: 0.2, min: 0.05,
    fn: (m, t, s, o, v) => {
      tono(m, t, s, o, v, 660, 0.06, 'square', 0.10);
      tono(m, t + 0.05, s, o, v, 990, 0.06, 'square', 0.10);
      return tono(m, t + 0.10, s, o, v, 1320, 0.12, 'square', 0.09);
    },
  },
  orden_trabajar: {
    prio: 4, gan: 0.45, rev: 0.15, min: 0.05,
    fn: (m, t, s, o, v) => { impacto(m, t, s, o, v, 'madera', 0.4); return tono(m, t + 0.03, s, o, v, 660, 0.10, 'triangle', 0.10); },
  },
  orden_construir: {
    prio: 4, gan: 0.5, rev: 0.2, min: 0.05,
    fn: (m, t, s, o, v) => { impacto(m, t, s, o, v, 'piedra', 0.5); return tono(m, t + 0.04, s, o, v, 523, 0.12, 'triangle', 0.11); },
  },
  guarnicion: {
    prio: 3, gan: 0.55, rev: 0.3, min: 0.06,
    fn: (m, t, s, o, v) => { impacto(m, t, s, o, v, 'madera', 1.1); return tono(m, t + 0.05, s, o, v, 165, 0.22, 'sine', 0.16, 110); },
  },
  error: {
    prio: 4, gan: 0.5, min: 0.12,
    fn: (m, t, s, o, v) => {
      tono(m, t, s, o, v, 466, 0.11, 'square', 0.13);
      tono(m, t + 0.11, s, o, v, 349, 0.18, 'square', 0.12);
      return 0.35;
    },
  },
  alerta_ataque: {
    prio: 4, gan: 0.9, rev: 0.6, min: 1.2,
    fn: (m, t, s, o, v) => {
      campana(m, t, s, o, v, 494, 0.26, 1.4);
      campana(m, t + 0.30, s, o, v, 494, 0.22, 1.6);
      campana(m, t + 0.60, s, o, v, 370, 0.18, 1.8);
      m._sumarIntensidad(0.35);
      return 2.2;
    },
  },
  aviso_info: { prio: 4, gan: 0.35, rev: 0.25, min: 0.25, fn: (m, t, s, o, v) => campana(m, t, s, o, v, 1046, 0.10, 0.5) },
  aviso_error: {
    prio: 4, gan: 0.45, min: 0.25,
    fn: (m, t, s, o, v) => { tono(m, t, s, o, v, 415, 0.10, 'triangle', 0.12); return tono(m, t + 0.10, s, o, v, 311, 0.18, 'triangle', 0.11); },
  },

  /* ---------------- especiales ---------------- */
  cura: {
    prio: 2, gan: 0.5, rev: 0.5, min: 0.15,
    fn: (m, t, s, o, v) => {
      for (let i = 0; i < 3; i++) tono(m, t + i * 0.07, s, o, v, 523 * Math.pow(1.26, i), 0.4, 'sine', 0.09);
      return 0.75;
    },
  },
  conversion: {
    prio: 3, gan: 0.6, rev: 0.6, min: 0.2,
    fn: (m, t, s, o, v) => {
      const osc = m._osc('sine', 220);
      osc.frequency.exponentialRampToValueAtTime(880, t + 0.9);
      const g = m._gan(0.0001);
      const lfo = m._osc('sine', 6.5);
      const lg = m._gan(0.5);
      lfo.connect(lg); lg.connect(g.gain);
      osc.connect(g); g.connect(s);
      m._envP(g.gain, t, 0.22, 0.15, 0.8);
      m._arrancar(v, osc, t, 1.1);
      m._arrancar(v, lfo, t, 1.1);
      campana(m, t + 0.75, s, o, v, 880, 0.14, 1.0);
      return 1.6;
    },
  },

  /* ---------------- naturaleza (bus de ambiente) ---------------- */
  pajaro: {
    prio: 0, gan: 0.5, rev: 0.4, bus: 'amb', min: 0.05,
    fn: (m, t, s, o, v) => {
      const notas = 2 + ((m._az() * 4) | 0);
      const base = 2200 + m._az() * 1600;
      for (let i = 0; i < notas; i++) {
        const t0 = t + i * (0.07 + m._az() * 0.05);
        const osc = m._osc('sine', base);
        const f1 = base * (0.75 + m._az() * 0.7);
        osc.frequency.setValueAtTime(base * (0.9 + m._az() * 0.3), t0);
        osc.frequency.exponentialRampToValueAtTime(f1, t0 + 0.05);
        osc.frequency.exponentialRampToValueAtTime(base * 0.85, t0 + 0.09);
        const g = m._gan(0.0001);
        osc.connect(g); g.connect(s);
        m._envP(g.gain, t0, 0.12, 0.006, 0.07);
        m._arrancar(v, osc, t0, 0.14);
      }
      return notas * 0.12 + 0.2;
    },
  },
  grillo: {
    prio: 0, gan: 0.35, rev: 0.3, bus: 'amb', min: 0.05,
    fn: (m, t, s, o, v) => {
      const pulsos = 3 + ((m._az() * 3) | 0);
      const f = 4200 + m._az() * 900;
      for (let i = 0; i < pulsos; i++) {
        const t0 = t + i * 0.055;
        const osc = m._osc('square', f);
        const bp = m._filtro('bandpass', f, 12);
        const g = m._gan(0.0001);
        osc.connect(bp).connect(g); g.connect(s);
        m._envP(g.gain, t0, 0.06, 0.004, 0.028);
        m._arrancar(v, osc, t0, 0.05);
      }
      return pulsos * 0.06 + 0.1;
    },
  },
};

/** Claves que otros módulos usan con otro nombre. */
const ALIAS = {
  orden_atacar: 'orden_ataque',
  disparo_bala: 'disparo_fusil',
  aviso: 'aviso_info',
  campana: 'alerta_ataque',
  pala: 'pico',
  paso: 'recoleccion',
};

export default MotorAudio;

/**
 * IMPERIOS 1800–2100 — arranque.
 * Acá se ensambla el ctx (ver src/core/Ctx.js) y se registran los sistemas.
 */
import * as THREE from 'three';
import { Engine } from './core/Engine.js';
import { World } from './core/World.js';
import { bus } from './core/EventBus.js';
import { RNG, Ruido } from './core/RNG.js';
import { Renderer } from './render/Renderer.js';
import { CamaraRTS } from './render/CamaraRTS.js';
import { Cielo } from './render/Cielo.js';
import { Sombras } from './render/Sombras.js';
import { BibliotecaTexturas } from './art/ProceduralTextures.js';
import { Terreno } from './world/Terreno.js';
import { Agua } from './world/Agua.js';
import { generarMapa } from './world/MapaGenerador.js';
import { Foliaje } from './world/Foliaje.js';
import { VistaEntidades } from './render/VistaEntidades.js';
import { Navegacion } from './sim/Navegacion.js';
import { Movimiento } from './sim/Movimiento.js';
import { Combate } from './sim/Combate.js';
import { Economia } from './sim/Economia.js';
import { Produccion } from './sim/Produccion.js';
import { SistemaEdades } from './sim/Edades.js';
import { Niebla } from './sim/Niebla.js';
import { IA } from './sim/IA.js';
import { Seleccion } from './ui/Seleccion.js';
import { Trucos } from './sim/Trucos.js';
import { Ordenes } from './sim/Ordenes.js';
import { HUD } from './ui/HUD.js';
import { MotorAudio } from './audio/MotorAudio.js';
import { Efectos } from './render/Efectos.js';

const el = (id) => document.getElementById(id);
const paso = (txt, pct) => {
  const t = el('carga-texto'); if (t) t.textContent = txt;
  const b = document.querySelector('#cargando .barra i'); if (b) b.style.width = `${pct}%`;
};

async function arrancar() {
  const lienzo = el('lienzo');
  const params = new URLSearchParams(location.search);
  const calidad = params.get('calidad') || 'alta';
  const semilla = Number(params.get('semilla') || 20260727);

  const motor = new Engine();
  const mundo = new World(6000);
  const rng = new RNG(semilla);
  const ruido = new Ruido(semilla);

  paso('Encendiendo el motor gráfico…', 6);
  const render = new Renderer(lienzo, calidad);
  const ctx = {
    motor, mundo, bus, rng, ruido,
    escena: render.escena, camara: render.camara, renderer: render.renderer,
    render, calidad, jugadorLocal: 0, semilla,
    THREE,
  };
  window.__juego = ctx;

  paso('Tejiendo texturas…', 14);
  ctx.texturas = new BibliotecaTexturas(ctx);
  await ctx.texturas.precargar();

  paso('Levantando el cielo…', 24);
  ctx.cielo = new Cielo(ctx);
  ctx.sombras = new Sombras(ctx);

  paso('Modelando el terreno…', 34);
  ctx.mapa = generarMapa(ctx, { semilla, tam: 512 });
  ctx.terreno = new Terreno(ctx);
  ctx.agua = new Agua(ctx);

  paso('Plantando bosques…', 48);
  ctx.foliaje = new Foliaje(ctx);

  paso('Trazando caminos…', 58);
  ctx.nav = new Navegacion(ctx);
  ctx.niebla = new Niebla(ctx);

  paso('Fundando aldeas…', 66);
  ctx.eco = new Economia(ctx);
  ctx.edades = new SistemaEdades(ctx);
  ctx.produccion = new Produccion(ctx);
  ctx.vista = new VistaEntidades(ctx);
  ctx.efectos = new Efectos(ctx);
  ctx.movimiento = new Movimiento(ctx);
  ctx.combate = new Combate(ctx);
  ctx.ordenes = new Ordenes(ctx);
  ctx.ia = new IA(ctx);

  paso('Afinando la orquesta…', 80);
  ctx.audio = new MotorAudio(ctx);

  paso('Desplegando el estandarte…', 90);
  ctx.camCtrl = new CamaraRTS(render.camara, lienzo, ctx);
  ctx.camCtrl.setLimite(ctx.mapa.tam);
  ctx.seleccion = new Seleccion(ctx);
  ctx.trucos = new Trucos(ctx);
  ctx.ui = new HUD(ctx);

  // poblado inicial (bases, aldeanos, recursos)
  ctx.mapa.poblar?.(ctx);

  // civilizaciones y rivales
  const civLocal = params.get('civ') || 'rioplatense';
  const civRival = params.get('civRival') || 'prusiana';
  const dificultad = params.get('dificultad') || 'normal';
  ctx.edades.aplicarCiv?.(0, civLocal);
  for (let j = 1; j < ctx.mapa.inicios.length; j++) {
    ctx.edades.aplicarCiv?.(j, civRival);
    ctx.ia.agregarJugador?.(j, dificultad, civRival);
  }

  const sistemas = [
    ctx.camCtrl, ctx.seleccion, ctx.ordenes, ctx.ia, ctx.nav, ctx.movimiento,
    ctx.combate, ctx.eco, ctx.produccion, ctx.edades, ctx.niebla,
    ctx.cielo, ctx.sombras, ctx.terreno, ctx.agua, ctx.foliaje,
    ctx.vista, ctx.efectos, ctx.audio, ctx.ui, render,
  ].filter(Boolean);
  for (const s of sistemas) if (s.fijo || s.cada) motor.registrar(s);

  const inicio = ctx.mapa.inicios[ctx.jugadorLocal];
  if (inicio) ctx.camCtrl.enfocar(inicio.x, inicio.z, true);

  paso('¡Listo!', 100);
  await new Promise((r) => setTimeout(r, 220));
  el('cargando')?.classList.add('oculto');
  setTimeout(() => el('cargando')?.remove(), 900);

  // Los módulos se construyen en cadena y varios parchean materiales ajenos
  // (CSM inyecta su GLSL, el foliaje su viento, el terreno su splatting). El que
  // llega tarde encuentra el programa ya compilado y su parche no entra: el
  // terreno sale lavado y el foliaje en cuadrones pálidos. Una recompilación
  // única acá, con todos los parches ya puestos, deja todo consistente.
  ctx.sombras?.registrarMaterial && ctx.escena.traverse((o) => {
    const m = o.material;
    if (m) (Array.isArray(m) ? m : [m]).forEach((x) => ctx.sombras.registrarMaterial(x));
  });
  const recompilarTodo = () => {
    ctx.escena.traverse((o) => {
      const m = o.material;
      if (!m) return;
      (Array.isArray(m) ? m : [m]).forEach((x) => {
        // La clave de caché de programa no distingue una cadena de parches
        // incompleta de la completa: si el material se compiló antes de que
        // todos los onBeforeCompile estuvieran puestos, three devuelve el
        // programa viejo del caché para siempre. Invalidar la clave obliga a
        // three a compilar de verdad en vez de reutilizar el fantasma.
        const previa = x.customProgramCacheKey;
        let sello = (x.userData.__selloRecompila = (x.userData.__selloRecompila || 0) + 1);
        x.customProgramCacheKey = previa
          ? function () { return `${previa.call(this)}|r${sello}`; }
          : function () { return `r${sello}`; };
        x.needsUpdate = true;
      });
    });
  };
  recompilarTodo();

  // Y otra vez unos frames más tarde: varios módulos instalan su parche de
  // forma perezosa (el primer chunk de terreno que entra en cámara, el primer
  // material de foliaje que se siembra), así que una sola pasada al arranque
  // deja fuera todo lo que nace después.
  let framesArranque = 0;
  motor.registrar({
    nombre: 'revalidacion',
    orden: 1,
    cada() {
      framesArranque++;
      if (framesArranque === 4 || framesArranque === 60 || framesArranque === 240) recompilarTodo();
    },
  });

  if (params.get('arnes') === '1') {
    const { instalar } = await import('./dev/Arnes.js');
    instalar(ctx);
  }

  motor.iniciar(ctx);
  bus.emit('juego:listo', ctx);
  console.info('[Imperios] listo — semilla', semilla, '· calidad', calidad);
}

arrancar().catch((e) => {
  console.error(e);
  const t = el('carga-texto');
  if (t) { t.textContent = `Error al iniciar: ${e.message}`; t.style.color = '#ff8a7a'; }
});

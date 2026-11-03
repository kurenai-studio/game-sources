/**
 * TRUCOS — panel de códigos, como el chat de los Age of Empires originales.
 *
 * Enter abre el panel, se escribe el código, Enter lo manda y Escape cancela.
 *
 * Por qué un panel y no escuchar la palabra suelta en el teclado: en un RTS
 * casi todas las letras ya son atajos —WASD mueve la cámara, H centra la Sede,
 * T abre el árbol tecnológico— así que tipear un truco "en el aire" dispara
 * media docena de acciones por el camino y el jugador nunca sabe si lo está
 * escribiendo bien. El panel además es descubrible: se ve lo que se escribe.
 *
 * Mientras el panel está abierto NADA del juego recibe teclado. Eso no sale
 * gratis: `CamaraRTS` y `Seleccion` escuchan en `window`, y un keydown dentro
 * de un input burbujea hasta ahí igual. Por eso el handler corta la propagación
 * —también la del keyup, si no la cámara se queda con teclas trabadas apretadas
 * y sigue paneando sola cuando cerrás el panel.
 */
import { ORDEN } from '../core/Ctx.js';
import { CLAVES_RECURSO } from '../data/recursos.js';
import { bus } from '../core/EventBus.js';

export const TRUCOS = [
  {
    clave: 'klapaucius',
    descripcion: '+1000 de cada recurso',
    aplicar(ctx) {
      const j = ctx.jugadorLocal;
      for (const r of CLAVES_RECURSO) ctx.eco?.sumar?.(j, r, 1000);
      return '¡Klapaucius! +1000 de cada recurso';
    },
  },
];

const CSS = `
#panel-trucos{
  position:absolute; left:50%; bottom:34%; transform:translateX(-50%);
  display:none; align-items:center; gap:.6rem;
  padding:.55rem .8rem; border-radius:.35rem;
  background:var(--panel-fondo, rgba(18,20,24,.92));
  border:1px solid var(--panel-borde, rgba(255,255,255,.22));
  box-shadow:0 .5rem 1.6rem rgba(0,0,0,.55);
  font-family:var(--tipo-ui, ui-sans-serif, system-ui, sans-serif);
  z-index:60; pointer-events:auto;
}
#panel-trucos.abierto{ display:flex; }
#panel-trucos .rotulo{
  font-size:.78rem; letter-spacing:.08em; text-transform:uppercase;
  color:var(--acento, #e8c15a); opacity:.85; white-space:nowrap;
}
#panel-trucos input{
  width:min(24rem, 42vw); background:transparent; border:0; outline:0;
  color:var(--texto, #f2f4f7); font:inherit; font-size:1rem; letter-spacing:.02em;
  border-bottom:1px solid var(--panel-borde, rgba(255,255,255,.28)); padding:.15rem 0;
}
#panel-trucos .pista{
  font-size:.72rem; color:var(--texto-tenue, rgba(242,244,247,.55)); white-space:nowrap;
}
`;

export class Trucos {
  constructor(ctx) {
    this.nombre = 'trucos';
    this.orden = ORDEN.ENTRADA;
    this.ctx = ctx;
    this.activos = true;
    this.abierto = false;

    this._construirPanel();

    // captura en window: tiene que ver el Enter ANTES que cualquier otro
    // sistema, para poder abrir el panel y quedarse con la tecla
    this._alTeclear = (e) => this._teclear(e);
    window.addEventListener('keydown', this._alTeclear, true);
  }

  _construirPanel() {
    // Cuelga de #app, NO de #hud: el HUD se construye después que esto y
    // reescribe su propio innerHTML, así que un panel metido ahí adentro
    // desaparece sin dejar rastro. Con pointer-events propio y z-index alto
    // no necesita estar dentro del HUD para funcionar.
    const raiz = document.getElementById('app') || document.body;

    if (!document.getElementById('estilo-trucos')) {
      const s = document.createElement('style');
      s.id = 'estilo-trucos';
      s.textContent = CSS;
      document.head.appendChild(s);
    }

    const p = document.createElement('div');
    p.id = 'panel-trucos';
    p.innerHTML = `
      <span class="rotulo">Código</span>
      <input type="text" autocomplete="off" spellcheck="false" aria-label="Código de truco">
      <span class="pista">Enter para enviar · Esc para cerrar</span>`;
    raiz.appendChild(p);

    this.panel = p;
    this.entrada = p.querySelector('input');

    // El input come TODO el teclado mientras está abierto. Sin esto, escribir
    // "klapaucius" mueve la cámara con la A y la S y abre el árbol con la T.
    const comer = (e) => e.stopPropagation();
    this.entrada.addEventListener('keyup', comer);
    this.entrada.addEventListener('keypress', comer);
    this.entrada.addEventListener('keydown', (e) => {
      e.stopPropagation();
      if (e.key === 'Enter') { e.preventDefault(); this._enviar(); }
      else if (e.key === 'Escape') { e.preventDefault(); this.cerrar(); }
    });
  }

  _teclear(e) {
    if (!this.activos) return;
    if (e.key !== 'Enter' || e.ctrlKey || e.metaKey || e.altKey) return;
    if (this.abierto) return;   // ya lo maneja el input

    // si el foco está en otro campo de texto, el jugador está escribiendo ahí
    const foco = document.activeElement;
    if (foco && foco !== this.entrada &&
        (foco.tagName === 'INPUT' || foco.tagName === 'TEXTAREA' || foco.isContentEditable)) return;

    e.preventDefault();
    e.stopPropagation();
    this.abrir();
  }

  abrir() {
    if (this.abierto) return;
    // Red de seguridad: si algún módulo reescribió su contenedor y se llevó el
    // panel puesto, lo reconstruimos en vez de fallar en silencio.
    if (!this.panel?.isConnected) this._construirPanel();
    this.abierto = true;
    this.panel.classList.add('abierto');
    this.entrada.value = '';
    this.entrada.focus();
    // la cámara pudo quedarse con teclas apretadas del frame anterior
    this.ctx.camCtrl?.teclas?.clear?.();
  }

  cerrar() {
    if (!this.abierto) return;
    this.abierto = false;
    this.panel.classList.remove('abierto');
    this.entrada.value = '';
    this.entrada.blur();
    this.ctx.camCtrl?.teclas?.clear?.();
  }

  _enviar() {
    const texto = this.entrada.value.trim().toLowerCase();
    this.cerrar();
    if (!texto) return;

    const truco = TRUCOS.find((t) => t.clave === texto);
    if (!truco) {
      bus.emit('aviso', { texto: `Código desconocido: “${texto}”`, tipo: 'error' });
      return;
    }
    this.aplicar(truco.clave);
  }

  /** Aplica un truco por su clave. Público: sirve para probarlo sin tipear. */
  aplicar(clave) {
    const truco = TRUCOS.find((t) => t.clave === clave);
    if (!truco) return false;
    const texto = truco.aplicar(this.ctx) || truco.descripcion;
    bus.emit('aviso', { texto, tipo: 'info' });
    bus.emit('truco', { clave });
    this.ctx.audio?.sfx?.('unidad_lista', { volumen: 0.5 });
    console.info(`[truco] ${clave} — ${texto}`);
    return true;
  }

  dispose() {
    window.removeEventListener('keydown', this._alTeclear, true);
    this.panel?.remove();
  }
}

// Werpen door te slepen en los te laten. Pointer Events dekken muis en touch in één.

const clamp = (x, a, b) => Math.min(b, Math.max(a, x));

// Vertaalt de sleepbeweging naar een worp. punten: [{x, y, t}] in pixels en ms, y naar beneden.
// Snelheid volgt uit de vaart van de laatste 100 ms, de richting uit de sleeprichting, de hoek uit
// de hoogte waarop je loslaat, en zijspin uit de bocht in het sleeppad. Geeft null als het geen worp was.
export function throwFromDrag(punten, hoogte) {
  const last = punten.at(-1);
  if (!last) return null;
  const sinds = (ms) => punten.find((p) => last.t - p.t <= ms) || last;
  const a = sinds(100), dt = (last.t - a.t) / 1000;
  if (dt < 0.01) return null;
  const vx = (last.x - a.x) / dt, vy = (last.y - a.y) / dt;
  const speed = clamp((Math.hypot(vx, vy) / hoogte) * 9, 0, 30);
  if (vy >= 0 || speed < 3.5) return null; // omlaag of te traag: bal blijft in de hand
  const b = sinds(260);
  const d1 = { x: a.x - b.x, y: a.y - b.y }, n1 = Math.hypot(d1.x, d1.y), n2 = Math.hypot(vx, vy);
  const bocht = n1 > 4 ? (d1.x * vy - d1.y * vx) / (n1 * n2) : 0; // > 0: pad buigt naar rechts
  return {
    speed,
    yaw: clamp(Math.atan2(vx, -vy) * 0.9, -1, 1), // > 0: naar rechts
    elev: (8 + 50 * clamp((1 - last.y / hoogte - 0.2) / 0.6, 0, 1)) * (Math.PI / 180),
    zijspin: clamp(bocht * 220, -160, 160), // rad/s
    backspin: 20 + speed,
  };
}

// el: het canvas. grijp(e) zegt of de aanraking de bal pakt; sleep(x, y) en worp(w | null) melden het verloop.
export function createThrow(el, { grijp, sleep, worp }) {
  let id = null, punten = [];
  const punt = (e) => ({ x: e.clientX, y: e.clientY, t: e.timeStamp });
  el.addEventListener('pointermove', (e) => {
    if (e.pointerId !== id) return;
    punten.push(punt(e));
    if (punten.length > 60) punten.shift();
    sleep(e.clientX, e.clientY);
  });
  const klaar = (e) => {
    if (e.pointerId !== id) return;
    id = null;
    punten.push(punt(e));
    worp(e.type === 'pointerup' ? throwFromDrag(punten, el.clientHeight) : null);
  };
  el.addEventListener('pointerup', klaar);
  el.addEventListener('pointercancel', klaar);
  // Geeft true terug als de bal is vastgepakt.
  return (e) => {
    if (id !== null || !grijp(e)) return false;
    id = e.pointerId;
    punten = [punt(e)];
    el.setPointerCapture(id);
    sleep(e.clientX, e.clientY);
    return true;
  };
}

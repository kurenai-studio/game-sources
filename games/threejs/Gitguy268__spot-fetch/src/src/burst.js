// Opspattende deeltjes bij een inslag: in één keer weggeschoten onder willekeurige hoeken, omlaag
// getrokken door de zwaartekracht en na een vaste levensduur weg. Naar explode() van de particle
// emitter van Phaser. Zonder three.js, zodat het los te testen is.
import { G } from './physics.js';

export const LEVEN = 0.6; // seconden

export function newBurst(n) {
  return { n, p: new Float32Array(n * 3), v: new Float32Array(n * 3), t: LEVEN };
}

// kracht 0..1: hoe hard de inslag was
export function explode(b, x, y, z, kracht, rand = Math.random) {
  for (let i = 0; i < b.n * 3; i += 3) {
    const hoek = rand() * Math.PI * 2, uit = (0.5 + rand() * 1.5) * kracht;
    b.p[i] = x; b.p[i + 1] = y; b.p[i + 2] = z;
    b.v[i] = Math.cos(hoek) * uit; b.v[i + 1] = (1.5 + rand() * 3) * kracht; b.v[i + 2] = Math.sin(hoek) * uit;
  }
  b.t = 0;
}

// Geeft false zodra de deeltjes op zijn.
export function stepBurst(b, dt) {
  if (b.t >= LEVEN) return false;
  b.t += dt;
  for (let i = 0; i < b.n * 3; i += 3) {
    b.v[i + 1] -= G * dt;
    b.p[i] += b.v[i] * dt; b.p[i + 1] += b.v[i + 1] * dt; b.p[i + 2] += b.v[i + 2] * dt;
  }
  return true;
}

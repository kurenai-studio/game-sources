/**
 * Arma pares A/B a ciegas entre capturas de Imperios y capturas oficiales de
 * Age of Empires II: Definitive Edition, para que un agente crítico las juzgue
 * sin saber cuál es cuál.
 *
 *   node tools/pares-ciegos.mjs <dirNuestras> <dirReferencia> <dirSalida> <semilla>
 *
 * Escribe <dirSalida>/par_NN/{a.png,b.png} y un CLAVE.json que el crítico NO debe leer.
 */
import fs from 'node:fs';
import path from 'node:path';

const [, , dirN, dirR, dirS, semillaArg] = process.argv;
if (!dirN || !dirR || !dirS) {
  console.error('uso: node tools/pares-ciegos.mjs <nuestras> <referencia> <salida> [semilla]');
  process.exit(1);
}

let s = (Number(semillaArg) || 1234) >>> 0;
const rnd = () => {
  s ^= s << 13; s >>>= 0; s ^= s >>> 17; s ^= s << 5; s >>>= 0;
  return s / 4294967296;
};

const pngs = (d) => fs.readdirSync(d).filter((f) => /\.(png|jpg)$/i.test(f)).sort();
const nuestras = pngs(dirN);
const refs = pngs(dirR);
if (!nuestras.length || !refs.length) { console.error('faltan imágenes'); process.exit(1); }

fs.rmSync(dirS, { recursive: true, force: true });
fs.mkdirSync(dirS, { recursive: true });

// Sin reposición: si dos pares comparten referencia, dos de los veredictos dejan
// de ser observaciones independientes y el marcador miente.
const bolsa = refs.slice();
for (let i = bolsa.length - 1; i > 0; i--) {
  const j = Math.floor(rnd() * (i + 1));
  const t = bolsa[i]; bolsa[i] = bolsa[j]; bolsa[j] = t;
}
if (bolsa.length < nuestras.length) {
  console.error(`faltan referencias: ${bolsa.length} para ${nuestras.length} capturas`);
  process.exit(1);
}

const clave = [];
nuestras.forEach((n, i) => {
  const r = bolsa[i];
  const carpeta = path.join(dirS, `par_${String(i + 1).padStart(2, '0')}`);
  fs.mkdirSync(carpeta);
  const nuestraEsA = rnd() < 0.5;
  fs.copyFileSync(path.join(dirN, n), path.join(carpeta, nuestraEsA ? 'a.png' : 'b.png'));
  fs.copyFileSync(path.join(dirR, r), path.join(carpeta, nuestraEsA ? 'b.png' : 'a.png'));
  clave.push({ par: path.basename(carpeta), nuestra: nuestraEsA ? 'a' : 'b', archivoNuestro: n, archivoRef: r });
});

fs.writeFileSync(path.join(dirS, 'CLAVE.json'), JSON.stringify(clave, null, 2));
console.log(`${clave.length} pares en ${dirS}`);
console.log(clave.map((c) => `${c.par}: nuestra=${c.nuestra} (${c.archivoNuestro})`).join('\n'));

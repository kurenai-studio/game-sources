/* Valida o banco de desafios de código.
 *
 * Roda TODO desafio de js/data/pyChallenges.js contra o mesmo harness Python
 * que o jogo usa em produção (extraído de js/py/pyodideWorker.js), com dois
 * critérios:
 *
 *   1. a `solution` precisa passar em todos os casos  — senão o gabarito mente;
 *   2. o `starterCode` NÃO pode passar em todos      — senão o desafio é vazio.
 *
 * Uso:  node tools/validate_py_challenges.mjs
 * Requer python3 com numpy e pandas (aproximação do ambiente Pyodide).
 */

import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

// pyChallenges.js não tem imports, então dá para importá-lo como data: URL
// sem precisar de package.json nem bundler.
const src = readFileSync(join(ROOT, 'js/data/pyChallenges.js'), 'utf8');
const mod = await import('data:text/javascript;base64,' + Buffer.from(src).toString('base64'));
const { PY_CHALLENGES } = mod;

// O harness vem do worker de verdade — validar contra uma cópia não provaria nada.
const workerSrc = readFileSync(join(ROOT, 'js/py/pyodideWorker.js'), 'utf8');
const m = workerSrc.match(/const HARNESS = String\.raw`([\s\S]*?)`;/);
if (!m) {
    console.error('Não encontrei a constante HARNESS em js/py/pyodideWorker.js');
    process.exit(1);
}
const harness = m[1];

const challenges = Object.values(PY_CHALLENGES).flat();
const payloads = challenges.map(c => ({
    id: c.id,
    topic: c.topic,
    difficulty: c.difficulty,
    title: c.title,
    packages: c.packages || [],
    setup: c.setup || '',
    solution: c.solution || '',
    starter: c.starterCode || '',
    cases: (c.cases || []).map(t => ({
        name: t.name, call: t.call, expected: t.expected, hidden: !!t.hidden,
    })),
}));

const dir = mkdtempSync(join(tmpdir(), 'meanfall-py-'));
const dataPath = join(dir, 'challenges.json');
const runnerPath = join(dir, 'runner.py');
writeFileSync(dataPath, JSON.stringify(payloads));

const runner = `${harness}

import json, sys

with open(${JSON.stringify(dataPath)}, encoding='utf-8') as fh:
    desafios = json.load(fh)

falhas = []
vazios = []
total_casos = 0

for d in desafios:
    if not d['cases']:
        falhas.append((d['id'], 'sem casos de teste'))
        continue
    total_casos += len(d['cases'])

    rel = json.loads(_mf_run(json.dumps({
        'setup': d['setup'], 'code': d['solution'], 'cases': d['cases'],
    })))
    if rel['error']:
        falhas.append((d['id'], f"gabarito quebrou em {rel['errorStage']}: {rel['error']}"))
        continue
    for r in rel['results']:
        if not r['passed']:
            motivo = r['error'] or f"esperado {r['expected']} · obtido {r['got']}"
            falhas.append((d['id'], f"caso '{r['name']}': {motivo}"))

    rel_starter = json.loads(_mf_run(json.dumps({
        'setup': d['setup'], 'code': d['starter'], 'cases': d['cases'],
    })))
    if rel_starter['ok']:
        vazios.append(d['id'])

print(f"{len(desafios)} desafios · {total_casos} casos de teste")
if vazios:
    print(f"\\nESQUELETO JÁ PASSA (desafio vazio): {', '.join(vazios)}")
for cid, motivo in falhas:
    print(f"FALHOU {cid} — {motivo}")
print("\\nOK — banco íntegro" if not falhas and not vazios else f"\\n{len(falhas)} falha(s), {len(vazios)} desafio(s) vazio(s)")
sys.exit(1 if (falhas or vazios) else 0)
`;
writeFileSync(runnerPath, runner);

try {
    const out = execFileSync('python3', [runnerPath], { encoding: 'utf8' });
    process.stdout.write(out);
} catch (err) {
    process.stdout.write(err.stdout || '');
    process.stderr.write(err.stderr || '');
    process.exit(1);
}

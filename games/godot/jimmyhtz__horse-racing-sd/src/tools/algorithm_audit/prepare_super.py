"""Register the stronger seed candidate and fixed training schedule, before fitting."""
import json,secrets,hashlib
from pathlib import Path
OUT=Path(__file__).resolve().parents[2]/'test-results'/'algorithm-audit'
if (OUT/'super-registration.json').exists(): raise SystemExit('Existing super-seed registration preserved.')
fixtures=[]
for profile in ('super','super_equal','super_coarse','super_fine'):
    for i in range(12):
        config={}
        if profile=='super_equal': config['strengths']=[0.,0.,0.,0.,0.]
        if profile=='super_coarse': config['round_seconds']=.05
        if profile=='super_fine': config['round_seconds']=.001
        fixtures.append(dict(id=f'{profile}-{i}',profile=profile,seed=secrets.token_hex(32),model='super',config=config))
(OUT/'super-oracle-manifest.json').write_text(json.dumps(fixtures))
with (OUT/'super-oracle-input.csv').open('w') as f:
    for row in fixtures: f.write(f"{row['id']},{row['profile']},{row['seed']},1\n")
(OUT/'training-seeds.txt').write_text('\n'.join(secrets.token_hex(32) for _ in range(10000))+'\n')
reg=dict(master_seed='256-bit OS cryptographic entropy, supplemented by high-resolution/system time, process id and optional in-game mouse-activity digest; encoded as 64 hex characters',
    stream='SHA-256 counter blocks, separate scheduler and horse domains; entire master used in every block, unbiased rejection sampling for shuffle indices',
    production_change=False,timing_baseline_seconds=.005,timing_label='1 tick, Standard; coarser to left, finer to right',
    training=dict(seeds=10000,iterations=6,objective='individual win frequencies only',
                  update='strength += 0.7 * log(target/observed)/8, subtract mean, clamp to [-0.3,0.3]',
                  seed_sha256=hashlib.sha256((OUT/'training-seeds.txt').read_bytes()).hexdigest()),
    validation='Freeze final iteration, then generate independent holdout seeds. No intervals from training. Pair probabilities remain independently tested; no deployment if targets fail.',
    scope='User authorized remaining calculation/testing; offline parameter fitting is evidence for the next fix, not an automatic production calibration.')
(OUT/'super-registration.json').write_text(json.dumps(reg,indent=2))
print('Registered 48 actual-engine fixtures and 10,000 fixed training seeds; six predetermined iterations.')

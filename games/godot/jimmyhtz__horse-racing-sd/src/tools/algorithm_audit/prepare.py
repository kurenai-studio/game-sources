"""Freeze independent seeds and source hashes before seeing any batch outcomes."""
from pathlib import Path
import hashlib
import json
import math
import secrets

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'test-results' / 'algorithm-audit'
OUT.mkdir(parents=True, exist_ok=True)
profiles = {
    'legacy': ('legacy', {}),
    'effort': ('effort', {}),
    'equal': ('effort', {'strengths': [0., 0., 0., 0., 0.]}),
    'constant': ('effort', {'base_speed': 10., 'speed_spread': 0., 'round_seconds': .01, 'finish_steps': .15}),
    'edge': ('effort', {'speed_spread': .4, 'acceleration': 1., 'round_seconds': .001, 'finish_steps': 100., 'strengths': [.3, -.3, .3, -.3, 0.]}),
}
if (OUT / 'preregistration.json').exists():
    raise SystemExit('Existing preregistration preserved; do not replace seeds after observing outcomes.')
fixtures = []
for profile, (model, config) in profiles.items():
    seeds = [0, 1, 123, 5000, 5086, 2147483646, 4294967295] + [secrets.randbits(32) for _ in range(25)]
    for index, seed in enumerate(seeds):
        fixtures.append(dict(id=f'{profile}-{index}', profile=profile, seed=seed, model=model, config=config))
(OUT / 'oracle-manifest.json').write_text(json.dumps(fixtures), encoding='utf-8')
with (OUT / 'oracle-input.csv').open('w', encoding='utf-8') as f:
    for row in fixtures: f.write(f"{row['id']},{row['profile']},{row['seed']},1\n")
with (OUT / 'batch-input.csv').open('w', encoding='utf-8') as f:
    for profile in ('legacy', 'effort', 'equal'):
        for i in range(50000):
            # Domain is each row's independently generated 32-bit seed; duplicates are valid draws.
            f.write(f'{profile}-{i},{profile},{secrets.randbits(32)},{int(i < 1000 and profile != "equal")}\n')
hashes = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
          for p in [ROOT / 'core' / name for name in ('random_stream.gd','race_engine.gd','effort_race_engine.gd','odds_model.gd')]}
manifest = dict(date='2026-10-23', races_per_scenario=50000, scenarios=['legacy','effort','equal'],
                probability_endpoints=105, family_alpha=.01,
                simultaneous_hoeffding_radius=math.sqrt(math.log(2*105/.01)/(2*50000)),
                seed_source='Independent OS cryptographic 32-bit draws, with replacement; fixed before batch results',
                batch_seed_sha256=hashlib.sha256((OUT/'batch-input.csv').read_bytes()).hexdigest(),
                first_targets=[.35,.27,.20,.13,.05], pair_targets='Existing predeclared Plackett-Luce targets',
                equal_targets='Five 0.2 wins, ten 0.1 unordered pairs and twenty 0.05 ordered pairs',
                secondary_sample='First 1000 preselected seeds per default model; 1001 interpolated positions through second finish',
                acceptance='Diagnostic pass/fail of targets against simultaneous bounds, not equivalence or payout certification',
                engine_hashes=hashes)
(OUT/'preregistration.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
print(json.dumps(manifest, indent=2))

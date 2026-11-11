"""Freeze a fresh stream-seeding diagnosis after the equal-strength pair failure."""
from pathlib import Path
import secrets
import json
import hashlib
import math

OUT=Path(__file__).resolve().parents[2]/'test-results'/'algorithm-audit'
if (OUT/'diagnostic-registration.json').exists(): raise SystemExit('Keep the existing diagnostic seeds.')
fixtures=[]
for profile in ('mixed','mixed_equal'):
    for i in range(32):
        fixtures.append(dict(id=f'{profile}-{i}',profile=profile,seed=secrets.randbits(32),model='mixed',
                             config={} if profile=='mixed' else {'strengths':[0.,0.,0.,0.,0.]}))
(OUT/'mixed-oracle-manifest.json').write_text(json.dumps(fixtures))
with (OUT/'mixed-oracle-input.csv').open('w') as f:
    for row in fixtures: f.write(f"{row['id']},{row['profile']},{row['seed']},1\n")
with (OUT/'diagnostic-input.csv').open('w') as f:
    for profile in ('mixed','mixed_equal'):
        for i in range(50000): f.write(f'{profile}-{i},{profile},{secrets.randbits(32)},{int(i<1000 and profile=="mixed")}\n')
reg=dict(hypothesis='Additive per-horse seeds create correlated random streams and unequal joint finish probabilities even with equal strengths.',
    intervention='Only hash-domain-separate scheduler and horse seeds; inherit every movement equation and exact 10x timing.',
    production_change=False,races_per_scenario=50000,scenarios=['mixed','mixed_equal'],probability_endpoints=70,family_alpha=.01,
    radius=math.sqrt(math.log(2*70/.01)/100000),
    scope='Fresh diagnostic experiment; separate 99% family, not retroactive extension of initial confidence claim.',
    seed_sha256=hashlib.sha256((OUT/'diagnostic-input.csv').read_bytes()).hexdigest())
(OUT/'diagnostic-registration.json').write_text(json.dumps(reg,indent=2))
print(json.dumps(reg,indent=2))

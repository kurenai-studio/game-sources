"""Freeze the predeclared final training iteration, then draw independent holdout seeds."""
import csv,hashlib,json,math,secrets
from pathlib import Path
OUT=Path(__file__).resolve().parents[2]/'test-results'/'algorithm-audit'
if (OUT/'frozen-registration.json').exists(): raise SystemExit('Frozen candidate and seeds already exist.')
training=list(csv.DictReader((OUT/'training.csv').open()))
assert len(training)==6 and training[-1]['iteration']=='5'
strengths=[float(training[-1][f's{i}']) for i in range(1,6)]
profile='super_fit:'+';'.join(repr(x) for x in strengths)
# Standard validation is separate from coarse/fine diagnostics and training.
with (OUT/'holdout-input.csv').open('w') as f:
    for i in range(200000): f.write(f'frozen-{i},{profile},{secrets.token_hex(32)},{int(i<1000)}\n')
with (OUT/'ticks-input.csv').open('w') as f:
    for i in range(10000):
        seed=secrets.token_hex(32)
        for label,tick in [('coarse',.05),('standard',.005),('fine',.001)]:
            f.write(f'{label}-{i},{profile},{seed},0,{tick}\n')
fixtures=[]
for label,tick in [('coarse',.05),('standard',.005),('fine',.001)]:
    for i in range(8):
        fixtures.append(dict(id=f'{label}-{i}',profile=profile,seed=secrets.token_hex(32),model='super',config={'strengths':strengths,'round_seconds':tick}))
(OUT/'frozen-oracle-manifest.json').write_text(json.dumps(fixtures))
with (OUT/'frozen-oracle-input.csv').open('w') as f:
    for row in fixtures: f.write(f"{row['id']},{profile},{row['seed']},1,{row['config']['round_seconds']}\n")
reg=dict(strengths=strengths,profile=profile,production_change=False,
    training_sha256=hashlib.sha256((OUT/'training.csv').read_bytes()).hexdigest(),
    holdout=dict(races=200000,endpoints=35,alpha=.01,radius=math.sqrt(math.log(2*35/.01)/(2*200000)),
                 interpretation='Fresh frozen-model win/pair/ordered diagnostic bounds, not equivalence or certified payback.'),
    ticks=dict(races_per_setting=10000,settings={'coarse':.05,'standard':.005,'fine':.001},endpoints=105,alpha=.01,
               radius=math.sqrt(math.log(2*105/.01)/(2*10000)),
               interpretation='Paired common seeds across resolutions; marginal bounds remain valid. A broad sensitivity screen cannot certify odds invariance.'),
    seed_hashes={name:hashlib.sha256((OUT/name).read_bytes()).hexdigest() for name in ['holdout-input.csv','ticks-input.csv']})
(OUT/'frozen-registration.json').write_text(json.dumps(reg,indent=2))
print(json.dumps(reg,indent=2))

"""Register independent seeds after freezing the numerical contract."""
import hashlib
import json
import math
import secrets
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'test-results'/'payback-v2'

def prepare():
    path=OUT/'registration.json'
    if path.exists():
        raise FileExistsError('Registered validation inputs must not be replaced')
    catalog=json.loads((OUT/'catalog.json').read_text())
    with (OUT/'config.csv').open('w') as out:
        for percent,card in catalog['cards'].items():
            component=catalog['components'][card['component']]
            out.write(','.join(map(str,[percent,component['high_threshold'],component['low_threshold'],*card['profile_units']]))+'\n')
    with (OUT/'oracle-input.csv').open('w') as out:
        for i in range(32):
            percent=[70,80,90,100,125,200,89,97][i%8]
            seed=hashlib.sha256(f'payback-v2-oracle-{i}'.encode()).hexdigest()
            out.write(f'oracle-{i},{seed},{percent},1\n')
    with (OUT/'holdout-input.csv').open('w') as out:
        for percent in [80,90]:
            for i in range(100000):
                out.write(f'{percent}-{i},{secrets.token_hex(32)},{percent},{int(i<250)}\n')
    inputs=['catalog.json','config.csv','oracle-input.csv','holdout-input.csv']
    registration={'model':'positive-step-mixture-v1','races_per_setting':100000,'settings':[80,90],
        'hypotheses':70,'alpha':.01,'simultaneous_frequency_radius':math.sqrt(math.log(140/.01)/(2*100000)),
        'sampling':'Independent OS 256-bit seeds sampled with replacement after catalog freeze',
        'purpose':'Validate movement implementation against analytic win, unordered and ordered probabilities; not fit those probabilities',
        'sha256':{name:hashlib.sha256((OUT/name).read_bytes()).hexdigest() for name in inputs}}
    path.write_text(json.dumps(registration,indent=2)+'\n')
    print(json.dumps({k:v for k,v in registration.items() if k!='sha256'},indent=2))

if __name__=='__main__': prepare()

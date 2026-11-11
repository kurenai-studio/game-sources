"""Analyze frozen audit outcomes without changing targets or production settings."""
from collections import Counter, defaultdict
import csv
import hashlib
import json
import math
from pathlib import Path
from statistics import mean
from validate_runs import validate

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT/'test-results'/'algorithm-audit'
validate(OUT/'batch-input.csv', OUT/'batch.csv', 150000)
prereg = json.loads((OUT/'preregistration.json').read_text())
assert hashlib.sha256((OUT/'batch-input.csv').read_bytes()).hexdigest() == prereg['batch_seed_sha256']
for path, digest in prereg['engine_hashes'].items():
    assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest() == digest, path
weights = prereg['first_targets']
ordered = {f'{a+1}-{b+1}':weights[a]*weights[b]/(1-weights[a]) for a in range(5) for b in range(5) if a!=b}
pairs = {f'{a}-{b}': ordered[f'{a}-{b}']+ordered[f'{b}-{a}'] for a in range(1,6) for b in range(a+1,6)}
payouts = {pair:max(2,min(200,math.floor(.9/p+.5))) for pair,p in pairs.items()}
data=defaultdict(list)
with (OUT/'batch.csv').open() as f:
    for row in csv.DictReader(f): data[row['profile']].append(row)
assert set(data) == set(prereg['scenarios'])
radius=prereg['simultaneous_hoeffding_radius']

def probability(count,n,target):
    observed=count/n
    lo,hi=max(0,observed-radius),min(1,observed+radius)
    return dict(count=count,target=target,observed=observed,low=lo,high=hi,
                difference_pp=100*(observed-target),target_excluded=not lo<=target<=hi)

from metrics import metrics

report=dict(preregistration=prereg,replica_parity=json.loads((OUT/'oracle-parity.json').read_text()),models={},
            rounding=dict(requested_rtp=.9,payouts=payouts,target_probabilities=pairs,
                          target_expected_return={p:pairs[p]*payouts[p] for p in pairs}))
for profile,rows in data.items():
    n=len(rows); assert n==50000
    win_counts=Counter(int(r['first'])+1 for r in rows)
    pair_counts=Counter('-'.join(map(str,sorted([int(r['first'])+1,int(r['second'])+1]))) for r in rows)
    ordered_counts=Counter(f"{int(r['first'])+1}-{int(r['second'])+1}" for r in rows)
    model=dict(races=n,wins={str(h):probability(win_counts[h],n,.2 if profile=='equal' else weights[h-1]) for h in range(1,6)},
               pairs={p:probability(pair_counts[p],n,.1 if profile=='equal' else pairs[p]) for p in pairs},
               ordered={p:probability(ordered_counts[p],n,.05 if profile=='equal' else ordered[p]) for p in ordered})
    model['excluded_targets']={key:sum(v['target_excluded'] for v in model[key].values()) for key in ('wins','pairs','ordered')}
    model['invalid_finishes']=sum(int(r['first'])==int(r['second']) or float(r['t1'])>float(r['t2']) or sorted(int(r[f'o{i}']) for i in range(1,6))!=list(range(5)) or abs(float(r[f'p{int(r["second"])+1}'])-1000)>1e-7 for r in rows)
    model['exact_first_second_ties']=sum(float(r['t1'])==float(r['t2']) for r in rows)
    win_sequence=[int(r['first']) for r in rows]
    pair_sequence=[tuple(sorted((r['first'],r['second']))) for r in rows]
    model['three_race_same_winner_windows']=sum(len(set(win_sequence[i:i+3]))==1 for i in range(n-2))
    model['three_race_same_pair_windows']=sum(len(set(pair_sequence[i:i+3]))==1 for i in range(n-2))
    model['pair_1_2_three_consecutive_probability_estimate']=(pair_counts['1-2']/n)**3
    model['pair_expected_returns_at_current_90pct_board']={p:dict(observed=payouts[p]*pair_counts[p]/n,
        low=payouts[p]*model['pairs'][p]['low'],high=payouts[p]*model['pairs'][p]['high']) for p in pairs}
    report['models'][profile]=model

observations=defaultdict(list)
# Cross-check the independent Python metric calculations against the existing Godot harness.
metric_oracle={r['id']:r['metrics'] for r in map(json.loads,(OUT/'oracle-metrics.jsonl').read_text().splitlines())}
metric_checks=0
for row in map(json.loads,(OUT/'oracle.jsonl').read_text().splitlines()):
    calculated=metrics(row['samples'],row['result']['first'])
    for key,expected in metric_oracle[row['id']].items():
        assert abs(calculated[key]-expected)<1e-8,(row['id'],key,calculated[key],expected)
        metric_checks+=1
report['metric_oracle_checks']=metric_checks
with (OUT/'batch-samples.csv').open() as f:
    current=None; samples=[]
    def flush():
        if current is None: return
        profile,index=current.rsplit('-',1)
        assert len(samples)==1001
        row=data[profile][int(index)]
        value=metrics(samples,int(row['first']))
        value.update(id=current,seed=int(row['seed']),first=int(row['first'])+1,second=int(row['second'])+1)
        observations[profile].append(value)
    for row in csv.DictReader(f):
        if row['id']!=current:
            flush(); current=row['id']; samples=[]
        samples.append([float(row[f'p{i}']) for i in range(1,6)])
    flush()
for profile,observed in observations.items():
    assert len(observed)==1000
    keys=[k for k in observed[0] if k not in ('id','seed','first','second')]
    report['models'][profile]['competition']=dict(races=1000,means={k:mean(r[k] for r in observed) for k in keys},
        races_with_3plus_lead_changes=sum(r['lead_changes']>=3 for r in observed),
        races_with_mean_span_under_5pct=sum(r['mean_span_pct']<5 for r in observed),
        last_to_first_example_seeds=[r['seed'] for r in observed if r['winner_last_at_90pct']][:12])
(OUT/'competition-races.json').write_text(json.dumps(observations,indent=2))
report['data_sha256']={name:hashlib.sha256((OUT/name).read_bytes()).hexdigest() for name in ('batch.csv','batch-samples.csv','oracle.jsonl')}
(OUT/'report.json').write_text(json.dumps(report,indent=2))
print(json.dumps({p:dict(wins={h:round(v['observed']*100,3) for h,v in m['wins'].items()},excluded=m['excluded_targets'],invalid=m['invalid_finishes'],ties=m['exact_first_second_ties'],competition=m.get('competition')) for p,m in report['models'].items()},indent=2))
print('Target-only expected returns with integer rounding:',report['rounding']['target_expected_return'])

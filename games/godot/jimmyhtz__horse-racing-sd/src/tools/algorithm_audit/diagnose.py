"""Analyze the separately registered stream-seeding experiment and payout arithmetic."""
import csv
import hashlib
import json
import math
from collections import Counter,defaultdict
from pathlib import Path
from statistics import mean
from metrics import metrics
from validate_runs import validate

OUT=Path(__file__).resolve().parents[2]/'test-results'/'algorithm-audit'
validate(OUT/'diagnostic-input.csv', OUT/'diagnostic.csv', 100000)
reg=json.loads((OUT/'diagnostic-registration.json').read_text())
base=json.loads((OUT/'report.json').read_text())
assert hashlib.sha256((OUT/'diagnostic-input.csv').read_bytes()).hexdigest()==reg['seed_sha256']
data=defaultdict(list)
with (OUT/'diagnostic.csv').open() as f:
    for row in csv.DictReader(f): data[row['profile']].append(row)
report=dict(registration=reg,replica_parity=json.loads((OUT/'mixed-oracle-parity.json').read_text()),models={})
for profile,rows in data.items():
    n=len(rows); assert n==50000
    counts=dict(wins=Counter(str(int(r['first'])+1) for r in rows),
        pairs=Counter('-'.join(map(str,sorted([int(r['first'])+1,int(r['second'])+1]))) for r in rows),
        ordered=Counter(f"{int(r['first'])+1}-{int(r['second'])+1}" for r in rows))
    targets=base['models']['equal' if profile=='mixed_equal' else 'effort']
    result=dict(races=n)
    for family in ('wins','pairs','ordered'):
        result[family]={}
        for key,v in targets[family].items():
            observed=counts[family][key]/n
            lo,hi=max(0,observed-reg['radius']),min(1,observed+reg['radius'])
            result[family][key]=dict(count=counts[family][key],observed=observed,target=v['target'],low=lo,high=hi,
                target_excluded=not lo<=v['target']<=hi)
    result['excluded_targets']={family:sum(v['target_excluded'] for v in result[family].values()) for family in counts}
    result['invalid_finishes']=sum(r['first']==r['second'] or float(r['t1'])>=float(r['t2']) or abs(float(r[f'p{int(r["second"])+1}'])-1000)>1e-7 for r in rows)
    report['models'][profile]=result
assert set(data)==set(reg['scenarios'])
observations=[]
with (OUT/'diagnostic-samples.csv').open() as f:
    current=None; samples=[]
    def flush():
        if current is None: return
        index=int(current.split('-')[-1]); row=data['mixed'][index]
        assert len(samples)==1001
        observation=metrics(samples,int(row['first']))
        observation.update(id=current,seed=int(row['seed']))
        observations.append(observation)
    for row in csv.DictReader(f):
        if row['id']!=current:
            flush(); current=row['id']; samples=[]
        samples.append([float(row[f'p{i}']) for i in range(1,6)])
    flush()
assert len(observations)==1000
keys=[k for k in observations[0] if k not in ('id','seed')]
report['models']['mixed']['competition']=dict(races=1000,means={k:mean(r[k] for r in observations) for k in keys},
    races_with_3plus_lead_changes=sum(r['lead_changes']>=3 for r in observations),
    races_with_mean_span_under_5pct=sum(r['mean_span_pct']<5 for r in observations),
    last_to_first_example_seeds=[r['seed'] for r in observations if r['winner_last_at_90pct']][:12])
(OUT/'diagnostic-competition.json').write_text(json.dumps(observations,indent=2))
# Describe the exact additive-seed relationship independently of outcomes.
modulus=2147483647
report['original_stream_relationship']=dict(modulus=modulus,seed_offset=7919,multiplier=48271,
    first_draw_offset_modulus=7919*48271%modulus,
    formula='state_j(k) - state_i(k) = 48271^k * 7919 * (j-i) modulo 2147483647, away from initial seed-wrap boundaries; modulo-M normalization must be considered at wrap boundaries.',
    scope='A known joint dependence, not a claim of financial security or independent cryptographic streams after hashing.')
# Fixed diagnostic portfolios. No actual player accounts or virtual-player implementation.
payouts=base['rounding']['payouts']; pairs=base['rounding']['target_probabilities']
portfolios={
    'One on every pair':list(pairs),'Pair 1-2':['1-2'],'Pair 4-5':['4-5'],
    'All horse 1 pairs':[p for p in pairs if '1' in p.split('-')],
    'All horse 5 pairs':[p for p in pairs if '5' in p.split('-')],
    'Middle horses':['2-3','2-4','3-4'],
    'Three shortest prices':sorted(pairs,key=lambda p:payouts[p])[:3],
    'Three longest prices':sorted(pairs,key=lambda p:payouts[p])[-3:]}
report['style_expectations']={name:dict(selected=selected,
    target_only_rtp=sum(pairs[p]*payouts[p] for p in selected)/len(selected),
    legacy_observed_rtp=sum(base['models']['legacy']['pairs'][p]['observed']*payouts[p] for p in selected)/len(selected),
    effort_observed_rtp=sum(base['models']['effort']['pairs'][p]['observed']*payouts[p] for p in selected)/len(selected)) for name,selected in portfolios.items()}
report['fixed_board_equal_rtp']=1/sum(1/m for m in payouts.values())
report['fixed_board_identity']='If all mutually exclusive pairs return the same rho, p_i*m_i=rho and sum(p_i)=1 imply rho=1/sum(1/m_i).'
report['hashes']={name:hashlib.sha256((OUT/name).read_bytes()).hexdigest() for name in ['diagnostic.csv','diagnostic-samples.csv']}
(OUT/'diagnostic-report.json').write_text(json.dumps(report,indent=2))
print(json.dumps({p:dict(wins={h:round(v['observed']*100,3) for h,v in m['wins'].items()},pairs={h:round(v['observed']*100,3) for h,v in m['pairs'].items()},excluded=m['excluded_targets'],invalid=m['invalid_finishes']) for p,m in report['models'].items()},indent=2))

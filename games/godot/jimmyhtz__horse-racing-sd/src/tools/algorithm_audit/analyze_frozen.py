import csv,hashlib,json
from pathlib import Path
from collections import defaultdict,Counter
from statistics import mean
from metrics import metrics
from validate_runs import validate
OUT=Path(__file__).resolve().parents[2]/'test-results'/'algorithm-audit'
validate(OUT/'holdout-input.csv', OUT/'holdout.csv', 200000)
validate(OUT/'ticks-input.csv', OUT/'ticks.csv', 30000)
reg=json.loads((OUT/'frozen-registration.json').read_text())
base=json.loads((OUT/'report.json').read_text())
for name,digest in reg['seed_hashes'].items(): assert hashlib.sha256((OUT/name).read_bytes()).hexdigest()==digest
def summarize(rows,radius):
    n=len(rows)
    counts=dict(wins=Counter(str(int(r['first'])+1) for r in rows),
        pairs=Counter('-'.join(map(str,sorted([int(r['first'])+1,int(r['second'])+1]))) for r in rows),
        ordered=Counter(f"{int(r['first'])+1}-{int(r['second'])+1}" for r in rows))
    result=dict(races=n)
    for family in counts:
        result[family]={}
        for key,ref in base['models']['effort'][family].items():
            p=counts[family][key]/n; lo=max(0,p-radius); hi=min(1,p+radius)
            result[family][key]=dict(count=counts[family][key],observed=p,target=ref['target'],low=lo,high=hi,
                                    difference_pp=100*(p-ref['target']),target_excluded=not lo<=ref['target']<=hi)
    result['excluded_targets']={family:sum(v['target_excluded'] for v in result[family].values()) for family in counts}
    result['invalid_finishes']=sum(r['first']==r['second'] or float(r['t1'])>=float(r['t2']) or abs(float(r[f'p{int(r["second"])+1}'])-1000)>1e-7 for r in rows)
    return result
rows=list(csv.DictReader((OUT/'holdout.csv').open()))
assert len(rows)==200000
report=dict(registration=reg,holdout=summarize(rows,reg['holdout']['radius']))
observations=[]
with (OUT/'holdout-samples.csv').open() as f:
    current=None; samples=[]
    def flush():
        if current is None:return
        index=int(current.split('-')[-1]); row=rows[index]
        assert len(samples)==1001
        m=metrics(samples,int(row['first'])); m.update(id=current,seed=row['seed']); observations.append(m)
    for row in csv.DictReader(f):
        if row['id']!=current: flush(); current=row['id']; samples=[]
        samples.append([float(row[f'p{i}']) for i in range(1,6)])
    flush()
assert len(observations)==1000
keys=[k for k in observations[0] if k not in ('id','seed')]
report['competition']=dict(races=1000,means={k:mean(r[k] for r in observations) for k in keys},
    races_with_3plus_lead_changes=sum(r['lead_changes']>=3 for r in observations),
    races_with_mean_span_under_5pct=sum(r['mean_span_pct']<5 for r in observations),
    late_comeback_seeds=[r['seed'] for r in observations if r['winner_last_at_90pct']][:12])
(OUT/'frozen-competition.json').write_text(json.dumps(observations,indent=2))
del rows
ticks=defaultdict(list)
with (OUT/'ticks.csv').open() as f:
    for r in csv.DictReader(f): ticks[r['id'].split('-')[0]].append(r)
assert set(ticks)=={'coarse','standard','fine'} and all(len(r)==10000 for r in ticks.values())
report['ticks']={key:summarize(value,reg['ticks']['radius']) for key,value in ticks.items()}
report['tick_same_seed_winner_changes']={key:sum(a['first']!=b['first'] for a,b in zip(ticks['standard'],ticks[key])) for key in ('coarse','fine')}
for key in ('coarse','fine'):
    assert all(a['seed']==b['seed'] for a,b in zip(ticks['standard'],ticks[key]))
report['data_hashes']={name:hashlib.sha256((OUT/name).read_bytes()).hexdigest() for name in ['holdout.csv','ticks.csv']}
(OUT/'frozen-report.json').write_text(json.dumps(report,indent=2))
print(json.dumps(dict(wins=report['holdout']['wins'],excluded=report['holdout']['excluded_targets'],invalid=report['holdout']['invalid_finishes'],competition=report['competition'],tick_wins={k:{h:round(v['observed']*100,3) for h,v in m['wins'].items()} for k,m in report['ticks'].items()},same_seed_winner_changes=report['tick_same_seed_winner_changes']),indent=2))

"""Validate complete registered movement runs and compare every joint target."""
import csv
import hashlib
import json
import math
import sys
from collections import Counter
from fractions import Fraction
from pathlib import Path
from statistics import mean
from math_model import PAIRS, card_contract, finish_pmf, finish_probabilities

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'test-results'/'payback-v2'
sys.path.insert(0,str(ROOT/'tools'/'algorithm_audit'))
from metrics import metrics

def analyze():
    registration=json.loads((OUT/'registration.json').read_text())
    for name,digest in registration['sha256'].items():
        assert hashlib.sha256((OUT/name).read_bytes()).hexdigest()==digest,('changed input',name)
    assert json.loads((OUT/'oracle-parity.json').read_text())['status']=='PASS'
    catalog=json.loads((OUT/'catalog.json').read_text())
    radius=registration['simultaneous_frequency_radius']
    counts={r:{'wins':Counter(),'pairs':Counter(),'ordered':Counter(),'profiles':Counter(),'n':0} for r in registration['settings']}
    requested=list(csv.reader((OUT/'holdout-input.csv').open()))
    assert len({row[0] for row in requested})==len(requested)
    results={}; seen=set()
    with (OUT/'holdout-fast.csv').open() as f:
        for index,row in enumerate(csv.DictReader(f)):
            assert index<len(requested),'extra result'
            source=requested[index]
            assert row['id']==source[0] and row['seed']==source[1] and row['percent']==source[2]
            assert row['id'] not in seen
            seen.add(row['id'])
            order=[int(row[f'o{i}']) for i in range(5)]
            assert sorted(order)==list(range(5))
            first,second=int(row['first']),int(row['second'])
            assert order[:2]==[first,second]
            rounds,events=int(row['rounds']),int(row['events'])
            assert 5000<=rounds<=10000 and (rounds-1)*5<events<=rounds*5
            t1,t2=float(row['first_time']),float(row['second_time'])
            assert 24.995<t1<t2<=50 and math.isfinite(t1+t2)
            profile=int(row['profile']); assert 0<=profile<10
            c=counts[int(row['percent'])]
            c['n']+=1; c['wins'][first]+=1; c['pairs'][tuple(sorted((first,second)))]+=1
            c['ordered'][first,second]+=1; c['profiles'][profile]+=1
            if source[3]=='1': results[row['id']]=first
    assert len(seen)==len(requested)==200000,'missing or extra movement results'
    samples={key:[] for key in results}
    for row in csv.DictReader((OUT/'holdout-fast-samples.csv').open()):
        assert row['id'] in samples
        sample=samples[row['id']]
        assert int(row['index'])==len(sample),'duplicate or missing playback sample'
        values=[float(row[f'p{i}']) for i in range(5)]
        assert all(math.isfinite(v) and v>=0 for v in values)
        if sample: assert all(v>=previous-1e-9 for v,previous in zip(values,sample[-1]))
        sample.append(values)
    assert all(len(s)==1001 for s in samples.values())
    comparisons=[]; summaries=[]
    for percent,c in counts.items():
        assert c['n']==100000
        card=catalog['cards'][str(percent)]
        for i in range(5):
            comparisons.append({'percent':percent,'type':'win','key':str(i+1),'observed':c['wins'][i]/c['n'],'target':card['wins'][i]})
        returns=[]
        for k,(i,j) in enumerate(PAIRS):
            observed=c['pairs'][i,j]/c['n']
            comparisons.append({'percent':percent,'type':'pair','key':f'{i+1}-{j+1}','observed':observed,'target':card['pairs'][k]})
            returns.append(observed*card['payoffs'][k])
        for i in range(5):
            for j in range(5):
                if i!=j: comparisons.append({'percent':percent,'type':'ordered','key':f'{i+1}-{j+1}','observed':c['ordered'][i,j]/c['n'],'target':card['ordered'][i][j]})
        measured=[metrics(s,results[key]) for key,s in samples.items() if key.startswith(str(percent)+'-')]
        summaries.append({'requested_percent':percent,'races':c['n'],'competition_samples':len(measured),
                          'competition_mean':{k:mean(m[k] for m in measured) for k in measured[0]},
                          'empirical_equal_stakes_return_percent':100*mean(returns),
                          'empirical_per_pair_return_range_percent':[100*min(returns),100*max(returns)]})
    failures=[c for c in comparisons if abs(c['observed']-c['target'])>radius]
    # Recompute the full-size analytical reference with more decimal precision.
    maximum_precision_difference=0.
    for component in catalog['components']:
        high=finish_pmf(10000,Fraction(component['high_threshold'],2**32),precision=85)
        low=finish_pmf(10000,Fraction(component['low_threshold'],2**32),precision=85)
        check=finish_probabilities([high]*2+[low]*3)
        maximum_precision_difference=max(maximum_precision_difference,max(abs(a-b) for a,b in zip(check['pairs'],component['probabilities']['pairs'])))
    assert maximum_precision_difference<1e-12
    for percent,card in catalog['cards'].items():
        c=card_contract(int(percent),card['payoffs'])
        assert sum(card['profile_units'])==2**48 and min(card['profile_units'])>=0
        assert max(abs(p*m-int(percent)/100) for p,m in zip(card['pairs'],card['payoffs']))<=1e-6
        # Conditional expectation is the same for every nonnegative stake vector.
        for stakes in [[1]*10]+[[int(i==j) for i in range(10)] for j in range(10)]+[list(range(1,11)),list(range(10,0,-1))]:
            ret=sum(s*p*m for s,p,m in zip(stakes,card['pairs'],card['payoffs']))/sum(stakes)
            assert abs(ret-int(percent)/100)<=1e-6
    report={'status':'PASS' if not failures else 'FAIL','model':catalog['model'],
            'races':len(seen),'hypotheses':len(comparisons),'alpha':.01,
            'simultaneous_radius_percentage_points':radius*100,'excluded_targets':len(failures),
            'maximum_frequency_error_percentage_points':100*max(abs(c['observed']-c['target']) for c in comparisons),
            'cards_checked':len(catalog['cards']),
            'worst_analytic_return_error_percentage_points':100*max(c['max_return_error'] for c in catalog['cards'].values()),
            'higher_precision_difference':maximum_precision_difference,'summaries':summaries,
            'developer_only_comparisons':comparisons,'failures':failures}
    (OUT/'report.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k not in ['developer_only_comparisons','failures']},indent=2))
    if failures: raise SystemExit(1)

if __name__=='__main__': analyze()

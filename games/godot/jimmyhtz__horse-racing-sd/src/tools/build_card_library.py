"""Compile source cards and reusable movement mathematics, without simulating winners."""
from pathlib import Path
from fractions import Fraction
import bisect, hashlib, json, math, sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools/payback_v2'))
from math_model import PAIRS, fit_profiles, solve_linear

def build():
    source_path=ROOT/'data/historical_cards.json'
    source=json.loads(source_path.read_text())
    base_path=ROOT/'data/payback_v1.json'
    base=json.loads(base_path.read_text())
    assert source['schema']==1 and len(source['cards'])==48
    assert len({c['id'] for c in source['cards']})==48
    bases=[]
    for component in base['components']:
        ordered=component['probabilities']['ordered']; orders=[]
        for pair in PAIRS:
            labels=list(pair)+[h for h in range(5) if h not in pair]
            rev=[labels.index(h) for h in range(5)]
            orders.append([[ordered[rev[i]][rev[j]] for j in range(5)] for i in range(5)])
        matrix=[[o[i][j]+o[j][i] for o in orders] for i,j in PAIRS]
        columns=[solve_linear(matrix,[float(i==j) for i in range(10)]) for j in range(10)]
        inverse=[[columns[j][i] for j in range(10)] for i in range(10)]
        bases.append({'inverse':inverse,'orders':orders})
    cards=[]; returns=[]
    for row in source['cards']:
        payoffs=row['payoffs']
        assert len(payoffs)==10 and all(type(v) is int and 2<=v<=200 for v in payoffs)
        actual=1/sum(Fraction(1,v) for v in payoffs)
        contract={'payoffs':payoffs,'pair_probabilities':[actual/v for v in payoffs],'requested_percent':float(actual*100)}
        for index,component in enumerate(base['components']):
            try: fit=fit_profiles(component['probabilities'],contract)
            except ValueError: continue
            cards.append({**row,'component':index,**fit,'card_return':float(actual)})
            returns.append(actual)
            break
        else: raise ValueError('Unrepresentable source card: '+row['id'])
    # Equal starting quantities, then bounded integer swaps. No source payout changes.
    size=1000; counts=[size//len(cards)]*len(cards)
    for i in range(size%len(cards)): counts[i]+=1
    target=Fraction(4,5)*size
    differences=sorted((float(returns[j]-returns[i]),i,j) for i in range(48) for j in range(48) if i!=j)
    values=[d[0] for d in differences]
    for iteration in range(12):
        residual=target-sum(n*r for n,r in zip(counts,returns))
        best=(abs(residual),None)
        for delta,a,b in differences:
            if counts[a]<=1: continue
            index=bisect.bisect_left(values,float(residual)-delta)
            for k in [index-1,index]:
                if not 0<=k<len(differences): continue
                _,c,d=differences[k]
                if counts[c] <= (2 if c==a else 1): continue
                error=abs(residual-(returns[b]-returns[a])-(returns[d]-returns[c]))
                if error<best[0]: best=(error,(a,b,c,d))
        if best[1] is None: break
        a,b,c,d=best[1];counts[a]-=1;counts[b]+=1;counts[c]-=1;counts[d]+=1
    actual=sum(n*r for n,r in zip(counts,returns))/size
    assert sum(counts)==size and min(counts)>0 and max(counts)<size//2
    assert abs(actual-Fraction(4,5))<Fraction(1,100000000)
    result={'schema':1,'revision':source['revision'],'source_sha256':hashlib.sha256(source_path.read_bytes()).hexdigest(),'kernel_sha256':hashlib.sha256(base_path.read_bytes()).hexdigest(),'basis':bases,'cards':cards,'cycle_counts':counts,'cycle_size':size,'cycle_return':float(actual),'cycle_return_fraction':[actual.numerator,actual.denominator],'target_return':.8,'max_card_fit_error':max(c['max_return_error'] for c in cards)}
    (ROOT/'data/card_math_v1.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({'cards':len(cards),'cycle_size':size,'cycle_return_percent':float(actual*100),'error_percentage_points':float((actual-Fraction(4,5))*100),'card_min_percent':min(map(float,returns))*100,'card_max_percent':max(map(float,returns))*100,'largest_movement_fit_error':result['max_card_fit_error']},indent=2))
if __name__=='__main__': build()

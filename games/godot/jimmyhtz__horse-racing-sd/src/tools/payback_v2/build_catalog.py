"""Freeze coherent whole-credit cards and movement-derived profile mixtures."""
import bisect
import hashlib
import json
import random
import sys
from fractions import Fraction
from pathlib import Path
from math_model import PAIRS, card_contract, finish_pmf, finish_probabilities, fit_profiles

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT/'test-results'/'payback-v2'
RANGE = 2**32
DISTANCE = 10000


def find_card(percent):
    exact = {90:[3,5,9,30,6,10,45,15,45,18],80:[2,4,10,20,8,16,20,16,40,40]}
    if percent in exact:
        return card_contract(percent,exact[percent])
    # This deterministic build-time search chooses a payoff table, never a race.
    rng = random.Random(202610230000+percent)
    sums = sorted((1/a+1/b,a,b) for a in range(12,201) for b in range(a,201))
    values = [x[0] for x in sums]
    base = [3,5,6,9,10,15,18,30]
    for attempt in range(200000):
        first = sorted(max(2,min(200,round(v*percent/90*rng.uniform(.8,1.2)))) for v in base)
        needed = 100/percent-sum(1/v for v in first)
        index = bisect.bisect_left(values,needed)
        for k in [index-1,index]:
            if not 0<=k<len(sums):
                continue
            _,a,b = sums[k]
            if min(a,b)<first[-1]:
                continue
            payoffs = first+[a,b]
            actual = 1/sum(1/v for v in payoffs)
            if abs(actual-percent/100)>2e-7:
                continue
            # Whole-horse mapping, not independent payoff cell shuffling at runtime.
            mapped = [0]*10
            for cell,m in zip([0,1,4,2,5,7,3,6,8,9],payoffs):
                mapped[cell]=m
            contract=card_contract(percent,mapped)
            contract['search_attempts']=attempt+1
            return contract
    raise ValueError(f'No acceptable integer payoff card for {percent}%')


def build():
    target = OUT/'catalog.json'
    if target.exists():
        raise FileExistsError('Frozen catalog exists; use a new experiment folder')
    OUT.mkdir(parents=True,exist_ok=True)
    contracts = [find_card(r) for r in range(70,201)]
    components=[]
    pending=list(contracts)
    cards={}
    # Small differences accumulate through positive steps. No rank/gap feedback.
    for gap in [.006,.008,.010,.012,.015,.020,.030]:
        high=round((.5+gap)*RANGE); low=RANGE-high
        high_pmf=finish_pmf(DISTANCE,Fraction(high,RANGE))
        low_pmf=finish_pmf(DISTANCE,Fraction(low,RANGE))
        component=finish_probabilities([high_pmf]*2+[low_pmf]*3)
        component_id=len(components)
        components.append({'high_threshold':high,'low_threshold':low,'probabilities':component})
        still_pending=[]
        for c in pending:
            try:
                fit=fit_profiles(component,c)
            except ValueError:
                still_pending.append(c)
                continue
            cards[str(c['requested_percent'])]={'payoffs':c['payoffs'],'component':component_id,
                'exact_return_numerator':c['exact_return'].numerator,
                'exact_return_denominator':c['exact_return'].denominator,**fit}
        pending=still_pending
        print(f'gap {gap}: fitted {len(cards)}/131',flush=True)
        if not pending:
            break
    if pending:
        raise ValueError(f'No representable movement mixture for {[c["requested_percent"] for c in pending]}')
    data={'schema':1,'model':'positive-step-mixture-v1','distance_units':DISTANCE,
          'logical_finish':1000,'round_seconds':.005,'profile_mass':2**48,
          'return_tolerance':1e-6,'components':components,'cards':cards,
          'notice':'Developer numerical candidate only. Not connected to normal play.'}
    target.write_text(json.dumps(data,indent=2)+'\n')
    print(json.dumps({'cards':len(cards),'worst_error_percentage_points':100*max(c['max_return_error'] for c in cards.values()),
                      'sha256':hashlib.sha256(target.read_bytes()).hexdigest()},indent=2))


if __name__=='__main__':
    build()

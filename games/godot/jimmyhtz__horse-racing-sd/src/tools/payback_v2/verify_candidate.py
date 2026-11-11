"""Require complete one-to-one fixture and sample coverage before batching."""
import csv
import json
import math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'test-results'/'payback-v2'

def verify():
    assert (OUT/'oracle-fast.csv').exists(), 'Fast movement replica has not produced evidence'
    requested=[r[0] for r in csv.reader((OUT/'oracle-input.csv').open())]
    assert len(requested)==len(set(requested))>0
    original=[json.loads(line) for line in (OUT/'oracle.jsonl').read_text().splitlines()]
    assert len(original)==len(requested) and {r['id'] for r in original}==set(requested)
    oracle={r['id']:r for r in original}
    rows=list(csv.DictReader((OUT/'oracle-fast.csv').open()))
    assert len(rows)==len(requested) and {r['id'] for r in rows}==set(requested)
    checks=0; maximum=0.
    for row in rows:
        ref=oracle[row['id']]
        assert int(row['profile'])==ref['profile']
        for key in ['first','second','events','rounds']:
            assert int(row[key])==ref['result'][key],(row['id'],key)
            checks+=1
        assert [int(row[f'o{i}']) for i in range(5)]==ref['result']['full_order']
        for key in ['first_time','second_time']:
            difference=abs(float(row[key])-ref['result'][key])
            assert math.isfinite(difference) and difference<1e-8
            maximum=max(maximum,difference); checks+=1
    seen=set()
    for row in csv.DictReader((OUT/'oracle-fast-samples.csv').open()):
        key=(row['id'],int(row['index']))
        assert key not in seen and key[0] in oracle and 0<=key[1]<=1000
        seen.add(key)
        expected=oracle[key[0]]['samples'][key[1]]
        for i in range(5):
            difference=abs(float(row[f'p{i}'])-expected[i])
            assert math.isfinite(difference) and difference<1e-8,(key,i,difference)
            maximum=max(maximum,difference); checks+=1
    assert len(seen)==len(requested)*1001
    report={'status':'PASS','fixtures':len(rows),'samples':len(seen),'checks':checks,'max_difference':maximum}
    (OUT/'oracle-parity.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))

if __name__=='__main__': verify()

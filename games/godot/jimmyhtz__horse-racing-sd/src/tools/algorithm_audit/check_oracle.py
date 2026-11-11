"""Fail closed if the offline replica differs from actual Godot outcomes or playback."""
import csv
import json
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / 'test-results' / 'algorithm-audit'
prefix = sys.argv[1] if len(sys.argv)>1 else 'oracle'
oracle = {r['id']: r for r in map(json.loads,(OUT/f'{prefix}.jsonl').read_text().splitlines())}
rows = list(csv.DictReader((OUT/f'{prefix}-fast.csv').open()))
assert len(rows) == len(oracle) and len(oracle)>0
checks = 0
maximum = 0.
for row in rows:
    ref = oracle[row['id']]['result']
    for name, field in [('first','first'),('second','second'),('events','events')]:
        assert int(row[name]) == ref[field], (row['id'], name, row[name], ref[field])
        checks += 1
    for i in range(5):
        assert int(row[f'o{i+1}']) == ref['order'][i], (row['id'],'order')
        checks += 1
    for name, expected in [('t1',ref['first_time']),('t2',ref['second_time'])]+[(f'p{i+1}',v) for i,v in enumerate(ref['positions'])]+[(f'v{i+1}',v) for i,v in enumerate(ref['velocities'])]:
        error=abs(float(row[name])-expected)
        maximum=max(maximum,error)
        assert error < 1e-8, (row['id'],name,error)
        checks += 1
sample_count=0
with (OUT/f'{prefix}-fast-samples.csv').open() as f:
    for row in csv.DictReader(f):
        reference=oracle[row['id']]['samples'][int(row['index'])]
        for i,value in enumerate(reference):
            error=abs(float(row[f'p{i+1}'])-value)
            maximum=max(maximum,error)
            assert error < 1e-8,(row['id'],row['index'],i,error)
            checks+=1
        sample_count+=1
assert sample_count == len(oracle)*1001
report=dict(result='PASS',fixtures=len(rows),samples=sample_count,checks=checks,maximum_absolute_error=maximum,tolerance=1e-8)
(OUT/f'{prefix}-parity.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))

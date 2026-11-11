"""Check complete row identity and result integrity before interpreting a batch."""
import csv
import hashlib
import itertools
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'test-results' / 'algorithm-audit'


def validate(input_path, result_path, expected):
    seen = set()
    count = 0
    with input_path.open() as inputs, result_path.open() as results:
        for source, result in itertools.zip_longest(csv.reader(inputs), csv.DictReader(results)):
            assert source is not None and result is not None, 'Missing or extra result row'
            assert len(source) in (4, 5), source
            assert (result['id'], result['profile'], result['seed']) == tuple(source[:3]), source[0]
            assert result['id'] not in seen, 'Duplicate race id'
            seen.add(result['id'])
            first, second = int(result['first']), int(result['second'])
            assert 0 <= first < 5 and 0 <= second < 5 and first != second
            order = [int(result[f'o{i}']) for i in range(1, 6)]
            assert sorted(order) == list(range(5)) and order[:2] == [first, second]
            values = [float(result[k]) for k in ['t1', 't2'] + [f'{tag}{i}' for tag in ('p', 'v') for i in range(1, 6)]]
            assert all(math.isfinite(v) for v in values)
            assert 0 < float(result['t1']) <= float(result['t2'])
            assert source[1] == 'legacy' or float(result['t1']) < float(result['t2'])
            assert 0 < int(result['events']) <= 300000
            assert all(float(result[f'v{i}']) > 0 for i in range(1, 6))
            assert abs(float(result[f'p{second+1}']) - 1000) < 1e-7
            count += 1
    assert count == expected, (count, expected)
    return dict(rows=count, input_sha256=hashlib.sha256(input_path.read_bytes()).hexdigest(),
                output_sha256=hashlib.sha256(result_path.read_bytes()).hexdigest())


if __name__ == '__main__':
    prereg = json.loads((OUT / 'preregistration.json').read_text())
    for name, digest in prereg['engine_hashes'].items():
        assert hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == digest, name
    result = {}
    for inputs, output, n in [('batch-input.csv', 'batch.csv', 150000),
                             ('diagnostic-input.csv', 'diagnostic.csv', 100000),
                             ('holdout-input.csv', 'holdout.csv', 200000),
                             ('ticks-input.csv', 'ticks.csv', 30000)]:
        result[output] = validate(OUT / inputs, OUT / output, n)
    super_reg = json.loads((OUT / 'super-registration.json').read_text())
    frozen = json.loads((OUT / 'frozen-registration.json').read_text())
    assert hashlib.sha256((OUT / 'training-seeds.txt').read_bytes()).hexdigest() == super_reg['training']['seed_sha256']
    assert hashlib.sha256((OUT / 'training.csv').read_bytes()).hexdigest() == frozen['training_sha256']
    training = list(csv.DictReader((OUT / 'training.csv').open()))
    assert [int(r['iteration']) for r in training] == list(range(6))
    assert [float(training[-1][f's{i}']) for i in range(1, 6)] == frozen['strengths']
    assert all(sum(int(r[f'w{i}']) for i in range(1, 6)) == 10000 for r in training)
    result['production_engines_unchanged'] = True
    result['training_and_frozen_parameters_verified'] = True
    (OUT / 'integrity.json').write_text(json.dumps(result, indent=2))
    print(json.dumps(result, indent=2))

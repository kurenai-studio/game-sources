"""Small negative-control check: corrupt or incomplete outcomes must be rejected."""
import csv
import tempfile
from pathlib import Path
from validate_runs import OUT, validate

with (OUT / 'batch-input.csv').open() as f:
    source = next(csv.reader(f))
with (OUT / 'batch.csv').open() as f:
    reader = csv.DictReader(f)
    fields = reader.fieldnames
    row = next(reader)

with tempfile.TemporaryDirectory(prefix='integrity-guard-', dir=OUT) as directory:
    root = Path(directory)
    assert root.resolve().is_relative_to(OUT.resolve())
    input_path, output_path = root / 'input.csv', root / 'result.csv'
    with input_path.open('w', newline='') as f:
        csv.writer(f).writerow(source)

    def write(rows):
        with output_path.open('w', newline='') as f:
            w = csv.DictWriter(f, fieldnames=fields)
            w.writeheader()
            w.writerows(rows)

    write([row])
    assert validate(input_path, output_path, 1)['rows'] == 1
    cases = [[], [row, row]]
    for key, value in [('seed', 'wrong'), ('profile', 'wrong'), ('first', row['second']),
                       ('p1', 'nan'), ('v1', '-1'), ('o1', row['o2']), ('events', '0')]:
        corrupted = dict(row)
        corrupted[key] = value
        cases.append([corrupted])
    for rows in cases:
        write(rows)
        try:
            validate(input_path, output_path, 1)
        except AssertionError:
            continue
        raise AssertionError('Corrupt results were accepted')
print(f'INTEGRITY GUARD: one valid fixture accepted; {len(cases)} corrupt/incomplete fixtures rejected')

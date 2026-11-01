"""Check resolved artifacts against their repositories and query OSV by coordinate."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import hashlib
import json
import urllib.request
import urllib.error

ROOT = Path(__file__).resolve().parents[1]
items = json.loads((ROOT / 'build/dependency-inventory.json').read_text())
items = [item for item in items if item['group'] != 'ElMagica']


def read(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'ElMagica-dependency-audit'}), timeout=45).read()


def verify(item):
    path = Path(item['file'])
    base = 'https://repo.maven.apache.org/maven2/' if item['scope'] == 'runtime' else 'https://plugins.gradle.org/m2/'
    url = base + item['group'].replace('.', '/') + '/' + item['name'] + '/' + item['version'] + '/' + path.name
    data = path.read_bytes()
    report = {'file': path.name, 'url': url, 'sha256': hashlib.sha256(data).hexdigest()}
    try:
        try:
            expected = read(url + '.sha256').decode().strip().split()[0].lower()
            matched = report['sha256'] == expected
            report['verification'] = 'repository SHA-256'
        except urllib.error.HTTPError as error:
            if error.code != 404: raise
            matched = hashlib.sha256(read(url)).hexdigest() == report['sha256']
            report['verification'] = 'downloaded artifact SHA-256'
        report['matched'] = matched
    except Exception as error:
        report['matched'] = None
        report['error'] = str(error)
    return report


with ThreadPoolExecutor(max_workers=6) as pool:
    results = list(pool.map(verify, items))
(ROOT / 'docs/dependency-integrity.json').write_text(json.dumps(results, indent=2) + '\n', encoding='utf-8')
seen = set()
queries = []
for item in items:
    coordinate = item['group'] + ':' + item['name']
    if coordinate not in seen:
        queries.append({'package': {'ecosystem': 'Maven', 'name': coordinate}, 'version': item['version']})
        seen.add(coordinate)
request = urllib.request.Request('https://api.osv.dev/v1/querybatch', data=json.dumps({'queries': queries}).encode(), headers={'Content-Type': 'application/json'})
response = json.load(urllib.request.urlopen(request, timeout=45))
report = {'checked': datetime.now(timezone.utc).isoformat(), 'queries': queries, 'results': response['results'],
          'scope': 'Resolved Maven libraries and build plugins. Native C code and optional disabled GraalVM tooling are not covered.'}
(ROOT / 'docs/vulnerability-report.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print('Artifact checks:', sum(x['matched'] is True for x in results), '/', len(results))
for result in results:
    if result['matched'] is not True: print(result)
print('OSV advisories:', sum(len(r.get('vulns', [])) for r in response['results']))
if any(result['matched'] is False for result in results): raise ValueError('Dependency checksum mismatch')

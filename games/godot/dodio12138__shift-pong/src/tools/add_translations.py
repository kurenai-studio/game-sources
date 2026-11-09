"""Adds or replaces rows in scripts/i18n_data.gd.

usage: python3 tools/add_translations.py rows.tsv
rows.tsv: one row per line, Chinese<TAB>English<TAB>Japanese; a literal \\n in a
cell stands for a line break.
"""
import json, sys

rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1], encoding="utf-8") if l.strip() and not l.startswith("#")]
rows = [[c.replace("\\n", "\n") for c in r] for r in rows]
path = "scripts/i18n_data.gd"
s = open(path, encoding="utf-8").read()


def q(x):
    return json.dumps(x, ensure_ascii=False)


for col, name in ((1, "EN"), (2, "JA")):
    start = s.index("const %s := {" % name)
    end = s.index("\n}", start)
    lines = s[start:end].split("\n")
    for r in rows:
        key = "\t%s: " % q(r[0])
        lines = [l for l in lines if not l.startswith(key)]
        lines.append(key + q(r[col]) + ",")
    s = s[:start] + "\n".join(lines) + s[end:]
open(path, "w", encoding="utf-8").write(s)
print("added", len(rows))

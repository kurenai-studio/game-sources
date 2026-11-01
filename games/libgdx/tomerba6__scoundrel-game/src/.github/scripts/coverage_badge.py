"""Generate a coverage badge for the packages the build actually gates.

Deliberately scoped. A whole-report number would average in `screens` and the
root package, which are GL-bound, screenshot-verified and excluded from the
JaCoCo gate on purpose -- they sit far below the engine, and blending them in
would report a figure well under half the engine's. That would misrepresent the
project in both directions depending on how much UI code exists at the time, so
the badge measures exactly what `jacocoTestCoverageVerification` enforces, and
the label says "engine" to be clear it is not the whole repository. (No figures
here on purpose: they went stale; the README's Testing section measures them.)

Usage: coverage_badge.py <jacoco-xml> <out-svg>
"""
import re
import sys
import xml.etree.ElementTree as ET

# Must match the `includes` list in core/build.gradle -- CoverageGateTest
# fails when it does not, so a package that joins the gate cannot be left off
# the badge.
GATED = {"model", "rules", "runs", "achievements", "tutorial", "audio"}


def engine_line_coverage(xml_path):
    root = ET.parse(xml_path).getroot()
    missed = covered = 0
    for package in root.findall("package"):
        name = package.get("name", "").split("/")[-1]
        if name not in GATED:
            continue
        # The package-level counters are the direct children, not the ones
        # nested inside each <class>/<method>; findall on the package element
        # only returns direct children, which is what we want.
        for counter in package.findall("counter"):
            if counter.get("type") == "LINE":
                missed += int(counter.get("missed"))
                covered += int(counter.get("covered"))
    total = missed + covered
    if total == 0:
        raise SystemExit("no LINE counters found for the gated packages")
    return 100.0 * covered / total


def colour(pct):
    if pct >= 95:
        return "#4c1"
    if pct >= 90:
        return "#97ca00"
    if pct >= 75:
        return "#dfb317"
    return "#e05d44"


def badge(label, value, fill):
    # Flat shields-style badge. Widths are approximated from the character
    # count; at these short strings that is accurate enough not to clip.
    lw = 6 * len(label) + 20
    vw = 6 * len(value) + 20
    total = lw + vw
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{total}" height="20" \
role="img" aria-label="{label}: {value}">
<title>{label}: {value}</title>
<linearGradient id="s" x2="0" y2="100%">
<stop offset="0" stop-color="#bbb" stop-opacity=".1"/><stop offset="1" stop-opacity=".1"/>
</linearGradient>
<clipPath id="r"><rect width="{total}" height="20" rx="3" fill="#fff"/></clipPath>
<g clip-path="url(#r)">
<rect width="{lw}" height="20" fill="#555"/>
<rect x="{lw}" width="{vw}" height="20" fill="{fill}"/>
<rect width="{total}" height="20" fill="url(#s)"/>
</g>
<g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" \
font-size="11">
<text x="{lw / 2:.0f}" y="15" fill="#010101" fill-opacity=".3">{label}</text>
<text x="{lw / 2:.0f}" y="14">{label}</text>
<text x="{lw + vw / 2:.0f}" y="15" fill="#010101" fill-opacity=".3">{value}</text>
<text x="{lw + vw / 2:.0f}" y="14">{value}</text>
</g>
</svg>
'''


if __name__ == "__main__":
    xml_path, out_path = sys.argv[1], sys.argv[2]
    pct = engine_line_coverage(xml_path)
    value = f"{pct:.1f}%"
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(badge("engine coverage", value, colour(pct)))
    print(f"engine line coverage: {value}")

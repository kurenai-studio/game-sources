#!/usr/bin/env bash
# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
#
# Renders README.md, Mermaid diagrams included, to build/README.html and/or
# build/README.pdf.
#
# Usage: tools/render_readme.sh [html|pdf|all]      (default: all)
#
# Needs:
#   node + npx   runs mermaid-cli, which turns each diagram into a PNG
#   a browser    mermaid-cli draws with headless Chromium. Set
#                PUPPETEER_EXECUTABLE_PATH, or have chromium / google-chrome
#                on PATH. Failing that, the script downloads Chrome for
#                Testing's headless shell once (~110 MB, Linux x86-64 only,
#                into ~/.cache/starexplorer-render; needs curl and unzip).
#   pandoc 3+    Markdown -> HTML / PDF
#   PDF engine   weasyprint (preferred, uses the same CSS as the HTML),
#                otherwise typst or xelatex
#
# Arch Linux:  sudo pacman -S nodejs npm pandoc chromium python-weasyprint
set -euo pipefail
cd "$(dirname "$0")/.."

MERMAID_CLI="@mermaid-js/mermaid-cli@11.4.2"
# Matches the Chrome build that mermaid-cli 11.4.2's puppeteer expects.
CHROME_VERSION="131.0.6778.204"
CHROME_URL="https://storage.googleapis.com/chrome-for-testing-public/$CHROME_VERSION/linux64/chrome-headless-shell-linux64.zip"
CACHE="${RENDER_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/starexplorer-render}"
OUT=build
what="${1:-all}"

die() { echo "error: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null || die "$1 not found. $2"; }

case "$what" in html|pdf|all) ;; *) die "usage: $0 [html|pdf|all]" ;; esac
need npx "Install Node.js (Arch: sudo pacman -S nodejs npm)."
need pandoc "Install pandoc 3 or newer (Arch: sudo pacman -S pandoc)."

pdf_engine=""
if [ "$what" != html ]; then
	for e in weasyprint typst xelatex; do
		if command -v "$e" >/dev/null; then pdf_engine="$e"; break; fi
	done
	[ -n "$pdf_engine" ] || die "no PDF engine found. Install weasyprint (Arch: sudo pacman -S python-weasyprint), typst or xelatex."
fi

mkdir -p "$OUT"

# --- 1. Diagrams -> PNG --------------------------------------------------
if [ -z "${PUPPETEER_EXECUTABLE_PATH:-}" ]; then
	for b in chromium google-chrome-stable google-chrome chromium-browser; do
		if command -v "$b" >/dev/null; then
			PUPPETEER_EXECUTABLE_PATH="$(command -v "$b")"
			break
		fi
	done
fi
if [ -z "${PUPPETEER_EXECUTABLE_PATH:-}" ]; then
	# puppeteer's own installer can leave a half-extracted browser on newer
	# Node versions, so fetch and unpack Chrome for Testing directly.
	shell="$CACHE/chrome-headless-shell-linux64/chrome-headless-shell"
	if [ ! -x "$shell" ]; then
		[ "$(uname -sm)" = "Linux x86_64" ] || die "no browser found. Set PUPPETEER_EXECUTABLE_PATH to Chrome or Chromium."
		need curl "Install curl."
		need unzip "Install unzip (Arch: sudo pacman -S unzip)."
		echo "== no browser on PATH; downloading headless Chrome $CHROME_VERSION to $CACHE (one-time, ~110 MB)"
		mkdir -p "$CACHE"
		curl -fL --progress-bar -o "$CACHE/shell.zip" "$CHROME_URL"
		unzip -q -o "$CACHE/shell.zip" -d "$CACHE"
		rm -f "$CACHE/shell.zip"
	fi
	PUPPETEER_EXECUTABLE_PATH="$shell"
fi
echo "== browser: $PUPPETEER_EXECUTABLE_PATH"
puppeteer_cfg="$OUT/puppeteer.json"
printf '{"executablePath": "%s", "headless": "shell", "args": ["--no-sandbox"]}\n' "$PUPPETEER_EXECUTABLE_PATH" >"$puppeteer_cfg"

echo "== rendering Mermaid diagrams"
rm -f "$OUT"/README.md "$OUT"/README-*.png
# Writes build/README.md with each ```mermaid block swapped for an image link
# to build/README-N.png. PNG rather than SVG, because Mermaid's SVG labels use
# HTML that PDF engines can't draw.
npx -y "$MERMAID_CLI" -p "$puppeteer_cfg" -i README.md -o "$OUT/README.md" \
	-e png -s 2 -b white -q

# --- 2. Markdown -> HTML / PDF -------------------------------------------
css="$OUT/readme.css"
cat >"$css" <<'CSS'
@page { size: A4; margin: 18mm 16mm; }
body { font-family: "Noto Sans", "DejaVu Sans", sans-serif; font-size: 11pt;
       line-height: 1.5; color: #1f2328; max-width: 960px; margin: 2rem auto; padding: 0 1rem; }
h1, h2, h3 { line-height: 1.25; } h2 { border-bottom: 1px solid #d0d7de; padding-bottom: .3em; }
img { max-width: 100%; height: auto; }
code, pre { font-family: "DejaVu Sans Mono", monospace; font-size: 9.5pt; background: #f6f8fa; }
pre { padding: .8em; border-radius: 6px; white-space: pre-wrap; }
table { border-collapse: collapse; margin: 1em 0; }
th, td { border: 1px solid #d0d7de; padding: .3em .6em; vertical-align: top; }
th { background: #f6f8fa; }
hr { border: 0; border-top: 1px solid #d0d7de; }
@media print { body { max-width: none; margin: 0; padding: 0; }
               pre, table, img { break-inside: avoid; } td img { max-width: 84mm; } }
CSS

# Images resolve against the repo root (screenshots) and build/ (diagrams).
common=(-f gfm "$OUT/README.md" --standalone --metadata pagetitle=StarExplorer
	--resource-path=".:$OUT")

if [ "$what" != pdf ]; then
	echo "== writing $OUT/README.html"
	pandoc "${common[@]}" --embed-resources --css "$css" -o "$OUT/README.html"
fi

if [ "$what" != html ]; then
	echo "== writing $OUT/README.pdf (engine: $pdf_engine)"
	case "$pdf_engine" in
	weasyprint) pandoc "${common[@]}" --css "$css" --pdf-engine=weasyprint -o "$OUT/README.pdf" ;;
	typst) pandoc "${common[@]}" --pdf-engine=typst -V margin='(x: 16mm, y: 18mm)' -o "$OUT/README.pdf" ;;
	xelatex) pandoc "${common[@]}" --pdf-engine=xelatex -V geometry:margin=16mm \
		-V mainfont="DejaVu Sans" -V monofont="DejaVu Sans Mono" -o "$OUT/README.pdf" ;;
	esac
fi

echo "== done: $(ls "$OUT"/README.html "$OUT"/README.pdf 2>/dev/null | tr '\n' ' ')"

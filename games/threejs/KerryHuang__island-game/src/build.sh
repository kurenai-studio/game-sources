#!/bin/sh
# 把 parts/ 依檔名順序串成單一 index.html（發布 artifact 用，平台會包 skeleton）
# 另產生 preview.html：補上 doctype／charset，給本機瀏覽器預覽
# dist/index.html：同 preview.html，給 Cloudflare Workers 靜態網站部署
set -e
cd "$(dirname "$0")"
ISSUES="${ISSUES_FILE:-data/issues.json}"
node scripts/validate.mjs "$ISSUES" >/dev/null  # 驗證不過就不 build
{
  for f in parts/*; do
    # 議題文字裡的 </ 改成 <\/，避免 </script> 截斷頁面的 script
    case "$f" in parts/10-*) printf 'const ISSUES = '; sed 's#</#<\\/#g' "$ISSUES"; printf ';\n' ;; esac
    cat "$f"
  done
} > index.html
{ printf '<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">\n'; cat index.html; } > preview.html
mkdir -p dist && cp preview.html dist/index.html
wc -c index.html

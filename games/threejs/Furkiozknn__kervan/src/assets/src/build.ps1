# Rebuilds every Kervan model: headless Blender via asset-forge, then slim_glb.py (no normals/UVs) into ../models.
# Run inside the shared heavy lock (_sablonlar/heavy-lock.md). Set $env:KV_PREVIEW=1 for readable preview PNGs only.
param([string[]]$Names = @('camel', 'riders', 'han', 'bazaar', 'bursa', 'izmir', 'konya', 'aksaray', 'goreme', 'kayseri', 'urfa'))
$forge = 'D:\Claude Projeleri Master\_araclar\asset-forge\forge.py'
$models = Join-Path $PSScriptRoot '..\models'
$tmp = Join-Path $env:TEMP 'kervan-build'
New-Item -ItemType Directory -Force $models, $tmp | Out-Null
foreach ($n in $Names) {
  python $forge build (Join-Path $PSScriptRoot "$n.py") (Join-Path $tmp $n)
  if (-not $?) { throw "build failed: $n" }
  python (Join-Path $PSScriptRoot 'slim_glb.py') (Join-Path $tmp "$n.glb") (Join-Path $models "$n.glb")
}

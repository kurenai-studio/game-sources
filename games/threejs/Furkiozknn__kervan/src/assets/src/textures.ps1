# Builds the shipped textures from the downloaded CC0 sources (Poly Haven / ambientCG diffuse maps, 512 px).
# Sources: python forge.py ph-tex <id> <Src> --size 512 --maps diff for sandy_gravel_02, aerial_grass_rock, aerial_rocks_02;
# python forge.py acg-tex Paper006 <Src> --size 512
param([string]$Src = "$env:TEMP\kervan-tex", [string]$Out = "D:\Claude Projeleri Master\oyunlar\kervan\assets\textures")
New-Item -ItemType Directory -Force $Out | Out-Null
# grey high-pass detail (mean 128): removes the large blotches so the tiling does not show
function HP($in, $out, $c, $sigma = 24) {
  ffmpeg -y -loglevel error -i $in -vf "format=gray,split[a][b];[b]gblur=sigma=${sigma}[bl];[a][bl]blend=all_mode=grainextract,eq=contrast=$c" $out
}
HP "$Src\sandy_gravel_02_diff.jpg" "$Src\d_sand.png" 3.0
HP "$Src\aerial_grass_rock_diff.jpg" "$Src\d_grass.png" 2.4
HP "$Src\aerial_rocks_02_diff.jpg" "$Src\d_rock.png" 1.25
# pack: R = sand, G = steppe, B = rock (gbrp plane order is G, B, R); 4:4:4 JPEG keeps the channels apart
ffmpeg -y -loglevel error -i "$Src\d_grass.png" -i "$Src\d_rock.png" -i "$Src\d_sand.png" -filter_complex "[0][1][2]mergeplanes=0x001020:gbrp,format=yuvj444p" -q:v 4 "$Out\terrain_detail.jpg"
# parchment fibres for the UI panels: grey high-pass, blended with "overlay" in CSS (grey 128 = no change)
HP "$Src\paper006_diff.jpg" "$Src\d_paper.png" 9 8
# white where lighter than 128, black where darker, alpha = distance from 128: a neutral grain layer for normal blending
ffmpeg -y -loglevel error -i "$Src\d_paper.png" -vf "scale=256:256,format=gray,geq=lum='lum(X,Y)',format=rgba,geq=r='255*gt(r(X,Y),128)':g='255*gt(g(X,Y),128)':b='255*gt(b(X,Y),128)':a='min(255,abs(r(X,Y)-128)*0.6)'" -c:v libwebp -quality 80 "$Out\parchment.webp"
Get-ChildItem $Out | Select-Object Name, Length


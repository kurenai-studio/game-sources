#!/bin/sh

cd src/textures
sh asepritecompile.sh
cd ..
mkdir ../output
rm countdown.love
FILES=""

FILES="$FILES $(find -type f -name "*.png")"
FILES="$FILES $(find -type f -name "*.lua")"
FILES="$FILES $(find -type f -name "*.ogg")"
FILES="$FILES $(find -type f -name "*.wav")"
FILES="$FILES $(find -type f -name "*.otf")"
zip -9 -r countdown.love $FILES

npx love.js -c countdown.love ../output -m 106777216

# Replace style
cd ..
cp src/index.html output/index.html
cp src/love.css output/theme/love.css
rm "output/theme/bg.png"

echo "Built to ./output/"
echo "Running locally on localhost:8000"
cd output
python -m http.server 8000

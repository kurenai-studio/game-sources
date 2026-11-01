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
rm ../countdown.love -f
zip -9 -r ../countdown.love $FILES

echo "Run game using love2D:\$ love countdown.love"

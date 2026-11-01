sh build.sh

cd builds/lovejs

rm -rf Game-lovejs

unzip Game-lovejs.zip -d .

cd Game

open http://localhost:8000

python3 -m http.server 8000

cd ../..

#!/bin/bash
# Arma la app de Android: toma el APK oficial de LÖVE 11.5, le mete orbita84.love adentro
# (modo "embed"), le pone nombre, paquete e ícono propios y lo firma.
# Requiere: java, apktool, gh (para bajar la base la primera vez), python3 con PIL.
# Salida: publicar/android/orbita84.apk
# La llave de firma vive en android/firma/ (fuera de git) y se copia a ~/Respaldos/ORBITA-84/android/.
# Sin esa misma llave no se pueden publicar actualizaciones de la app: no hay que perderla.
set -euo pipefail
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"
PAQUETE="com.darker03.orbita84"
NOMBRE="Órbita 84"
A="$RAIZ/android"
mkdir -p "$A/base" "$A/firma" publicar/android

# base: el APK de LÖVE y el firmador (se bajan una vez, cada uno en su carpeta)
[ -f "$A/base/love-11.5-android.apk" ] || gh release download 11.5 -R love2d/love -p 'love-11.5-android.apk' -D "$A/base"
FIRMADOR="$A/base/uber-apk-signer-1.3.0.jar"
if [ ! -f "$FIRMADOR" ]; then
	gh release download v1.3.0 -R patrickfav/uber-apk-signer -p 'uber-apk-signer-1.3.0.jar' -p 'checksum-sha256.txt' -D "$A/base"
	(cd "$A/base" && sha256sum -c <(sed 's/ \*/  /' checksum-sha256.txt))
fi

# llave de firma (se crea una sola vez)
LLAVE="$A/firma/orbita84.keystore"
if [ ! -f "$LLAVE" ]; then
	head -c 24 /dev/urandom | base64 | tr -d '/+=' > "$A/firma/clave.txt"
	keytool -genkeypair -keystore "$LLAVE" -alias orbita84 -keyalg RSA -keysize 4096 -validity 36500 \
		-storepass "$(cat "$A/firma/clave.txt")" -dname "CN=D4RK3R, O=D4RK3R, C=CO" >/dev/null 2>&1
	mkdir -p ~/Respaldos/ORBITA-84/android
	cp "$LLAVE" "$A/firma/clave.txt" ~/Respaldos/ORBITA-84/android/
	echo "Llave nueva creada (copia en ~/Respaldos/ORBITA-84/android/)"
fi
CLAVE="$(cat "$A/firma/clave.txt")"

# el juego al día
bash herramientas/empaquetar.sh >/dev/null

OBRA="$A/obra"
rm -rf "$OBRA"
apktool d -f -q -o "$OBRA" "$A/base/love-11.5-android.apk"
mkdir -p "$OBRA/assets"
cp port/orbita84/orbita84.love "$OBRA/assets/game.love"

VERSION_CODIGO="$(git rev-list --count HEAD)"
python3 - "$OBRA" "$PAQUETE" "$NOMBRE" "$VERSION_CODIGO" "$RAIZ/estetica/img/icono_app.png" <<'EOF'
import re, sys
from PIL import Image
obra, paquete, nombre, codigo, icono = sys.argv[1:]

# abrir el juego de adentro en lugar del cargador de LÖVE
p = obra + "/res/values/bools.xml"
t = open(p).read()
t = t.replace('<bool name="embed">false</bool>', '<bool name="embed">true</bool>')
open(p, "w").write(t)

p = obra + "/AndroidManifest.xml"
t = open(p).read()
# solo los permisos que hacen falta: ninguno (sin internet, micrófono, bluetooth ni archivos)
for permiso in ["READ_EXTERNAL_STORAGE", "WRITE_EXTERNAL_STORAGE", "INTERNET", "VIBRATE", "BLUETOOTH", "RECORD_AUDIO"]:
    t = re.sub(r'\s*<uses-permission[^>]*android\.permission\.%s"/>' % permiso, "", t)
# sin el cargador de archivos .love ni las descargas
t = re.sub(r'\s*<intent-filter>\s*<action android:name="android.intent.action.VIEW"/>.*?</intent-filter>', "", t, flags=re.S)
t = re.sub(r'\s*<service android:name="org.love2d.android.DownloadService"/>', "", t)
t = re.sub(r'\s*<activity android:exported="true" android:name="org.love2d.android.DownloadActivity".*?</activity>', "", t, flags=re.S)
t = re.sub(r'\s*<activity android:enabled="@bool/selector_active".*?</activity>', "", t, flags=re.S)
t = t.replace("org.love2d.android.DYNAMIC_RECEIVER", paquete + ".DYNAMIC_RECEIVER")
t = t.replace("org.love2d.android.androidx-startup", paquete + ".androidx-startup")
t = t.replace('android:label="LÖVE for Android"', 'android:label="%s"' % nombre)
t = t.replace('android:usesCleartextTraffic="true"', 'android:usesCleartextTraffic="false"')
open(p, "w").write(t)

p = obra + "/apktool.yml"
t = open(p).read()
t = re.sub(r"versionCode: \d+", "versionCode: " + codigo, t)
t = re.sub(r"versionName: .*", "versionName: 1.0." + codigo, t)
t = t.replace("apkFileName: love-11.5-android.apk", "apkFileName: orbita84.apk")
t += "renameManifestPackage: %s\n" % paquete
open(p, "w").write(t)

im = Image.open(icono)
for carpeta, lado in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)]:
    im.resize((lado, lado), Image.LANCZOS).save("%s/res/drawable-%s/love.png" % (obra, carpeta))
EOF

apktool b -q -o "$A/sin_firma.apk" "$OBRA"
rm -rf "$A/firmado"
java -jar "$FIRMADOR" -a "$A/sin_firma.apk" -o "$A/firmado" --ks "$LLAVE" --ksAlias orbita84 \
	--ksPass "$CLAVE" --ksKeyPass "$CLAVE" >/dev/null
cp "$A"/firmado/*.apk publicar/android/orbita84.apk
java -jar "$FIRMADOR" -a publicar/android/orbita84.apk --onlyVerify | grep -E "VERIFY|signature" | head -3 || true
echo "Listo: publicar/android/orbita84.apk ($(du -h publicar/android/orbita84.apk | cut -f1), versión 1.0.$VERSION_CODIGO)"

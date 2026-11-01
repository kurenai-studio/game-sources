"""Export clean sources and a playable release without copying local caches."""
from pathlib import Path
import hashlib
import shutil
import zipfile
from datetime import datetime
from verify_publication import check

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "GitHub-ready"
PROJECT = OUT / "ElMagica"
check(ROOT)
# Preserve the previous generated export locally, then create a clean tree.
if PROJECT.exists():
    if PROJECT.is_symlink() or PROJECT.resolve().parent != OUT.resolve():
        raise ValueError("Unexpected export path")
    backup = ROOT / "build" / ("export-backup-" + datetime.now().strftime("%Y%m%d-%H%M%S"))
    backup.parent.mkdir(exist_ok=True)
    try:
        PROJECT.rename(backup)
    except PermissionError:
        # A running game can lock the old export on Windows.
        PROJECT = OUT / ("ElMagica-" + datetime.now().strftime("%Y%m%d-%H%M%S"))
PROJECT.mkdir(parents=True, exist_ok=True)

for name in ["assets", "art-source", "third-party-sources", "core/src", "lwjgl3/src", "lwjgl3/icons", "gradle", ".github", "docs"]:
    source = ROOT / name
    if source.exists():
        shutil.copytree(source, PROJECT / name, dirs_exist_ok=True, ignore=shutil.ignore_patterns("__pycache__"))
for name in ["build.gradle", "settings.gradle", "gradle.properties", "gradlew", "gradlew.bat", ".gitignore", ".gitattributes", ".editorconfig", "README.md", "LICENSE", "THIRD_PARTY_NOTICES.md", "CONTRIBUTING.md", "SECURITY.md"]:
    shutil.copy2(ROOT / name, PROJECT / name)
for module in ["core", "lwjgl3"]:
    for source in (ROOT / module).glob("*.gradle"):
        shutil.copy2(source, PROJECT / module / source.name)
(PROJECT / "tools").mkdir(exist_ok=True)
for name in ["generate_audio.py", "prepare_github.py", "split_assets.py", "collect_licenses.py", "audit_dependencies.py", "verify_publication.py"]:
    shutil.copy2(ROOT / "tools" / name, PROJECT / "tools" / name)

play = PROJECT / "play"
play.mkdir(exist_ok=True)
jar = ROOT / "lwjgl3/build/libs/ElMagica-1.0.0.jar"
with zipfile.ZipFile(jar) as archive:
    names = set(archive.namelist())
    for asset in (ROOT / "assets").rglob("*"):
        if asset.is_file() and asset.relative_to(ROOT / "assets").as_posix() not in names:
            raise ValueError("Missing packaged asset: " + str(asset))
shutil.copy2(jar, play / "ElMagica-Beta1.0.jar")
for name in ["LICENSE", "THIRD_PARTY_NOTICES.md"]:
    shutil.copy2(ROOT / name, play / name)
shutil.copytree(ROOT / "docs/third-party", play / "third-party", dirs_exist_ok=True)
shutil.copytree(ROOT / "third-party-sources", play / "third-party-sources", dirs_exist_ok=True)
shutil.copy2(ROOT / "docs/LIBRARY_REPLACEMENT.md", play / "LIBRARY_REPLACEMENT.md")
(play / "Run-ElMagica.bat").write_text('@echo off\ncd /d "%~dp0"\njava -jar "ElMagica-Beta1.0.jar"\nif errorlevel 1 pause\n', encoding="ascii")
(play / "README.txt").write_text("""ElMagica — Build Beta1.0
Created by: SA_Ton_
Thanks to: OpenAI Codex (GPT-6.1 Sol)

Нужна Java 17 или новее, рекомендую Java 21. В архив она не входит.
Windows: открой Run-ElMagica.bat в этой папке.
Через терминал из этой папки: java -jar ElMagica-Beta1.0.jar

WASD — ходить, мышь — целиться, зажатая ЛКМ — стрелять.
E — купить товар рядом или поговорить. ESC — пауза.
В настройках есть язык, размер ХУДа и отдельная громкость музыки и звуков.
Забег не сохраняется. Игра работает без интернета.

Код проекта под MIT. У библиотек свои лицензии: LICENSE,
THIRD_PARTY_NOTICES.md, third-party/ и LIBRARY_REPLACEMENT.md.
""", encoding="utf-8-sig")


def make_zip(target, folder, skip_play=False):
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as archive:
        for source in sorted(folder.rglob("*")):
            relative = source.relative_to(folder)
            if not source.is_file() or any(part in {"build", ".gradle", ".idea", ".git", "__pycache__"} for part in relative.parts):
                continue
            if skip_play and relative.parts[0] == "play":
                continue
            archive.write(source, (Path(folder.name) / relative).as_posix())


check(PROJECT)
make_zip(OUT / "ElMagica-Beta1.0-source.zip", PROJECT, True)
make_zip(OUT / "ElMagica-Beta1.0-play.zip", play)
checksums = []
for source in sorted(OUT.glob("*.zip")):
    checksums.append(hashlib.sha256(source.read_bytes()).hexdigest() + "  " + source.name)
(OUT / "SHA256SUMS.txt").write_text("\n".join(checksums) + "\n", encoding="ascii")
print("Prepared sources:", PROJECT)
print("Prepared playable JAR:", play / "ElMagica-Beta1.0.jar")
print("Source and playable ZIPs:", OUT)

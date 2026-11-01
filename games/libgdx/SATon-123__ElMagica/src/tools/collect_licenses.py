"""Fetch upstream notices and redistributable sources, recording URLs and hashes.

Run Gradle's lwjgl3:dependencyInventory first. Network is only used explicitly
when this maintenance script runs, never when launching the game.
"""
from pathlib import Path
import hashlib
import json
import urllib.request
import zipfile
import io

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "docs/third-party"
SOURCES = ROOT / "third-party-sources"
records = []


def fetch(url, relative, source=False):
    target = (SOURCES if source else DEST) / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    data = urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "ElMagica-license-audit"}), timeout=60).read()
    if not data:
        raise ValueError("Unexpected empty upstream document: " + url)
    target.write_bytes(data)
    records.append({"file": target.relative_to(ROOT).as_posix(), "url": url,
                    "sha256": hashlib.sha256(data).hexdigest()})
    print("Saved", target.relative_to(ROOT))
    return data


raw = "https://raw.githubusercontent.com/"
fetch(raw + "libgdx/libgdx/1.14.2/LICENSE", "libgdx-1.14.2/LICENSE.txt")
fetch(raw + "libgdx/libgdx/1.14.2/AUTHORS", "libgdx-1.14.2/AUTHORS.txt")
fetch(raw + "libgdx/gdx-jnigen/2.5.2/LICENSE", "gdx-jnigen-loader-2.5.2/LICENSE.txt")
fetch(raw + "LWJGL/lwjgl3/3.4.3/LICENSE.md", "lwjgl-3.4.3/LICENSE.txt")
for module, name in [("core", "libffi"), ("core", "liburing"), ("glfw", "glfw"),
                     ("jemalloc", "jemalloc"), ("openal", "openal_soft"), ("opengl", "khronos")]:
    fetch(raw + f"LWJGL/lwjgl3/3.4.3/modules/lwjgl/{module}/{name}_license.txt",
          f"lwjgl-3.4.3/{name}-LICENSE.txt")
fetch(raw + "gradle/gradle/v9.8.0/LICENSE", "gradle-9.8.0/LICENSE.txt")
fetch(raw + "gradle/gradle/v9.8.0/packaging/distributions-full/src/toplevel/NOTICE", "gradle-9.8.0/NOTICE.txt")
fetch(raw + "fourlastor-alexandria/construo/v2.2.2/LICENSE", "construo-2.2.2/LICENSE.txt")
fetch(raw + "gradle/foojay-toolchains/foojay-toolchains-plugin-1.0.0/LICENSE", "foojay-resolver-1.0.0/LICENSE.txt")
fetch("https://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt", "lgpl-2.1/LICENSE.txt")
fetch("https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt", "gpl-2.0/LICENSE.txt")
for group, name, version in [("com/badlogicgames/jlayer", "jlayer", "1.0.1-gdx"), ("org/jcraft", "jorbis", "0.0.17")]:
    fetch(f"https://repo.maven.apache.org/maven2/{group}/{name}/{version}/{name}-{version}-sources.jar",
          f"{name}-{version}-sources.jar", True)
    fetch(f"https://repo.maven.apache.org/maven2/{group}/{name}/{version}/{name}-{version}.pom",
          f"{name}-{version}.pom", True)
fetch("https://codeload.github.com/kcat/openal-soft/zip/refs/tags/1.25.2", "openal-soft-1.25.2.zip", True)
for project, name in [("LWJGL-CI/OpenAL-Soft", "openal-soft-lwjgl-build"), ("libgdx/jlayer-gdx", "jlayer-gdx-build")]:
    commit = json.load(urllib.request.urlopen(f"https://api.github.com/repos/{project}/commits/master"))["sha"]
    fetch(f"https://codeload.github.com/{project}/zip/{commit}", name + ".zip", True)

# Preserve native dependency headers verbatim, including embedded copyright notices.
for project, tag, prefixes in [
    ("LWJGL/lwjgl3", "3.4.3", ["modules/lwjgl/stb/src/main/c/", "modules/lwjgl/core/src/main/c/dependencies/miniz/"]),
    ("libgdx/libgdx", "1.14.2", ["gdx/jni/gdx2d/", "gdx/jni/etc1/"])]:
    tree = json.load(urllib.request.urlopen(f"https://api.github.com/repos/{project}/git/trees/{tag}?recursive=1"))
    for entry in tree["tree"]:
        path = entry["path"]
        if entry["type"] == "blob" and any(path.startswith(p) for p in prefixes) and path.endswith((".h", ".c", ".cpp")):
            fetch(raw + f"{project}/{tag}/{path}", project.split("/")[1] + "-native-notices/" + Path(path).name)

inventory = json.loads((ROOT / "build/dependency-inventory.json").read_text())
for item in inventory:
    file = Path(item.pop("file"))
    item["file"] = file.name
    item["sha256"] = hashlib.sha256(file.read_bytes()).hexdigest()
(ROOT / "docs/dependencies.json").write_text(json.dumps(inventory, indent=2) + "\n", encoding="utf-8")
(DEST / "manifest.json").write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")
print("Recorded", len(records), "upstream documents and", len(inventory), "resolved artifacts.")

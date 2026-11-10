"""Check that distributable ZIPs are self-contained and contain no QA exports."""
from pathlib import Path
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PACKAGES = ROOT/"exports/packages"
expected = {
    "Windows": {"KittyhmSkate.exe","KittyhmSkate.pck","LICENSE","CREDITS.md","FONT-LICENSE.txt","PLAYME.txt"},
    "Web": {"index.html","index.js","index.wasm","index.pck","LICENSE","CREDITS.md","FONT-LICENSE.txt","PLAYME.txt"},
}
report = []
for kind, required in expected.items():
    archive = PACKAGES/f"KittyhmSkate-{kind}.zip"
    with zipfile.ZipFile(archive) as bundle:
        files = set(bundle.namelist())
        assert required <= files,(kind,"Missing files",required-files)
        if kind == "Windows":
            assert files == required,(kind,"Unexpected build leftovers",files-required)
        assert not any(path.lower().endswith((".tmp",".log",".bak")) for path in files),(kind,"Temporary file in package")
        assert not any("qa" in path.lower() or "test" in path.lower() or path.startswith(".git") for path in files),(kind,"Development files in public ZIP")
        if kind == "Web":
            with bundle.open("index.wasm") as stream:
                assert stream.read(4) == b"\0asm"
            html = bundle.read("index.html").decode()
            assert "index.pck" in html and "index.wasm" in html
        else:
            with bundle.open("KittyhmSkate.exe") as stream:
                assert stream.read(2) == b"MZ"
        with bundle.open("index.pck" if kind == "Web" else "KittyhmSkate.pck") as stream:
            assert stream.read(4) == b"GDPC"
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    report.append({"platform":kind,"file":archive.name,"bytes":archive.stat().st_size,"sha256":digest})
print(json.dumps(report,indent=2))
(PACKAGES/"package-checksums.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
print("PASS: Windows/Web ZIP contents, entry points, binary headers and licenses")

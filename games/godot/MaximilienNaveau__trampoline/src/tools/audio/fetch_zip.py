"""Download only some files out of a zip archive on the web.

The sample libraries come as big zip archives of which the music needs a
part (one file of a 1 GB room database, the plucked half of a bass). A zip
keeps its table of contents at its end and each file at a known offset, so
with HTTP range requests (asking the server for a slice of the file) this
reads the table of contents, then only the wanted files: a few MB instead
of the whole archive.

Used by flake.nix (`fetchZipMembers`), or by hand:
    python3 fetch_zip.py URL OUT_FOLDER PATTERN...   # fnmatch patterns
    python3 fetch_zip.py URL --list                  # what's inside
"""

import fnmatch
import io
import os
import shutil
import sys
import urllib.request
import zipfile


class _RemoteFile(io.RawIOBase):
    """A file on a web server, read in slices: seekable, like an open file,
    as zipfile needs."""

    def __init__(self, url):
        self.url = url
        self.position = 0
        # A HEAD request gives the size (following redirects).
        with urllib.request.urlopen(urllib.request.Request(url, method="HEAD")) as response:
            self.size = int(response.headers["Content-Length"])
            self.url = response.url

    def seekable(self):
        return True

    def readable(self):
        return True

    def tell(self):
        return self.position

    def seek(self, offset, whence=io.SEEK_SET):
        base = {io.SEEK_SET: 0, io.SEEK_CUR: self.position, io.SEEK_END: self.size}[whence]
        self.position = base + offset
        return self.position

    def readinto(self, buffer):
        end = min(self.position + len(buffer), self.size)
        if end <= self.position:
            return 0
        request = urllib.request.Request(self.url, headers={"Range": f"bytes={self.position}-{end - 1}"})
        with urllib.request.urlopen(request) as response:
            assert response.status == 206, f"{self.url}: the server ignores range requests"
            data = response.read()
        buffer[: len(data)] = data
        self.position += len(data)
        return len(data)


def main(url, out, *patterns):
    # Read through a 4 MB buffer: a few big requests rather than many small ones.
    archive = zipfile.ZipFile(io.BufferedReader(_RemoteFile(url), buffer_size=4 << 20))
    if out == "--list":
        for info in archive.infolist():
            print(f"{info.file_size:>12}  {info.filename}")
        return
    wanted = [i for i in archive.infolist()
              if not i.is_dir() and any(fnmatch.fnmatch(i.filename, p) for p in patterns)]
    assert wanted, f"nothing in {url} matches {patterns}"
    for info in wanted:
        path = os.path.join(out, info.filename)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with archive.open(info) as source, open(path, "wb") as target:
            shutil.copyfileobj(source, target)
    print(f"{len(wanted)} files, {sum(i.file_size for i in wanted) / 1e6:.1f} MB")


if __name__ == "__main__":
    main(*sys.argv[1:])

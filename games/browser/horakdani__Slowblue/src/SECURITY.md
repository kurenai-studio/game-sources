# Security

Slowblue has no server, no accounts, no network code and no runtime dependencies: nothing
is uploaded, nothing is fetched, and everything it stores lives in the player's own
`localStorage` under the `tide.*` prefix. The surface that is left is small — the static
build served from GitHub Pages, its service worker, and the development toolchain.

If you find something in that surface, please report it privately rather than in a public
issue: use **Report a vulnerability** under the repository's Security tab, which opens a
private advisory with the maintainer. Expect an answer within a week. A report that says
what you did, what happened and which browser it was in is plenty.

The `?admin`, `?debug` and `?act` URL parameters, and the `window.__slowblue` handle, are
deliberate development doors that exist in the shipped build and touch nothing outside the
player's own device; they are documented in
[docs/DEVELOPING.md](docs/DEVELOPING.md) and are not vulnerabilities.

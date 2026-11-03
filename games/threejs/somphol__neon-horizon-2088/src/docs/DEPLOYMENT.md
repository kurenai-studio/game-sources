# Deployment

## Hosting model

The site is a **GitHub Pages legacy branch deployment**:

| Setting | Value |
| --- | --- |
| Repository | `somphol/neon-horizon-2088` |
| Branch | `main` |
| Folder | `/ (root)` |
| Build type | Deploy from a branch (no Actions build) |
| Custom domain | None |
| HTTPS | GitHub-provided certificate |
| Live URL | <https://somphol.github.io/neon-horizon-2088/> |

There is no CI workflow in `.github/workflows/`. `scripts/check.mjs` is a local/manual
gate; it is not wired to Actions. Pages publishes the repository root exactly as
committed — there is no build artifact, minification or bundling step.

## What is published

Everything tracked at the repository root, including:

- `index.html`, `style.css`, `script.js`, `favicon.svg`
- `docs/` (guides and `social-card.png`)
- `skills/neon-horizon-2088/` (skill documentation and the source template)
- `screenshots`, `README.md`, policy files, `state.json`, `STATE.md`
- `.nojekyll`

The runtime still loads Three.js r128 and Cannon.js 0.6.2 from cdnjs and Orbitron /
Rajdhani from Google Fonts. Those are third-party requests, not Pages assets.

`.nojekyll` is intentional. It disables Jekyll processing and keeps every file and
directory name served literally. Do not delete it.

## Push and release

```bash
cd ~/Projects/neon-horizon-2088

# gate
node --check script.js
node scripts/check.mjs
node ~/.config/opencode/skills/skill-publish/scripts/check-skill.mjs skills/neon-horizon-2088

# deploy (one commit, no force-push)
git add -A
git commit -m "docs: ..."
git push origin main
```

Pages rebuilds automatically after the push. A typical rebuild takes under a minute, but
the CDN can serve the previous `script.js` for a short window. There is no cache-busting
query string in the HTML, so verify by fetching the file and checking for a known symbol
before declaring the deploy complete.

If the machine's credential helper is the Keychain, a push may prompt. Use the existing
private credential store configured for this machine; do not print, copy or commit its
contents, and never put a token in a command that will be recorded.

## Verification URLs

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://somphol.github.io/neon-horizon-2088/
curl -s -o /dev/null -w '%{http_code}\n' https://somphol.github.io/neon-horizon-2088/script.js
curl -s -o /dev/null -w '%{http_code}\n' https://somphol.github.io/neon-horizon-2088/style.css
curl -s -o /dev/null -w '%{http_code}\n' https://somphol.github.io/neon-horizon-2088/docs/social-card.png
curl -s -o /dev/null -w '%{http_code}\n' https://somphol.github.io/neon-horizon-2088/favicon.svg
```

Expected: `200` for each. Pages returns `404` while the first build is running or when the
branch/folder setting is wrong.

Functional check:

```text
https://somphol.github.io/neon-horizon-2088/?selftest=1
```

Open the console. Expected:

```text
[NEON HORIZON self-test] 16/16
NEON HORIZON 2088 online · Three.js r128 · Cannon.js 0.6.2
```

and `window.__SELFTEST__.pass === 16`.

Social preview: the OG/Twitter tags point at
`https://somphol.github.io/neon-horizon-2088/docs/social-card.png` (1200 × 630). After a
rename or domain change, update those tags in `index.html` and the links in `README.md`,
`AGENTS.md` and `state.json`.

## Caching

- GitHub Pages serves through a CDN with default cache headers. There is no way to set
  custom `Cache-Control` headers on Pages without a custom domain/proxy.
- There is no service worker and no offline cache. A hard refresh (Shift-Reload or
  empty-cache reload) is the reliable way to pick up a new `script.js`.
- The CDN libraries and Google Fonts are cached by the browser and the third-party CDNs,
  independently of Pages.
- The app never fetches `state.json`, so stale build metadata cannot affect gameplay.

## Rollback

Do not force-push. Revert and push a new commit:

```bash
git log --oneline -5
git revert <bad-commit-sha>
git push origin main
```

For a multi-commit regression, revert the range or create a new commit that restores the
last known-good versions of `index.html`, `style.css` and `script.js`. Pages will rebuild
the reverted tree. After rollback, re-run `scripts/check.mjs` and
`?selftest=1`.

If only the score archive is corrupted, that is client-side: clear
`neon_horizon_scores_v1` in the browser's local storage or import a known-good
`neon_horizon_scores.json`.

## Troubleshooting

| Symptom | Likely cause | Action |
| --- | --- | --- |
| Root 404 | Pages disabled, wrong branch/folder | Settings → Pages → `main` / `/ (root)` |
| Boot screen says `SYSTEM FAULT` | Three.js or Cannon.js failed to load | Check network/ad-blocker; the CDN URLs are required |
| Table renders but fonts are wrong | Google Fonts blocked | System fallbacks are used; layout still works |
| Old behaviour after deploy | CDN/browser cache | Hard refresh; verify `script.js` content over HTTP |
| No sound | `AudioContext` not unlocked | Click or press a key once; check the mute toggle |
| Scores missing after moving origins | `localStorage` is per-origin | Export and import the JSON archive |
| Import rejected | File > 2 MB, invalid JSON, or no score array | Use an exported `neon_horizon_scores.json` |
| Mobile right panel absent | Below 900 px it is a drawer | Use the **SCORES** button |
| Ball escapes the cabinet | Rare high-energy seam case | Press `R` or **RECOVER STUCK BALL**; recovery does not cost a ball |

## Pages enablement (if it is ever disabled)

The repository has no `.github/workflows/` deploy job. Enable Pages manually:

1. Repository **Settings → Pages**.
2. **Source:** Deploy from a branch.
3. **Branch:** `main`, **Folder:** `/ (root)`.
4. Save, then wait for the build and re-check the URLs above.

No environment variables, secrets or build commands are required.

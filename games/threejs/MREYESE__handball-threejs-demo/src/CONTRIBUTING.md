# Artifact updates

Develop and validate the game in its private source repository. Produce a minified
Vite build with sourcemap:false, export only HTML/CSS/JS plus a hash manifest to
site/, and review the exact public diff. No game source or diagnostics belong here.
Use the existing Pages workflow, verify hosted gameplay and retain the prior
artifact for rollback. Browser bundles are public executable code, not a means of
keeping all implementation details secret.

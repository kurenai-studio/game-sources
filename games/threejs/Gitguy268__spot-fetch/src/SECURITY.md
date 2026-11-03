# Security policy

## Reporting a vulnerability

Please report security problems privately, not in a public issue.

Use GitHub's private reporting form: <https://github.com/Gitguy268/spot-fetch/security/advisories/new>

Include what you found, how to reproduce it, and the browser and version you used. You should get a reply within a week. Please give the fix time to ship before you publish details.

## Scope

It is a static page. It has no server and no accounts, and it keeps its data in the browser's own storage. The game saves Spot's state and your best score in `localStorage` and makes no network requests of its own. The most useful reports are about anything that makes the page send data off the device, and about the GitHub Actions workflow in this repository.

## Supported versions

Only the latest version on the `main` branch is supported.

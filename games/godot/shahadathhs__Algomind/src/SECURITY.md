# Security Policy

## Supported versions

Only the latest code on `main` is supported. Releases are cut from `main`; older releases do not receive security patches.

## Reporting a vulnerability

Do **not** open a public issue. Use GitHub's private vulnerability reporting: open the repository's **Security** tab and choose **Report a vulnerability**. Include:

- what the vulnerability is and where,
- how to reproduce it,
- what an attacker could do with it.

You will get a reply within a week. Once a fix is released, your report will be credited in the release notes if you want.

## Scope

- The API (`apps/api`): authentication, level publishing, the public catalog, and later account sync.
- The web app (`apps/web`): the admin dashboard and the public site.
- The game client (`apps/game`): it talks only to the configured API URL and stores progress and session data in app-local storage.

## Known non-issues

- The game is offline-first: signed-out play uploads no progress by design.
- A level that was downloaded before it was unpublished stays on the device; unpublishing controls future fetches, not remote deletion.

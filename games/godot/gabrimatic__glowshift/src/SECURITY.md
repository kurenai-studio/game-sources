# Security Policy

## Privacy by Design

- **No network access.** The game makes no network requests. The browser build loads its files from GitHub Pages and then runs entirely in the page.
- **No accounts, telemetry, or analytics.**
- **Local data only.** Glowshift stores one small settings file: sound, music, and effects preferences plus your best score.

## Stored Data

| Platform | Location |
|----------|----------|
| macOS | `~/Library/Application Support/Godot/app_userdata/Glowshift/settings.cfg` |
| Windows | `%APPDATA%\Godot\app_userdata\Glowshift\settings.cfg` |
| Linux | `~/.local/share/godot/app_userdata/Glowshift/settings.cfg` |
| Browser | The site's IndexedDB storage for `gabrimatic.github.io` |

Delete the file (or clear the site data) to reset everything.

## Trust Boundaries

| Boundary | Trust level | Notes |
|----------|-------------|-------|
| Game code and shaders | Trusted | Built from this repository by the release workflow |
| Godot engine and export templates | Third-party, open source | Official Godot 4.7.2 release binaries from the Godot GitHub releases |
| `settings.cfg` | Local input | Read as plain config values; nothing in it is executed |
| Release downloads | Unsigned or ad-hoc signed | Not notarized on macOS and not code-signed on Windows; checksums are on the release page |

## Supported Versions

Only the latest release receives fixes.

## Vulnerability Reporting

1. **Do not open a public issue.**
2. Use [GitHub's private vulnerability reporting](https://github.com/gabrimatic/glowshift/security/advisories/new) to submit.
3. Include steps to reproduce, the affected version, and your platform.

# Type Clash — Windows desktop build

3D typing combat game packaged as a desktop app with Electron. Works offline.

## Run it (developer)
1. Install Node.js LTS from nodejs.org
2. In this folder: `npm install` (also copies Three.js locally)
3. `npm start` to play, F11 for fullscreen

## Build a Windows installer
`npm run dist` → the installer (`Type Clash Setup x.x.x.exe`) and a portable `.exe` appear in `dist/`.
Share these directly (e.g. GitHub Releases). Unsigned installers can show a Windows SmartScreen warning ("More info → Run anyway").

## Microsoft Store
1. Register at storedeveloper.microsoft.com (individual accounts are free; Microsoft account + ID + selfie).
2. Reserve the app name in Partner Center; it gives you the package identity and publisher values.
3. Add an `appx` target with those values in package.json `build.win.target`, run `npm run dist`, and upload the `.appx`.
4. You also need a privacy policy URL, screenshots and an age rating. The Store signs the package, so no SmartScreen warning.

## Known limitations
Fighters are procedural shapes (no rigged models); no analytics screen yet; not tested on all PCs.

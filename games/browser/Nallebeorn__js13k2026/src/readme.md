# Unifrost

A tiny browser 3D platformer made for [js13kGames 2016](https://js13kgames.com/2026/).
Play it on the js13kGames [website](https://js13kgames.com/games/unifrost)!

You can read more about the development of the game in my [blog post](https://nallebeorn.se/blog/js13k2026-post-mortem/).

## Attribution
This games makes use of Frank Force's fantastic
[ZzFX](https://github.com/KilledByAPixel/ZzFX) sound engine to power the game's
very hastily added sound effects. The license and copyright notice for this
library are preserved in zzfx.js.

### Playtesters
Special thanks to Albin, Amanda, Hirad, Mirjam, and Sebastian for trying out
the various early drafts of my game and giving feedback.

## AI disclosure
No AI was involved with any of the game's design, art, audio or dialogue.
I regularly used a chatbot to help answer questions about APIs, algorithms and
language details. One function (`createPill`) was predominantly LLM-generated.
I used no agentic AI.


## Building

Yes, I'm a web developer, of course my 13KB game has a 100MB node_modules!

### Installing development dependencies

I use pnpm to manage both packages and the Node runtime. If you have a recent
version of pnpm, simply run `pnpm install` to install everything.

If you prefer it, regular `npm install` should work fine too, but you'll get an
error if you don't have the exact version of node pinned in package.json.
Install it yourself, or delete `devEngines` from package.json if you can't be
bothered :)

### Build distribution
* `pnpm run build-once` creates dist.zip. That's the game!
* The build script expects `advzip` to exist on the path. If you're on Linux,
  chances are you can install it with your system package manager, probably as
  `advancecomp", and it's also in Homebrew on macOS for example. On Windows, you
  can download it from their [website](https://www.advancemame.it/download).

### Development with watch mode

You need to run at least `pnpm run dev` and `pnpm run bindata` to build
everything. The game will rebuild automatically on changes, and run a Vite
development server.

You can also run `pnpm run build` to build the final distribution in watch mode.
It'll even print the current zip size on every change!

See package.json for other scripts
(tests (which I think don't pass anymore) etc.).

Note that some of the gamedata source files are dependent on generated source files for full type checking.
That means some files may have type errors until you've run `bindata` for the first time.

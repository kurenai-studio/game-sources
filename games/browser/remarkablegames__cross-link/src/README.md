<p align="center">
  <img src="public/favicon.svg" width="200" alt="Cross-Link">
</p>

# Cross-Link

[![release](https://img.shields.io/github/v/release/remarkablegames/cross-link)](https://github.com/remarkablegames/cross-link/releases)
[![build](https://github.com/remarkablegames/cross-link/actions/workflows/build.yml/badge.svg)](https://github.com/remarkablegames/cross-link/actions/workflows/build.yml)

🔗 Connect the dots. Cross the lines.

<kbd>Cross-Link</kbd> is a puzzle game about connections — drawing lines between matching stars to form constellations, then crossing those lines to make them vanish. Each level is a star map waiting to be untangled: pair up the dots, weave your lines across each other, and watch the night sky clear one crossing at a time.

Play the game on:

- [itch.io](https://remarkablegames.itch.io/cross-link)
- [Wavedash](https://wavedash.com/games/cross-link)
- [remarkablegames](https://remarkablegames.org/cross-link/)

Read the [blog post](https://remarkablegames.org/posts/cross-link/).

## How to Play

1. **Connect the dots** – Tap a colored star, then tap another star of the same color to draw a line between them.
2. **Cross to clear** – When two or more lines cross, all connected pairs disappear. The goal is to clear all stars from the board.
3. **Plan your moves** – The order in which you connect pairs matters. Think ahead to create crossings that clear multiple pairs at once.
4. **Deselect** – Tap a selected star again to cancel, or tap anywhere else on the screen.

## Credits

- [Sci-Fi Music](https://alkakrab.itch.io/free-sci-fi-music-2) by alkakrab
- [Pixel Combat](https://heltonyan.itch.io/pixelcombat) by Helton Yan & Beto Bezerra
- [Sound Effects](https://shapeforms.itch.io/shapeforms-audio-free-sfx) by Shapeforms

## Prerequisites

[nvm](https://github.com/nvm-sh/nvm#installing-and-updating):

```sh
brew install nvm
```

## Install

Clone the repository:

```sh
git clone https://github.com/remarkablegames/cross-link.git
cd cross-link
```

Install the dependencies:

```sh
npm install
```

## Environment Variables

Update the environment variables:

```sh
cp .env .env.local
```

Update the **Secrets** in the repository **Settings**.

## Available Scripts

In the project directory, you can run:

### `npm start`

Runs the game in the development mode.

Open [http://localhost:5173](http://localhost:5173) to view it in the browser.

The page will reload if you make edits.

You will also see any errors in the console.

### `npm run build`

Builds the game for production to the `dist` folder.

It correctly bundles in production mode and optimizes the build for the best performance.

The build is minified and the filenames include the hashes.

Your game is ready to be deployed!

### `npm run bundle`

Builds the game and compresses the contents into a ZIP archive in the `dist` folder.

Your game can be uploaded to your server, [itch.io](https://itch.io/), [newgrounds](https://www.newgrounds.com/), etc.

Builds the game for [Wavedash](https://wavedash.com/dev-portal):

```sh
WAVEDASH=true npm run bundle
```

## Testing

Start a specific level by appending `?level=<number>` to the URL (e.g., `?level=2`):

```sh
open http://localhost:5173/?level=5
```

## Cover

To view the static cover art for screenshots, append `?cover` to the URL:

```sh
open http://localhost:5173/?cover
```

This displays a 512×512 centered composition with the game title and 3 colored dots arranged in a triangle constellation pattern — ideal for taking cover art screenshots.

## License

[MIT](LICENSE)

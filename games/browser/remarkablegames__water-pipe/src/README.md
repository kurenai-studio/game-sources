<p align="center">
  <img src="public/cover_wide.jpeg" alt="Water Pipe" height="300">
</p>

# Water Pipe

[![release](https://img.shields.io/github/v/release/remarkablegames/water-pipe)](https://github.com/remarkablegames/water-pipe/releases)
[![build](https://github.com/remarkablegames/water-pipe/actions/workflows/build.yml/badge.svg)](https://github.com/remarkablegames/water-pipe/actions/workflows/build.yml)

🚰 Water Pipe is a casual pipe-rotation puzzle game. Click or tap the pipes to rotate them and connect every piece so the water can flow.

Play in browser:

- [itch.io](https://remarkablegames.itch.io/water-pipe)
- [Wavedash](https://wavedash.com/games/water-pipe)
- [Newgrounds](https://www.newgrounds.com/portal/view/930938)
- [remarkablegames](https://remarkablegames.org/water-pipe/)

Read the [blog post](https://remarkablegames.org/posts/water-pipe/).

## Features

- **11 handcrafted levels** - each with a unique pipe layout and scale.
- **One-click rotation** - tap or click a pipe to rotate it into place.
- **Randomized starting orientations** - every level is shuffled for a fresh challenge.
- **Automatic solution check** - when the path is complete, the water flows and the next level loads.
- **Ambient audio** - looping ocean waves with splash and click sound effects.
- **Random background colors** - a new brick wall color for every level.
- **Responsive scaling** - the puzzle board scales for desktop and mobile screens.

## Credits

### Art

- [Kenney - Puzzle Pack 2](https://kenney.nl/assets/puzzle-pack-2)
- Photo by [Bernard Hermant](https://unsplash.com/@bernardhermant) on [Unsplash](https://unsplash.com/photos/brown-concrete-brick-t4DuoDHjxrQ)

### Sounds

- [Kenney - UI Audio](https://kenney.nl/assets/ui-audio)
- [Pixabay - SPLASH](https://pixabay.com/sound-effects/splash-by-blaukreuz-6261/)
- [Pixabay - Gentle ocean waves birdsong and gull](https://pixabay.com/sound-effects/gentle-ocean-waves-birdsong-and-gull-7109/)

## Prerequisites

- [nvm](https://github.com/nvm-sh/nvm#readme)

## Install

Clone the repository:

```sh
git clone https://github.com/remarkablegames/water-pipe.git
cd water-pipe
```

Use the Node.js version:

```sh
nvm use
```

Install the dependencies:

```sh
npm install
```

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

Builds the game and packages it into a Zip file in the `dist` folder.

Your game can be uploaded to your server, [itch.io](https://itch.io/), [Newgrounds](https://www.newgrounds.com/), etc.

## License

[MIT](LICENSE)

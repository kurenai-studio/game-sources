<p align="center">
  <img src="public/logo.svg" width="150" alt="Memory Matrix">
</p>

# Memory Matrix

[![build](https://github.com/remarkablegames/memory-matrix/actions/workflows/build.yml/badge.svg)](https://github.com/remarkablegames/memory-matrix/actions/workflows/build.yml)
[![test](https://github.com/remarkablegames/memory-matrix/actions/workflows/test.yml/badge.svg)](https://github.com/remarkablegames/memory-matrix/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/remarkablegames/memory-matrix/graph/badge.svg?token=IqRfA9X3VC)](https://codecov.io/gh/remarkablegames/memory-matrix)

🧩 <kbd>Memory Matrix</kbd> is a spatial memory game where you recreate a pattern of tiles from memory.

Read the [blog post](https://remarkablegames.org/posts/memory-matrix/).

## Play

Play in your browser:

- [Wavedash](https://wavedash.com/games/memory-matrix/)
- [itch.io](https://remarkablegames.itch.io/memory-matrix)
- [remarkablegames](https://remarkablegames.org/memory-matrix/)

Or download for desktop:

- [Windows](https://github.com/remarkablegames/memory-matrix/releases/latest/download/windows.zip)
- [macOS](https://github.com/remarkablegames/memory-matrix/releases/latest/download/macos.zip)
- [Linux](https://github.com/remarkablegames/memory-matrix/releases/latest/download/linux.zip)

## How to Play

1. **Watch:** A set of tiles lights up. Memorize their positions.
2. **Recall:** Select the tiles that lit up. The game checks your selection automatically once you've selected the required number of tiles.
3. **Climb:** Clear a round to expand the grid and increase the difficulty.

## Features

- **2 modes:**
  - **Classic:** A mistake ends the run.
  - **Timed:** Start with 60 seconds and gain time after each cleared round. The run ends when time runs out.
- **Increasing difficulty:** The grid expands from 3×3 to 7×7 and the pattern grows along with it.
- **Controls:** Click or tap a tile, or move around the grid with the arrow keys and select tiles by pressing **Enter** or **Space**.
- **Accessibility:** The level, number of tiles to recall, timer, and results are announced to screen readers.
- **Theme:** The game follows your system's light or dark theme and disables animations when reduced motion is enabled.
- **Small footprint:** The game is under 10 kB gzipped.

## Install

Clone the repository:

```sh
git clone https://github.com/remarkablemark/memory-matrix.git
cd memory-matrix
```

Install the dependencies:

```sh
npm install
```

## Available Scripts

In the project directory, you can run:

### `npm start`

Runs the app in development mode.

Open [http://127.0.0.1:5173](http://127.0.0.1:5173) to view it in the browser.

The page will reload if you make edits.

You will also see any errors in the console.

### `npm run build`

Builds the app for production to the `dist` folder.

It correctly bundles in production mode and optimizes the build for the best performance.

The build is minified and the filenames include the hashes.

Your app is ready to be deployed!

### `npm run lint`

Checks the code quality.

### `npm run lint:tsc`

Checks for type errors.

### `npm test`

Runs the tests.

## License

[MIT](LICENSE)

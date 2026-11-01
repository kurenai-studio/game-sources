<p align="center">
  <img src="screenshots/logo.png" alt="Match3" width="300">
</p>

# Match3

[![build](https://github.com/remarkablegames/match3/actions/workflows/build.yml/badge.svg)](https://github.com/remarkablegames/match3/actions/workflows/build.yml)
[![test](https://github.com/remarkablegames/match3/actions/workflows/test.yml/badge.svg)](https://github.com/remarkablegames/match3/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/remarkablegames/match3/graph/badge.svg?token=yiIaBuRwzx)](https://codecov.io/gh/remarkablegames/match3)

🌈 **Match3** is a match-3 puzzle game built with JavaScript and the HTML5 canvas. Swap adjacent emoji tiles to create matches of three or more, trigger cascading combos, and chase high scores across three game modes. It was made for [js13kGames 2026](https://js13kgames.com/games/match3), where the theme was **Unicorns and Rainbows**.

Play the game on:

- [Wavedash](https://wavedash.com/games/match3)
- [itch.io](https://remarkablegames.itch.io/match3)
- [remarkablegames](https://remarkablegames.org/match3/)

Read the [blog post](https://remarkablegames.org/posts/match3/) or watch the [YouTube Short](https://youtube.com/shorts/kqXlC9TMgxA).

## Features

- Three game modes: **Levels**, **Time Attack**, and **Endless**
- Touch, mouse, and keyboard controls
- Cascading matches with combo multipliers
- Pastel rainbow canvas rendering with particle effects
- Synthesized Web Audio sound effects
- Build under 13 KB zipped

## Install

Clone the repository:

```sh
git clone https://github.com/remarkablegames/match3.git
cd match3
```

Install the dependencies:

```sh
npm install
```

## Available Scripts

In the project directory, you can run:

### `npm start`

Runs the app in the development mode.

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

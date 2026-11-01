<p align="center">
  <img src="https://github.com/remarkablegames/secret-identity/blob/master/public/cover.png?raw=true" alt="Secret Identity">
</p>

# Secret Identity

[![release](https://img.shields.io/github/v/release/remarkablegames/secret-identity)](https://github.com/remarkablegames/secret-identity/releases)
[![build](https://github.com/remarkablegames/secret-identity/actions/workflows/build.yml/badge.svg)](https://github.com/remarkablegames/secret-identity/actions/workflows/build.yml)

🦸 <kbd>Secret Identity</kbd> is an AI chatbot game where you guess a superhero's secret identity.

This game was made for [Game Off 2024](https://itch.io/jam/game-off-2024), which the theme was **SECRETS**.

Play the game on:

- [itch.io](https://remarkablegames.itch.io/secret-identity)
- [remarkablegames](https://remarkablegames.org/secret-identity/)

Read the [blog post](https://remarkablegames.org/posts/secret-identity/).

## Credits

- Incognito by Soremba from [Noun Project](https://thenounproject.com/icon/incognito-3847037/) (CC BY 3.0)
- [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds)

## Install

Clone the repository:

```sh
git clone https://github.com/remarkablegames/secret-identity.git
cd secret-identity
```

Install the dependencies:

```sh
npm install
```

## Run

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

Runs ESLint.

## Debug

Login via Wrangler:

```sh
npx wrangler login
```

Start a logging session:

```sh
npx wrangler pages deployment tail
```

## License

[MIT](LICENSE)

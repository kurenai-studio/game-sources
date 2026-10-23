# first-threejs-game

# Project Structure

|-- /src
| |-- /components # Components for the project (e.g., creatures, environment)
| |-- /utils # Utility functions
| `-- index.js # Entry point of the application
|
|-- /assets # Static assets like models, textures, and sounds
|-- /lib # Third-party libraries not managed by npm
|-- /styles # CSS stylesheets
|-- /dist # Distribution folder for bundled and minified files
|-- README.md # Project documentation
|-- package.json # NPM package and dependency information

# Set up developing environment

Initialize npm (follow the prompts to create your package.json)
`npm init`

Install Three.js and Cannon.js for physics
`npm install three cannon`

install webpack and babel for bundling
`npm install --save-dev webpack webpack-cli @babel/core babel-loader @babel/preset-env`

Create a webpack.config.js file in the root. This file configures Webpack to bundle the JavaScript.
Configure Babel: Add a babel section in your package.json to configure Babel. This is where you tell Babel to use the preset installed earlier.

`{
  "presets": ["@babel/preset-env"]
}`

Modify your package.json to add a build script:

`"scripts": {
  "build": "webpack --mode production",
  "start": "webpack serve --open --mode development"
},`

# Development

Create the scene, camera, and renderer.
Add physics.

# Run/Test

Set up a local development server
`npm install --global http-server`

Run your development server: Navigate to your project's root directory and run your server.
`http-server . -p 8000`

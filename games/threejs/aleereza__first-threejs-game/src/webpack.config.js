const path = require("path");
const HtmlWebpackPlugin = require("html-webpack-plugin");

module.exports = {
  // Entry point of your application
  entry: "./src/index.js",

  // Output configuration
  output: {
    path: path.resolve(__dirname, "dist"), // Output directory
    filename: "bundle.js", // Name of the bundled JavaScript file
  },

  // Development server configuration
  devServer: {
    static: {
      directory: path.join(__dirname, "dist"), // Directory to serve
    },
    compress: true, // Enable gzip compression
    port: 8080, // Port to run the server on
    open: true, // Automatically open the browser
  },

  // Module resolution and transformation rules
  module: {
    rules: [
      {
        test: /\.js$/, // Apply this rule to JavaScript files
        exclude: /node_modules/, // Do not transpile node_modules
        use: {
          loader: "babel-loader", // Use Babel loader to transpile JS
          options: {
            presets: ["@babel/preset-env"], // Preset for compiling ES6 and above down to ES5
          },
        },
      },
    ],
  },

  // Plugins configuration
  plugins: [
    new HtmlWebpackPlugin({
      template: "./src/index.html", // Path to your HTML template
      filename: "index.html", // Output file name
    }),
  ],

  // Resolve configuration for Webpack
  resolve: {
    fallback: {
      fs: false,
      path: false,
      os: false,
    },
  },
};

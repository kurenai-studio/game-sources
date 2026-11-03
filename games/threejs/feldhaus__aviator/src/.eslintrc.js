module.exports = {
  extends: ["airbnb-base"],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: "./tsconfig.json",
  },
  plugins: ["@typescript-eslint"],
  rules: {
    "@typescript-eslint/lines-between-class-members": [
      "error",
      "always",
      { exceptAfterSingleLine: true },
    ],
    "@typescript-eslint/comma-dangle": ["error", "always-multiline"],
    "no-plusplus": ["error", { allowForLoopAfterthoughts: true }],
    "no-continue": "off",
    "lines-between-class-members": [
      "error",
      "always",
      { exceptAfterSingleLine: true },
    ],
    "import/extensions": [
      "error",
      "ignorePackages",
      {
        js: "never",
        jsx: "never",
        ts: "never",
        tsx: "never",
        mjs: "never",
      },
    ],
  },
  overrides: [
    {
      files: "./src/utils/**/*.ts",
      rules: {
        "import/prefer-default-export": "off",
      },
    },
  ],
  settings: {
    "import/resolver": {
      node: {
        paths: ["src"], //name the subproject folders here!!!
        extensions: [".ts"],
      },
    },
  },
};

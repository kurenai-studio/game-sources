const js = require('@eslint/js');
const globals = require('globals');

module.exports = [
  {
    ignores: [
      'coverage/**',
      'dist/**',
      'build/**',
      'node_modules/**',
      'public/assets/**',
      '.idea/**',
    ],
  },
  js.configs.recommended,
  {
    files: ['**/*.js'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        ...globals.browser,
      },
    },
    rules: {
      'no-console': 'off',
    },
  },
  {
    files: ['*.cjs', 'eslint.config.js', 'scripts/**/*.js'],
    languageOptions: {
      sourceType: 'commonjs',
      globals: {
        ...globals.node,
      },
    },
  },
  {
    files: ['tests/**/*.js'],
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.jest,
        ...globals.node,
      },
    },
  },
];

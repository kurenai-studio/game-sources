import resolve from '@rollup/plugin-node-resolve';

export default {
  input: 'scripts/main.js',
  output: [
    {
      format: 'esm',
      file: 'bundle.js'
    },
  ],
  plugins: [
    resolve()
  ]
};
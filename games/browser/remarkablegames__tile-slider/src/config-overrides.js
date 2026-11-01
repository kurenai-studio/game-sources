/**
 * Config overrides.
 *
 * https://github.com/timarney/react-app-rewired#extended-configuration-options
 */
module.exports = (config, env) => {
  // replace `react` with `preact` in production
  if (process.env.NODE_ENV === 'production') {
    config.resolve = {
      alias: {
        react: 'preact-compat',
        'react-dom': 'preact-compat',
      },
    };
  }

  // otherwise use default `create-react-app` config
  return config;
};

const path = require('path');

module.exports = {
  mode: process.env.NODE_ENV === 'production' ? 'production' : 'development',
  devtool:
    process.env.NODE_ENV === 'production' ? undefined : 'eval-source-map',
  entry: './dist-esm/index.js',
  output: {
    library: 'JinrouFront',
    path: path.join(__dirname, '..', 'client/static/front-assets/'),
    publicPath: '/front-assets/',
    crossOriginLoading: 'anonymous',
    filename: 'bundle.js',
    chunkFilename: '[id].[chunkhash].bundle.js',
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        use: ['source-map-loader'],
        enforce: 'pre',
      },
      {
        test: /\.yaml$/,
        use: ['json-loader', 'yaml-loader'],
      },
    ],
  },
  resolve: {
    alias: {
      '@fortawesome/fontawesome-free-solid$':
        '@fortawesome/fontawesome-free-solid/shakable.es.js',
      '@fortawesome/fontawesome-free-regular':
        '@fortawesome/fontawesome-free-regular/shakable.es.js',
    },
  },
};

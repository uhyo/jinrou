// Register CoffeeScript for reading config from app.config.
require('coffee-script/register');

const path = require('path');
const webpack = require('webpack');

// system language.
let systemLanguage;
try {
  const config = require('../config/app.coffee');

  systemLanguage = config.language.value;
} catch(e) {
  console.error(`Error: '../config/app.coffee' does not exist. Prepare configuration file before building.`);

  throw e;
}

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
      {
        test: /\.(?:pug|jade)$/,
        use: ['pug-loader'],
      },
    ],
  },
  plugins: [
    new webpack.DefinePlugin({
      EXTERNAL_SYSTEM_LANGUAGE: JSON.stringify(systemLanguage),
    }),
  ],
  resolve: {
    alias: {
      '@fortawesome/fontawesome-free-solid$':
        '@fortawesome/fontawesome-free-solid/shakable.es.js',
      '@fortawesome/fontawesome-free-regular':
        '@fortawesome/fontawesome-free-regular/shakable.es.js',
    },
  },
};

// Register CoffeeScript for reading config from app.config.
require('coffee-script/register');

const path = require('path');
const webpack = require('webpack');
const ManifestPlugin = require('webpack-manifest-plugin');
const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');

// config values ----------
// system language.
let systemLanguage;
// publicPath.
let publicPath;
try {
  const config = require('../config/app.coffee');

  systemLanguage = config.language.value;
  publicPath = config.front.publicPath;
} catch (e) {
  console.error(
    `Error: '../config/app.coffee' does not exist. Prepare configuration file before building.`,
  );

  throw e;
}

const isProduction = process.env.NODE_ENV === 'production';

module.exports = {
  mode: isProduction ? 'production' : 'development',
  devtool: isProduction ? undefined : 'eval-source-map',
  entry: './dist-esm/index.js',
  output: {
    library: 'JinrouFront',
    path: path.join(__dirname, '..', 'client/static/front-assets/'),
    publicPath,
    crossOriginLoading: 'anonymous',
    // for production, include hash information.
    filename: isProduction ? 'bundle.[chunkhash].js' : 'bundle.js',
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
    new ManifestPlugin(),
    new BundleAnalyzerPlugin({
      analyzerMode: isProduction ? 'static' : 'server',
      openAnalyzer: !isProduction,
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

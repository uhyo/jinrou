const path = require('path');

module.exports = {
    mode: process.env.NODE_ENV === 'production' ? 'production' : 'development',
    entry: './dist-esm/index.js',
    output: {
        library: 'JinrouFront',
        path: path.join(__dirname, 'dist'),
        publicPath: '/front-assets/',
        filename: 'bundle.js',
    },
    module: {
        rules: [
            {
                test: /\.js$/,
                use: ['source-map-loader'],
                enforce: 'pre',
            },
        ],
    }
};

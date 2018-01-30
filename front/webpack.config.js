const path = require('path');

module.exports = {
    mode: process.env.NODE_ENV === 'production' ? 'production' : 'development',
    entry: './dist-esm/index.js',
    output: {
        path: path.join(__dirname, 'dist'),
        filename: 'bundle.js',
    },
};

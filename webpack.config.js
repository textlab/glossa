module.exports = {
    entry: "./entry.js",
    output: {
        path: "./resources/public/js/",
        filename: "bundle.js"
    },
    module: {
        loaders: [
            { test: /\.jsx?$/, loader: 'jsx' },
            { test: /\.js$/, loader: 'babel-loader' }
        ]
    }
};

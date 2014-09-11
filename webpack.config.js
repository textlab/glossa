module.exports = {
    entry: "./app/assets/javascripts/rglossa/entry.js",
    output: {
        path: "./app/assets/javascripts/rglossa",
        filename: "bundle.js"
    },
    module: {
        loaders: [
            { test: /\.jsx?$/, loader: 'jsx' }
        ]
    }
};
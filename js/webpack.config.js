const path = require('path');

module.exports = (env, argv) => ({
  devtool: argv.mode === 'development' ? 'eval-source-map' : 'source-map',
  entry: {
    timer: './src/timer.js',
    clients: './src/clients.js',
    dashboard: './src/dashboard.js',
    projects: './src/projects.js',
    reports: './src/reports.js',
    tags: './src/tags.js',
    goals: './src/goals.js',
    timelines: './src/timelines.js',
    timelinesadmin: './src/timelines-admin.js',
  },
  output: {
    filename: '[name].js',
    path: path.resolve(__dirname, 'dist'),
    clean: true,
    assetModuleFilename: '[contenthash][ext][query]',
  },
  resolve: {
    alias: {
        'jquery-ui': 'jqueryui'
    }
  },
    module: {
        rules: [
          {
            test: /\.css$/,
            use: ['style-loader', 'css-loader'],
          },
          {
            test: /\.(jpg|png|jpeg|svg)$/i,
            type: 'asset/resource',
          },
        ]
      },
});

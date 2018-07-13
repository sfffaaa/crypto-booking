const { app } = require('./app');

const server = app.listen(config.get('port'), () => {
  if (config.get('log')) {
    console.log(`WT API AT ${config.get('port')}!`);
  }
});

module.exports = server;
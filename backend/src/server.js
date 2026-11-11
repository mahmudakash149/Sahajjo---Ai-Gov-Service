const config = require('./config');
const app = require('./app');
const { initDatabase } = require('./initDb');

app.listen(config.port, async () => {
  console.log(`Sahajjo API listening on port ${config.port}`);
  await initDatabase();
});

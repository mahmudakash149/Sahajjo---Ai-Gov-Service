const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const authRoutes = require('./routes/auth');
const serviceRoutes = require('./routes/services');
const requestRoutes = require('./routes/requests');

const app = express();

app.disable('x-powered-by');
app.use(helmet());
app.use(cors()); // Mobile app clients; tighten origins if a web client is added.
app.use(express.json({ limit: '10kb' }));

app.get('/health', (_req, res) => res.json({ status: 'ok' }));
app.use('/api/auth', authRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/requests', requestRoutes);

app.use((_req, res) => res.status(404).json({ message: 'Not found' }));

// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ message: 'Malformed JSON' });
  }
  console.error(err);
  res.status(500).json({ message: 'Internal server error' });
});

module.exports = app;

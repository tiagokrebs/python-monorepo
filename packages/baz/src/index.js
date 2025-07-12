const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({ message: 'hello' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'baz' });
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Baz server running on port ${PORT}`);
  });
}

module.exports = app;

const { Pool } = require('pg');

// En Render usa DATABASE_URL (la base compartida, con SSL).
// En tu compu usa la base local socio_courier.
const pool = process.env.DATABASE_URL
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    })
  : new Pool({
      host: 'localhost',
      database: 'socio_courier',
      user: 'postgres',
      password: '23082025AYM',
      port: 5432,
    });

module.exports = pool;
const { Pool } = require('pg');

// En Render usa DATABASE_URL (base compartida, SSL). En tu compu, la local.
const pool = process.env.DATABASE_URL
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    })
  : new Pool({
      host: 'localhost',
      database: 'socio_proveedor',
      user: 'postgres',
      password: '23082025AYM',
      port: 5432,
    });

module.exports = pool;
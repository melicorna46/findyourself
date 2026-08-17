const { Pool } = require('pg');

const pool = process.env.DATABASE_URL
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    })
  : new Pool({
      host: 'localhost',
      database: 'tse_simulado',
      user: 'postgres',
      password: '23082025AYM',
      port: 5432,
    });

module.exports = pool;
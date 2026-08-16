const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  database: 'progra5_FINDYOURSELF',
  user: 'postgres',
  password: '23082025AYM',
  port: 5432,
});

module.exports = pool;
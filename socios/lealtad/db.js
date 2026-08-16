const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  database: 'socio_lealtad',
  user: 'postgres',
  password: '23082025AYM',
  port: 5432,
});

module.exports = pool;
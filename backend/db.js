const { Pool } = require('pg');

// Si existe DATABASE_URL (en Render), usa esa conexion con SSL.
// Si no (en tu compu), usa la configuracion local de siempre.
const pool = process.env.DATABASE_URL
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    })
  : new Pool({
      host: 'localhost',
      database: 'progra5_FINDYOURSELF',
      user: 'postgres',
      password: '23082025AYM',
      port: 5432,
    });

module.exports = pool;
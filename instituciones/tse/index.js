const express = require('express');
const cors = require('cors');
const pool = require('./db');

const app = express();
app.use(cors());
app.use(express.json());

// ─────────────────────────────────────────────
// ENDPOINT: consultar una persona por cédula
// GET http://localhost:5001/personas/304560789
// ─────────────────────────────────────────────
app.get('/personas/:cedula', async (req, res) => {
  try {
    const { cedula } = req.params;

    const resultado = await pool.query(
      'SELECT cedula, nombre, apellido1, apellido2, fecha_nacimiento FROM personas WHERE cedula = $1',
      [cedula]
    );

    // Si la cédula no está registrada en el TSE
    if (resultado.rows.length === 0) {
      return res.status(404).json({
        encontrado: false,
        mensaje: 'Cédula no registrada en el TSE',
      });
    }

    const persona = resultado.rows[0];

    res.json({
      encontrado: true,
      cedula: persona.cedula,
      nombre: persona.nombre,
      apellido1: persona.apellido1,
      apellido2: persona.apellido2,
      nombreCompleto: `${persona.nombre} ${persona.apellido1} ${persona.apellido2}`,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => {
  console.log(`API TSE corriendo en http://localhost:${PORT}`);
});
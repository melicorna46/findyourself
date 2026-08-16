const express = require('express');
const router = express.Router();
const pool = require('../db');

// POST enviar consulta
router.post('/', async (req, res) => {
  try {
    const { nombre, telefono, correo, motivo, mensaje } = req.body;

    await pool.query(
      `INSERT INTO consultas (nombre, telefono, correo, motivo, mensaje)
       VALUES ($1, $2, $3, $4, $5)`,
      [nombre, telefono, correo, motivo, mensaje]
    );

    res.json({ mensaje: 'Consulta enviada exitosamente' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
const express = require('express');
const router = express.Router();
const pool = require('../db');

// GET reseñas de un producto + promedio
// GET /resenas/2
router.get('/:productoId', async (req, res) => {
  try {
    const { productoId } = req.params;

    const resenas = await pool.query(
      `SELECT id, usuario_nombre, calificacion, comentario, fecha
       FROM resenas WHERE producto_id = $1 ORDER BY fecha DESC`,
      [productoId]
    );

    // Calcular promedio
    const promedio = await pool.query(
      `SELECT COALESCE(AVG(calificacion), 0) AS promedio, COUNT(*) AS total
       FROM resenas WHERE producto_id = $1`,
      [productoId]
    );

    res.json({
      promedio: parseFloat(promedio.rows[0].promedio).toFixed(1),
      total: parseInt(promedio.rows[0].total),
      resenas: resenas.rows,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST dejar una reseña
// body: { productoId, usuarioId, usuarioNombre, calificacion, comentario }
router.post('/', async (req, res) => {
  try {
    const { productoId, usuarioId, usuarioNombre, calificacion, comentario } = req.body;

    if (!calificacion || calificacion < 1 || calificacion > 5) {
      return res.status(400).json({ error: 'La calificación debe ser de 1 a 5' });
    }

    await pool.query(
      `INSERT INTO resenas (producto_id, usuario_id, usuario_nombre, calificacion, comentario)
       VALUES ($1, $2, $3, $4, $5)`,
      [productoId, usuarioId, usuarioNombre, calificacion, comentario]
    );

    res.json({ mensaje: 'Reseña publicada' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
const express = require('express');
const router = express.Router();
const pool = require('../db');

// GET listar favoritos de un usuario (con datos del producto)
// GET /favoritos/14
router.get('/:usuarioId', async (req, res) => {
  try {
    const { usuarioId } = req.params;
    const result = await pool.query(
      `SELECT p.id, p.categoria_id, p.nombre, p.descripcion, p.precio,
              p.stock, p.etiqueta, p.imagen_url, p.activo
       FROM favoritos f
       JOIN productos p ON p.id = f.producto_id
       WHERE f.usuario_id = $1
       ORDER BY f.fecha DESC`,
      [usuarioId]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST agregar un favorito
// body: { usuarioId, productoId }
router.post('/', async (req, res) => {
  try {
    const { usuarioId, productoId } = req.body;
    await pool.query(
      `INSERT INTO favoritos (usuario_id, producto_id)
       VALUES ($1, $2)
       ON CONFLICT (usuario_id, producto_id) DO NOTHING`,
      [usuarioId, productoId]
    );
    res.json({ mensaje: 'Producto agregado a favoritos' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// DELETE quitar un favorito
// DELETE /favoritos/14/2  (usuario 14, producto 2)
router.delete('/:usuarioId/:productoId', async (req, res) => {
  try {
    const { usuarioId, productoId } = req.params;
    await pool.query(
      'DELETE FROM favoritos WHERE usuario_id = $1 AND producto_id = $2',
      [usuarioId, productoId]
    );
    res.json({ mensaje: 'Producto quitado de favoritos' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
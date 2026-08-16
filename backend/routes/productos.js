const express = require('express');
const router = express.Router();
const pool = require('../db');

// GET todos los productos
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, categoria_id, nombre, descripcion, precio, stock, etiqueta, imagen_url FROM productos WHERE activo = true'
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET productos por categoría
router.get('/categoria/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'SELECT id, categoria_id, nombre, descripcion, precio, stock, etiqueta, imagen_url FROM productos WHERE activo = true AND categoria_id = $1',
      [id]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET todas las categorías
router.get('/categorias', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, nombre, descripcion FROM categorias WHERE activa = true'
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
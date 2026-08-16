const express = require('express');
const router = express.Router();
const pool = require('../db');

// GET buscar/filtrar productos
// GET /busqueda?texto=collar&precioMin=1000&precioMax=8000&categoria=2
router.get('/', async (req, res) => {
  try {
    const { texto, precioMin, precioMax, categoria } = req.query;

    // Construimos la consulta dinamicamente segun los filtros que llegaron
    let sql = `SELECT id, categoria_id, nombre, descripcion, precio, stock, etiqueta, imagen_url, activo
               FROM productos WHERE activo = true`;
    const params = [];
    let i = 1;

    if (texto) {
      sql += ` AND LOWER(nombre) LIKE LOWER($${i})`;
      params.push(`%${texto}%`);
      i++;
    }
    if (precioMin) {
      sql += ` AND precio >= $${i}`;
      params.push(precioMin);
      i++;
    }
    if (precioMax) {
      sql += ` AND precio <= $${i}`;
      params.push(precioMax);
      i++;
    }
    if (categoria) {
      sql += ` AND categoria_id = $${i}`;
      params.push(categoria);
      i++;
    }

    sql += ' ORDER BY nombre';

    const result = await pool.query(sql, params);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
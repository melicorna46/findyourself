const express = require('express');
const router = express.Router();
const pool = require('../db');
//obtener
// GET items del carrito de un usuario
router.get('/:usuarioId', async (req, res) => {
  try {
    const { usuarioId } = req.params;

    // Buscar o crear carrito
    let result = await pool.query(
      'SELECT id FROM carritos WHERE usuario_id = $1',
      [usuarioId]
    );

    let carritoId;
    if (result.rows.length === 0) {
      const nuevo = await pool.query(
        'INSERT INTO carritos (usuario_id) VALUES ($1) RETURNING id',
        [usuarioId]
      );
      carritoId = nuevo.rows[0].id;
    } else {
      carritoId = result.rows[0].id;
    }

    // Obtener items
    const items = await pool.query(
      `SELECT ci.id, ci.producto_id, p.nombre, p.imagen_url, ci.cantidad, ci.precio_unit
       FROM carrito_items ci
       JOIN productos p ON p.id = ci.producto_id
       WHERE ci.carrito_id = $1`,
      [carritoId]
    );

    res.json(items.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
// enviar/crear datos
// POST agregar producto al carrito
router.post('/agregar', async (req, res) => {
  try {
    const { usuarioId, productoId, precio } = req.body;

    // Buscar o crear carrito
    let result = await pool.query(
      'SELECT id FROM carritos WHERE usuario_id = $1',
      [usuarioId]
    );

    let carritoId;
    if (result.rows.length === 0) {
      const nuevo = await pool.query(
        'INSERT INTO carritos (usuario_id) VALUES ($1) RETURNING id',
        [usuarioId]
      );
      carritoId = nuevo.rows[0].id;
    } else {
      carritoId = result.rows[0].id;
    }

    // Agregar o aumentar cantidad
    await pool.query(
      `INSERT INTO carrito_items (carrito_id, producto_id, cantidad, precio_unit)
       VALUES ($1, $2, 1, $3)
       ON CONFLICT (carrito_id, producto_id)
       DO UPDATE SET cantidad = carrito_items.cantidad + 1`,
      [carritoId, productoId, precio]
    );

    res.json({ mensaje: 'Producto agregado al carrito' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// DELETE eliminar item del carrito
router.delete('/item/:itemId', async (req, res) => {
  try {
    const { itemId } = req.params;
    await pool.query('DELETE FROM carrito_items WHERE id = $1', [itemId]);
    res.json({ mensaje: 'Item eliminado' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
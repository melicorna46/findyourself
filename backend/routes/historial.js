const express = require('express');
const router = express.Router();
const pool = require('../db');

// GET historial de pedidos de un usuario
// GET /historial/14
router.get('/:usuarioId', async (req, res) => {
  try {
    const { usuarioId } = req.params;

    // Traer los pedidos del usuario
    const pedidos = await pool.query(
      `SELECT id, total, metodo_pago, numero_guia, costo_envio, direccion_envio, fecha
       FROM pedidos
       WHERE usuario_id = $1
       ORDER BY fecha DESC`,
      [usuarioId]
    );

    // Para cada pedido, traer sus items
    const resultado = [];
    for (const pedido of pedidos.rows) {
      const items = await pool.query(
        `SELECT pi.cantidad, pi.precio_unit, p.nombre, p.imagen_url
         FROM pedido_items pi
         JOIN productos p ON p.id = pi.producto_id
         WHERE pi.pedido_id = $1`,
        [pedido.id]
      );
      resultado.push({
        ...pedido,
        items: items.rows,
      });
    }

    res.json(resultado);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
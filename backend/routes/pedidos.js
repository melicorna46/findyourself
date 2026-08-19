const express = require('express');
const router = express.Router();
const pool = require('../db');
const axios = require('axios'); // para llamar al courier (API a API)

const COURIER_URL = process.env.COURIER_URL || 'http://localhost:4001';

const LEALTAD_URL = process.env.LEALTAD_URL || 'http://localhost:4003';

// POST crear pedido
router.post('/', async (req, res) => {
  try {
    const { usuarioId, direccionEnvio, metodoPago, notas, provincia } = req.body;

    // Obtener carrito del usuario
    const carrito = await pool.query(
      'SELECT id FROM carritos WHERE usuario_id = $1',
      [usuarioId]
    );

    if (carrito.rows.length === 0) {
      return res.status(400).json({ error: 'No hay carrito activo' });
    }

    const carritoId = carrito.rows[0].id;

    // Obtener items del carrito
    const items = await pool.query(
      'SELECT producto_id, cantidad, precio_unit FROM carrito_items WHERE carrito_id = $1',
      [carritoId]
    );

    if (items.rows.length === 0) {
      return res.status(400).json({ error: 'El carrito está vacío' });
    }

    // Calcular subtotal de productos
    const subtotal = items.rows.reduce(
      (sum, item) => sum + item.cantidad * item.precio_unit,
      0
    );

    // ─────────────────────────────────────────────
    // LLAMADA API A API: pedir la guía al courier
    // ─────────────────────────────────────────────
    let numeroGuia = null;
    let costoEnvio = 0;

    try {
      const envio = await axios.post(`${COURIER_URL}/envio`, { provincia });
      numeroGuia = envio.data.numeroGuia;
      costoEnvio = parseFloat(envio.data.costo);
    } catch (errorCourier) {
      // Si el courier falla, el pedido igual se crea pero sin guía
      console.log('Courier no disponible:', errorCourier.message);
    }

    // Total = productos + envío
    const total = subtotal + costoEnvio;

    // Crear pedido (ahora con guía y costo de envío)
    const pedido = await pool.query(
      `INSERT INTO pedidos (usuario_id, direccion_envio, metodo_pago, total, notas, numero_guia, costo_envio)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
      [usuarioId, direccionEnvio, metodoPago, total, notas, numeroGuia, costoEnvio]
    );

    const pedidoId = pedido.rows[0].id;

    // Insertar items del pedido
    for (const item of items.rows) {
      await pool.query(
        `INSERT INTO pedido_items (pedido_id, producto_id, cantidad, precio_unit)
         VALUES ($1, $2, $3, $4)`,
        [pedidoId, item.producto_id, item.cantidad, item.precio_unit]
      );
    }

    // Vaciar carrito
    await pool.query(
      'DELETE FROM carrito_items WHERE carrito_id = $1',
      [carritoId]
    );
    
    // ─────────────────────────────────────────────
    // LLAMADA API A API: acumular puntos en el socio de lealtad
    // ─────────────────────────────────────────────
    let puntosGanados = 0;
    let saldoPuntos = 0;

    try {
      const lealtad = await axios.post(`${LEALTAD_URL}/acumular`, {
        usuarioId: usuarioId,
        pedidoId: pedidoId,
        monto: total,
      });
      puntosGanados = lealtad.data.puntosGanados;
      saldoPuntos = lealtad.data.saldoTotal;
    } catch (errorLealtad) {
      // Si el socio de lealtad falla, el pedido igual se completa
      console.log('Socio de lealtad no disponible:', errorLealtad.message);
    }

    res.json({
      mensaje: 'Pedido creado exitosamente',
      pedidoId,
      numeroGuia,
      costoEnvio,
      total,
      puntosGanados,
      saldoPuntos
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;d
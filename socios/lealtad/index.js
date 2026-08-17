const express = require('express');
const cors = require('cors');
const pool = require('./db');

const app = express();
app.use(cors());
app.use(express.json());

// Regla del programa: 1 punto por cada ₡2000 gastados
const COLONES_POR_PUNTO = 2000;

// ─────────────────────────────────────────────
// ENDPOINT 1: acumular puntos por una compra
// POST http://localhost:4003/acumular
// body: { "usuarioId": 14, "pedidoId": 1, "monto": 18200 }
// ─────────────────────────────────────────────
app.post('/acumular', async (req, res) => {
  try {
    const { usuarioId, pedidoId, monto } = req.body;

    if (!usuarioId || !monto) {
      return res.status(400).json({ error: 'Faltan datos (usuarioId, monto)' });
    }

    // Calcular puntos ganados (redondeo hacia abajo)
    const puntosGanados = Math.floor(monto / COLONES_POR_PUNTO);

    // Sumar al saldo del usuario (si no existe, lo crea)
    const saldo = await pool.query(
      `INSERT INTO saldos (usuario_id, puntos)
       VALUES ($1, $2)
       ON CONFLICT (usuario_id)
       DO UPDATE SET puntos = saldos.puntos + $2
       RETURNING puntos`,
      [usuarioId, puntosGanados]
    );

    // Guardar el movimiento en el historial
    await pool.query(
      `INSERT INTO movimientos (usuario_id, pedido_id, monto_compra, puntos_ganados)
       VALUES ($1, $2, $3, $4)`,
      [usuarioId, pedidoId, monto, puntosGanados]
    );

    res.json({
      usuarioId: usuarioId,
      puntosGanados: puntosGanados,
      saldoTotal: saldo.rows[0].puntos,
      mensaje: `Ganaste ${puntosGanados} puntos por esta compra`,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ─────────────────────────────────────────────
// ENDPOINT 2: consultar saldo de puntos de un usuario
// GET http://localhost:4003/saldo/14
// ─────────────────────────────────────────────
app.get('/saldo/:usuarioId', async (req, res) => {
  try {
    const { usuarioId } = req.params;

    const saldo = await pool.query(
      'SELECT puntos FROM saldos WHERE usuario_id = $1',
      [usuarioId]
    );

    // Si el usuario nunca ha comprado, saldo en 0
    const puntos = saldo.rows.length > 0 ? saldo.rows[0].puntos : 0;

    // Traer también el historial de movimientos
    const historial = await pool.query(
      `SELECT pedido_id, monto_compra, puntos_ganados, fecha
       FROM movimientos WHERE usuario_id = $1 ORDER BY fecha DESC`,
      [usuarioId]
    );

    res.json({
      usuarioId: parseInt(usuarioId),
      puntos: puntos,
      historial: historial.rows,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 4003;
app.listen(PORT, () => {
  console.log(`API Lealtad corriendo en http://localhost:${PORT}`);
});
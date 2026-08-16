const express = require('express');
const cors = require('cors');
const pool = require('./db');

const app = express();
app.use(cors());
app.use(express.json());

// ─────────────────────────────────────────────
// ENDPOINT 1: validar un cupón y calcular el descuento
// POST http://localhost:4004/validar
// body: { "codigo": "VERANO20", "subtotal": 16200 }
// ─────────────────────────────────────────────
app.post('/validar', async (req, res) => {
  try {
    const { codigo, subtotal } = req.body;

    if (!codigo || subtotal === undefined) {
      return res.status(400).json({ error: 'Faltan datos (codigo, subtotal)' });
    }

    // Buscar el cupón (en mayúsculas, por si lo escriben distinto)
    const resultado = await pool.query(
      'SELECT * FROM cupones WHERE UPPER(codigo) = UPPER($1)',
      [codigo]
    );

    // Caso 1: el cupón no existe
    if (resultado.rows.length === 0) {
      return res.json({
        valido: false,
        motivo: 'El código de cupón no existe',
      });
    }

    const cupon = resultado.rows[0];

    // Caso 2: el cupón está inactivo
    if (!cupon.activo) {
      return res.json({
        valido: false,
        motivo: 'Este cupón ya no está disponible',
      });
    }

    // Caso 3: el cupón está vencido
    const hoy = new Date();
    if (cupon.fecha_vencimiento && new Date(cupon.fecha_vencimiento) < hoy) {
      return res.json({
        valido: false,
        motivo: 'Este cupón ya venció',
      });
    }

    // Caso 4: el cupón agotó sus usos
    if (cupon.usos_maximos && cupon.usos_actuales >= cupon.usos_maximos) {
      return res.json({
        valido: false,
        motivo: 'Este cupón alcanzó su límite de usos',
      });
    }

    // Cupón válido: calcular el descuento
    const descuento = Math.round((subtotal * cupon.porcentaje) / 100);

    res.json({
      valido: true,
      codigo: cupon.codigo,
      descripcion: cupon.descripcion,
      porcentaje: cupon.porcentaje,
      subtotal: subtotal,
      descuento: descuento,
      totalConDescuento: subtotal - descuento,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ─────────────────────────────────────────────
// ENDPOINT 2: registrar el uso del cupón
// POST http://localhost:4004/aplicar
// body: { "codigo": "VERANO20" }
// (se llama cuando la compra se confirma de verdad)
// ─────────────────────────────────────────────
app.post('/aplicar', async (req, res) => {
  try {
    const { codigo } = req.body;

    const resultado = await pool.query(
      `UPDATE cupones SET usos_actuales = usos_actuales + 1
       WHERE UPPER(codigo) = UPPER($1)
       RETURNING codigo, usos_actuales, usos_maximos`,
      [codigo]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({ error: 'Cupón no encontrado' });
    }

    res.json({
      mensaje: 'Uso del cupón registrado',
      cupon: resultado.rows[0],
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = 4004;
app.listen(PORT, () => {
  console.log(`API Cupones corriendo en http://localhost:${PORT}`);
});
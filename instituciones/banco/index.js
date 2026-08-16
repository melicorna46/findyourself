const express = require('express');
const cors = require('cors');
const pool = require('./db');

const app = express();
app.use(cors());
app.use(express.json());

// ─────────────────────────────────────────────
// Detectar la marca de la tarjeta por el primer dígito
// 4 = Visa, 5 = Mastercard
// ─────────────────────────────────────────────
function detectarMarca(numero) {
  if (numero.startsWith('4')) return 'Visa';
  if (numero.startsWith('5')) return 'Mastercard';
  return 'Desconocida';
}

// ─────────────────────────────────────────────
// ENDPOINT 1: detectar marca (para mostrar el logo mientras escribe)
// GET http://localhost:5002/marca/4532110012345678
// ─────────────────────────────────────────────
app.get('/marca/:numero', (req, res) => {
  const { numero } = req.params;
  res.json({ marca: detectarMarca(numero) });
});

// ─────────────────────────────────────────────
// ENDPOINT 2: procesar pago con tarjeta
// POST http://localhost:5002/pago-tarjeta
// body: { numero, vencimiento, cvv, monto }
// ─────────────────────────────────────────────
app.post('/pago-tarjeta', async (req, res) => {
  try {
    const { numero, vencimiento, cvv, monto } = req.body;

    // Validación 1: número de 16 dígitos
    if (!numero || numero.length !== 16 || !/^\d+$/.test(numero)) {
      return res.json({ aprobado: false, motivo: 'El número de tarjeta debe tener 16 dígitos' });
    }

    // Detectar la marca
    const marca = detectarMarca(numero);
    if (marca === 'Desconocida') {
      return res.json({ aprobado: false, motivo: 'Marca de tarjeta no reconocida (debe ser Visa o Mastercard)' });
    }

    // Validación 2: vencimiento y CVV presentes
    if (!vencimiento || !cvv) {
      return res.json({ aprobado: false, motivo: 'Faltan datos de la tarjeta' });
    }

    // Buscar la tarjeta en el banco
    const resultado = await pool.query(
      'SELECT * FROM tarjetas WHERE numero = $1',
      [numero]
    );

    // Validación 3: la tarjeta existe
    if (resultado.rows.length === 0) {
      return res.json({ aprobado: false, motivo: 'Tarjeta no encontrada en el banco' });
    }

    const tarjeta = resultado.rows[0];

    // Validación 4: el CVV coincide
    if (tarjeta.cvv !== cvv) {
      return res.json({ aprobado: false, motivo: 'CVV incorrecto' });
    }

    // Validación 5: hay saldo suficiente
    if (parseFloat(tarjeta.saldo) < parseFloat(monto)) {
      // Registrar transacción rechazada
      await pool.query(
        `INSERT INTO transacciones (numero_tarjeta, tipo, monto, estado, referencia)
         VALUES ($1, 'TARJETA', $2, 'RECHAZADO', $3)`,
        [numero, monto, 'REF-' + Date.now()]
      );
      return res.json({ aprobado: false, motivo: 'Fondos insuficientes' });
    }

    // ✅ Pago aprobado: descontar del saldo
    await pool.query(
      'UPDATE tarjetas SET saldo = saldo - $1 WHERE numero = $2',
      [monto, numero]
    );

    // Registrar la transacción aprobada
    const referencia = 'REF-' + Date.now();
    await pool.query(
      `INSERT INTO transacciones (numero_tarjeta, tipo, monto, estado, referencia)
       VALUES ($1, 'TARJETA', $2, 'APROBADO', $3)`,
      [numero, monto, referencia]
    );

    res.json({
      aprobado: true,
      marca: marca,
      titular: tarjeta.titular,
      monto: parseFloat(monto),
      referencia: referencia,
      mensaje: `Pago de ₡${monto} aprobado con ${marca}`,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ─────────────────────────────────────────────
// ENDPOINT 3: procesar pago con SINPE Móvil
// POST http://localhost:5002/pago-sinpe
// body: { telefono, monto }
// ─────────────────────────────────────────────
app.post('/pago-sinpe', async (req, res) => {
  try {
    const { telefono, monto } = req.body;

    // Validación: teléfono de 8 dígitos
    if (!telefono || telefono.length !== 8 || !/^\d+$/.test(telefono)) {
      return res.json({ aprobado: false, motivo: 'El teléfono debe tener 8 dígitos' });
    }

    // Buscar la cuenta SINPE
    const resultado = await pool.query(
      'SELECT * FROM cuentas_sinpe WHERE telefono = $1',
      [telefono]
    );

    // La cuenta no existe / no tiene SINPE
    if (resultado.rows.length === 0) {
      return res.json({ aprobado: false, motivo: 'Este número no tiene SINPE Móvil asociado' });
    }

    const cuenta = resultado.rows[0];

    // Saldo insuficiente
    if (parseFloat(cuenta.saldo) < parseFloat(monto)) {
      await pool.query(
        `INSERT INTO transacciones (numero_tarjeta, tipo, monto, estado, referencia)
         VALUES ($1, 'SINPE', $2, 'RECHAZADO', $3)`,
        [telefono, monto, 'SINPE-' + Date.now()]
      );
      return res.json({ aprobado: false, motivo: 'Fondos insuficientes en SINPE Móvil' });
    }

    // ✅ Pago aprobado: descontar saldo
    await pool.query(
      'UPDATE cuentas_sinpe SET saldo = saldo - $1 WHERE telefono = $2',
      [monto, telefono]
    );

    const referencia = 'SINPE-' + Date.now();
    await pool.query(
      `INSERT INTO transacciones (numero_tarjeta, tipo, monto, estado, referencia)
       VALUES ($1, 'SINPE', $2, 'APROBADO', $3)`,
      [telefono, monto, referencia]
    );

    res.json({
      aprobado: true,
      titular: cuenta.titular,
      telefono: telefono,
      monto: parseFloat(monto),
      referencia: referencia,
      mensaje: `Pago SINPE de ₡${monto} aprobado`,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});



const PORT = 5002;
app.listen(PORT, () => {
  console.log(`API Banco corriendo en http://localhost:${PORT}`);
});
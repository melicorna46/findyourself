const express = require('express'); // framework del servidor
const cors = require('cors');       // permite conexión desde tu backend
const pool = require('./db');       // conexión a la BD socio_courier

const app = express();
app.use(cors());
app.use(express.json()); // para leer JSON en el body

// ─────────────────────────────────────────────
// ENDPOINT 1: consultar tarifa de envío por provincia
// GET http://localhost:4001/tarifa/Cartago
// ─────────────────────────────────────────────
app.get('/tarifa/:provincia', async (req, res) => {
  try {
    const { provincia } = req.params;

    const resultado = await pool.query(
      'SELECT * FROM tarifas_envio WHERE provincia = $1',
      [provincia]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({ error: 'Provincia no encontrada' });
    }

    res.json(resultado.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ─────────────────────────────────────────────
// ENDPOINT 2: generar un envío (crea número de guía)
// POST http://localhost:4001/envio
// body: { "provincia": "Cartago" }
// ─────────────────────────────────────────────
app.post('/envio', async (req, res) => {
  try {
    const { provincia } = req.body;

    // Buscar la tarifa de esa provincia
    const resultado = await pool.query(
      'SELECT * FROM tarifas_envio WHERE provincia = $1',
      [provincia]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({ error: 'Provincia no encontrada' });
    }

    const tarifa = resultado.rows[0];

    // Generar número de guía simulado (ej: CR-1737400000000)
    const numeroGuia = 'CR-' + Date.now();

    res.json({
      numeroGuia: numeroGuia,
      provincia: tarifa.provincia,
      costo: tarifa.costo,
      diasEstimados: tarifa.dias_estimados,
      mensaje: 'Envío generado exitosamente'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ─────────────────────────────────────────────
// Levantar el servidor en el puerto 4001
// ─────────────────────────────────────────────
const PORT = 4001;
app.listen(PORT, () => {
  console.log(`API Courier corriendo en http://localhost:${PORT}`);
});
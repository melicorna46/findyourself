const express = require('express');
const router = express.Router();
const axios = require('axios');

const BANCO_URL = 'http://localhost:5002';

// POST pago con tarjeta
// Flutter llama: POST /pagos/tarjeta
router.post('/tarjeta', async (req, res) => {
  try {
    const { numero, vencimiento, cvv, monto } = req.body;

    // LLAMADA API A API: tu Node → banco
    const respuesta = await axios.post(`${BANCO_URL}/pago-tarjeta`, {
      numero, vencimiento, cvv, monto,
    });

    res.json(respuesta.data);
  } catch (error) {
    res.status(500).json({ error: 'No se pudo procesar el pago con tarjeta' });
  }
});

// POST pago con SINPE
// Flutter llama: POST /pagos/sinpe
router.post('/sinpe', async (req, res) => {
  try {
    const { telefono, monto } = req.body;

    // LLAMADA API A API: tu Node → banco
    const respuesta = await axios.post(`${BANCO_URL}/pago-sinpe`, {
      telefono, monto,
    });

    res.json(respuesta.data);
  } catch (error) {
    res.status(500).json({ error: 'No se pudo procesar el pago con SINPE' });
  }
});

// GET detectar marca de tarjeta (para el logo mientras escribe)
// Flutter llama: GET /pagos/marca/4532...
router.get('/marca/:numero', async (req, res) => {
  try {
    const { numero } = req.params;
    const respuesta = await axios.get(`${BANCO_URL}/marca/${numero}`);
    res.json(respuesta.data);
  } catch (error) {
    res.status(500).json({ error: 'No se pudo detectar la marca' });
  }
});

module.exports = router;
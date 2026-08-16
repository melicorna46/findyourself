const express = require('express');
const router = express.Router();
const axios = require('axios');

const CUPONES_URL = 'http://localhost:4004';

router.post('/validar', async (req, res) => {
  try {
    const { codigo, subtotal } = req.body;
    const respuesta = await axios.post(`${CUPONES_URL}/validar`, {
      codigo,
      subtotal,
    });
    res.json(respuesta.data);
  } catch (error) {
    res.status(500).json({ error: 'No se pudo validar el cupon' });
  }
});

module.exports = router;

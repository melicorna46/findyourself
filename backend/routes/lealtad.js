const express = require('express');
const router = express.Router();
const axios = require('axios');

const LEALTAD_URL = 'http://localhost:4003';

// GET saldo de puntos de un usuario
// Se consulta: GET /lealtad/saldo/14
router.get('/saldo/:usuarioId', async (req, res) => {
  try {
    const { usuarioId } = req.params;

    // LLAMADA API A API: tu Node → socio de lealtad
    const respuesta = await axios.get(`${LEALTAD_URL}/saldo/${usuarioId}`);

    res.json(respuesta.data);
  } catch (error) {
    res.status(500).json({ error: 'No se pudo consultar el saldo de puntos' });
  }
});

module.exports = router;
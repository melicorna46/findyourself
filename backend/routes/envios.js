const express = require('express');
const router = express.Router();
const axios = require('axios'); // para llamar al courier (API a API)

// URL del socio courier (empresa externa, puerto 4001)
const COURIER_URL = 'http://localhost:4001';

// ─────────────────────────────────────────────
// GET costo de envío según provincia
// Flutter llama: GET /envios/costo/Cartago
// Por dentro, tu backend le pregunta al courier
// ─────────────────────────────────────────────
router.get('/costo/:provincia', async (req, res) => {
  try {
    const { provincia } = req.params;

    // LLAMADA API A API: tu Node → courier
    const respuesta = await axios.get(`${COURIER_URL}/tarifa/${provincia}`);

    // Devolvemos a Flutter lo que el courier respondió
    res.json({
      provincia: respuesta.data.provincia,
      costo: respuesta.data.costo,
      diasEstimados: respuesta.data.dias_estimados,
    });
  } catch (error) {
    // Si el courier no encuentra la provincia o está caído
    if (error.response && error.response.status === 404) {
      return res.status(404).json({ error: 'Provincia no disponible para envío' });
    }
    res.status(500).json({ error: 'No se pudo consultar el costo de envío' });
  }
});

module.exports = router;
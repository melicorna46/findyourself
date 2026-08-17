const express = require('express');
const router = express.Router();
const axios = require('axios'); // para llamar al proveedor (API a API)

// URL del socio proveedor (empresa externa, puerto 4002)
const PROVEEDOR_URL = process.env.PROVEEDOR_URL || 'http://localhost:4002';

// ─────────────────────────────────────────────
// GET disponibilidad de materiales para reponer un producto
// Se consulta: GET /inventario/disponibilidad/4
// Por dentro, tu backend le pregunta al proveedor
// ─────────────────────────────────────────────
router.get('/disponibilidad/:productoId', async (req, res) => {
  try {
    const { productoId } = req.params;

    // LLAMADA API A API: tu Node → proveedor
    const respuesta = await axios.get(
      `${PROVEEDOR_URL}/disponibilidad/${productoId}`
    );

    // Devolvemos lo que el proveedor respondió
    res.json(respuesta.data);
  } catch (error) {
    if (error.response && error.response.status === 404) {
      return res.status(404).json({ error: 'Producto sin receta de materiales' });
    }
    res.status(500).json({ error: 'No se pudo consultar el inventario del proveedor' });
  }
});

module.exports = router;
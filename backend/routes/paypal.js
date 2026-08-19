const express = require('express');
const router = express.Router();
const paypal = require('@paypal/checkout-server-sdk');
const os = require('os');

// ─────────────────────────────────────────────
// Detecta la IP local automáticamente (funciona en cualquier red)
// ─────────────────────────────────────────────
function obtenerIPLocal() {
  const interfaces = os.networkInterfaces();
  for (const nombre of Object.keys(interfaces)) {
    for (const iface of interfaces[nombre]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost';
}
const IP_LOCAL = obtenerIPLocal();

// URL publica del backend cuando esta hosteado (Render). En local usa la IP.
const BASE_URL = process.env.PUBLIC_URL || `http://${IP_LOCAL}:3000`;

// ─────────────────────────────────────────────
// Credenciales de PayPal (Sandbox)
// ─────────────────────────────────────────────
const CLIENT_ID = 'AXjIOVzmZeAFCbJFDsKehLxdK1ZSAvJXfEho3WkkwDoxhKQS-8l_Ywya2mMhCohgSVRnhYDzOlcGqgce';
const CLIENT_SECRET = 'EIKf7wC19SM2REk_ZfLrHfW2wdnBVLajxUhOY6otFHhvA6ehQOIPOLZvc2tER4cL1SVCgikVp1Kz74kD';

// Ambiente Sandbox (prueba). Para producción sería LiveEnvironment.
const environment = new paypal.core.SandboxEnvironment(CLIENT_ID, CLIENT_SECRET);
const client = new paypal.core.PayPalHttpClient(environment);

// ─────────────────────────────────────────────
// ENDPOINT 1: crear orden de pago
// POST /paypal/crear-orden
// body: { monto: 18200 }  (en colones, lo convertimos a USD aprox)
// ─────────────────────────────────────────────
router.post('/crear-orden', async (req, res) => {
  try {
    const { monto } = req.body;

    // PayPal trabaja en USD en sandbox; convertimos colones a dólares (aprox 500)
    const montoUSD = (parseFloat(monto) / 500).toFixed(2);

    const request = new paypal.orders.OrdersCreateRequest();
    request.prefer('return=representation');
    request.requestBody({
      intent: 'CAPTURE',
      purchase_units: [{
        amount: {
          currency_code: 'USD',
          value: montoUSD,
        },
        description: 'Compra en Find Your Self',
      }],
      application_context: {
        brand_name: 'Find Your Self',
        return_url: `${BASE_URL}/paypal/exito`,
        cancel_url: `${BASE_URL}/paypal/cancelado`,
      },
    });

    const orden = await client.execute(request);

    // Buscamos el link de aprobación que devuelve PayPal
    const linkAprobacion = orden.result.links.find(l => l.rel === 'approve');

    res.json({
      ordenId: orden.result.id,
      linkAprobacion: linkAprobacion.href,
      montoUSD: montoUSD,
    });
  } catch (error) {
    res.status(500).json({ error: 'No se pudo crear la orden de PayPal', detalle: error.message });
  }
});

// ─────────────────────────────────────────────
// ENDPOINT 2: capturar el pago (confirmar)
// POST /paypal/capturar
// body: { ordenId: "..." }
// ─────────────────────────────────────────────
router.post('/capturar', async (req, res) => {
  try {
    const { ordenId } = req.body;

    const request = new paypal.orders.OrdersCaptureRequest(ordenId);
    request.requestBody({});

    const captura = await client.execute(request);

    res.json({
      estado: captura.result.status,
      ordenId: captura.result.id,
      mensaje: 'Pago de PayPal capturado exitosamente',
    });
  } catch (error) {
    res.status(500).json({ error: 'No se pudo capturar el pago', detalle: error.message });
  }
});

// Páginas simples de retorno (cuando PayPal redirige de vuelta)
router.get('/exito', (req, res) => {
  res.send('<h1>Pago aprobado ✅</h1><p>Podés volver a la app.</p>');
});
router.get('/cancelado', (req, res) => {
  res.send('<h1>Pago cancelado ❌</h1><p>Podés volver a la app.</p>');
});

module.exports = router;
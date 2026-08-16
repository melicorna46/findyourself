const express = require('express');
const router = express.Router();
const axios = require('axios');

/*
  Consume el servicio real del BCCR y devuelve el tipo de cambio
  de compra del dolar (indicador 317). La app pide a este backend,
  el backend consulta al BCCR con un token (Bearer) y devuelve el valor.
*/

// PEGÁ TU TOKEN DEL BCCR (SDDE) AQUÍ:
const BCCR_TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJCQ0NSLVNEREUiLCJzdWIiOiJtZWxpY29ybmE0NkBnbWFpbC5jb20iLCJhdWQiOiJTRERFLVNpdGlvRXh0ZXJubyIsImV4cCI6MjUzNDAyMzAwODAwLCJuYmYiOjE3ODUzMDUzNTUsImlhdCI6MTc4NTMwNTM1NSwianRpIjoiYTgxYThkNjUtYjM5OC00YTYzLTkwZGEtODgxMjRjNjA3OGI5IiwiZW1haWwiOiJtZWxpY29ybmE0NkBnbWFpbC5jb20ifQ.3KYt3VP9HNxkPbj5OLvgcyA9Ls5hpL9EMXrbqWPp-Ms';

const BCCR_BASE = 'https://apim.bccr.fi.cr/SDDE/api/Bccr.GE.SDDE.Publico.Indicadores.API';

// GET tipo de cambio de compra del dólar (BCCR real - sistema nuevo SDDE)
router.get('/', async (req, res) => {
  try {
    // Rango de fechas: últimos 7 días (para asegurar traer el último dato)
    const hoy = new Date();
    const hace7 = new Date();
    hace7.setDate(hoy.getDate() - 7);

    const fmt = (d) => {
      const dia = String(d.getDate()).padStart(2, '0');
      const mes = String(d.getMonth() + 1).padStart(2, '0');
      const anio = d.getFullYear();
      return `${anio}/${mes}/${dia}`;
    };

    const fechaInicio = fmt(hace7);
    const fechaFin = fmt(hoy);

    // Indicador 317 = tipo de cambio COMPRA del dólar
    const url = `${BCCR_BASE}/indicadoresEconomicos/317/series?fechaInicio=${encodeURIComponent(fechaInicio)}&fechaFin=${encodeURIComponent(fechaFin)}&idioma=ES`;

    // LLAMADA API A API: tu Node → BCCR (con Bearer Token)
    const respuesta = await axios.get(url, {
      headers: {
        'Authorization': `Bearer ${BCCR_TOKEN}`,
        'Accept': 'application/json',
      },
    });

    // La respuesta trae las series; tomamos el último valor
    const datos = respuesta.data.datos;
    const serie = datos[0].series;
    const ultimo = serie[serie.length - 1];

    res.json({
      indicador: 'Tipo de cambio compra USD',
      fecha: ultimo.fecha,
      valor: ultimo.valorDatoPorPeriodo,
    });
  } catch (error) {
    res.status(500).json({
      error: 'No se pudo consultar el BCCR',
      detalle: error.response ? error.response.status : error.message,
    });
  }
});

module.exports = router;
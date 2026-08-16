const express = require('express');
const router = express.Router();
const pool = require('../db');

///Cada endpoint consulta la BD filtrando por el ID recibido y devuelve los datos en JSON.


router.get('/paises', async (req, res) => {
  try {
    const resultado = await pool.query('SELECT * FROM paises ORDER BY nombre');
    res.json(resultado.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/provincias/:paisId', async (req, res) => {
  try {
    const { paisId } = req.params;
    const resultado = await pool.query(
      'SELECT * FROM provincias WHERE pais_id = $1 ORDER BY nombre',
      [paisId]
    );
    res.json(resultado.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/cantones/:provinciaId', async (req, res) => {
  try {
    const { provinciaId } = req.params;
    const resultado = await pool.query(
      'SELECT * FROM cantones WHERE provincia_id = $1 ORDER BY nombre',
      [provinciaId]
    );
    res.json(resultado.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/distritos/:cantonId', async (req, res) => {
  try {
    const { cantonId } = req.params;
    const resultado = await pool.query(
      'SELECT * FROM distritos WHERE canton_id = $1 ORDER BY nombre',
      [cantonId]
    );
    res.json(resultado.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
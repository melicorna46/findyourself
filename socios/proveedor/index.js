const express = require('express');
const cors = require('cors');
const pool = require('./db');

const app = express();
app.use(cors());
app.use(express.json());

// ─────────────────────────────────────────────
// ENDPOINT 1: ver todo el inventario de materiales
// GET http://localhost:4002/materiales
// ─────────────────────────────────────────────
app.get('/materiales', async (req, res) => {
  try {
    const resultado = await pool.query('SELECT * FROM materiales ORDER BY id');
    res.json(resultado.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ─────────────────────────────────────────────
// ENDPOINT 2: verificar si hay materiales para reponer un producto
// GET http://localhost:4002/disponibilidad/2
// (revisa la receta del producto y compara con el stock)
// ─────────────────────────────────────────────
app.get('/disponibilidad/:productoId', async (req, res) => {
  try {
    const { productoId } = req.params;

    // Traer la receta del producto + el stock actual de cada material
    const receta = await pool.query(
      `SELECT pm.material_id, m.nombre, pm.cantidad_necesaria, m.stock, m.unidad
       FROM producto_materiales pm
       JOIN materiales m ON m.id = pm.material_id
       WHERE pm.producto_id = $1`,
      [productoId]
    );

    if (receta.rows.length === 0) {
      return res.status(404).json({ error: 'Producto sin receta de materiales' });
    }

    // Revisar cuáles materiales NO alcanzan
    const faltantes = [];
    for (const item of receta.rows) {
      if (item.stock < item.cantidad_necesaria) {
        faltantes.push({
          material: item.nombre,
          necesita: item.cantidad_necesaria,
          disponible: item.stock,
          unidad: item.unidad,
        });
      }
    }

    // Responder según si se puede reponer o no
    if (faltantes.length === 0) {
      res.json({
        productoId: parseInt(productoId),
        sePuedeReponer: true,
        mensaje: 'Hay materiales suficientes para reponer este producto',
        materiales: receta.rows,
      });
    } else {
      res.json({
        productoId: parseInt(productoId),
        sePuedeReponer: false,
        mensaje: 'Faltan materiales para reponer este producto',
        faltantes: faltantes,
      });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 4002;
app.listen(PORT, () => {
  console.log(`API Proveedor corriendo en http://localhost:${PORT}`);
});
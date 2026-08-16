const express = require('express');// el framework del servidor
const cors = require('cors'); // permite comunicación con Flutter
const path = require('path');// maneja rutas de carpetas
const app = express();//crea la app

app.use(cors());// permite que Flutter se conecte al servidor
app.use(express.json());
app.use('/imagenes', express.static(path.join(__dirname, 'public/imagenes')));

// Rutas
const productosRoutes = require('./routes/productos');
const carritoRoutes = require('./routes/carrito');
const consultasRoutes = require('./routes/consultas');
const pedidosRoutes = require('./routes/pedidos');
const authRoutes = require('./routes/auth');
const ubicacionRoutes = require('./routes/ubicacion');
const enviosRoutes = require('./routes/envios');
const inventarioRoutes = require('./routes/inventario');
const lealtadRoutes = require('./routes/lealtad');
const cuponesRoutes = require('./routes/cupones');
const pagosRoutes = require('./routes/pagos');
const tipoCambioRoutes = require('./routes/tipocambio');
const paypalRoutes = require('./routes/paypal');
const favoritosRoutes = require('./routes/favoritos');
const resenasRoutes = require('./routes/resenas');
const historialRoutes = require('./routes/historial');
const busquedaRoutes = require('./routes/busqueda');



app.use('/productos', productosRoutes);
app.use('/carrito', carritoRoutes);
app.use('/consultas', consultasRoutes);
app.use('/pedidos', pedidosRoutes);
app.use('/auth', authRoutes);
app.use('/ubicacion', ubicacionRoutes);
app.use('/envios', enviosRoutes);
app.use('/inventario', inventarioRoutes);
app.use('/lealtad', lealtadRoutes);
app.use('/cupones', cuponesRoutes);
app.use('/pagos', pagosRoutes);
app.use('/tipo-cambio', tipoCambioRoutes);
app.use('/paypal', paypalRoutes);
app.use('/favoritos', favoritosRoutes);
app.use('/resenas', resenasRoutes);
app.use('/historial', historialRoutes);
app.use('/busqueda', busquedaRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor corriendo en http://localhost:${PORT}`);
});
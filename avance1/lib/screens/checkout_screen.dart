import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/pago_service.dart';
import '../services/pedido_service.dart';
import '../services/tipo_cambio_service.dart';

class CheckoutScreen extends StatefulWidget {
  final double total;
  final String provincia;

  const CheckoutScreen({
    super.key,
    required this.total,
    this.provincia = 'San Jose',
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Datos de envio
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();

  // Datos de tarjeta
  final _numeroTarjetaController = TextEditingController();
  final _vencimientoController = TextEditingController();
  final _cvvController = TextEditingController();

  // Dato de SINPE
  final _sinpeController = TextEditingController();

  String _metodoPago = 'Tarjeta';
  bool _procesando = false;
  String _marcaTarjeta = '';

  // Tipo de cambio del BCCR
  double? _tipoCambio;

  // Estado de PayPal
  String? _ordenPaypalId;
  bool _paypalAbierto = false;

  // Paleta
  final Color _cafe = const Color(0xFFB8956A);
  final Color _cafeOscuro = const Color(0xFF8a6840);
  final Color _crema = const Color(0xFFFAF6F0);
  final Color _texto = const Color(0xFF3d2f22);
  final Color _azulPaypal = const Color(0xFF003087);

  @override
  void initState() {
    super.initState();
    _cargarTipoCambio();
  }

  // Trae el tipo de cambio real del BCCR al abrir la pantalla
  Future<void> _cargarTipoCambio() async {
    try {
      final tc = await TipoCambioService.obtenerTipoCambio();
      setState(() => _tipoCambio = tc);
    } catch (_) {
      // si falla, usamos un aproximado
      setState(() => _tipoCambio = 500);
    }
  }

  // Monto en dolares segun el tipo de cambio del BCCR
  String get _montoUSD {
    final tc = _tipoCambio ?? 500;
    return (widget.total / tc).toStringAsFixed(2);
  }

  Future<void> _detectarMarca(String numero) async {
    final limpio = numero.replaceAll(' ', '');
    if (limpio.isNotEmpty) {
      try {
        final marca = await PagoService.detectarMarca(limpio);
        setState(() => _marcaTarjeta = marca);
      } catch (_) {
        setState(() => _marcaTarjeta = '');
      }
    } else {
      setState(() => _marcaTarjeta = '');
    }
  }

  // ── PAYPAL ──
  Future<void> _iniciarPaypal() async {
    if (!_validarEnvio()) return;
    setState(() => _procesando = true);
    try {
      final orden = await PagoService.crearOrdenPaypal(monto: widget.total);
      _ordenPaypalId = orden['ordenId'];
      final uri = Uri.parse(orden['linkAprobacion']);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        setState(() {
          _paypalAbierto = true;
          _procesando = false;
        });
      } catch (_) {
        setState(() => _procesando = false);
        _mostrarError('No se pudo abrir PayPal');
      }
    } catch (e) {
      setState(() => _procesando = false);
      _mostrarError('No se pudo iniciar el pago con PayPal');
    }
  }

  Future<void> _confirmarPaypal() async {
    if (_ordenPaypalId == null) return;
    setState(() => _procesando = true);
    try {
      final captura = await PagoService.capturarPaypal(ordenId: _ordenPaypalId!);
      if (captura['estado'] != 'COMPLETED') {
        setState(() => _procesando = false);
        _mostrarError('El pago de PayPal no se completo.');
        return;
      }
      final pedido = await PedidoService.crearPedido(
        direccionEnvio: _direccionController.text,
        metodoPago: 'PayPal',
        provincia: widget.provincia,
        notas: 'Cliente: ${_nombreController.text}, Tel: ${_telefonoController.text}',
      );
      setState(() => _procesando = false);
      if (mounted) _mostrarExito(pedido);
    } catch (e) {
      setState(() => _procesando = false);
      _mostrarError('No se pudo confirmar el pago de PayPal');
    }
  }

  bool _validarEnvio() {
    if (_nombreController.text.isEmpty ||
        _direccionController.text.isEmpty ||
        _telefonoController.text.isEmpty) {
      _mostrarError('Por favor completa los datos de envio');
      return false;
    }
    return true;
  }

  Future<void> _procesarPago() async {
    if (!_validarEnvio()) return;
    setState(() => _procesando = true);
    try {
      if (_metodoPago == 'Tarjeta') {
        final numero = _numeroTarjetaController.text.replaceAll(' ', '');
        if (numero.isEmpty || _vencimientoController.text.isEmpty || _cvvController.text.isEmpty) {
          setState(() => _procesando = false);
          _mostrarError('Completa los datos de la tarjeta');
          return;
        }
        final pago = await PagoService.pagarConTarjeta(
          numero: numero,
          vencimiento: _vencimientoController.text,
          cvv: _cvvController.text,
          monto: widget.total,
        );
        if (pago['aprobado'] != true) {
          setState(() => _procesando = false);
          _mostrarError(pago['motivo'] ?? 'Pago rechazado');
          return;
        }
      } else if (_metodoPago == 'SINPE Movil') {
        if (_sinpeController.text.isEmpty) {
          setState(() => _procesando = false);
          _mostrarError('Ingresa tu numero SINPE');
          return;
        }
        final pago = await PagoService.pagarConSinpe(
          telefono: _sinpeController.text,
          monto: widget.total,
        );
        if (pago['aprobado'] != true) {
          setState(() => _procesando = false);
          _mostrarError(pago['motivo'] ?? 'Pago SINPE rechazado');
          return;
        }
      }

      final pedido = await PedidoService.crearPedido(
        direccionEnvio: _direccionController.text,
        metodoPago: _metodoPago,
        provincia: widget.provincia,
        notas: 'Cliente: ${_nombreController.text}, Tel: ${_telefonoController.text}',
      );
      setState(() => _procesando = false);
      if (mounted) _mostrarExito(pedido);
    } catch (e) {
      setState(() => _procesando = false);
      _mostrarError('No se pudo completar la compra. Intenta de nuevo.');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(Map<String, dynamic> pedido) {
    final guia = pedido['numeroGuia'];
    final puntos = pedido['puntosGanados'];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _crema,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _cafe.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, color: _cafeOscuro, size: 50),
            ),
            const SizedBox(height: 16),
            Text('Pedido realizado!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _texto)),
            const SizedBox(height: 8),
            Text('Gracias ${_nombreController.text}, tu pedido fue recibido.',
                textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF7a6150))),
            const SizedBox(height: 12),
            Text('\u20a1${widget.total.toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: _cafeOscuro, fontSize: 24)),
            if (guia != null) ...[
              const SizedBox(height: 10),
              _chipInfo(Icons.local_shipping_outlined, 'Guia: $guia'),
            ],
            if (puntos != null) ...[
              const SizedBox(height: 6),
              _chipInfo(Icons.star_outline, 'Ganaste $puntos puntos'),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cafe,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Volver al inicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipInfo(IconData icono, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _cafe.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 15, color: _cafeOscuro),
          const SizedBox(width: 6),
          Text(texto, style: TextStyle(fontSize: 12, color: _cafeOscuro)),
        ],
      ),
    );
  }

  InputDecoration _decoracion(String label, IconData icono, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffix,
      labelStyle: const TextStyle(color: Color(0xFF9a8672)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE3D5C3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _cafe, width: 2),
      ),
      prefixIcon: Icon(icono, color: _cafe, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _crema,
      appBar: AppBar(
        title: const Text('Finalizar compra',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: _cafe,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card del total
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_cafe, _cafeOscuro],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: _cafe.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total a pagar',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('\u20a1${widget.total.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  if (_tipoCambio != null)
                    Text('\u2248 \$$_montoUSD USD  (BCCR \u20a1${_tipoCambio!.toStringAsFixed(2)})',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _tituloSeccion('Datos de envio', Icons.local_shipping_outlined),
            const SizedBox(height: 14),
            TextField(controller: _nombreController, decoration: _decoracion('Nombre completo *', Icons.person_outline)),
            const SizedBox(height: 12),
            TextField(controller: _telefonoController, keyboardType: TextInputType.phone, decoration: _decoracion('Telefono *', Icons.phone_outlined)),
            const SizedBox(height: 12),
            TextField(controller: _direccionController, maxLines: 2, decoration: _decoracion('Direccion de envio *', Icons.location_on_outlined)),

            const SizedBox(height: 24),
            _tituloSeccion('Metodo de pago', Icons.payments_outlined),
            const SizedBox(height: 14),

            // Selector de metodos con iconos (fila de 4)
            Row(
              children: [
                _tarjetaMetodo('Tarjeta', Icons.credit_card),
                const SizedBox(width: 8),
                _tarjetaMetodo('SINPE Movil', Icons.smartphone, label: 'SINPE'),
                const SizedBox(width: 8),
                _tarjetaMetodo('PayPal', Icons.account_balance_wallet),
                const SizedBox(width: 8),
                _tarjetaMetodo('Efectivo', Icons.attach_money),
              ],
            ),

            const SizedBox(height: 18),

            // Contenido segun metodo
            if (_metodoPago == 'Tarjeta') _camposTarjeta(),
            if (_metodoPago == 'SINPE Movil') _campoSinpe(),
            if (_metodoPago == 'PayPal') _seccionPaypal(),
            if (_metodoPago == 'Efectivo') _seccionEfectivo(),

            const SizedBox(height: 24),
            _botonPrincipal(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _tituloSeccion(String texto, IconData icono) {
    return Row(
      children: [
        Icon(icono, color: _cafeOscuro, size: 20),
        const SizedBox(width: 8),
        Text(texto, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _texto)),
      ],
    );
  }

  // Tarjetita de metodo de pago (con icono)
  Widget _tarjetaMetodo(String metodo, IconData icono, {String? label}) {
    final seleccionado = _metodoPago == metodo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _metodoPago = metodo;
          _paypalAbierto = false;
          _ordenPaypalId = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: seleccionado ? _cafe : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: seleccionado ? _cafe : const Color(0xFFE3D5C3)),
            boxShadow: seleccionado
                ? [BoxShadow(color: _cafe.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                : [],
          ),
          child: Column(
            children: [
              Icon(icono, color: seleccionado ? Colors.white : _cafe, size: 24),
              const SizedBox(height: 6),
              Text(
                label ?? metodo,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: seleccionado ? Colors.white : _texto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _camposTarjeta() {
    final esVisa = _marcaTarjeta == 'Visa';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3D5C3)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _numeroTarjetaController,
            keyboardType: TextInputType.number,
            onChanged: _detectarMarca,
            decoration: _decoracion(
              'Numero de tarjeta',
              Icons.credit_card,
              suffix: _marcaTarjeta.isNotEmpty && _marcaTarjeta != 'Desconocida'
                  ? Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: esVisa ? Colors.blue[50] : Colors.deepOrange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_marcaTarjeta,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: esVisa ? Colors.blue[800] : Colors.deepOrange)),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _vencimientoController, decoration: _decoracion('MM/AA', Icons.calendar_today_outlined))),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: _decoracion('CVV', Icons.lock_outline).copyWith(counterText: ''),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _campoSinpe() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3D5C3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.smartphone, color: _cafe, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Ingresa el numero asociado a tu SINPE Movil',
                    style: TextStyle(fontSize: 12, color: _texto)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sinpeController,
            keyboardType: TextInputType.phone,
            maxLength: 8,
            decoration: _decoracion('Numero SINPE (8 digitos)', Icons.phone_android).copyWith(counterText: ''),
          ),
        ],
      ),
    );
  }

  // Seccion PayPal con tipo de cambio del BCCR
  Widget _seccionPaypal() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _azulPaypal.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet, color: _azulPaypal, size: 30),
          const SizedBox(height: 8),
          Text('Pagar con PayPal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _azulPaypal)),
          const SizedBox(height: 6),
          const Text(
            'Al tocar "Pagar con PayPal" se abrira PayPal en tu navegador para que apruebes el pago de forma segura.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF5a6b82)),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Tipo de cambio BCCR
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tipo de cambio (BCCR)', style: TextStyle(fontSize: 13, color: Color(0xFF5a6b82))),
              Text(
                _tipoCambio != null ? '\u20a1${_tipoCambio!.toStringAsFixed(2)} / USD' : '...',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _azulPaypal),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pagaras en PayPal', style: TextStyle(fontSize: 13, color: Color(0xFF5a6b82))),
              Text('\$$_montoUSD USD',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _azulPaypal)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Tipo de cambio oficial del Banco Central de Costa Rica',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Color(0xFF8a97a8), fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _seccionEfectivo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3D5C3)),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_money, color: _cafe, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Pagaras en efectivo al momento de recibir tu pedido.',
                style: TextStyle(fontSize: 13, color: _texto)),
          ),
        ],
      ),
    );
  }

  Widget _botonPrincipal() {
    if (_metodoPago == 'PayPal') {
      if (!_paypalAbierto) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _procesando ? null : _iniciarPaypal,
            icon: _procesando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.account_balance_wallet),
            label: const Text('Pagar con PayPal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _azulPaypal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        );
      } else {
        return Column(
          children: [
            const Text('Aproba el pago en la ventana de PayPal y luego confirma aqui.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF7a6150))),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _procesando ? null : _confirmarPaypal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cafe,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _procesando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Ya pague, confirmar pedido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      }
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _procesando ? null : _procesarPago,
        style: ElevatedButton.styleFrom(
          backgroundColor: _cafe,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _procesando
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Confirmar pedido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _numeroTarjetaController.dispose();
    _vencimientoController.dispose();
    _cvvController.dispose();
    _sinpeController.dispose();
    super.dispose();
  }
}
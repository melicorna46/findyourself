import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../models/categoria.dart';
import '../services/producto_service.dart';
import '../services/busqueda_service.dart';
import '../widgets/product_card.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  List<Producto> _productos = [];
  List<Categoria> _categorias = [];
  int? _categoriaSeleccionada;
  bool _cargando = true;

  final _busquedaController = TextEditingController();
  RangeValues _rangoPrecio = const RangeValues(0, 10000);
  bool _filtrosVisibles = false;

  final Color _cafe = const Color(0xFFB8956A);
  final Color _cafeOscuro = const Color(0xFF8a6840);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final productos = await ProductoService.obtenerTodos();
      final categorias = await ProductoService.obtenerCategorias();
      if (mounted) {
        setState(() {
          _productos = productos;
          _categorias = categorias;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Aplica busqueda + filtros llamando al API /busqueda
  Future<void> _buscar() async {
    setState(() => _cargando = true);
    try {
      final resultados = await BusquedaService.buscar(
        texto: _busquedaController.text,
        precioMin: _rangoPrecio.start > 0 ? _rangoPrecio.start : null,
        precioMax: _rangoPrecio.end < 10000 ? _rangoPrecio.end : null,
        categoria: _categoriaSeleccionada,
      );
      if (mounted) {
        setState(() {
          _productos = resultados;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _limpiarFiltros() async {
    _busquedaController.clear();
    setState(() {
      _rangoPrecio = const RangeValues(0, 10000);
      _categoriaSeleccionada = null;
    });
    await _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: const Text('Catalogo',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: _cafe,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_filtrosVisibles ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _filtrosVisibles = !_filtrosVisibles),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de busqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _busquedaController,
              onSubmitted: (_) => _buscar(),
              decoration: InputDecoration(
                hintText: 'Buscar joyas...',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.search, color: _cafe),
                suffixIcon: IconButton(
                  icon: Icon(Icons.arrow_forward, color: _cafe),
                  onPressed: _buscar,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE3D5C3)),
                ),
              ),
            ),
          ),

          // Panel de filtros (se muestra/oculta)
          if (_filtrosVisibles)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE3D5C3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rango de precio: \u20a1${_rangoPrecio.start.toInt()} - \u20a1${_rangoPrecio.end.toInt()}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _cafeOscuro, fontSize: 13)),
                  RangeSlider(
                    values: _rangoPrecio,
                    min: 0,
                    max: 10000,
                    divisions: 20,
                    activeColor: _cafe,
                    labels: RangeLabels(
                      '\u20a1${_rangoPrecio.start.toInt()}',
                      '\u20a1${_rangoPrecio.end.toInt()}',
                    ),
                    onChanged: (values) => setState(() => _rangoPrecio = values),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _buscar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cafe,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Aplicar filtros'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _limpiarFiltros,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _cafeOscuro,
                          side: BorderSide(color: _cafe),
                        ),
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Chips de categoria
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Todas'),
                    selected: _categoriaSeleccionada == null,
                    selectedColor: const Color(0xFFD4B896),
                    checkmarkColor: _cafeOscuro,
                    onSelected: (_) {
                      setState(() => _categoriaSeleccionada = null);
                      _buscar();
                    },
                  ),
                ),
                ..._categorias.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat.nombre),
                        selected: _categoriaSeleccionada == cat.id,
                        selectedColor: const Color(0xFFD4B896),
                        checkmarkColor: _cafeOscuro,
                        onSelected: (_) {
                          setState(() => _categoriaSeleccionada = cat.id);
                          _buscar();
                        },
                      ),
                    )),
              ],
            ),
          ),

          // Resultados
          Expanded(
            child: _cargando
                ? Center(child: CircularProgressIndicator(color: _cafe))
                : _productos.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.black26),
                            SizedBox(height: 12),
                            Text('No se encontraron joyas',
                                style: TextStyle(color: Color(0xFF7a6150))),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _productos.length,
                        itemBuilder: (context, index) {
                          return ProductCard(producto: _productos[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }
}
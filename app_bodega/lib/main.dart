import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'api_service.dart';
import 'product_model.dart';
import 'calc_screen.dart';

void main() {
  initializeDateFormatting('es_ES', null).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bodega Ponciano',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const ProductListScreen(),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  // Lista original de la API
  List<Product> _allProducts = [];
  // Lista filtrada para búsquedas
  List<Product> _filteredProducts = [];

  double _tasa = 0.0;
  bool _loading = true;
  String _errorMessage = ''; // Para mostrar errores en pantalla
  String _searchQuery = '';
  final ApiService _apiService = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      // Intentamos cargar la tasa primero (sin bloquear si falla)
      try {
        _tasa = await _apiService.getTasa();
      } catch (e) {
        print("Error cargando tasa: $e");
        _tasa = 0.0;
      }

      // Ahora cargamos los productos
      List<Product> rawProducts = await _apiService.getProducts();

      // Procesar productos (desglosar paquetes si es necesario)
      List<Product> processed = [];

      // Fix manual anterior: el 'push' no existe en dart Lists, es 'add'.
      // Re-implemented logic correctly below:

      processed = [];
      for (var p in rawProducts) {
        // 1. Unidad
        processed.add(
          Product(
            id: p.id, // Original ID
            nombre: p.nombre,
            descripcion: p.descripcion,
            unidadMedida: 'unidad',
            precioVenta: p.precioReal,
            precioCompra: p.precioCompra,
            monedaCompra: p.monedaCompra,
            qty: 0,
          ),
        );

        // 2. Paquete (si aplica)
        if (p.isPaquete &&
            p.precioVentaPaquete != null &&
            p.precioVentaPaquete! > 0) {
          processed.add(
            Product(
              id: -p.id, // ID negativo para diferenciar
              nombre: '${p.nombre} (Paquete)',
              descripcion: p.descripcion,
              unidadMedida: 'paquete',
              precioVenta: p.precioVentaPaquete,
              precioCompra: p.precioCompra,
              monedaCompra: p.monedaCompra,
              qty: 0,
            ),
          );
        }
      }

      setState(() {
        _allProducts = processed;
        _filteredProducts = processed;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Error conectando: $e';
        });
      }
    }
  }

  void _filter(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        final lower = query.toLowerCase();
        _filteredProducts = _allProducts
            .where((p) => p.nombre.toLowerCase().contains(lower))
            .toList();
      }
    });
  }

  // Calcular Total en la moneda principal
  double get _totalBs {
    double total = 0;
    for (var p in _allProducts) {
      if (p.qty > 0) {
        double precio = p.precioVenta ?? 0;
        bool esDolar = (p.monedaCompra != 'BS');
        double precioEnBs = esDolar ? (precio * _tasa) : precio;
        total += precioEnBs * p.qty;
      }
    }
    return total;
  }

  double get _totalUsd {
    if (_tasa == 0) return 0;
    return _totalBs / _tasa;
  }

  int get _totalItems => _allProducts.fold(0, (sum, item) => sum + item.qty);

  void _showTicket() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Recalculamos la lista de seleccionados en cada renderizado del modal
            List<Product> selected = _allProducts
                .where((p) => p.qty > 0)
                .toList();

            // Si no quedan items, podríamos cerrar el modal o mostrar aviso vacío
            if (selected.isEmpty) {
              // Opcional: Cerrar automáticamente si se vacía
              Future.microtask(() => Navigator.pop(context));
              return const SizedBox();
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          'Detalle de Cuenta',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: selected.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final p = selected[index];
                        double precio = p.precioVenta ?? 0;
                        bool esDolar = p.monedaCompra != 'BS';
                        double precioBs = esDolar ? precio * _tasa : precio;
                        double subtotalBs = precioBs * p.qty;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            p.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${p.qty} x ${precioBs.toStringAsFixed(2)} Bs',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${subtotalBs.toStringAsFixed(2)} Bs',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  // 1. Eliminar item (qty = 0)
                                  p.qty = 0;

                                  // 2. Actualizar Modal (setModalState)
                                  setModalState(() {});

                                  // 3. Actualizar Pantalla Principal (setState global)
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(thickness: 2),
                  // Envolvemos la parte inferior en SafeArea
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Ajustar al contenido
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL BS:',
                                style: TextStyle(fontSize: 18),
                              ),
                              Text(
                                '${_totalBs.toStringAsFixed(2)} Bs',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL USD:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '${_totalUsd.toStringAsFixed(2)} \$',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Cerrar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header con Tasa y Buscador
          Container(
            padding: const EdgeInsets.only(
              top: 40,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bodega Ponciano',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CalcScreen(tasa: _tasa > 0 ? _tasa : 0.0),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.currency_exchange,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Tasa: ${_tasa.toStringAsFixed(2)} Bs',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  onChanged: _filter,
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ],
            ),
          ),

          // Lista de Productos
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            size: 60,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error de conexión',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      bottom: 100,
                    ), // Espacio para el banner inferior
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = _filteredProducts[index];
                      double precio = p.precioVenta ?? 0;
                      bool esDolar = p.monedaCompra != 'BS';

                      String precioStr = '';
                      if (esDolar) {
                        precioStr =
                            '${precio.toStringAsFixed(2)} \$ (${(precio * _tasa).toStringAsFixed(2)} Bs)';
                      } else {
                        precioStr = '${precio.toStringAsFixed(2)} Bs';
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.nombre,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      precioStr,
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Controles + / -
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        if (p.qty > 0) {
                                          setState(() => p.qty--);
                                        }
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 30,
                                      child: Text(
                                        p.qty.toString(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add,
                                        size: 18,
                                        color: Colors.green,
                                      ),
                                      onPressed: () {
                                        setState(() => p.qty++);
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: Colors.white, // Fondo blanco para cubrir detrás en zonas seguras
        child: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              // Eliminamos sombra superior conflictiva o la hacemos sutil
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            child: InkWell(
              onTap: _showTicket,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_cart, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          '${_totalItems} Items',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Total: ${_totalBs.toStringAsFixed(2)} Bs',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

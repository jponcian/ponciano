import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'product_model.dart';
import 'api_service.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late TextEditingController _nombreCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _unidadMedidaCtrl;
  late TextEditingController _precioCompraCtrl;
  late TextEditingController _precioVentaCtrl;
  late TextEditingController _proveedorCtrl;
  late TextEditingController _stockBajoCtrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.product?.nombre ?? '');
    _descCtrl = TextEditingController(text: widget.product?.descripcion ?? '');
    _unidadMedidaCtrl = TextEditingController(
      text: widget.product?.unidadMedida ?? 'unidad',
    );
    _precioCompraCtrl = TextEditingController(
      text: widget.product?.precioCompra?.toString() ?? '',
    );
    _precioVentaCtrl = TextEditingController(
      text: widget.product?.precioVenta?.toString() ?? '',
    );
    _proveedorCtrl = TextEditingController(
      text: '',
    ); // Proveedor por defecto o cargar
    _stockBajoCtrl = TextEditingController(
      text: widget.product?.bajoInventario?.toString() ?? '5',
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _unidadMedidaCtrl.dispose();
    _precioCompraCtrl.dispose();
    _precioVentaCtrl.dispose();
    _proveedorCtrl.dispose();
    _stockBajoCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Map<String, dynamic> data = {
      'nombre': _nombreCtrl.text,
      'descripcion': _descCtrl.text,
      'unidad_medida': _unidadMedidaCtrl.text,
      'tam_paquete': 1, // Default por simplicidad
      'precio_compra': double.tryParse(_precioCompraCtrl.text) ?? 0.0,
      'precio_venta': double.tryParse(_precioVentaCtrl.text) ?? 0.0,
      'proveedor': _proveedorCtrl.text.isEmpty
          ? 'General'
          : _proveedorCtrl.text,
      'bajo_inventario': int.tryParse(_stockBajoCtrl.text) ?? 5,
      // Campos requeridos por tu backend
      'moneda_compra': 'USD',
      'vende_media': 0,
      'precio_venta_paquete': 0,
      'precio_venta_mediopaquete': 0,
      'precio_venta_unidad': 0,
    };

    bool success;
    if (widget.product == null) {
      success = await _apiService.createProduct(data);
    } else {
      success = await _apiService.updateProduct(widget.product!.id, data);
    }

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Guardado correctamente')));
        Navigator.pop(context, true); // Retornar true para refrescar
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error al guardar')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Nuevo Producto' : 'Editar Producto',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Producto',
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precioCompraCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Precio Compra',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _precioVentaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Precio Venta',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _stockBajoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alerta Stock Bajo',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('GUARDAR', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

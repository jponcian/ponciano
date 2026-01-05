class Product {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? unidadMedida;
  final double? precioVenta;
  final double? precioCompra;
  final int? bajoInventario;

  final double? precioVentaPaquete;
  final double? precioVentaUnidad;
  final String? monedaCompra;

  // Campo local para la app (no viene de API directamente, o se inicializa en 0)
  int qty = 0;

  Product({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.unidadMedida,
    this.precioVenta,
    this.precioCompra,
    this.bajoInventario,
    this.precioVentaPaquete,
    this.precioVentaUnidad,
    this.monedaCompra,
    this.qty = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      unidadMedida: json['unidad_medida'],
      precioVenta: double.tryParse(json['precio_venta'].toString()),
      precioCompra: double.tryParse(json['precio_compra'].toString()),
      bajoInventario: int.tryParse(json['bajo_inventario'].toString()),
      precioVentaPaquete: double.tryParse(
        json['precio_venta_paquete'].toString(),
      ),
      precioVentaUnidad: double.tryParse(
        json['precio_venta_unidad'].toString(),
      ),
      monedaCompra: json['moneda_compra'],
    );
  }

  // Helpers para lógica de negocio
  bool get isPaquete => unidadMedida == 'paquete';

  double get precioReal {
    // Prioridad: Unitario > Venta normal
    if (precioVentaUnidad != null && precioVentaUnidad! > 0)
      return precioVentaUnidad!;
    return precioVenta ?? 0.0;
  }
}

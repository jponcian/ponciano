import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // import para kIsWeb
import 'product_model.dart';

class ApiService {
  // Configuración de URL base
  static String get baseUrl {
    // A petición del usuario: Usar SIEMPRE producción, incluso en Web (Chrome)
    // Nota: Esto requiere que el servidor de producción tenga habilitado CORS.
    return 'https://ponciano.zz.com.ve/bodega/api';

    /* 
    Configuración anterior:
    if (kIsWeb) {
      return 'http://localhost/ponciano/bodega/api';
    } else {
      return 'https://ponciano.zz.com.ve/bodega/api';
    }
    */
  }

  // Obtener tasa de cambio
  Future<double> getTasa() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tasa.php'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          return double.tryParse(data['valor'].toString()) ?? 0.0;
        }
      }
      return 0.0;
    } catch (e) {
      print('Error obteniendo tasa: $e');
      return 0.0;
    }
  }

  // Obtener todos los productos
  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/ver.php'));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<Product> products = body
            .map((dynamic item) => Product.fromJson(item))
            .toList();
        return products;
      } else {
        throw Exception('Fallo al cargar productos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener producto único
  Future<Product> getProduct(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/ver.php?id=$id'));
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('No se encontró el producto');
    }
  }

  // Crear producto
  Future<bool> createProduct(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/crear.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['ok'] ?? false;
    }
    return false;
  }

  // Actualizar producto
  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    data['id'] = id; // Asegurar que el ID vaya en el body
    final response = await http.post(
      Uri.parse('$baseUrl/editar.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['ok'] ?? false;
    }
    return false;
  }

  // Eliminar producto
  Future<bool> deleteProduct(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/eliminar.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id}),
    );
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['ok'] ?? false;
    }
    return false;
  }
}

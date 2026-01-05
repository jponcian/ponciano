import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalcScreen extends StatefulWidget {
  final double tasa;

  const CalcScreen({super.key, required this.tasa});

  @override
  State<CalcScreen> createState() => _CalcScreenState();
}

class _CalcScreenState extends State<CalcScreen> {
  late TextEditingController _usdCtrl;
  late TextEditingController _bsCtrl;

  // Formato para mostrar hasta 2 decimales limpiamente
  final NumberFormat _fmt = NumberFormat('##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _usdCtrl = TextEditingController(text: '1.00');
    _bsCtrl = TextEditingController(text: widget.tasa.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _usdCtrl.dispose();
    _bsCtrl.dispose();
    super.dispose();
  }

  void _onUsdChanged(String value) {
    if (value.isEmpty) {
      _bsCtrl.text = '';
      return;
    }
    double? usd = double.tryParse(value);
    if (usd != null) {
      double bs = usd * widget.tasa;
      // Actualizamos Bs sin disparar su listener (evitar bucle infinito si usáramos listeners directos)
      // Como usamos onChanged, es seguro actualizar el texto del OTRO controlador.
      // Pero para evitar conflicto de cursor, es mejor si el usuario está escribiendo aquí.
      _bsCtrl.text = bs.toStringAsFixed(2);
    }
  }

  void _onBsChanged(String value) {
    if (value.isEmpty) {
      _usdCtrl.text = '';
      return;
    }
    double? bs = double.tryParse(value);
    if (bs != null && widget.tasa > 0) {
      double usd = bs / widget.tasa;
      _usdCtrl.text = usd.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fecha actual formateada
    String fechaHoy = DateFormat(
      'EEEE, dd/MM/yyyy',
      'es_ES',
    ).format(DateTime.now());
    // Capitalizar primera letra
    fechaHoy = fechaHoy[0].toUpperCase() + fechaHoy.substring(1);

    return Scaffold(
      backgroundColor: Colors.white, // O Color(0xFF1E1E1E) para dark mode
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Calculadora Rápida',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Logo o Título Visual
            const Icon(Icons.currency_exchange, size: 60, color: Colors.blue),
            const SizedBox(height: 10),
            const Text(
              'Tasa del Día',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              '1 USD = ${widget.tasa.toStringAsFixed(2)} BS',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 40),

            // Card Principal de Cálculo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C), // Fondo oscuro estilo la foto
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Chip de Título
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A), // Verde brillante
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Dólar BCV',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Input USD
                  TextField(
                    controller: _usdCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                    onChanged: _onUsdChanged,
                    decoration: const InputDecoration(
                      prefixText: '\$   ',
                      prefixStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Input BS
                  TextField(
                    controller: _bsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                    onChanged: _onBsChanged,
                    decoration: const InputDecoration(
                      prefixText: 'Bs   ',
                      prefixStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Flechas indicadoras visuales
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_upward, color: Color(0xFF66BB6A)),
                      SizedBox(width: 10),
                      Text(
                        "Conversión Automática",
                        style: TextStyle(color: Color(0xFF66BB6A)),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_downward, color: Color(0xFF66BB6A)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Card de Fecha
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    fechaHoy,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

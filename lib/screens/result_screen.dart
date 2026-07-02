import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../domain/entities/recognition_result.dart';
import 'product_detail_screen.dart';

class ResultScreen extends StatelessWidget {
  final RecognitionResult resultado;
  final Uint8List fotoEscaneada;

  const ResultScreen({
    super.key,
    required this.resultado,
    required this.fotoEscaneada,
  });

  @override
  Widget build(BuildContext context) {
    switch (resultado.status) {
      case RecognitionStatus.matchUnico:
        // Navegamos directo a la ficha tecnica, como pide el flujo:
        // "la IA reconoce el modelo -> aparece automaticamente la info".
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                product: resultado.mejor!.product,
                similitud: resultado.mejor!.similitud,
              ),
            ),
          );
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case RecognitionStatus.variosCandidatos:
        return _CandidatosScreen(resultado: resultado, foto: fotoEscaneada);

      case RecognitionStatus.noIdentificado:
        return _NoIdentificadoScreen(resultado: resultado, foto: fotoEscaneada);
    }
  }
}

class _CandidatosScreen extends StatelessWidget {
  final RecognitionResult resultado;
  final Uint8List foto;

  const _CandidatosScreen({required this.resultado, required this.foto});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Posibles coincidencias')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'No encontramos una coincidencia exacta. '
            'Elige el modelo correcto:',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ...resultado.candidatos.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        c.product.imagenPortada,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      c.product.modelo,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${c.product.color} · ${c.porcentaje.toStringAsFixed(0)}% similitud'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(
                          product: c.product,
                          similitud: c.similitud,
                        ),
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _NoIdentificadoScreen extends StatelessWidget {
  final RecognitionResult resultado;
  final Uint8List foto;

  const _NoIdentificadoScreen({required this.resultado, required this.foto});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sin identificar')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 20),
            Text(
              'No pudimos identificar este producto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con mejor luz, mas cerca del calzado, '
              'o desde otro angulo.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}

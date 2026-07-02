import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/recognition_service.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Construye el indice de reconocimiento apenas abre la app,
    // asi el primer escaneo del usuario ya es instantaneo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecognitionService>().buildIndex();
    });
  }

  @override
  Widget build(BuildContext context) {
    final recognition = context.watch<RecognitionService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text(
                'TRIA',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Scan AI',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -1,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Apunta la camara a un calzado y obten\n'
                'su ficha tecnica al instante.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 3),
              _EstadoIndice(recognition: recognition),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: recognition.indexReady
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ScannerScreen(),
                          ),
                        )
                    : null,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Escanear'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoIndice extends StatelessWidget {
  final RecognitionService recognition;
  const _EstadoIndice({required this.recognition});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (recognition.isIndexing) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Preparando catalogo...',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      );
    }

    if (recognition.indexError != null) {
      return Text(
        recognition.indexError!,
        style: TextStyle(color: colorScheme.error, fontSize: 13),
      );
    }

    if (recognition.indexReady) {
      return Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '${recognition.totalProductosIndexados} modelos listos para reconocer',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/recognition_service.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecognitionService>().buildIndex();
    });
  }

  Future<void> _escanear() async {
    if (_procesando) return;
    setState(() => _procesando = true);

    try {
      final picker = ImagePicker();
      final XFile? foto = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (foto == null) {
        return;
      }

      final bytes = await foto.readAsBytes();

      if (!mounted) return;
      final recognition = context.read<RecognitionService>();
      final resultado = await recognition.identify(bytes);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(resultado: resultado, fotoEscaneada: bytes),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo procesar la foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
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
                onPressed: (recognition.indexReady && !_procesando) ? _escanear : null,
                icon: _procesando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.camera_alt_outlined),
                label: Text(_procesando ? 'Procesando...' : 'Escanear'),
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

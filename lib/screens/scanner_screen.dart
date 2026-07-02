import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/recognition_service.dart';
import 'result_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _abrirCamaraYReconocer());
  }

  Future<void> _abrirCamaraYReconocer() async {
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
        if (mounted) Navigator.of(context).pop();
        return;
      }

      final bytes = await foto.readAsBytes();

      if (!mounted) return;
      final recognition = context.read<RecognitionService>();
      final resultado = await recognition.identify(bytes);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultScreen(resultado: resultado, fotoEscaneada: bytes),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo procesar la foto: $e')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

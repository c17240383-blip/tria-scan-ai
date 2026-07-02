import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// ---------------------------------------------------------------------
/// EmbeddingService
/// ---------------------------------------------------------------------
/// Genera el "embedding visual" (huella digital numerica) de una foto de
/// calzado, para poder compararla contra el catalogo por similitud.
///
/// NOTA PARA EL EQUIPO DE DESARROLLO:
/// En produccion este servicio se reemplaza por un modelo de deep
/// learning on-device (TFLite: MobileCLIP / EfficientNet-Lite), tal
/// como se definio en el documento de arquitectura. Aqui se usa un
/// descriptor de vision clasica (cuadricula de color promedio) porque
/// es liviano, no requiere descargar pesos de un modelo, y ya demostramos
/// en la prueba piloto en Python que el mismo enfoque conceptual
/// funciona. Migrar a un modelo real significa reemplazar SOLO el
/// metodo `extractEmbedding` de esta clase; el resto del sistema
/// (indexado, comparacion, umbrales) no cambia.
class EmbeddingService {
  static const int gridSize = 10; // cuadricula de 10x10 celdas
  static const int targetSize = 200; // la imagen se normaliza a 200x200

  /// Genera el vector de embedding (normalizado L2) a partir de bytes
  /// de imagen (jpg/png), como los que entrega la camara o un asset.
  List<double> extractEmbeddingFromBytes(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('No se pudo decodificar la imagen.');
    }
    return _extractFromImage(decoded);
  }

  /// Genera el embedding a partir de un archivo en disco (foto capturada
  /// por la camara).
  Future<List<double>> extractEmbeddingFromFile(File file) async {
    final bytes = await file.readAsBytes();
    return extractEmbeddingFromBytes(bytes);
  }

  List<double> _extractFromImage(img.Image original) {
    final resized = img.copyResize(
      original,
      width: targetSize,
      height: targetSize,
      interpolation: img.Interpolation.average,
    );

    final cellSize = targetSize ~/ gridSize;
    final vector = <double>[];

    for (int gy = 0; gy < gridSize; gy++) {
      for (int gx = 0; gx < gridSize; gx++) {
        double sumR = 0, sumG = 0, sumB = 0;
        int count = 0;

        for (int y = gy * cellSize; y < (gy + 1) * cellSize; y++) {
          for (int x = gx * cellSize; x < (gx + 1) * cellSize; x++) {
            final pixel = resized.getPixel(x, y);
            sumR += pixel.r;
            sumG += pixel.g;
            sumB += pixel.b;
            count++;
          }
        }

        // Promedio de color de la celda, normalizado a [0, 1]
        vector.add((sumR / count) / 255.0);
        vector.add((sumG / count) / 255.0);
        vector.add((sumB / count) / 255.0);
      }
    }

    return _l2Normalize(vector);
  }

  List<double> _l2Normalize(List<double> vector) {
    double normSq = 0;
    for (final v in vector) {
      normSq += v * v;
    }
    final norm = math.sqrt(normSq);
    if (norm == 0) return vector;
    return vector.map((v) => v / norm).toList();
  }

  /// Similitud coseno entre dos vectores ya normalizados (producto punto).
  double cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0;
    final len = math.min(a.length, b.length);
    for (int i = 0; i < len; i++) {
      dot += a[i] * b[i];
    }
    return dot;
  }
}

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../domain/entities/product.dart';
import '../domain/entities/recognition_result.dart';
import 'catalog_repository.dart';
import 'embedding_service.dart';

/// Una foto indexada: su embedding y a que producto pertenece.
class _IndexedPhoto {
  final Product product;
  final List<double> embedding;
  _IndexedPhoto(this.product, this.embedding);
}

/// ---------------------------------------------------------------------
/// RecognitionService
/// ---------------------------------------------------------------------
/// Indexa TODAS las fotos de cada producto (no solo una), y al buscar
/// toma la MEJOR coincidencia entre todas las fotos de cada producto.
/// Esto hace que el reconocimiento funcione sin importar el angulo
/// desde el que se tome la foto de escaneo.
class RecognitionService extends ChangeNotifier {
  final CatalogRepository _catalogRepository;
  final EmbeddingService _embeddingService;

  static const double umbralAlto = 0.90;
  static const double umbralMedio = 0.75;
  static const double ventajaMinimaParaMatchUnico = 0.02;

  bool isIndexing = false;
  bool indexReady = false;
  String? indexError;

  final List<_IndexedPhoto> _index = [];

  RecognitionService({
    CatalogRepository? catalogRepository,
    EmbeddingService? embeddingService,
  })  : _catalogRepository = catalogRepository ?? CatalogRepository(),
        _embeddingService = embeddingService ?? EmbeddingService();

  Future<void> buildIndex() async {
    if (indexReady || isIndexing) return;

    isIndexing = true;
    indexError = null;
    notifyListeners();

    try {
      final products = await _catalogRepository.loadCatalog();

      for (final product in products) {
        for (final imagenAsset in product.imagenesAssets) {
          final bytes = await rootBundle.load(imagenAsset);
          final embedding = _embeddingService
              .extractEmbeddingFromBytes(bytes.buffer.asUint8List());
          _index.add(_IndexedPhoto(product, embedding));
        }
      }

      indexReady = true;
    } catch (e) {
      indexError = 'No se pudo construir el indice: $e';
    } finally {
      isIndexing = false;
      notifyListeners();
    }
  }

  Future<RecognitionResult> identify(Uint8List scanBytes) async {
    if (!indexReady) {
      throw StateError('El indice todavia no esta listo.');
    }

    final queryEmbedding = _embeddingService.extractEmbeddingFromBytes(scanBytes);

    // Similitud maxima entre TODAS las fotos de cada producto.
    final Map<String, double> mejorSimilitudPorProducto = {};
    final Map<String, Product> productosPorId = {};

    for (final foto in _index) {
      final sim = _embeddingService.cosineSimilarity(queryEmbedding, foto.embedding);
      final actual = mejorSimilitudPorProducto[foto.product.id];
      if (actual == null || sim > actual) {
        mejorSimilitudPorProducto[foto.product.id] = sim;
      }
      productosPorId[foto.product.id] = foto.product;
    }

    final scored = mejorSimilitudPorProducto.entries
        .map((e) => ScoredCandidate(product: productosPorId[e.key]!, similitud: e.value))
        .toList()
      ..sort((a, b) => b.similitud.compareTo(a.similitud));

    if (scored.isEmpty || scored.first.similitud < umbralMedio) {
      return RecognitionResult(
        status: RecognitionStatus.noIdentificado,
        candidatos: scored.take(5).toList(),
      );
    }

    final hayVentajaClara = scored.length == 1 ||
        (scored[0].similitud >= umbralAlto &&
            scored[0].similitud - scored[1].similitud >= ventajaMinimaParaMatchUnico);

    if (hayVentajaClara) {
      return RecognitionResult(
        status: RecognitionStatus.matchUnico,
        candidatos: scored.take(5).toList(),
      );
    }

    return RecognitionResult(
      status: RecognitionStatus.variosCandidatos,
      candidatos: scored.take(5).toList(),
    );
  }

  int get totalProductosIndexados {
    final ids = _index.map((e) => e.product.id).toSet();
    return ids.length;
  }
}

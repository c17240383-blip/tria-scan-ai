import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../domain/entities/product.dart';
import '../domain/entities/recognition_result.dart';
import 'catalog_repository.dart';
import 'embedding_service.dart';

class _IndexedProduct {
  final Product product;
  final List<double> embedding;
  _IndexedProduct(this.product, this.embedding);
}

class RecognitionService extends ChangeNotifier {
  final CatalogRepository _catalogRepository;
  final EmbeddingService _embeddingService;

  static const double umbralAlto = 0.90;
  static const double umbralMedio = 0.75;
  static const double ventajaMinimaParaMatchUnico = 0.02;

  bool isIndexing = false;
  bool indexReady = false;
  String? indexError;

  final List<_IndexedProduct> _index = [];

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
        final bytes = await rootBundle.load(product.imagenAsset);
        final embedding = _embeddingService
            .extractEmbeddingFromBytes(bytes.buffer.asUint8List());
        _index.add(_IndexedProduct(product, embedding));
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

    final scored = _index
        .map((entry) => ScoredCandidate(
              product: entry.product,
              similitud:
                  _embeddingService.cosineSimilarity(queryEmbedding, entry.embedding),
            ))
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

  int get totalProductosIndexados => _index.length;
}

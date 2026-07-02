import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../domain/entities/product.dart';
import '../domain/entities/recognition_result.dart';
import 'catalog_repository.dart';
import 'embedding_service.dart';

/// Entrada del indice: un producto ya con su embedding calculado.
class _IndexedProduct {
  final Product product;
  final List<double> embedding;
  _IndexedProduct(this.product, this.embedding);
}

/// ---------------------------------------------------------------------
/// RecognitionService
/// ---------------------------------------------------------------------
/// Orquesta el pipeline completo:
///   1. Indexacion offline (una vez, al abrir la app): genera el
///      embedding de cada foto oficial del catalogo.
///   2. Consulta online (cada escaneo): genera el embedding de la foto
///      capturada y la compara contra el indice.
///   3. Aplica los umbrales de confianza definidos en la arquitectura:
///      nunca se inventa un resultado.
///
/// En produccion, el paso 1 se movera a una Edge Function de Supabase
/// (pgvector) y el paso 2 solo enviara el vector via red. Aqui, para el
/// piloto, todo corre localmente en el dispositivo.
class RecognitionService extends ChangeNotifier {
  final CatalogRepository _catalogRepository;
  final EmbeddingService _embeddingService;

  // Umbrales calibrables (en produccion vendrian de configuracion remota).
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

  /// Construye el indice de embeddings a partir del catalogo. Se llama
  /// una vez al iniciar la app.
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

  /// Identifica una foto de escaneo (archivo capturado por la camara)
  /// contra el catalogo indexado.
  Future<RecognitionResult> identify(File scanFile) async {
    if (!indexReady) {
      throw StateError('El indice todavia no esta listo.');
    }

    final queryEmbedding =
        await _embeddingService.extractEmbeddingFromFile(scanFile);

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

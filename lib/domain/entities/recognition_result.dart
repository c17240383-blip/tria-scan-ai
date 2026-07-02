import 'product.dart';

/// Estado posible de una identificacion, tal como se definio en la
/// arquitectura: nunca se inventa un resultado.
enum RecognitionStatus { matchUnico, variosCandidatos, noIdentificado }

/// Un candidato con su porcentaje de similitud contra la foto escaneada.
class ScoredCandidate {
  final Product product;
  final double similitud; // 0.0 a 1.0

  const ScoredCandidate({required this.product, required this.similitud});

  double get porcentaje => similitud * 100;
}

/// Resultado completo devuelto por el motor de reconocimiento.
class RecognitionResult {
  final RecognitionStatus status;
  final List<ScoredCandidate> candidatos;

  const RecognitionResult({required this.status, required this.candidatos});

  ScoredCandidate? get mejor => candidatos.isNotEmpty ? candidatos.first : null;
}

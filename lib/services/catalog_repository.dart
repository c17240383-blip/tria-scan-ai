import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../domain/entities/product.dart';

/// Carga el catalogo de productos empaquetado como asset.
/// En una version futura, esta clase se reemplaza por un
/// `SupabaseProductRepository` sin tocar el resto de la app.
class CatalogRepository {
  List<Product>? _cache;

  Future<List<Product>> loadCatalog() async {
    if (_cache != null) return _cache!;

    final jsonStr = await rootBundle.loadString('assets/catalog/catalog.json');
    final Map<String, dynamic> data = json.decode(jsonStr);
    final List<dynamic> productsJson = data['products'] as List<dynamic>;

    _cache = productsJson
        .map((p) => Product.fromJson(p as Map<String, dynamic>))
        .toList();

    return _cache!;
  }
}

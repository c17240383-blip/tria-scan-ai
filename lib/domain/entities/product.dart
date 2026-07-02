/// Entidad de dominio: representa un producto del catalogo TRIA.
/// No depende de Flutter ni de ninguna fuente de datos concreta.
class Product {
  final String id;
  final String marca;
  final String modelo;
  final String sku;
  final String color;
  final String categoria;
  final String linea;
  final String imagenAsset;
  final String descripcion;
  final Map<String, String> fichaTecnica;

  const Product({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.sku,
    required this.color,
    required this.categoria,
    required this.linea,
    required this.imagenAsset,
    required this.descripcion,
    required this.fichaTecnica,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final ficha = <String, String>{};
    final fichaJson = json['fichaTecnica'] as Map<String, dynamic>? ?? {};
    fichaJson.forEach((key, value) {
      ficha[key] = value.toString();
    });

    return Product(
      id: json['id'] as String,
      marca: json['marca'] as String? ?? '',
      modelo: json['modelo'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      color: json['color'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
      linea: json['linea'] as String? ?? '',
      imagenAsset: json['imagen'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      fichaTecnica: ficha,
    );
  }
}

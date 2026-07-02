/// Entidad de dominio: representa un producto del catalogo TRIA.
class Product {
  final String id;
  final String marca;
  final String modelo;
  final String sku;
  final String color;
  final String categoria;
  final String linea;
  final List<String> imagenesAssets;
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
    required this.imagenesAssets,
    required this.descripcion,
    required this.fichaTecnica,
  });

  /// Foto principal (portada) para mostrar en tarjetas y listas.
  String get imagenPortada => imagenesAssets.first;

  factory Product.fromJson(Map<String, dynamic> json) {
    final ficha = <String, String>{};
    final fichaJson = json['fichaTecnica'] as Map<String, dynamic>? ?? {};
    fichaJson.forEach((key, value) {
      ficha[key] = value.toString();
    });

    final imagenesJson = json['imagenes'] as List<dynamic>?;
    final imagenes = imagenesJson != null
        ? imagenesJson.map((e) => 'assets/catalog/images/$e').toList()
        : <String>['assets/catalog/images/${json['imagen']}'];

    return Product(
      id: json['id'] as String,
      marca: json['marca'] as String? ?? '',
      modelo: json['modelo'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      color: json['color'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
      linea: json['linea'] as String? ?? '',
      imagenesAssets: imagenes,
      descripcion: json['descripcion'] as String? ?? '',
      fichaTecnica: ficha,
    );
  }
}

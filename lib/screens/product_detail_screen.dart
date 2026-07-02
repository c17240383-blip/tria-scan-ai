import 'package:flutter/material.dart';

import '../domain/entities/product.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final double similitud;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.similitud,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: colorScheme.surface,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black45,
                child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: product.id,
                child: Container(
                  color: colorScheme.surfaceContainerLow,
                  child: Image.asset(
                    product.imagenPortada,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ConfianzaBadge(similitud: similitud),
                  const SizedBox(height: 16),

                  Text(
                    product.modelo,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${product.marca} · ${product.color}',
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (product.sku.isNotEmpty) Chip(label: Text('SKU ${product.sku}')),
                      if (product.categoria.isNotEmpty) Chip(label: Text(product.categoria)),
                      if (product.linea.isNotEmpty) Chip(label: Text(product.linea)),
                    ],
                  ),

                  const SizedBox(height: 28),
                  _SectionTitle('Descripcion'),
                  const SizedBox(height: 8),
                  Text(
                    product.descripcion,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: colorScheme.onSurface.withOpacity(0.85),
                    ),
                  ),

                  if (product.fichaTecnica.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _SectionTitle('Ficha tecnica'),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Column(
                          children: product.fichaTecnica.entries
                              .map((e) => _FichaRow(label: e.key, value: e.value))
                              .toList(),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfianzaBadge extends StatelessWidget {
  final double similitud;
  const _ConfianzaBadge({required this.similitud});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final porcentaje = (similitud * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(
            'Identificado · $porcentaje% de coincidencia',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _FichaRow extends StatelessWidget {
  final String label;
  final String value;
  const _FichaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String nameUr;
  final String slug;
  final String? image;

  CategoryModel({required this.id, required this.name, required this.nameUr, required this.slug, this.image});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameUr: json['name_ur'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      image: (json['image_url'] ?? json['image']) as String?,
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String nameUr;
  final String slug;
  final String description;
  final String descriptionUr;
  final double pricePerKg;
  final double? comparePrice;
  final double stockKg;
  final double minOrderKg;
  final double maxOrderKg;
  final List<String> images;
  final String freshnessStatus;
  final bool isFeatured;
  final bool isActive;
  final List<String> cutOptions;
  final String? categoryId;

  ProductModel({
    required this.id, required this.name, required this.nameUr, required this.slug,
    required this.description, required this.descriptionUr, required this.pricePerKg,
    this.comparePrice, required this.stockKg, required this.minOrderKg,
    required this.maxOrderKg, required this.images, required this.freshnessStatus,
    required this.isFeatured, required this.isActive, required this.cutOptions,
    this.categoryId,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String) {
        try {
          final parsed = RegExp(r'[\w\-_]+').allMatches(val).map((m) => m.group(0)!).toList();
          return parsed.isNotEmpty ? parsed : [val];
        } catch (_) { return [val]; }
      }
      return [];
    }

    return ProductModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameUr: json['name_ur'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      descriptionUr: json['description_ur'] as String? ?? '',
      pricePerKg: (json['price_per_kg'] ?? json['pricePerKg'] ?? 0).toDouble(),
      comparePrice: (json['compare_price'] ?? json['comparePrice'])?.toDouble(),
      stockKg: (json['stock_kg'] ?? json['stockKg'] ?? 0).toDouble(),
      minOrderKg: (json['min_order_kg'] ?? json['minOrderKg'] ?? 0.5).toDouble(),
      maxOrderKg: (json['max_order_kg'] ?? json['maxOrderKg'] ?? 5).toDouble(),
      images: parseList(json['images']),
      freshnessStatus: json['freshness_status'] as String? ?? 'fresh',
      isFeatured: json['is_featured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      cutOptions: parseList(json['cut_options'] ?? json['cutOptions']),
      categoryId: json['category_id'] as String?,
    );
  }

  String get image => images.isNotEmpty ? images.first : '';
  bool get inStock => stockKg > 0;
}

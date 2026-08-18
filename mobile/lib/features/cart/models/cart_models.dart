class CartItem {
  final String productId;
  final String name;
  final String nameUr;
  final String image;
  final double pricePerKg;
  double weightKg;
  String cutType;
  String notes;

  CartItem({
    required this.productId, required this.name, required this.nameUr,
    required this.image, required this.pricePerKg,
    this.weightKg = 1.0, this.cutType = 'curry_cut', this.notes = '',
  });

  double get subtotal => pricePerKg * weightKg;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'nameUr': nameUr,
        'image': image,
        'pricePerKg': pricePerKg,
        'weightKg': weightKg,
        'cutType': cutType,
        'notes': notes,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        nameUr: json['nameUr'] as String? ?? '',
        image: json['image'] as String? ?? '',
        pricePerKg: (json['pricePerKg'] ?? 0).toDouble(),
        weightKg: (json['weightKg'] ?? 1.0).toDouble(),
        cutType: json['cutType'] as String? ?? 'curry_cut',
        notes: json['notes'] as String? ?? '',
      );
}

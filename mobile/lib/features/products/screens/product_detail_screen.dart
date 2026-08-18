import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../models/product_models.dart';
import '../providers/product_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../cart/models/cart_models.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productSlug;
  const ProductDetailScreen({super.key, required this.productSlug});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  double _selectedKg = 1.0;
  String _selectedCut = 'curry_cut';
  final _notesController = TextEditingController();
  final _customKgController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _customKgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productProvider);
    return productsAsync.when(
      data: (products) {
        final product = products.where((p) => p.slug == widget.productSlug).firstOrNull;
        if (product == null) return const Scaffold(body: Center(child: Text('Product not found')));
        return _buildProductPage(product);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildProductPage(ProductModel product) {
    final kgOptions = [0.5, 1.0, 2.0];
    final cutLabels = {'curry_cut': 'Curry Cut', 'bbq_cut': 'BBQ Cut', 'boneless': 'Boneless', 'mince': 'Mince/Qeema'};

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: CachedNetworkImage(
                imageUrl: product.image,
                height: 280, width: double.infinity, fit: BoxFit.cover,
                placeholder: (_, __) => Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(height: 280, color: Colors.white)),
                errorWidget: (_, __, ___) => Container(height: 280, color: AppColors.lightGray, child: const Icon(Icons.image, size: 64)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: product.inStock ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(product.inStock ? 'In Stock' : 'Out of Stock', style: TextStyle(color: product.inStock ? AppColors.success : AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(product.nameUr, style: const TextStyle(fontSize: 18, color: AppColors.gray)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Rs. ${product.pricePerKg.toStringAsFixed(0)}/kg', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      if (product.comparePrice != null) ...[
                        const SizedBox(width: 12),
                        Text('Rs. ${product.comparePrice!.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, decoration: TextDecoration.lineThrough, color: AppColors.gray)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (product.freshnessStatus.isNotEmpty) Row(
                    children: [
                      const Icon(Icons.eco, color: AppColors.success, size: 18),
                      const SizedBox(width: 6),
                      Text(product.freshnessStatus.toUpperCase(), style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(product.description, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),

                  const Text('Select Weight', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...kgOptions.map((kg) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(label: Text('${kg == 0.5 ? "500" : kg == 1 ? "1" : "2"}kg'), selected: _selectedKg == kg, onSelected: (_) => setState(() { _selectedKg = kg; _customKgController.clear(); })),
                      )),
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            controller: _customKgController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Custom kg',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                            onChanged: (v) {
                              final kg = double.tryParse(v);
                              if (kg != null) setState(() => _selectedKg = kg);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text('Cut Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: product.cutOptions.map((cut) => ChoiceChip(label: Text(cutLabels[cut] ?? cut), selected: _selectedCut == cut, onSelected: (_) => setState(() => _selectedCut = cut))).toList(),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Additional Notes', hintText: 'Any special instructions...'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              if (!product.inStock) return;
              final cartItem = CartItem(
                productId: product.id,
                name: product.name,
                nameUr: product.nameUr,
                image: product.image,
                pricePerKg: product.pricePerKg,
                weightKg: _selectedKg,
                cutType: _selectedCut,
                notes: _notesController.text,
              );
              ref.read(cartProvider.notifier).addItem(cartItem);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to cart'), backgroundColor: AppColors.success, duration: Duration(seconds: 1)),
              );
            },
            child: Text('Add to Cart - Rs. ${(product.pricePerKg * _selectedKg).toStringAsFixed(0)}'),
          ),
        ),
      ),
    );
  }
}

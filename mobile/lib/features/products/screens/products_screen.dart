import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/response_utils.dart';
import '../models/product_models.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  final String? categorySlug;
  const ProductsScreen({super.key, this.categorySlug});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _api = ApiClient();
  List<ProductModel> _products = [];
  bool _loading = true;
  String? _error;
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = widget.categorySlug != null ? {'category': widget.categorySlug} : null;
      final response = await _api.get(ApiConstants.products, queryParams: query);
      final data = extractList(response.data);
      final products = data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>? ?? {})).toList();
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
        if (widget.categorySlug != null) {
          _loadCategoryName();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _loadCategoryName() async {
    try {
      final response = await _api.get(ApiConstants.categories);
      final categories = extractList(response.data).map((e) => CategoryModel.fromJson(e as Map<String, dynamic>? ?? {})).toList();
      final cat = categories.where((c) => c.slug == widget.categorySlug).firstOrNull;
      if (cat != null && mounted) setState(() => _categoryName = cat.name);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_categoryName ?? (widget.categorySlug != null ? 'Category' : 'All Products')),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: AppColors.gray),
            const SizedBox(height: 12),
            Text('Failed to load products: $_error', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_products.isEmpty) {
      return const Center(child: Text('No products found', style: TextStyle(color: AppColors.gray)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: _products.length,
      itemBuilder: (_, i) => _productCard(_products[i]),
    );
  }

  Widget _productCard(ProductModel product) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.slug}'),
      child: Container(
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: const Offset(0, 3)),
        ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: product.image,
                height: 130, width: double.infinity, fit: BoxFit.cover,
                placeholder: (_, __) => Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(height: 130, color: Colors.white)),
                errorWidget: (_, __, ___) => Container(height: 130, color: AppColors.lightGray, child: const Icon(Icons.image, size: 40)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text('Rs. ${product.pricePerKg.toStringAsFixed(0)}/kg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
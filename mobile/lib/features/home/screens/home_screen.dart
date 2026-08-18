import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/response_utils.dart';
import '../../../core/constants/api_constants.dart';
import '../../products/models/product_models.dart';
import '../../products/providers/product_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _api = ApiClient();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.appName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(AppStrings.shopAddress, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => context.push('/notifications')),
          IconButton(icon: const Icon(Icons.shopping_cart_outlined), onPressed: () => context.go('/cart')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(productProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShopInfo(),
              _buildPromotionsBanner(),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 12),
              _buildCategories(),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Featured Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 12),
              _buildFeaturedProducts(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified, color: AppColors.white, size: 20),
              SizedBox(width: 8),
              Text('100% Fresh Halal Meat', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: const Row(
              children: [
                Icon(Icons.delivery_dining, color: AppColors.white, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text(AppStrings.deliveryInfo, style: TextStyle(color: AppColors.white, fontSize: 12.5))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.schedule, color: AppColors.white, size: 18),
              SizedBox(width: 8),
              Text('Open: ${AppStrings.shopTiming}', style: TextStyle(color: AppColors.white, fontSize: 13)),
              Spacer(),
              Icon(Icons.phone, color: AppColors.white, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionsBanner() {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _promoCard('Free Delivery', 'On orders above\nRs. 1,000', Icons.delivery_dining, AppColors.success),
          _promoCard('Fresh Meat', 'Direct from\nfarm to table', Icons.verified, AppColors.primary),
          _promoCard('10% Off', 'First order\ndiscount', Icons.percent, AppColors.warning),
        ],
      ),
    );
  }

  Widget _promoCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const Spacer(),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return FutureBuilder<List<CategoryModel>>(
      future: _fetchCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _shimmerGrid(itemCount: 3);
        }
        final categories = snapshot.data!;
        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              return GestureDetector(
                onTap: () => context.push('/products?category=${cat.slug}'),
                child: Container(
                  width: 88,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 68, height: 68,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withOpacity(0.12)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: cat.image != null && cat.image!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: cat.image!,
                                fit: BoxFit.cover,
                                width: 68, height: 68,
                                placeholder: (_, __) => Container(color: AppColors.primaryLight, child: Icon(Icons.restaurant, color: AppColors.primary, size: 28)),
                                errorWidget: (_, __, ___) => Container(color: AppColors.primaryLight, child: Icon(Icons.restaurant, color: AppColors.primary, size: 28)),
                              )
                            : Icon(Icons.restaurant, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(cat.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFeaturedProducts() {
    final productsAsync = ref.watch(featuredProductProvider);
    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (_, i) => _productCard(products[i]),
          ),
        );
      },
      loading: () => _shimmerGrid(itemCount: 3),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $e', style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
      ),
    );
  }

  Widget _productCard(ProductModel product) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.slug}'),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18), boxShadow: [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: const Offset(0, 3)),
        ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
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

  Widget _shimmerGrid({int itemCount = 3}) {
    return SizedBox(
      height: 100,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: itemCount,
          itemBuilder: (_, __) => Container(width: 60, height: 60, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
        ),
      ),
    );
  }

  Future<List<CategoryModel>> _fetchCategories() async {
    try {
      final response = await _api.get(ApiConstants.categories);
      final data = extractList(response.data);
      return data.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}

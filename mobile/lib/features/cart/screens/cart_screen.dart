import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.lightGray),
              const SizedBox(height: 16),
              const Text('Your cart is empty', style: TextStyle(fontSize: 18, color: AppColors.gray)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.go('/home'), child: const Text('Start Shopping')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cart'), actions: [
        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => ref.read(cartProvider.notifier).clear()),
      ]),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cartItems.length,
        itemBuilder: (_, i) {
          final item = cartItems[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(imageUrl: item.image, width: 70, height: 70, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(width: 70, height: 70, color: AppColors.lightGray, child: const Icon(Icons.image))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('Rs. ${item.pricePerKg.toStringAsFixed(0)}/kg', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              onPressed: () => ref.read(cartProvider.notifier).updateQuantity(i, item.weightKg - 0.5),
                              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                            ),
                            Text('${item.weightKg.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.w600)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              onPressed: () => ref.read(cartProvider.notifier).updateQuantity(i, item.weightKg + 0.5),
                              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text('Rs. ${item.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                        onPressed: () => ref.read(cartProvider.notifier).removeItem(i),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal', style: TextStyle(fontSize: 16)),
                  Text('Rs. ${cart.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delivery', style: TextStyle(fontSize: 16)),
                  Text(cart.hasFreeDelivery ? 'FREE' : 'Rs. ${cart.deliveryCharge.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cart.hasFreeDelivery ? AppColors.success : AppColors.textPrimary)),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Rs. ${cart.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/checkout'),
                  child: const Text('Proceed to Checkout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

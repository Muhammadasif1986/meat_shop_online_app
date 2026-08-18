import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  final int _currentStep = 0;

  final _steps = [
    {'label': 'Order Received', 'icon': Icons.receipt},
    {'label': 'Preparing', 'icon': Icons.restaurant},
    {'label': 'Packed', 'icon': Icons.inventory_2},
    {'label': 'Rider Assigned', 'icon': Icons.person},
    {'label': 'Out for Delivery', 'icon': Icons.delivery_dining},
    {'label': 'Delivered', 'icon': Icons.check_circle},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Tracking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Order Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ...List.generate(_steps.length, (i) {
                    final step = _steps[i];
                    final isActive = i <= _currentStep;
                    final isLast = i == _steps.length - 1;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.primary : AppColors.lightGray,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(step['icon'] as IconData, color: AppColors.white, size: 18),
                            ),
                            if (!isLast) Container(width: 2, height: 40, color: isActive ? AppColors.primary : AppColors.lightGray),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                          child: Text(step['label'] as String,
                            style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: isActive ? AppColors.textPrimary : AppColors.gray)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delivery Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Naval Colony, Karachi', style: TextStyle(color: AppColors.gray)),
                  const SizedBox(height: 4),
                  const Text('Estimated delivery: 30-45 min', style: TextStyle(color: AppColors.gray)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

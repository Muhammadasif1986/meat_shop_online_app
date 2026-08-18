import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/response_utils.dart';
import '../../../core/constants/api_constants.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _fetchOrders() async {
    final response = await _api.get(ApiConstants.orders);
    return extractList(response.data);
  }

  Future<void> _cancelOrder(String orderId, String orderNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text('Cancel order #$orderNumber?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _api.post('${ApiConstants.orders}/$orderId/cancel');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled')));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Active'), Tab(text: 'History')],
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchOrders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final allOrders = snapshot.data!;
          final active = allOrders.where((o) => !['delivered', 'cancelled'].contains(o['status'])).toList();
          final history = allOrders.where((o) => ['delivered', 'cancelled'].contains(o['status'])).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _orderList(active, 'No active orders'),
              _orderList(history, 'No order history'),
            ],
          );
        },
      ),
    );
  }

  Widget _orderList(List<dynamic> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 72, color: AppColors.lightGray),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(color: AppColors.gray)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => context.go('/home'), child: const Text('Order Now')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (_, i) {
          final order = orders[i] as Map<String, dynamic>;
          final status = order['status'] as String? ?? '';
          final total = (order['total'] ?? 0).toDouble();
          final createdAt = order['created_at'] as String? ?? '';
          final orderNumber = order['order_number'] as String? ?? '';
          final cancellable = ['pending', 'confirmed'].contains(status);

          String dateStr = '';
          try { dateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(createdAt)); } catch (_) {}

          return Card(
            child: ListTile(
              title: Text('Order #$orderNumber', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('$dateStr\nRs. ${total.toStringAsFixed(0)}'),
              trailing: cancellable
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _statusChip(status),
                        TextButton(
                          onPressed: () => _cancelOrder(order['id']?.toString() ?? '', orderNumber),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.error, fontSize: 12)),
                        ),
                      ],
                    )
                  : _statusChip(status),
              onTap: () => context.push('/order-tracking/${order['id']}'),
            ),
          );
        },
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'pending': color = AppColors.warning; break;
      case 'confirmed': color = AppColors.primary; break;
      case 'delivered': color = AppColors.success; break;
      case 'cancelled': color = AppColors.error; break;
      default: color = AppColors.gray;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

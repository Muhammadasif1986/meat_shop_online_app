import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/response_utils.dart';
import '../../../core/constants/api_constants.dart';
import '../../cart/providers/cart_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _api = ApiClient();
  final _notesController = TextEditingController();
  List<dynamic> _addresses = [];
  bool _loadingAddresses = true;
  String? _selectedAddressId;
  bool _isLoading = false;
  String _paymentMethod = 'cod';

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loadingAddresses = true);
    try {
      final response = await _api.get(ApiConstants.addresses);
      final list = extractList(response.data);
      if (!mounted) return;
      setState(() {
        _addresses = list;
        _loadingAddresses = false;
        // Preselect default if present
        final def = list.where((a) => a['is_default'] == true).firstOrNull;
        _selectedAddressId = def != null ? def['id']?.toString() : (list.isNotEmpty ? list.first['id']?.toString() : null);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingAddresses = false);
    }
  }

  Future<void> _addAddressAndSelect() async {
    final labelController = TextEditingController(text: 'Home');
    final addressController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Delivery Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Label (e.g. Home, Office)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Full Address', hintText: 'Sector, House/Shop No, Street, Area'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true || addressController.text.trim().isEmpty) return;

    try {
      final created = await _api.post(ApiConstants.addresses, data: {
        'label': labelController.text.trim().isEmpty ? 'Home' : labelController.text.trim(),
        'full_address': addressController.text.trim(),
      });
      if (!mounted) return;
      final data = created.data['data'] as Map<String, dynamic>?;
      setState(() {
        _addresses = data != null ? [..._addresses, data] : _addresses;
        _selectedAddressId = data != null ? data['id']?.toString() : _selectedAddressId;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address added'), backgroundColor: AppColors.success));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a delivery address first'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final cart = ref.read(cartProvider.notifier);
      final items = ref.read(cartProvider);
      final api = ApiClient();
      final orderData = {
        'address_id': _selectedAddressId,
        'payment_method': _paymentMethod,
        'delivery_notes': _notesController.text,
        'items': items.map((i) => {
          'product_id': i.productId, 'weight_kg': i.weightKg, 'cut_type': i.cutType, 'custom_instructions': i.notes,
        }).toList(),
      };
      await api.post(ApiConstants.orders, data: orderData);
      cart.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully!'), backgroundColor: AppColors.success));
      context.go('/orders');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.read(cartProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              _selectedAddressId == null
                  ? 'You must add a delivery address to place an order.'
                  : 'Select the address where your order will be delivered.',
              style: const TextStyle(fontSize: 12, color: AppColors.gray),
            ),
            const SizedBox(height: 8),
            _buildAddressSection(),
            if (_selectedAddressId == null && _addresses.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Please select one of your saved addresses above.',
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  RadioListTile(value: 'cod', groupValue: _paymentMethod, title: const Text('Cash on Delivery'), onChanged: (v) => setState(() => _paymentMethod = v!)),
                  RadioListTile(value: 'jazzcash', groupValue: _paymentMethod, title: const Text('JazzCash (coming soon)'), onChanged: null),
                  RadioListTile(value: 'easypaisa', groupValue: _paymentMethod, title: const Text('EasyPaisa (coming soon)'), onChanged: null),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Order Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(controller: _notesController, decoration: const InputDecoration(hintText: 'Any special instructions?'), maxLines: 2),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('Rs. ${cart.subtotal.toStringAsFixed(0)}')]),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Delivery'), Text(cart.hasFreeDelivery ? 'FREE' : 'Rs. ${cart.deliveryCharge.toStringAsFixed(0)}')]),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), Text('Rs. ${cart.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _placeOrder,
            child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Place Order'),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    if (_loadingAddresses) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_addresses.isEmpty) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: const Column(
              children: [
                Icon(Icons.location_off, color: AppColors.warning, size: 40),
                SizedBox(height: 8),
                Text(
                  'No address saved yet.\nPlease add your delivery address to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addAddressAndSelect,
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Add Delivery Address'),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        ..._addresses.map((a) => Card(
          child: RadioListTile(
            value: a['id']?.toString(),
            groupValue: _selectedAddressId,
            title: Text(a['label']?.toString() ?? 'Address', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(a['full_address']?.toString() ?? ''),
            secondary: a['is_default'] == true
                ? const Icon(Icons.star, color: AppColors.warning, size: 20)
                : null,
            onChanged: (v) => setState(() => _selectedAddressId = v),
          ),
        )),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addAddressAndSelect,
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
            icon: const Icon(Icons.add),
            label: const Text('Add New Address'),
          ),
        ),
      ],
    );
  }
}
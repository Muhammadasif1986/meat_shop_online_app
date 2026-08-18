import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/response_utils.dart';
import '../../../core/constants/api_constants.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  final _api = ApiClient();
  List<dynamic> _addresses = [];
  bool _loading = true;
  String? _error;

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
      final response = await _api.get(ApiConstants.addresses);
      if (!mounted) return;
      setState(() {
        _addresses = extractList(response.data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _addAddress() async {
    final labelController = TextEditingController(text: 'Home');
    final addressController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Address'),
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
              decoration: const InputDecoration(labelText: 'Full Address'),
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
      await _api.post(ApiConstants.addresses, data: {
        'label': labelController.text.trim().isEmpty ? 'Home' : labelController.text.trim(),
        'full_address': addressController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address added')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _deleteAddress(String id) async {
    try {
      await _api.delete('${ApiConstants.addresses}/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address deleted')));
      _load();
    } catch (e) {
      if (!mounted) return;
      final message = _errorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
    }
  }

  String _errorMessage(dynamic e) {
    final s = e.toString();
    final detailMatch = RegExp(r'detail["\s:]+([^"}\]]+)').firstMatch(s);
    if (detailMatch != null) return detailMatch.group(1)!.trim();
    return s.replaceAll('Exception: ', '').replaceAll('DioException', 'Error');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAddress,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
      body: _buildBody(),
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
            const SizedBox(height: 16),
            Text('Failed to load addresses', style: const TextStyle(color: AppColors.gray)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 72, color: AppColors.lightGray),
            const SizedBox(height: 16),
            const Text('No saved addresses', style: TextStyle(color: AppColors.gray)),
            const SizedBox(height: 8),
            const Text('Add your delivery address', style: TextStyle(color: AppColors.lightGray, fontSize: 12)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _addresses.length,
        itemBuilder: (_, i) {
          final a = _addresses[i] as Map<String, dynamic>;
          final isDefault = a['is_default'] == true;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isDefault ? AppColors.primaryLight : AppColors.lightGray,
                child: Icon(isDefault ? Icons.home : Icons.location_on, color: AppColors.primary),
              ),
              title: Text(
                a['label']?.toString() ?? 'Address',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(a['full_address']?.toString() ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () => _deleteAddress(a['id']?.toString() ?? ''),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _call(BuildContext context, String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No dialer available on this device')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to make a call from this device')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryLight,
              child: const Icon(Icons.storefront, size: 40, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.appName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text('Fresh Halal Meat', style: TextStyle(color: AppColors.gray), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on, color: AppColors.primary),
              title: const Text('Shop Address'),
              subtitle: Text(AppStrings.shopAddress),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone, color: AppColors.primary),
                  title: const Text('Phone'),
                  subtitle: const Text('Tap to call'),
                ),
                for (final phone in AppStrings.shopPhones)
                  ListTile(
                    leading: const Icon(Icons.phone_outlined, color: AppColors.gray),
                    title: Text(phone),
                    trailing: IconButton(
                      icon: const Icon(Icons.call, color: AppColors.success),
                      onPressed: () => _call(context, phone),
                    ),
                  ),
              ],
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule, color: AppColors.primary),
              title: const Text('Timing'),
              subtitle: Text(AppStrings.shopTiming),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delivery_dining, color: AppColors.primary),
              title: const Text('Delivery'),
              subtitle: const Text('Naval Colony, Baldia Town & surrounding areas'),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Delivery available across Naval Colony, Baldia Town and surrounding areas.',
            style: TextStyle(color: AppColors.gray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

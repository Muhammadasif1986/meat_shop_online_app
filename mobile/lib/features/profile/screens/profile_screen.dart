import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/i18n/app_localization.dart';
import '../../../main.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploading = false;

  Future<void> _pickAvatar() async {
    if (_uploading) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      await ref.read(authProvider.notifier).updateAvatar(picked.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                _avatar(user?.avatarUrl, user?.name),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _uploading ? null : _pickAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: _uploading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                          : const Icon(Icons.camera_alt, color: AppColors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(user?.name ?? 'Guest', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Text(user?.phone ?? '', style: const TextStyle(fontSize: 14, color: AppColors.gray), textAlign: TextAlign.center),
          if (user?.name == null || user!.name.isEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _showNameDialog(),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), visualDensity: VisualDensity.compact),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Set your name'),
              ),
            ),
          ],
          const SizedBox(height: 32),

          _menuItem(context, Icons.location_on, 'My Addresses', () => context.push('/addresses')),
          _menuItem(context, Icons.receipt_long, 'My Orders', () => context.go('/orders')),
          _menuItem(context, Icons.notifications_outlined, 'Notifications', () => context.push('/notifications')),
          _menuItem(context, Icons.language, 'Language', () => _showLanguagePicker(context, ref)),

          const Divider(height: 32),

          _menuItem(context, Icons.info_outline, 'About Shop', () => _showAboutDialog(context)),
          _menuItem(context, Icons.phone, 'Contact Us', () => context.push('/contact-us')),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/welcome');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String? avatarUrl, String? name) {
    final url = ApiConstants.resolveAssetUrl(avatarUrl);
    final initials = (name?.isNotEmpty == true) ? name![0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 48,
      backgroundColor: AppColors.primaryLight,
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: url.isEmpty
          ? Text(initials, style: const TextStyle(fontSize: 36, color: AppColors.primary, fontWeight: FontWeight.bold))
          : null,
    );
  }

  Future<void> _showNameDialog() async {
    final controller = TextEditingController(text: ref.read(authProvider).valueOrNull?.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Full name', hintText: 'e.g. Muhammad Asif'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(authProvider.notifier).updateName(name);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated'), backgroundColor: AppColors.success));
    }
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.gray),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ListTile(leading: const Icon(Icons.check), title: const Text('English'), onTap: () {
              AppLocalization.saveLocale('en');
              ref.read(localeProvider.notifier).state = const Locale('en');
              ctx.pop();
            }),
            ListTile(title: const Text('اردو'), onTap: () {
              AppLocalization.saveLocale('ur');
              ref.read(localeProvider.notifier).state = const Locale('ur');
              ctx.pop();
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text(AppStrings.appName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AppStrings.shopAddress),
          const SizedBox(height: 8),
          const Text(AppStrings.shopPhone),
          const SizedBox(height: 8),
          const Text('Hours: ${AppStrings.shopTiming}'),
          const SizedBox(height: 8),
          const Text('Fresh Halal Meat, Delivery to Naval Colony & surrounding areas.'),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ));
  }
}
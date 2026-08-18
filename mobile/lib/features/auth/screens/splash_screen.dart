import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    final authRepository = ref.read(authRepositoryProvider);
    final isLoggedIn = await authRepository.isLoggedIn();
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    if (isLoggedIn) {
      context.go('/home');
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant, size: 80, color: AppColors.white),
            const SizedBox(height: 24),
            Text(AppStrings.appName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.white)),
            const SizedBox(height: 8),
            Text(AppStrings.shopAddress, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: AppColors.white),
          ],
        ),
      ),
    );
  }
}

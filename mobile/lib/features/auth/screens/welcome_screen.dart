import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(30)),
                child: const Icon(Icons.restaurant, size: 64, color: AppColors.white),
              ),
              const SizedBox(height: 32),
              const Text(AppStrings.appName, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Text(AppStrings.shopAddress, style: const TextStyle(fontSize: 16, color: AppColors.gray), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                child: Text('Open ${AppStrings.shopTiming}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              const Spacer(flex: 2),
              const Text('Fresh Halal Meat Delivered to Your Doorstep', style: TextStyle(fontSize: 14, color: AppColors.gray), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Get Started'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Sign In'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

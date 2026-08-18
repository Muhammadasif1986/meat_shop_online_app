import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/phone_input_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/orders/screens/order_tracking_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/addresses_screen.dart';
import '../../features/profile/screens/contact_us_screen.dart';
import '../../features/reviews/screens/reviews_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
    GoRoute(path: '/login', builder: (_, __) => const PhoneInputScreen()),
    GoRoute(path: '/otp', builder: (_, state) => OtpScreen(phone: state.extra as String? ?? '')),
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
        GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
    GoRoute(path: '/products', builder: (_, state) => ProductsScreen(categorySlug: state.uri.queryParameters['category'])),
    GoRoute(path: '/product/:slug', builder: (_, state) => ProductDetailScreen(productSlug: state.pathParameters['slug'] ?? '')),
    GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
    GoRoute(path: '/order-tracking/:id', builder: (_, state) => OrderTrackingScreen(orderId: state.pathParameters['id'] ?? '')),
    GoRoute(path: '/reviews/:productId', builder: (_, state) => ReviewsScreen(productId: state.pathParameters['productId'] ?? '')),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/addresses', builder: (_, __) => const AddressesScreen()),
    GoRoute(path: '/contact-us', builder: (_, __) => const ContactUsScreen()),
  ],
);

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateIndex(context),
        onTap: (index) {
          switch (index) {
            case 0: context.go('/home');
            case 1: context.go('/cart');
            case 2: context.go('/orders');
            case 3: context.go('/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/cart')) return 1;
    if (location.startsWith('/orders')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }
}

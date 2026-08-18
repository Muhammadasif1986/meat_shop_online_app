import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/i18n/app_localization.dart';
import 'core/routes/app_router.dart';
import 'core/services/notification_service.dart';
import 'features/auth/providers/auth_provider.dart';

final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: AbdulGhaffarMeatShop()));
}

class AbdulGhaffarMeatShop extends ConsumerStatefulWidget {
  const AbdulGhaffarMeatShop({super.key});

  @override
  ConsumerState<AbdulGhaffarMeatShop> createState() => _AbdulGhaffarMeatShopState();
}

class _AbdulGhaffarMeatShopState extends ConsumerState<AbdulGhaffarMeatShop> {
  @override
  void initState() {
    super.initState();
    _loadLocale();
    _listenAuth();
  }

  void _listenAuth() {
    ref.listen(authProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          NotificationService.instance.startPolling();
        } else {
          NotificationService.instance.stopPolling();
        }
      });
    });
  }

  Future<void> _loadLocale() async {
    final saved = await AppLocalization.getSavedLocale();
    ref.read(localeProvider.notifier).state = saved;
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'Abdul Ghaffar Meat Shop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: const [
        AppLocalization.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supported) {
        if (locale != null && supported.contains(locale)) return locale;
        return const Locale('en');
      },
      routerConfig: appRouter,
    );
  }
}

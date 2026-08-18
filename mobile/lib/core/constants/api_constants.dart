class ApiConstants {
  static const String _envApiUrl = String.fromEnvironment('API_URL');

  static const String baseUrl =
      _envApiUrl == '' ? 'http://localhost:8000/api/v1' : _envApiUrl;

  static String get baseHost {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  static String resolveAssetUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$baseHost$path';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static const String login = '/auth/admin/login';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  static const String categories = '/categories';
  static const String products = '/products';
  static const String featured = '/products/featured';

  static const String cart = '/cart';
  static const String cartItems = '/cart/items';

  static const String orders = '/orders';
  static const String notifications = '/notifications';
  static const String reviews = '/reviews';
  static const String addresses = '/addresses';
}

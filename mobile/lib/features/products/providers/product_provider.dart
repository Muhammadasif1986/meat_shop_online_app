import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/response_utils.dart';
import '../../../core/constants/api_constants.dart';
import '../models/product_models.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final productProvider = FutureProvider<List<ProductModel>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.products);
  final data = extractList(response.data);
  return data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
});

final featuredProductProvider = FutureProvider<List<ProductModel>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final response = await api.get(ApiConstants.featured);
    final raw = extractList(response.data);
    return raw.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
});

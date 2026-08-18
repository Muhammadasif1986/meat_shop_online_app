import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  }

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshToken = await _storage.read(key: 'refresh_token');
          if (refreshToken != null) {
            try {
              final response = await Dio().post(
                '${ApiConstants.baseUrl}${ApiConstants.refresh}',
                data: {'refresh_token': refreshToken},
              );
              if (response.data['success'] == true) {
                final newToken = response.data['data']['access_token'] ?? response.data['data']['token'];
                await _storage.write(key: 'access_token', value: newToken);
                error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                final retryResponse = await _dio.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              }
            } catch (_) {}
          }
        }
        handler.next(error);
      },
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) =>
      _dio.get(path, queryParameters: queryParams);

  Future<Response> post(String path, {dynamic data}) => _dio.post(path, data: data);

  Future<Response> postMultipart(String path, {required FormData data}) => _dio.post(
        path,
        data: data,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

  Future<Response> put(String path, {dynamic data}) => _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) => _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);
}

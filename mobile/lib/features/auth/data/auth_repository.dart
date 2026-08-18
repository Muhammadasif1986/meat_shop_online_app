import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/auth_models.dart';
import '../models/user_model.dart';

class SendOtpResult {
  final bool delivered;
  final String reason;
  final String? botUsername;

  SendOtpResult({required this.delivered, required this.reason, this.botUsername});

  factory SendOtpResult.fromJson(Map<String, dynamic> data) => SendOtpResult(
        delivered: data['delivered'] == true,
        reason: data['reason'] as String? ?? 'unknown',
        botUsername: data['bot_username'] as String?,
      );
}

class AuthRepository {
  final ApiClient _api;
  final FlutterSecureStorage _storage;

  AuthRepository({ApiClient? api, FlutterSecureStorage? storage})
      : _api = api ?? ApiClient(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<AuthResponse> login(String email, String password) async {
    final response = await _api.post(ApiConstants.login, data: LoginRequest(email: email, password: password).toJson());
    final authResponse = AuthResponse.fromJson(response.data);
    await _storage.write(key: 'access_token', value: authResponse.token);
    if (authResponse.refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: authResponse.refreshToken);
    }
    return authResponse;
  }

  Future<SendOtpResult> sendOtp(String phone) async {
    final response = await _api.post(ApiConstants.sendOtp, data: SendOtpRequest(phone: phone).toJson());
    final raw = response.data is String ? jsonDecode(response.data as String) : response.data;
    final data = (raw as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
    return SendOtpResult.fromJson(data);
  }

  Future<AuthResponse> verifyOtp(String phone, String otp) async {
    final response = await _api.post(ApiConstants.verifyOtp, data: OtpRequest(phone: phone, otp: otp).toJson());
    final authResponse = AuthResponse.fromJson(response.data);
    await _storage.write(key: 'access_token', value: authResponse.token);
    if (authResponse.refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: authResponse.refreshToken);
    }
    return authResponse;
  }

  Future<UserModel?> getProfile() async {
    try {
      final response = await _api.get(ApiConstants.me);
      final data = response.data['data'] as Map<String, dynamic>? ?? response.data as Map<String, dynamic>?;
      if (data != null) return UserModel.fromJson(data);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _api.postMultipart('/auth/me/avatar', data: formData);
    final data = response.data is Map<String, dynamic> ? response.data['data'] : response.data as Map<String, dynamic>?;
    if (data == null) return null;
    final userData = data['user'] as Map<String, dynamic>?;
    if (userData == null) return null;
    return UserModel.fromJson(userData);
  }

  Future<UserModel?> updateName(String name) async {
    final response = await _api.patch(ApiConstants.me, data: {'name': name});
    final data = response.data is Map<String, dynamic> ? response.data['data'] : response.data as Map<String, dynamic>?;
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    try { await _api.post(ApiConstants.logout); } catch (_) {}
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<String?> getToken() => _storage.read(key: 'access_token');
}

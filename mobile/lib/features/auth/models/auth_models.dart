import 'user_model.dart';

class LoginRequest {
  final String email;
  final String password;
  LoginRequest({required this.email, required this.password});
  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class OtpRequest {
  final String phone;
  final String otp;
  OtpRequest({required this.phone, required this.otp});
  Map<String, dynamic> toJson() => {'phone': phone, 'otp': otp};
}

class SendOtpRequest {
  final String phone;
  SendOtpRequest({required this.phone});
  Map<String, dynamic> toJson() => {'phone': phone};
}

class AuthResponse {
  final String token;
  final String? refreshToken;
  final UserModel? user;

  AuthResponse({required this.token, this.refreshToken, this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return AuthResponse(
      token: data['access_token'] as String? ?? data['token'] as String? ?? '',
      refreshToken: data['refresh_token'] as String?,
      user: data['user'] != null ? UserModel.fromJson(data['user']) : null,
    );
  }
}

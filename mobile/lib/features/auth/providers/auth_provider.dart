import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final loggedIn = await _repository.isLoggedIn();
    if (loggedIn) {
      final user = await _repository.getProfile();
      state = AsyncValue.data(user);
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repository.login(email, password);
      final user = await _repository.getProfile();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendOtp(String phone) async {
    await _repository.sendOtp(phone);
  }

  Future<void> verifyOtp(String phone, String otp) async {
    state = const AsyncValue.loading();
    try {
      await _repository.verifyOtp(phone, otp);
      final user = await _repository.getProfile();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> updateAvatar(String filePath) async {
    try {
      final updated = await _repository.uploadAvatar(filePath);
      if (updated != null) state = AsyncValue.data(updated);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateName(String name) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateName(name);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshProfile() async {
    final user = await _repository.getProfile();
    if (user != null) state = AsyncValue.data(user);
  }
}

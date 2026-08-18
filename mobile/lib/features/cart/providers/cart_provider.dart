import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_models.dart';

const _cartKey = 'persisted_cart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cartKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) state = list;
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cartKey,
        jsonEncode(state.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  void addItem(CartItem item) {
    final index = state.indexWhere((i) => i.productId == item.productId && i.cutType == item.cutType);
    if (index >= 0) {
      state[index].weightKg += item.weightKg;
      state = [...state];
    } else {
      state = [...state, item];
    }
    _save();
  }

  void removeItem(int index) {
    state = [...state]..removeAt(index);
    _save();
  }

  void updateQuantity(int index, double kg) {
    if (kg <= 0) {
      removeItem(index);
      return;
    }
    state[index].weightKg = kg;
    state = [...state];
    _save();
  }

  void clear() {
    state = [];
    _save();
  }

  double get subtotal => state.fold(0, (sum, item) => sum + item.subtotal);
  double get deliveryCharge => subtotal >= 1000 ? 0 : 50;
  double get total => subtotal + deliveryCharge;
  bool get hasFreeDelivery => subtotal >= 1000;
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());

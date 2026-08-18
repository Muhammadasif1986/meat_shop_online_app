import 'package:flutter_test/flutter_test.dart';
import 'package:abdul_ghaffar_meat_shop/features/cart/models/cart_models.dart';

void main() {
  group('CartItem', () {
    test('should calculate subtotal correctly', () {
      final item = CartItem(
        productId: '1',
        name: 'Beef',
        nameUr: 'گائے کا گوشت',
        image: '',
        pricePerKg: 800,
        weightKg: 1.5,
        cutType: 'curry_cut',
      );

      expect(item.subtotal, equals(1200.0));
    });

    test('should use default values', () {
      final item = CartItem(
        productId: '1',
        name: 'Chicken',
        nameUr: 'چکن',
        image: '',
        pricePerKg: 500,
      );

      expect(item.weightKg, equals(1.0));
      expect(item.cutType, equals('curry_cut'));
      expect(item.subtotal, equals(500.0));
    });
  });
}

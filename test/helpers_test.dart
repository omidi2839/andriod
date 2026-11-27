import 'package:flutter_test/flutter_test.dart';
import 'package:almas_shop/main.dart';
void main() {
  test('Arabic and Persian digits normalize', () {
    expect(norm('٣۴'), '34');
  });
  test('IQD formatting', () {
    expect(money(495000), '495,000 د.ع');
  });
}

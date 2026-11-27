import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:almas_shop/product_photo.dart';
import 'package:almas_shop/main.dart';
void main() {
  test('Arabic and Persian digits normalize', () {
    expect(norm('٣۴'), '34');
  });
  test('media rejects HTML and accepts PNG signature', () {
    expect(looksLikeImage(Uint8List.fromList('<html>login page</html>'.codeUnits)), isFalse);
    expect(looksLikeImage(Uint8List.fromList([137,80,78,71,13,10,26,10,0,0,0,0])), isTrue);
  });
  test('media keeps the API base path', () {
    final m=ProductMedia(Uri.parse('https://example.com/api/'));
    expect(m.endpoint('store_product_showcase/thumbnail/42').toString(),'https://example.com/api/store_product_showcase/thumbnail/42');
  });
  test('IQD formatting', () {
    expect(money(495000), '495,000 د.ع');
  });
}

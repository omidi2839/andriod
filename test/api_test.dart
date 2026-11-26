import 'package:flutter_test/flutter_test.dart';
import 'package:almas_catalog_native/api.dart';
import 'package:almas_catalog_native/main.dart';
void main(){
 test('HTTPS catalog root',(){expect(CatalogApi.parseRoot('https://sejadalmas.iq/almas_catalog/catalog/').path,'/almas_catalog/catalog');expect(()=>CatalogApi.parseRoot('http://sejadalmas.iq/almas_catalog/catalog'),throwsA(isA<ApiError>()));expect(()=>CatalogApi.parseRoot('https://sejadalmas.iq/store'),throwsA(isA<ApiError>()));});
 test('endpoint and query',(){final a=CatalogApi('https://sejadalmas.iq/almas_catalog/catalog');expect(a.url('inventory',{'page':'2'}).toString(),'https://sejadalmas.iq/almas_catalog/catalog/inventory?page=2');expect(a.url('reservation_detail',{'item_id':'44'}).queryParameters['item_id'],'44');a.close();});
 test('unknown quantities are not zero',(){expect(n(null),'—');expect(n(0),'0');expect(n(320000),'320٬000');});
 test('record parsing',(){expect(records([{'id':1}]).first['id'],1);expect(()=>records(null),throwsA(isA<ApiError>()));});
}

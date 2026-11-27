import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

// Public images only. Separate transport from login/CSRF cookies.
class ProductMedia {
  final Uri base;
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 12), receiveTimeout: const Duration(seconds: 25), followRedirects: false));
  final Map<String, Future<Uint8List>> _pending = {};
  final Map<String, Uint8List> _cache = {};
  int _size = 0;
  ProductMedia(this.base);
  Uri endpoint(String path) => base.resolve(path);
  void invalidate(int id,bool full){final old=_cache.remove('$id/$full');if(old!=null)_size-=old.length;}
  Future<Uint8List> load(int id, bool full) {
    final key = '$id/$full';
    final cached = _cache.remove(key);
    if (cached != null) { _cache[key] = cached; return Future.value(cached); }
    return _pending.putIfAbsent(key, () async {
      try {
        final bytes = await _fetch(id, full);
        _cache[key] = bytes; _size += bytes.length;
        while (_size > 24 * 1024 * 1024 || _cache.length > 100) { final k = _cache.keys.first; _size -= _cache.remove(k)!.length; }
        return bytes;
      } finally { _pending.remove(key); }
    });
  }
  Future<Uint8List> _fetch(int id, bool full) async {
    if (id <= 0 || base.scheme != 'https') throw StateError('Invalid media request');
    final paths = full ? ['image', 'thumbnail'] : ['thumbnail', 'image'];
    // Prefer direct binary delivery, then use the dedicated JSON route if the legacy
    // image response is blocked, redirected or not a valid image.
    for (final path in paths.take(1)) {
      try { return await _binary(id, path); } catch (_) {}
    }
    try {
      final r = await _dio.getUri(endpoint('store_product_showcase/mobile_media').replace(queryParameters: {'id':'$id','full':full?'1':'0'}), options: Options(headers: {'Accept':'application/json','X-Requested-With':'XMLHttpRequest'}));
      final data = r.data is String ? jsonDecode(r.data as String) : r.data;
      if (data is! Map || data['success'] != true || data['data'] is! String || '${data['id']}' != '$id') throw StateError('Invalid image response');
      final encoded = data['data'] as String;
      if (encoded.length > 12 * 1024 * 1024) throw StateError('Image too large');
      final bytes = base64Decode(encoded);
      if (!looksLikeImage(bytes)) throw StateError('Invalid image data');
      return bytes;
    } catch (_) { return _binary(id, paths.last); }
  }
  Future<Uint8List> _binary(int id, String path) async {
    final r = await _dio.getUri<List<int>>(endpoint('store_product_showcase/$path/$id'),options: Options(responseType: ResponseType.bytes,headers: {'Accept':'image/*'}));
    final bytes = Uint8List.fromList(r.data ?? const <int>[]);
    if (bytes.length > 8 * 1024 * 1024 || !looksLikeImage(bytes)) throw StateError('Invalid image response');
    return bytes;
  }
}
// Reject HTML/login pages even when returned with HTTP 200.
bool looksLikeImage(Uint8List b) => b.length >= 12 && ((b[0]==255 && b[1]==216 && b[2]==255) || (b[0]==137 && b[1]==80 && b[2]==78 && b[3]==71) || (b[0]==71 && b[1]==73 && b[2]==70) || (b[0]==82 && b[1]==73 && b[2]==70 && b[3]==70 && b[8]==87 && b[9]==69 && b[10]==66 && b[11]==80));

class ProductPhoto extends StatefulWidget {
  final ProductMedia media; final int id; final bool full;
  const ProductPhoto({super.key,required this.media,required this.id,this.full=false});
  @override State<ProductPhoto> createState()=>_ProductPhotoState();
}
class _ProductPhotoState extends State<ProductPhoto> {
  late Future<Uint8List> _future;
  @override void initState(){super.initState();_load();}
  @override void didUpdateWidget(covariant ProductPhoto old){super.didUpdateWidget(old);if(old.id!=widget.id||old.full!=widget.full||old.media!=widget.media)_load();}
  void _load(){_future=widget.media.load(widget.id,widget.full);}
  Widget _missing()=>Center(child:InkWell(onTap:()=>setState((){widget.media.invalidate(widget.id,widget.full);_load();}),borderRadius:BorderRadius.circular(16),child:const Padding(padding:EdgeInsets.all(6),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.broken_image_outlined,color:Color(0xff977b56),size:25),SizedBox(height:4),Text('إعادة تحميل الصورة',textAlign:TextAlign.center,style:TextStyle(fontSize:10,color:Color(0xff796c5e)))]))));
  @override Widget build(BuildContext context)=>FutureBuilder<Uint8List>(future:_future,builder:(context,snapshot){if(snapshot.connectionState!=ConnectionState.done)return const Center(child:SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)));if(!snapshot.hasData)return _missing();return Image.memory(snapshot.data!,fit:BoxFit.contain,gaplessPlayback:false,cacheWidth:widget.full?null:520,errorBuilder:(_,__,___)=>_missing());});
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:html/parser.dart' as html;

class ApiError implements Exception {
  final String code;
  const ApiError(this.code);
}
List<Map<String,dynamic>> records(dynamic value) {
  if(value is! List) throw const ApiError('DATA');
  return value.map((e)=>Map<String,dynamic>.from(e as Map)).toList();
}
int integer(dynamic value, [int fallback=0]) => int.tryParse(value.toString()) ?? fallback;

class CatalogApi {
  final Uri root;
  final HttpClient client=HttpClient()..connectionTimeout=const Duration(seconds:12);
  final Map<String,Cookie> cookies={};
  bool closed=false;
  CatalogApi(String address):root=parseRoot(address);
  static Uri parseRoot(String input){
    final u=Uri.tryParse(input.trim());
    if(u==null||u.scheme!='https'||u.host.isEmpty||u.userInfo.isNotEmpty||u.hasQuery||u.hasFragment)throw const ApiError('HTTPS');
    final p=u.path.replaceFirst(RegExp(r'/+$'),'');
    if(!p.endsWith('/almas_catalog/catalog')&&!p.endsWith('/almas-catalog'))throw const ApiError('PATH');
    return u.replace(path:p);
  }
  Uri url(String path,[Map<String,String>? q])=>root.replace(path:'${root.path}/$path',queryParameters:q);
  bool matches(Cookie c,Uri u){
    final p=c.path??'/';
    return (c.expires==null||c.expires!.isAfter(DateTime.now()))&&(u.path==p||(u.path.startsWith(p)&&(p.endsWith('/')||u.path.substring(p.length).startsWith('/'))));
  }
  Future<({int status,Uint8List bytes})> request(String path,{Map<String,String>? query,Map<String,String>? form})async{
    if(closed)throw const ApiError('AUTH');
    try{
      final u=url(path,query);
      final req=await client.openUrl(form==null?'GET':'POST',u).timeout(const Duration(seconds:15));
      req.headers.set(HttpHeaders.cacheControlHeader,'no-cache, no-store');
      req.followRedirects=false;
      for(final c in cookies.values){if(matches(c,u))req.cookies.add(c);}
      if(form!=null){req.headers.contentType=ContentType('application','x-www-form-urlencoded',charset:'utf-8');req.write(Uri(queryParameters:form).query);}
      final res=await req.close().timeout(const Duration(seconds:20));
      if(closed)throw const ApiError('AUTH');
      for(final c in res.cookies){
        final domain=c.domain?.replaceFirst(RegExp(r'^\.'),'').toLowerCase();
        if(domain!=null&&domain!=root.host.toLowerCase())continue;
        if(c.value.isEmpty||(c.maxAge!=null&&c.maxAge!<=0)||(c.expires!=null&&!c.expires!.isAfter(DateTime.now()))){cookies.remove(c.name);}
        else if(cookies.length<24||cookies.containsKey(c.name)){cookies[c.name]=c;}
      }
      final b=BytesBuilder(copy:false);
      await for(final chunk in res.timeout(const Duration(seconds:20))){
        if(b.length+chunk.length>4194304)throw const ApiError('SIZE');
        b.add(chunk);
      }
      return(status:res.statusCode,bytes:b.takeBytes());
    } on ApiError{rethrow;} on HandshakeException{throw const ApiError('TLS');} on TimeoutException{throw const ApiError('NETWORK');} on SocketException{throw const ApiError('NETWORK');} on HttpException{throw const ApiError('NETWORK');}
  }
  Map<String,String> hidden(Uint8List bytes){
    final f=<String,String>{};
    for(final i in html.parse(utf8.decode(bytes,allowMalformed:true)).querySelectorAll('form input[type=hidden]')){
      final n=i.attributes['name'],v=i.attributes['value'];if(n!=null&&v!=null&&n.length<=100&&v.length<=300)f[n]=v;
    }
    if(!f.containsKey('alc_form_token'))throw const ApiError('FORM');return f;
  }
  Future<void> login(String user,String pass)async{
    cookies.clear();final r=await request('login');if(r.status!=200)throw const ApiError('LOGIN');
    final f=hidden(r.bytes);f['username']=user.trim();f['password']=pass;
    final result=await request('login',form:f);if(result.status!=302&&result.status!=303)throw const ApiError('LOGIN');
  }
  Future<Map<String,dynamic>> get(String path,[Map<String,String>? query])async{
    final r=await request(path,query:query);
    if(r.status==401||r.status==403)throw const ApiError('AUTH');
    if(r.status==404)throw const ApiError('UPDATE');if(r.status!=200)throw const ApiError('DATA');
    try{return Map<String,dynamic>.from(jsonDecode(utf8.decode(r.bytes)) as Map);}catch(_){throw const ApiError('DATA');}
  }
  Future<Map<String,dynamic>> products(Map<String,String> filters,int page,int afterId)async{
    final nonce=DateTime.now().microsecondsSinceEpoch.toString();
    final j=await get('data',{...filters,'page':'$page','native':'1','cursor':'1','after_id':'$afterId','request_id':nonce});
    if(j['native_pricing_version']!=3)throw const ApiError('UPDATE');
    if(j['request_id']!=nonce||integer(j['after_id'],-1)!=afterId||integer(j['page'])!=page)throw const ApiError('PAGE');
    final next=integer(j['next_cursor']);if(j['has_more']==true&&(next<1||(afterId>0&&next>=afterId)))throw const ApiError('PAGE');
    records(j['items']);return j;
  }
  Future<Map<String,dynamic>> racks(int id)=>get('racks',{'rack_id':'$id'});
  Future<Map<String,dynamic>> board(String name,String query,int page){
    if(name!='inventory'&&name!='reservations')throw const ApiError('DATA');
    return get(name,{'q':query,'page':'$page'});
  }
  Future<List<Map<String,dynamic>>> details(int id)async=>records((await get('reservation_detail',{'item_id':'$id'}))['items']);
  Future<void> logout()async{try{final r=await request('logout');if(r.status==200)await request('logout',form:hidden(r.bytes));}catch(_){}finally{close();}}
  void close(){closed=true;cookies.clear();client.close(force:true);}
}

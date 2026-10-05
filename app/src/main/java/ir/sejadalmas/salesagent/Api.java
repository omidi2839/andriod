package ir.sejadalmas.salesagent;
import org.json.*;import java.io.*;import java.net.*;import java.nio.charset.StandardCharsets;
public class Api{
 private final String base,token;
 Api(String b,String t){base=normalize(b);token=t==null?"":t;}
 static String normalize(String s){s=s==null?"":s.trim();s=s.replace("http;//","http://").replace("https;//","https://");if(!s.matches("(?i)^https?://.*"))s="https://"+s;s=s.replaceAll("/+$","");return s;}
 JSONObject call(String path,String method,JSONObject body)throws Exception{
  String[] roots={base+"/sales_mobile_api/api/",base+"/sales-mobile-api/"};Exception last=null;
  for(String root:roots){try{return request(root+path,method,body);}catch(Exception e){last=e;}}
  throw new Exception(last==null?"پاسخ معتبر از API دریافت نشد":last.getMessage());
 }
 private JSONObject request(String url,String method,JSONObject body)throws Exception{
  HttpURLConnection c=(HttpURLConnection)new URL(url).openConnection();c.setConnectTimeout(15000);c.setReadTimeout(20000);c.setInstanceFollowRedirects(false);c.setRequestMethod(method);c.setRequestProperty("Accept","application/json");c.setRequestProperty("Content-Type","application/json; charset=utf-8");c.setRequestProperty("X-Requested-With","XMLHttpRequest");if(!token.isEmpty())c.setRequestProperty("Authorization","Bearer "+token);if(body!=null){c.setDoOutput(true);try(OutputStream o=c.getOutputStream()){o.write(body.toString().getBytes(StandardCharsets.UTF_8));}}
  int code=c.getResponseCode();InputStream in=code>=400?c.getErrorStream():c.getInputStream();StringBuilder s=new StringBuilder();if(in!=null)try(BufferedReader r=new BufferedReader(new InputStreamReader(in,StandardCharsets.UTF_8))){String x;while((x=r.readLine())!=null)s.append(x);}String raw=s.toString().trim();if(code>=300&&code<400)throw new Exception("مسیر API به صفحه وب هدایت شد");if(raw.isEmpty())throw new Exception("پاسخ خالی از سرور");if(raw.startsWith("<")||raw.toLowerCase().contains("<!doctype"))throw new Exception("API فعال نیست یا مسیر آن به صفحه وب سامانه می‌رسد");try{return new JSONObject(raw);}catch(JSONException e){throw new Exception("پاسخ API از نوع JSON معتبر نیست (HTTP "+code+")");}
 }
}

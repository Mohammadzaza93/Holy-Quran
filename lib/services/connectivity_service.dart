import 'package:http/http.dart' as http;

/// فحص حقيقي لإمكانية الوصول للإنترنت (وليس مجرد وجود شبكة واي فاي).
class ConnectivityService {
  static Future<bool> isOnline() async {
    try {
      final r = await http
          .head(Uri.parse('https://api.alquran.cloud/v1/ayah/1:1'))
          .timeout(const Duration(seconds: 4));
      return r.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}

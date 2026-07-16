// lib/services/token_interceptor.dart
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../network/network.dart';

class TokenInterceptor {
  static const String _tokenKey = 'auth_token';

  // Sama seperti di AuthService: batasi lama tunggu supaya request yang
  // dipakai flow logout/ganti password tidak menggantung tanpa batas
  // saat sinyal buruk.
  static const Duration _timeout = Duration(seconds: 15);

  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ?? '';

    return {
      ...NetworkUrl.jsonHeaders(),
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final defaultHeaders = await getHeaders();
    final mergedHeaders = {...defaultHeaders, ...?headers};

    return http.post(url, headers: mergedHeaders, body: body).timeout(_timeout);
  }

  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final defaultHeaders = await getHeaders();
    final mergedHeaders = {...defaultHeaders, ...?headers};

    return http.get(url, headers: mergedHeaders).timeout(_timeout);
  }
}
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_token_store.dart';
import '../config/api_config.dart';
import 'api_exception.dart';

/// عميل HTTP بسيط لـ JSON REST — يطابق عادةً Django REST framework.
class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Uri _uri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}$normalized');
  }

  Map<String, String> _headers({Map<String, String>? extra}) {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      ...?extra,
      if (AuthTokenStore.accessToken != null && AuthTokenStore.accessToken!.isNotEmpty)
        'Authorization': 'Bearer ${AuthTokenStore.accessToken}',
    };
  }

  static String _parseErrorBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['detail'] != null) return decoded['detail'].toString();
        if (decoded['non_field_errors'] is List && (decoded['non_field_errors'] as List).isNotEmpty) {
          return (decoded['non_field_errors'] as List).first.toString();
        }
        final firstKey = decoded.keys.isNotEmpty ? decoded.keys.first : null;
        if (firstKey != null && decoded[firstKey] is List && (decoded[firstKey] as List).isNotEmpty) {
          return (decoded[firstKey] as List).first.toString();
        }
      }
    } catch (_) {}
    return body.isEmpty ? 'خطأ من الخادم' : body;
  }

  dynamic _handleResponse(http.Response r) {
    final bodyStr = utf8.decode(r.bodyBytes);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (bodyStr.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(bodyStr);
      return decoded;
    }
    throw ApiException(r.statusCode, _parseErrorBody(bodyStr));
  }

  Future<dynamic> get(String path) async {
    try {
      final r = await _http.get(_uri(path), headers: _headers());
      return _handleResponse(r);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'فشل الاتصال: $e');
    }
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    try {
      final r = await _http.post(
        _uri(path),
        headers: _headers(),
        body: body == null ? null : jsonEncode(body),
      );
      return _handleResponse(r);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'فشل الاتصال: $e');
    }
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    try {
      final r = await _http.patch(
        _uri(path),
        headers: _headers(),
        body: jsonEncode(body),
      );
      return _handleResponse(r);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'فشل الاتصال: $e');
    }
  }

  void close() => _http.close();
}

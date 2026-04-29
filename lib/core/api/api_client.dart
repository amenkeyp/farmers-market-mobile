import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/failure.dart';
import '../storage/secure_storage.dart';
import 'api_config.dart';

final secureStorageProvider = Provider<SecureStorage>((_) => SecureStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(secureStorageProvider));
});

/// Thin Dio wrapper that:
///  - injects bearer token from secure storage
///  - normalizes the Laravel envelope `{ success, message, data }`
///  - converts Dio errors into [Failure]
class ApiClient {
  final Dio dio;
  final SecureStorage _storage;

  ApiClient(this._storage)
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          validateStatus: (s) => s != null && s < 600,
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  /// Returns the `data` field of the envelope.
  Future<T> request<T>(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    try {
      final res = await dio.request<dynamic>(
        path,
        queryParameters: query,
        data: body,
        options: Options(method: method),
      );
      final data = res.data;

      if (res.statusCode == 401) {
        await _storage.clear();
        throw const Failure(
          'Session expirée. Veuillez vous reconnecter.',
          statusCode: 401,
        );
      }
      if (res.statusCode == 422 && data is Map) {
        throw Failure(
          (data['message'] as String?) ?? 'Données invalides.',
          statusCode: 422,
          validation: _parseErrors(data['errors']),
        );
      }
      if (res.statusCode != null && res.statusCode! >= 500) {
        throw Failure(
          'Erreur serveur. Veuillez réessayer plus tard.',
          statusCode: res.statusCode,
        );
      }
      if (res.statusCode != null && res.statusCode! >= 400) {
        final msg = (data is Map && data['message'] is String)
            ? data['message'] as String
            : 'Erreur ${res.statusCode}.';
        throw Failure(msg, statusCode: res.statusCode);
      }
      if (data is Map && data['success'] == false) {
        throw Failure((data['message'] as String?) ?? 'Erreur API.');
      }
      if (data is Map && data.containsKey('data')) {
        return data['data'] as T;
      }
      return data as T;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Failure.offline();
      }
      throw Failure(e.message ?? 'Erreur réseau.');
    }
  }

  Map<String, List<String>>? _parseErrors(dynamic raw) {
    if (raw is! Map) return null;
    return raw.map(
      (k, v) =>
          MapEntry(k.toString(), (v as List).map((e) => e.toString()).toList()),
    );
  }
}

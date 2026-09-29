import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings.dart';

/// A failed call, with the server's error code and a message the user can read.
class ApiException implements Exception {
  const ApiException(this.code, this.message, {this.status});

  final String code;
  final String message;
  final int? status;

  /// No answer at all: no signal, wrong address, or the laptop is off.
  bool get isNetwork => status == null;

  @override
  String toString() => 'ApiException($code, $status): $message';
}

/// Talks to the FastAPI backend. Adds the login token to every request and
/// turns every failure into an ApiException.
class ApiClient {
  ApiClient({required String baseUrl, String? token, this.simulateNoSignal = false})
      : _dio = Dio(BaseOptions(
          baseUrl: '$baseUrl/api/v1',
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 20),
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        )),
        _healthUrl = '$baseUrl/health';

  final Dio _dio;
  final String _healthUrl;

  /// Demo switch: behave exactly as if there were no network.
  final bool simulateNoSignal;

  static const _noSignal = ApiException('no_signal', 'No signal.');

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) => _send(() => _dio.post<dynamic>(path, data: body));

  /// "Online" means the server answered /health within 3 seconds, not just
  /// that Wi-Fi is on (Wi-Fi without internet or without the laptop is offline).
  Future<bool> isServerReachable() async {
    if (simulateNoSignal) return false;
    try {
      final response = await _dio.get<dynamic>(_healthUrl,
          options: Options(sendTimeout: const Duration(seconds: 3), receiveTimeout: const Duration(seconds: 3)));
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    if (simulateNoSignal) throw _noSignal;
    try {
      return (await call()).data;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  static ApiException _toApiException(DioException error) {
    final response = error.response;
    if (response == null) {
      return ApiException('network', error.message ?? 'No answer from the server.');
    }
    final data = response.data;
    if (data is Map && data['error'] is Map) {
      final body = data['error'] as Map;
      return ApiException('${body['code']}', '${body['message']}', status: response.statusCode);
    }
    return ApiException('http_${response.statusCode}', 'The server said ${response.statusCode}.',
        status: response.statusCode);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final settings = ref.watch(settingsProvider);
  return ApiClient(
      baseUrl: settings.apiBaseUrl, token: settings.token, simulateNoSignal: settings.simulateNoSignal);
});

/// Checks the server every 60 seconds (and at once when settings change).
final serverOnlineProvider = StreamProvider<bool>((ref) async* {
  final api = ref.watch(apiClientProvider);
  while (true) {
    yield await api.isServerReachable();
    await Future<void>.delayed(const Duration(seconds: 60));
  }
});

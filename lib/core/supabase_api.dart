import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'config.dart';

/// Keeps repository contracts while PostgREST executes the database RPC.
/// No local Node server is used in the published application.
Dio buildSupabaseDio({
  required TokenProvider tokenProvider,
  required Future<bool> Function() refreshTokens,
  required Future<void> Function() onSessionExpired,
}) {
  final dio = buildDio(
      tokenProvider: tokenProvider,
      refreshTokens: refreshTokens,
      onSessionExpired: onSessionExpired);
  dio.options.baseUrl = supabaseUrl;
  dio.interceptors.insert(
      0,
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path != '/rest/v1/rpc/studio_api') {
            final uri = Uri.parse(options.path);
            final arguments = <String, dynamic>{
              'endpoint': uri.path,
              'method': options.method,
              'query': {...uri.queryParameters, ...options.queryParameters},
              'payload': options.data ?? <String, dynamic>{},
            };
            options.path = '/rest/v1/rpc/studio_api';
            options.method = 'POST';
            options.queryParameters = {};
            options.data = arguments;
          }
          options.headers['apikey'] = supabasePublishableKey;
          handler.next(options);
        },
        onResponse: (response, handler) {
          final data = response.data;
          if (response.statusCode == 422 && data is Map) {
            final detail = data['details'];
            if (detail is String) {
              try {
                final errors = jsonDecode(detail);
                if (errors is Map) {
                  response.data = {...data, 'errors': errors};
                }
              } on FormatException {/* Message remains available. */}
            }
          }
          handler.next(response);
        },
      ));
  return dio;
}

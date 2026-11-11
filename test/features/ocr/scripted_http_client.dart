import 'dart:convert';

import 'package:http/http.dart' as http;

http.Response jsonHttpResponse(Object? body, [int status = 200]) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

/// Google Cloud Vision JSON for a bad API key: HTTP 400, not 401/403.
/// No real key. Used by engine / widget tests with [ScriptedHttpClient].
Map<String, Object?> cloudVisionApiKeyInvalidError() {
  return {
    'error': {
      'code': 400,
      'message': 'API key not valid. Please pass a valid API key.',
      'status': 'INVALID_ARGUMENT',
      'details': [
        {
          '@type': 'type.googleapis.com/google.rpc.ErrorInfo',
          'reason': 'API_KEY_INVALID',
          'domain': 'googleapis.com',
        },
      ],
    },
  };
}

/// Fake `package:http` client. No network. Records requests for assertions.
class ScriptedHttpClient extends http.BaseClient {
  ScriptedHttpClient(this.handler);

  final Future<http.Response> Function(http.BaseRequest request) handler;
  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final response = await handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }
}

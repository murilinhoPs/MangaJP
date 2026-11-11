import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/cloud_vision_exception.dart';
import '../domain/ocr_engine.dart';
import '../domain/ocr_engine_ids.dart';
import '../domain/ocr_result.dart';
import 'cloud_vision_response.dart';

/// Cloud Vision (`cloud_vision`) — `DOCUMENT_TEXT_DETECTION`, `ja`.
///
/// API key goes in `X-Goog-Api-Key`. Never in the query string, logs, or
/// exception text. Not the app default (ADR-0001).
class CloudVisionOcrEngine implements OcrEngine {
  CloudVisionOcrEngine({
    required this.readApiKey,
    this.client,
    this.timeout = defaultTimeout,
    this.log,
  });

  static const defaultTimeout = Duration(seconds: 15);
  static const endpoint = 'https://vision.googleapis.com/v1/images:annotate';
  static const apiKeyHeader = 'X-Goog-Api-Key';

  /// 1×1 PNG used only by **Testar chave** (one Vision call, user's quota).
  static final Uint8List probePng = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  final Future<String?> Function() readApiKey;
  final http.Client? client;
  final Duration timeout;
  final void Function(String message)? log;

  @override
  String get engineId => OcrEngineIds.cloudVision;

  /// Same request as [recognize] on [probePng]. Throws typed errors; ok = void.
  Future<void> testKey() async {
    await recognize(probePng);
  }

  @override
  Future<OcrResult> recognize(Uint8List image) async {
    final apiKey = (await readApiKey())?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw const CloudVisionMissingApiKey();
    }

    final uri = Uri.parse(endpoint);
    final payload = jsonEncode({
      'requests': [
        {
          'image': {'content': base64Encode(image)},
          'features': [
            {'type': 'DOCUMENT_TEXT_DETECTION'},
          ],
          'imageContext': {
            'languageHints': ['ja'],
          },
        },
      ],
    });

    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              apiKeyHeader: apiKey,
            },
            body: payload,
          )
          .timeout(timeout);
      return _parseHttp(response);
    } on CloudVisionException {
      rethrow;
    } on TimeoutException {
      _log('Cloud Vision timeout');
      throw const CloudVisionTimeout();
    } on http.ClientException {
      _log('Cloud Vision network error');
      throw const CloudVisionNetworkError();
    } catch (error) {
      final type = error.runtimeType.toString();
      if (type == 'SocketException' ||
          type == 'HandshakeException' ||
          type == 'OSError') {
        _log('Cloud Vision network error');
        throw const CloudVisionNetworkError();
      }
      if (error is FormatException || error is TypeError) {
        _log('Cloud Vision returned unreadable JSON');
        throw const CloudVisionUnexpected();
      }
      _log('Cloud Vision error: ${_redact('$error', apiKey)}');
      throw const CloudVisionUnexpected();
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  OcrResult _parseHttp(http.Response response) {
    Object? decoded;
    final raw = utf8.decode(response.bodyBytes, allowMalformed: true);
    if (raw.isNotEmpty) {
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        decoded = null;
      }
    }
    final status = cloudVisionErrorStatus(decoded);
    final mapped = _mapStatus(
      response.statusCode,
      status,
      invalidApiKeyReason: cloudVisionHasErrorReason(
        decoded,
        _apiKeyInvalidReason,
      ),
    );
    if (mapped != null) {
      _log(
        'Cloud Vision HTTP ${response.statusCode}'
        '${status == null ? '' : ' $status'}',
      );
      throw mapped;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _log('Cloud Vision HTTP ${response.statusCode}');
      throw const CloudVisionUnexpected();
    }
    try {
      return parseCloudVisionResponse(decoded);
    } on FormatException {
      _log('Cloud Vision returned unreadable JSON');
      throw const CloudVisionUnexpected();
    }
  }

  CloudVisionException? _mapStatus(
    int httpStatus,
    String? grpcStatus, {
    bool invalidApiKeyReason = false,
  }) {
    if (httpStatus == 401 ||
        httpStatus == 403 ||
        grpcStatus == 'UNAUTHENTICATED' ||
        grpcStatus == 'PERMISSION_DENIED' ||
        (httpStatus == 400 && invalidApiKeyReason)) {
      return const CloudVisionInvalidApiKey();
    }
    if (httpStatus == 429 || grpcStatus == 'RESOURCE_EXHAUSTED') {
      return const CloudVisionQuotaExceeded();
    }
    return null;
  }

  void _log(String message) {
    log?.call(message);
  }

  static String redact(String text, String apiKey) => _redact(text, apiKey);
}

/// Google Cloud returns this in `error.details[].reason` with HTTP 400
/// `INVALID_ARGUMENT` when the API key is not valid (not 401/403).
const _apiKeyInvalidReason = 'API_KEY_INVALID';

String _redact(String text, String apiKey) {
  if (apiKey.isEmpty) {
    return text;
  }
  return text.replaceAll(apiKey, '***');
}

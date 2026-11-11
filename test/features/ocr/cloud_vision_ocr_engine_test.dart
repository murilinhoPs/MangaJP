import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:manga_jp/features/ocr/data/cloud_vision_ocr_engine.dart';
import 'package:manga_jp/features/ocr/data/cloud_vision_response.dart';
import 'package:manga_jp/features/ocr/domain/cloud_vision_exception.dart';
import 'package:manga_jp/features/ocr/domain/ocr_engine_ids.dart';

import '../capture/fixture_png.dart';
import 'scripted_http_client.dart';

const _fakeKey = 'cv-test-key';

const _jpVisionJson = {
  'responses': [
    {
      'fullTextAnnotation': {
        'text': 'よぉ、相棒\n',
        'pages': [
          {
            'width': 200,
            'height': 80,
            'blocks': [
              {
                'blockType': 'TEXT',
                'confidence': 0.98,
                'boundingBox': {
                  'vertices': [
                    {'x': 8, 'y': 4},
                    {'x': 190, 'y': 4},
                    {'x': 190, 'y': 72},
                    {'x': 8, 'y': 72},
                  ],
                },
                'paragraphs': [
                  {
                    'words': [
                      {
                        'symbols': [
                          {'text': 'よ'},
                          {'text': 'ぉ'},
                        ],
                      },
                      {
                        'symbols': [
                          {'text': '、'},
                        ],
                      },
                      {
                        'symbols': [
                          {'text': '相'},
                          {'text': '棒'},
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      },
    },
  ],
};

void main() {
  test('parse JP DOCUMENT_TEXT_DETECTION into fullText, blocks, Rect', () {
    final result = parseCloudVisionResponse(_jpVisionJson);
    expect(result.engineId, OcrEngineIds.cloudVision);
    expect(result.fullText, 'よぉ、相棒\n');
    expect(result.blocks, hasLength(1));
    expect(result.blocks.single.text, 'よぉ、相棒');
    expect(result.blocks.single.confidence, closeTo(0.98, 1e-9));
    expect(
      result.blocks.single.boundingBox,
      const Rect.fromLTRB(8, 4, 190, 72),
    );
  });

  test('missing API key throws a typed error and does not HTTP', () async {
    var sent = false;
    final client = ScriptedHttpClient((request) async {
      sent = true;
      return http.Response('{}', 200);
    });
    final engine = CloudVisionOcrEngine(
      readApiKey: () async => null,
      client: client,
    );
    await expectLater(
      engine.recognize(fixturePng()),
      throwsA(isA<CloudVisionMissingApiKey>()),
    );
    expect(sent, isFalse);
    expect(client.requests, isEmpty);
  });

  test('POST uses X-Goog-Api-Key and never ?key=', () async {
    final client = ScriptedHttpClient((request) async {
      return jsonHttpResponse(_jpVisionJson);
    });
    final engine = CloudVisionOcrEngine(
      readApiKey: () async => _fakeKey,
      client: client,
    );
    final result = await engine.recognize(fixturePng());
    expect(result.fullText, 'よぉ、相棒\n');
    expect(client.requests, hasLength(1));
    final request = client.requests.single;
    expect(request.method, 'POST');
    expect(request.url.scheme, 'https');
    expect(request.url.host, 'vision.googleapis.com');
    expect(request.url.path, '/v1/images:annotate');
    expect(request.url.queryParameters.containsKey('key'), isFalse);
    expect(request.url.query, isEmpty);
    expect(request.url.toString(), isNot(contains(_fakeKey)));
    expect(request.headers[CloudVisionOcrEngine.apiKeyHeader], _fakeKey);
    final body = (request as http.Request).body;
    expect(body, isNot(contains(_fakeKey)));
    expect(body, contains('DOCUMENT_TEXT_DETECTION'));
    expect(body, contains('"ja"'));
  });

  test(
    '401 and 403 are invalid key; 429 / RESOURCE_EXHAUSTED is quota',
    () async {
      Future<void> expectStatus(int status, Matcher matcher) async {
        final client = ScriptedHttpClient((request) async {
          return http.Response('{"error":{"message":"no"}}', status);
        });
        final engine = CloudVisionOcrEngine(
          readApiKey: () async => _fakeKey,
          client: client,
        );
        await expectLater(engine.recognize(fixturePng()), throwsA(matcher));
      }

      await expectStatus(401, isA<CloudVisionInvalidApiKey>());
      await expectStatus(403, isA<CloudVisionInvalidApiKey>());
      await expectStatus(429, isA<CloudVisionQuotaExceeded>());
      await expectStatus(400, isA<CloudVisionUnexpected>());

      final exhausted = ScriptedHttpClient((request) async {
        return http.Response(
          jsonEncode({
            'responses': [
              {
                'error': {'status': 'RESOURCE_EXHAUSTED', 'message': 'quota'},
              },
            ],
          }),
          200,
        );
      });
      await expectLater(
        CloudVisionOcrEngine(
          readApiKey: () async => _fakeKey,
          client: exhausted,
        ).recognize(fixturePng()),
        throwsA(isA<CloudVisionQuotaExceeded>()),
      );
    },
  );

  test('HTTP 400 with reason API_KEY_INVALID is invalid key', () async {
    Future<void> expectInvalid(Object? body) async {
      final client = ScriptedHttpClient((request) async {
        return jsonHttpResponse(body, 400);
      });
      final engine = CloudVisionOcrEngine(
        readApiKey: () async => _fakeKey,
        client: client,
      );
      await expectLater(
        engine.recognize(fixturePng()),
        throwsA(isA<CloudVisionInvalidApiKey>()),
      );
      await expectLater(
        CloudVisionOcrEngine(
          readApiKey: () async => _fakeKey,
          client: ScriptedHttpClient((request) async {
            return jsonHttpResponse(body, 400);
          }),
        ).testKey(),
        throwsA(isA<CloudVisionInvalidApiKey>()),
      );
    }

    await expectInvalid(cloudVisionApiKeyInvalidError());
    await expectInvalid({
      'responses': [
        {
          'error': {
            'status': 'INVALID_ARGUMENT',
            'details': [
              {'reason': 'API_KEY_INVALID'},
            ],
          },
        },
      ],
    });
  });

  test('HTTP 400 without API_KEY_INVALID stays unexpected', () async {
    Future<void> expectUnexpected(Object? body) async {
      final engine = CloudVisionOcrEngine(
        readApiKey: () async => _fakeKey,
        client: ScriptedHttpClient((request) async {
          return jsonHttpResponse(body, 400);
        }),
      );
      await expectLater(
        engine.recognize(fixturePng()),
        throwsA(isA<CloudVisionUnexpected>()),
      );
    }

    await expectUnexpected({
      'error': {
        'code': 400,
        'message': 'Request had invalid argument.',
        'status': 'INVALID_ARGUMENT',
      },
    });
    await expectUnexpected({
      'error': {
        'status': 'INVALID_ARGUMENT',
        'details': [
          {'reason': 'BAD_IMAGE_DATA'},
        ],
      },
    });
    await expectUnexpected({
      'error': {'details': 'API_KEY_INVALID'},
    });
  });

  test(
    'HTTP 400 with malformed body is unexpected and does not crash',
    () async {
      Future<void> expectUnexpected(http.Response response) async {
        final engine = CloudVisionOcrEngine(
          readApiKey: () async => _fakeKey,
          client: ScriptedHttpClient((request) async => response),
        );
        await expectLater(
          engine.recognize(fixturePng()),
          throwsA(isA<CloudVisionUnexpected>()),
        );
        await expectLater(
          CloudVisionOcrEngine(
            readApiKey: () async => _fakeKey,
            client: ScriptedHttpClient((request) async => response),
          ).testKey(),
          throwsA(isA<CloudVisionUnexpected>()),
        );
      }

      await expectUnexpected(http.Response('{', 400));
      await expectUnexpected(http.Response('not-json', 400));
      await expectUnexpected(http.Response('', 400));
      await expectUnexpected(http.Response('[]', 400));
      await expectUnexpected(
        http.Response('{"error":{"details":[null,1,{"reason":12}]}}', 400),
      );
    },
  );

  test('cloudVisionHasErrorReason reads details and ignores junk', () {
    expect(
      cloudVisionHasErrorReason(
        cloudVisionApiKeyInvalidError(),
        'API_KEY_INVALID',
      ),
      isTrue,
    );
    expect(
      cloudVisionHasErrorReason({
        'error': {'status': 'INVALID_ARGUMENT'},
      }, 'API_KEY_INVALID'),
      isFalse,
    );
    expect(cloudVisionHasErrorReason(null, 'API_KEY_INVALID'), isFalse);
    expect(cloudVisionHasErrorReason('nope', 'API_KEY_INVALID'), isFalse);
    expect(cloudVisionHasErrorReason(<Object?>[], 'API_KEY_INVALID'), isFalse);
    expect(
      cloudVisionHasErrorReason({
        'error': {'details': 'API_KEY_INVALID'},
      }, 'API_KEY_INVALID'),
      isFalse,
    );
    expect(
      cloudVisionHasErrorReason({
        'error': {
          'details': [
            null,
            1,
            {'reason': 12},
          ],
        },
      }, 'API_KEY_INVALID'),
      isFalse,
    );
  });

  test('network error and timeout 15 s are typed', () async {
    final offline = ScriptedHttpClient((request) async {
      throw const SocketException('offline');
    });
    await expectLater(
      CloudVisionOcrEngine(
        readApiKey: () async => _fakeKey,
        client: offline,
      ).recognize(fixturePng()),
      throwsA(isA<CloudVisionNetworkError>()),
    );

    final slow = ScriptedHttpClient((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      return jsonHttpResponse(_jpVisionJson);
    });
    await expectLater(
      CloudVisionOcrEngine(
        readApiKey: () async => _fakeKey,
        client: slow,
        timeout: const Duration(milliseconds: 20),
      ).recognize(fixturePng()),
      throwsA(isA<CloudVisionTimeout>()),
    );
  });

  test('logger and error text never include the API key', () async {
    final logs = <String>[];
    final client = ScriptedHttpClient((request) async {
      return http.Response(
        jsonEncode({
          'error': {
            'message': 'API_KEY_INVALID $_fakeKey',
            'status': 'PERMISSION_DENIED',
          },
        }),
        403,
      );
    });
    final engine = CloudVisionOcrEngine(
      readApiKey: () async => _fakeKey,
      client: client,
      log: logs.add,
    );
    Object? thrown;
    try {
      await engine.recognize(fixturePng());
    } catch (error) {
      thrown = error;
    }
    expect(thrown, isA<CloudVisionInvalidApiKey>());
    expect('$thrown', isNot(contains(_fakeKey)));
    expect(logs.join('\n'), isNot(contains(_fakeKey)));
    expect(
      CloudVisionOcrEngine.redact('header $_fakeKey leaked', _fakeKey),
      'header *** leaked',
    );
  });

  test('Testar chave ok / 401 / 429 / network / timeout', () async {
    Future<void> run({
      required Future<http.Response> Function(http.BaseRequest request) handler,
      required Matcher matcher,
      Duration timeout = CloudVisionOcrEngine.defaultTimeout,
    }) async {
      final engine = CloudVisionOcrEngine(
        readApiKey: () async => _fakeKey,
        client: ScriptedHttpClient(handler),
        timeout: timeout,
      );
      await expectLater(engine.testKey(), matcher);
    }

    await run(
      handler: (request) async => jsonHttpResponse(_jpVisionJson),
      matcher: completes,
    );
    await run(
      handler: (request) async => http.Response('{}', 401),
      matcher: throwsA(isA<CloudVisionInvalidApiKey>()),
    );
    await run(
      handler: (request) async =>
          jsonHttpResponse(cloudVisionApiKeyInvalidError(), 400),
      matcher: throwsA(isA<CloudVisionInvalidApiKey>()),
    );
    await run(
      handler: (request) async => http.Response('{}', 429),
      matcher: throwsA(isA<CloudVisionQuotaExceeded>()),
    );
    await run(
      handler: (request) async => throw http.ClientException('offline'),
      matcher: throwsA(isA<CloudVisionNetworkError>()),
    );
    await run(
      handler: (request) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response('{}', 200);
      },
      matcher: throwsA(isA<CloudVisionTimeout>()),
      timeout: const Duration(milliseconds: 10),
    );
  });
}

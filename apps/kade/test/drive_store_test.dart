// DriveApiStore (googleapis Drive v3) với MockClient: đúng URL/method/header
// Authorization, list → get alt=media, create/update multipart, 401 → DriveException.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kade/data/sync/drive_store.dart';

void main() {
  const json = {'content-type': 'application/json; charset=utf-8'};

  test(
    'find: list trong appDataFolder rồi tải alt=media; header Bearer',
    () async {
      final seen = <http.Request>[];
      final store = DriveApiStore(
        client: MockClient((req) async {
          seen.add(req);
          if (req.method == 'GET' && req.url.path == '/drive/v3/files') {
            return http.Response(
              jsonEncode({
                'files': [
                  {
                    'id': 'old',
                    'name': syncFileName,
                    'modifiedTime': '2026-09-01T00:00:00Z',
                  },
                  {
                    'id': 'newer',
                    'name': syncFileName,
                    'modifiedTime': '2026-09-09T00:00:00Z',
                  },
                ],
              }),
              200,
              headers: json,
            );
          }
          if (req.method == 'GET' && req.url.path == '/drive/v3/files/newer') {
            return http.Response(
              '{"schema": 1, "events": []}',
              200,
              headers: json,
            );
          }
          return http.Response('nope', 404);
        }),
      );
      final file = await store.find('tok');
      expect(file!.id, 'newer');
      expect(file.content, '{"schema": 1, "events": []}');
      expect(seen.length, 2);
      expect(seen[0].url.queryParameters['spaces'], 'appDataFolder');
      expect(seen[0].url.queryParameters['q'], "name = '$syncFileName'");
      expect(seen[0].headers['Authorization'], 'Bearer tok');
      expect(seen[1].url.queryParameters['alt'], 'media');
      expect(seen[1].headers['Authorization'], 'Bearer tok');
    },
  );

  test('find: không có file → null', () async {
    final store = DriveApiStore(
      client: MockClient(
        (req) async => http.Response('{"files": []}', 200, headers: json),
      ),
    );
    expect(await store.find('tok'), isNull);
  });

  test(
    'create: POST upload multipart, parents appDataFolder, có nội dung',
    () async {
      late http.Request seen;
      final store = DriveApiStore(
        client: MockClient((req) async {
          seen = req;
          return http.Response('{"id": "f2"}', 200, headers: json);
        }),
      );
      expect(await store.create('tok', '{"schema":1}'), 'f2');
      expect(seen.method, 'POST');
      expect(seen.url.path, '/upload/drive/v3/files');
      expect(seen.url.queryParameters['uploadType'], 'multipart');
      expect(seen.body, contains('"parents":["appDataFolder"]'));
      expect(seen.body, contains('"name":"$syncFileName"'));
      expect(seen.body, contains(base64.encode(utf8.encode('{"schema":1}'))));
    },
  );

  test('update: PATCH upload multipart theo id', () async {
    late http.Request seen;
    final store = DriveApiStore(
      client: MockClient((req) async {
        seen = req;
        return http.Response('{"id": "f1"}', 200, headers: json);
      }),
    );
    await store.update('tok', 'f1', '{"schema":1,"x":2}');
    expect(seen.method, 'PATCH');
    expect(seen.url.path, '/upload/drive/v3/files/f1');
    expect(
      seen.body,
      contains(base64.encode(utf8.encode('{"schema":1,"x":2}'))),
    );
  });

  test('401 → DriveException(401, message)', () async {
    final store = DriveApiStore(
      client: MockClient(
        (req) async => http.Response(
          '{"error": {"code": 401, "message": "Invalid Credentials"}}',
          401,
          headers: json,
        ),
      ),
    );
    await expectLater(
      store.find('bad'),
      throwsA(
        isA<DriveException>()
            .having((e) => e.status, 'status', 401)
            .having((e) => e.message, 'message', contains('Invalid')),
      ),
    );
  });
}

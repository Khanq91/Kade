// File sync trên Google Drive appDataFolder (plan §3.10, D007): đúng một file
// `kade_events.json`, nội dung = SyncEnvelope (D004). Sync/test chỉ thấy
// [DriveStore]; bản thật [DriveApiStore] dùng googleapis Drive v3 (D003) với
// access token từ GoogleAuth (bước 11).
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Tên file trong appDataFolder.
const syncFileName = 'kade_events.json';

/// Không gian Drive riêng của app (ẩn với user, xóa khi gỡ quyền).
const _appDataSpace = 'appDataFolder';

/// File sync đã tìm thấy trên Drive.
class RemoteFile {
  const RemoteFile({required this.id, required this.content});

  final String id;
  final String content;
}

/// Lỗi Drive kèm HTTP status (401 = token hết hạn/thu hồi — bước 13 xin lại).
class DriveException implements Exception {
  DriveException(this.status, this.message);

  final int? status;
  final String message;

  @override
  String toString() => 'DriveException($status, $message)';
}

/// Đọc / ghi file sync. [token] truyền từng lần vì có thể đổi giữa các lần sync.
abstract class DriveStore {
  /// File sync (id + nội dung) hoặc `null` nếu chưa có.
  Future<RemoteFile?> find(String token);

  /// Tạo file mới với [content], trả id.
  Future<String> create(String token, String content);

  /// Ghi đè nội dung file [id].
  Future<void> update(String token, String id, String content);

  /// Xóa file [id] ("Xóa dữ liệu trên Drive", plan §3.10).
  Future<void> delete(String token, String id);
}

/// Bản thật: Drive REST v3 qua package googleapis, header `Authorization`.
class DriveApiStore implements DriveStore {
  DriveApiStore({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  drive.DriveApi _api(String token) =>
      drive.DriveApi(_BearerClient(_client, token));

  @override
  Future<RemoteFile?> find(String token) => _guard(() async {
    final api = _api(token);
    final list = await api.files.list(
      spaces: _appDataSpace,
      q: "name = '$syncFileName'",
      pageSize: 10,
      $fields: 'files(id,name,modifiedTime)',
    );
    final files = list.files ?? const <drive.File>[];
    if (files.isEmpty) return null;
    // Lỡ có nhiều file cùng tên (2 máy tạo cùng lúc) → lấy file sửa mới nhất.
    files.sort(
      (a, b) => (b.modifiedTime ?? DateTime.utc(1970)).compareTo(
        a.modifiedTime ?? DateTime.utc(1970),
      ),
    );
    final id = files.first.id!;
    final media =
        await api.files.get(
              id,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;
    return RemoteFile(id: id, content: await utf8.decodeStream(media.stream));
  });

  @override
  Future<String> create(String token, String content) => _guard(() async {
    final file = await _api(token).files.create(
      drive.File(
        name: syncFileName,
        parents: const [_appDataSpace],
        mimeType: 'application/json',
      ),
      uploadMedia: _media(content),
      $fields: 'id',
    );
    return file.id!;
  });

  @override
  Future<void> update(String token, String id, String content) =>
      _guard(() async {
        await _api(token).files.update(
          drive.File(),
          id,
          uploadMedia: _media(content),
          $fields: 'id',
        );
      });

  @override
  Future<void> delete(String token, String id) =>
      _guard(() => _api(token).files.delete(id));

  static drive.Media _media(String content) {
    final bytes = utf8.encode(content);
    return drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on drive.DetailedApiRequestError catch (e) {
      throw DriveException(e.status, e.message ?? 'HTTP ${e.status}');
    } on drive.ApiRequestError catch (e) {
      throw DriveException(null, e.message ?? 'Drive');
    }
  }
}

/// http.Client gắn `Authorization: Bearer <token>` vào mọi request.
class _BearerClient extends http.BaseClient {
  _BearerClient(this._inner, this._token);

  final http.Client _inner;
  final String _token;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }
}

/// Mặc định bản thật (http.Client chạy được cả web lẫn Android); test override.
final driveStoreProvider = Provider<DriveStore>((ref) => DriveApiStore());

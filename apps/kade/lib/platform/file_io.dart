// Chọn / lưu file JSON qua `file_picker` cho cả web + Android (plan §4.4;
// §4.7: không dart:io, không dart:html). UI chỉ thấy [FileIo]; test dùng fake.
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Đọc / ghi file văn bản JSON do user chọn.
abstract class FileIo {
  /// Mở hộp chọn file `.json`, trả nội dung; `null` nếu user hủy.
  Future<String?> pickJson();

  /// Lưu [content] thành file tên [name]; `false` nếu user hủy.
  Future<bool> saveJson(String name, String content);
}

/// Bản thật: `file_picker` 12 (web: `<input type=file>` + anchor download;
/// Android: Storage Access Framework).
class FilePickerFileIo implements FileIo {
  @override
  Future<String?> pickJson() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    return utf8.decode(await file.readAsBytes(), allowMalformed: true);
  }

  @override
  Future<bool> saveJson(String name, String content) async {
    final uri = await FilePicker.saveFile(
      fileName: name,
      bytes: utf8.encode(content),
      mimeType: 'application/json',
    );
    // Web: file_picker tự kích hoạt tải xuống và luôn trả null (E015).
    return kIsWeb || uri != null;
  }
}

/// Override trong `main()` bằng [FilePickerFileIo]; test override bằng fake.
final fileIoProvider = Provider<FileIo>(
  (ref) => throw UnimplementedError(
    'fileIoProvider phải được override trong ProviderScope',
  ),
);

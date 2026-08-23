import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/media_storage_service.dart';

typedef MediaDirectoryProvider = Future<Directory> Function();

class LocalMediaStorageService implements MediaStorageService {
  LocalMediaStorageService({MediaDirectoryProvider? directoryProvider})
    : _directoryProvider =
          directoryProvider ?? getApplicationDocumentsDirectory;

  final MediaDirectoryProvider _directoryProvider;

  @override
  bool get isDeviceOnly => true;

  @override
  Future<StoredMedia> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (bytes.isEmpty) {
      throw const MediaFailure('The selected file is empty.');
    }
    try {
      final file = await _fileFor(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return StoredMedia(path: path, downloadUrl: file.uri.toString());
    } on MediaFailure {
      rethrow;
    } on Object {
      throw const MediaFailure(
        'The file could not be saved on this device. Check free space and try again.',
      );
    }
  }

  @override
  Future<void> delete(String path) async {
    if (path.isEmpty) return;
    try {
      final file = await _fileFor(path);
      if (await file.exists()) await file.delete();
    } on MediaFailure {
      rethrow;
    } on Object {
      throw const MediaFailure('The local file could not be removed.');
    }
  }

  Future<File> _fileFor(String logicalPath) async {
    final root = await _directoryProvider();
    final safeSegments = logicalPath
        .split('/')
        .where(
          (segment) => segment.isNotEmpty && segment != '.' && segment != '..',
        )
        .map(_safeSegment)
        .toList();
    if (safeSegments.isEmpty) {
      throw const MediaFailure('The file location is invalid.');
    }
    return File('${root.path}/pawfectcare_media/${safeSegments.join('/')}');
  }

  String _safeSegment(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return cleaned.isEmpty ? 'file' : cleaned;
  }
}

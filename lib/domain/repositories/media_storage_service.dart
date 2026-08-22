import 'dart:typed_data';

abstract interface class MediaStorageService {
  Future<StoredMedia> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  });

  Future<void> delete(String path);
}

class StoredMedia {
  const StoredMedia({required this.path, required this.downloadUrl});
  final String path;
  final String downloadUrl;
}

class MediaFailure implements Exception {
  const MediaFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

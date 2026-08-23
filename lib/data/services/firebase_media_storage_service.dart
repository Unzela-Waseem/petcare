import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/repositories/media_storage_service.dart';

class FirebaseMediaStorageService implements MediaStorageService {
  FirebaseMediaStorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  bool get isDeviceOnly => false;

  @override
  Future<StoredMedia> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final reference = _storage.ref(path);
      await reference.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      return StoredMedia(
        path: path,
        downloadUrl: await reference.getDownloadURL(),
      );
    } on FirebaseException catch (error) {
      throw MediaFailure(switch (error.code) {
        'unauthorized' => 'You are not allowed to upload this file.',
        'quota-exceeded' => 'File storage is currently unavailable.',
        'retry-limit-exceeded' => 'Upload timed out. Please try again.',
        _ => 'The file could not be uploaded securely.',
      });
    }
  }

  @override
  Future<void> delete(String path) async {
    if (path.isEmpty) return;
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') {
        throw const MediaFailure('The stored file could not be removed.');
      }
    }
  }
}

class DemoMediaStorageService implements MediaStorageService {
  const DemoMediaStorageService();

  @override
  bool get isDeviceOnly => true;

  @override
  Future<StoredMedia> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async => StoredMedia(path: path, downloadUrl: '');

  @override
  Future<void> delete(String path) async {}
}

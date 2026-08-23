import 'package:flutter/foundation.dart';

import '../../domain/repositories/media_storage_service.dart';
import 'cloudinary_media_storage_service.dart';

class HybridMediaStorageService implements MediaStorageService {
  const HybridMediaStorageService({
    required this.cloudImages,
    required this.privateFiles,
  });

  final CloudinaryMediaStorageService cloudImages;
  final MediaStorageService privateFiles;

  @override
  bool get isDeviceOnly => false;

  @override
  Future<StoredMedia> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) {
    if (_isPrivateMedicalPath(path)) {
      if (kIsWeb) {
        throw const MediaFailure(
          'Private medical reports can only be attached from the Android or iOS app.',
        );
      }
      return privateFiles.upload(
        path: path,
        bytes: bytes,
        contentType: contentType,
      );
    }
    return cloudImages.upload(
      path: path,
      bytes: bytes,
      contentType: contentType,
    );
  }

  @override
  Future<void> delete(String path) {
    if (cloudImages.owns(path)) return cloudImages.delete(path);
    return privateFiles.delete(path);
  }

  bool _isPrivateMedicalPath(String path) => path.startsWith('medical/');
}

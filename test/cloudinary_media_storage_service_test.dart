import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pawfect_care/data/services/cloudinary_media_storage_service.dart';
import 'package:pawfect_care/data/services/hybrid_media_storage_service.dart';
import 'package:pawfect_care/domain/repositories/media_storage_service.dart';

void main() {
  test('uploads a validated image with an unsigned Cloudinary preset', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'public_id': 'pawfectcare/random-image-id',
          'secure_url':
              'https://res.cloudinary.com/test/image/upload/random-image-id.png',
        }),
        200,
      );
    });
    final service = CloudinaryMediaStorageService(
      cloudName: 'test-cloud',
      uploadPreset: 'test-unsigned',
      client: client,
    );

    final media = await service.upload(
      path: 'pets/pet-1/images/cat photo.png',
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      contentType: 'image/png',
    );

    expect(captured.method, 'POST');
    expect(
      captured.url.toString(),
      'https://api.cloudinary.com/v1_1/test-cloud/image/upload',
    );
    expect(
      captured.headers['content-type'],
      startsWith('multipart/form-data;'),
    );
    expect(media.path, 'cloudinary:image:pawfectcare/random-image-id');
    expect(media.downloadUrl, startsWith('https://res.cloudinary.com/'));
  });

  test(
    'rejects unsupported or oversized public images before upload',
    () async {
      final service = CloudinaryMediaStorageService(
        cloudName: 'test-cloud',
        uploadPreset: 'test-unsigned',
        client: MockClient((_) async => http.Response('{}', 500)),
      );

      expect(
        () => service.upload(
          path: 'pets/pet-1/images/report.pdf',
          bytes: Uint8List.fromList([1]),
          contentType: 'application/pdf',
        ),
        throwsA(isA<MediaFailure>()),
      );
      expect(
        () => service.upload(
          path: 'pets/pet-1/images/large.png',
          bytes: Uint8List(5 * 1024 * 1024 + 1),
          contentType: 'image/png',
        ),
        throwsA(isA<MediaFailure>()),
      );
    },
  );

  test('hybrid storage keeps medical files out of Cloudinary', () async {
    var cloudCalls = 0;
    final cloud = CloudinaryMediaStorageService(
      cloudName: 'test-cloud',
      uploadPreset: 'test-unsigned',
      client: MockClient((_) async {
        cloudCalls += 1;
        return http.Response(
          jsonEncode({
            'public_id': 'pet-image',
            'secure_url':
                'https://res.cloudinary.com/test/image/upload/pet-image.png',
          }),
          200,
        );
      }),
    );
    final privateFiles = _MemoryMediaStorage();
    final hybrid = HybridMediaStorageService(
      cloudImages: cloud,
      privateFiles: privateFiles,
    );

    final report = await hybrid.upload(
      path: 'medical/pet-1/record-1/report.pdf',
      bytes: Uint8List.fromList([1, 2]),
      contentType: 'application/pdf',
    );
    final image = await hybrid.upload(
      path: 'pets/pet-1/images/photo.png',
      bytes: Uint8List.fromList([3, 4]),
      contentType: 'image/png',
    );

    expect(report.downloadUrl, startsWith('file:'));
    expect(privateFiles.uploadCalls, 1);
    expect(cloudCalls, 1);
    expect(image.path, 'cloudinary:image:pet-image');
  });
}

class _MemoryMediaStorage implements MediaStorageService {
  var uploadCalls = 0;

  @override
  bool get isDeviceOnly => true;

  @override
  Future<void> delete(String path) async {}

  @override
  Future<StoredMedia> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadCalls += 1;
    return StoredMedia(path: path, downloadUrl: 'file:///private/$path');
  }
}

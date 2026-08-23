import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pawfect_care/data/services/local_media_storage_service.dart';
import 'package:pawfect_care/data/services/local_reminder_service.dart';

void main() {
  test('local media persists and deletes a private device file', () async {
    final root = await Directory.systemTemp.createTemp('pawfectcare-media-');
    addTearDown(() => root.delete(recursive: true));
    final service = LocalMediaStorageService(
      directoryProvider: () async => root,
    );

    final stored = await service.upload(
      path: 'pets/pet-1/images/cat photo.png',
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      contentType: 'image/png',
    );
    final file = File.fromUri(Uri.parse(stored.downloadUrl));

    expect(service.isDeviceOnly, isTrue);
    expect(await file.readAsBytes(), [1, 2, 3, 4]);

    await service.delete(stored.path);
    expect(await file.exists(), isFalse);
  });

  test('local reminder IDs are stable and distinct', () {
    expect(notificationId('owner:appointment:a'), isNot(0));
    expect(
      notificationId('owner:appointment:a'),
      notificationId('owner:appointment:a'),
    );
    expect(
      notificationId('owner:appointment:a'),
      isNot(notificationId('owner:appointment:b')),
    );
  });
}

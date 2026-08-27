import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PickedMedia {
  const PickedMedia({
    required this.name,
    required this.bytes,
    required this.contentType,
  });

  final String name;
  final Uint8List bytes;
  final String contentType;
}

abstract final class MediaPicker {
  static Future<PickedMedia?> image() async {
    final image = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );

    if (image == null) return null;

    final file = image.files.single;
    final bytes = file.bytes;

    if (bytes == null) {
      throw const FormatException('Unable to read the selected image.');
    }

    if (bytes.lengthInBytes >= 5 * 1024 * 1024) {
      throw const FormatException('Images must be smaller than 5 MB.');
    }

    final contentType = _imageType(file.name);

    return PickedMedia(
      name: _safeName(file.name),
      bytes: bytes,
      contentType: contentType,
    );
  }

  static Future<PickedMedia?> medicalDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );

    if (result == null) return null;

    final file = result.files.single;
    final bytes = file.bytes;

    if (bytes == null) {
      throw const FormatException('Unable to read the selected file.');
    }

    if (bytes.lengthInBytes >= 10 * 1024 * 1024) {
      throw const FormatException(
        'Medical files must be smaller than 10 MB.',
      );
    }

    final extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : '';

    final contentType = switch (extension) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw const FormatException(
          'Choose a PDF, JPG, PNG, or WebP file.',
        ),
    };

    return PickedMedia(
      name: _safeName(file.name),
      bytes: bytes,
      contentType: contentType,
    );
  }

  static String _imageType(String name) {
    final extension = name.split('.').last.toLowerCase();

    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw const FormatException(
          'Choose a JPG, PNG, or WebP image.',
        ),
    };
  }

  static String _safeName(String name) => name
      .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
      .replaceAll(RegExp(r'_+'), '_');
}
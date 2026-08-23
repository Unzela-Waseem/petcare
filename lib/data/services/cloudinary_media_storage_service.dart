import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../domain/repositories/media_storage_service.dart';

class CloudinaryMediaStorageService implements MediaStorageService {
  CloudinaryMediaStorageService({
    required this.cloudName,
    required this.uploadPreset,
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const pathPrefix = 'cloudinary:image:';
  static const _maximumImageBytes = 5 * 1024 * 1024;
  static const _allowedImageTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  final String cloudName;
  final String uploadPreset;
  final http.Client _client;

  @override
  bool get isDeviceOnly => false;

  bool owns(String path) => path.startsWith(pathPrefix);

  @override
  Future<StoredMedia> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    _validate(bytes: bytes, contentType: contentType);
    if (cloudName.trim().isEmpty || uploadPreset.trim().isEmpty) {
      throw const MediaFailure('Cloud image storage is not configured.');
    }

    final request =
        http.MultipartRequest(
            'POST',
            Uri.https(
              'api.cloudinary.com',
              '/v1_1/${cloudName.trim()}/image/upload',
            ),
          )
          ..fields['upload_preset'] = uploadPreset.trim()
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: _safeFilename(path),
            ),
          );

    try {
      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      final decoded = _decode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw MediaFailure(_errorMessage(decoded, response.statusCode));
      }

      final publicId = decoded['public_id'];
      final secureUrl = decoded['secure_url'];
      final url = secureUrl is String ? Uri.tryParse(secureUrl) : null;
      if (publicId is! String ||
          publicId.isEmpty ||
          url == null ||
          url.scheme != 'https') {
        throw const MediaFailure(
          'Cloudinary returned an invalid image response.',
        );
      }
      return StoredMedia(
        path: '$pathPrefix$publicId',
        downloadUrl: secureUrl as String,
      );
    } on MediaFailure {
      rethrow;
    } on Object {
      throw const MediaFailure(
        'The image could not be uploaded. Check your connection and try again.',
      );
    }
  }

  @override
  Future<void> delete(String path) async {
    // Unsigned client uploads cannot securely destroy an old Cloudinary asset.
    // Removing the Firestore reference immediately hides it from the app; remote
    // cleanup is performed from the Cloudinary Media Library until a trusted
    // signed deletion backend is available.
  }

  void _validate({required Uint8List bytes, required String contentType}) {
    if (bytes.isEmpty) {
      throw const MediaFailure('The selected image is empty.');
    }
    if (bytes.length > _maximumImageBytes) {
      throw const MediaFailure('Images must be 5 MB or smaller.');
    }
    if (!_allowedImageTypes.contains(contentType.toLowerCase())) {
      throw const MediaFailure('Choose a JPG, PNG, or WebP image.');
    }
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }

  String _errorMessage(Map<String, dynamic> response, int statusCode) {
    final error = response['error'];
    final message = error is Map<String, dynamic> ? error['message'] : null;
    if (message is String && message.isNotEmpty) {
      return 'Cloudinary upload failed: $message';
    }
    return 'Cloudinary upload failed (HTTP $statusCode).';
  }

  String _safeFilename(String path) {
    final filename = path.split('/').last;
    final cleaned = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return cleaned.isEmpty ? 'pawfectcare-image' : cleaned;
  }
}

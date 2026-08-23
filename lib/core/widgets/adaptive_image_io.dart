import 'dart:io';

import 'package:flutter/material.dart';

bool isLocalMedia(String source) {
  final uri = Uri.tryParse(source);
  return uri?.scheme == 'file' ||
      ((uri?.scheme.isEmpty ?? true) && source.startsWith('/'));
}

Widget localImage({
  required String source,
  required double? width,
  required double? height,
  required BoxFit fit,
  required AlignmentGeometry alignment,
  required ImageErrorWidgetBuilder errorBuilder,
}) {
  final uri = Uri.tryParse(source);
  final file = uri?.scheme == 'file' ? File.fromUri(uri!) : File(source);
  return Image.file(
    file,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    errorBuilder: errorBuilder,
  );
}

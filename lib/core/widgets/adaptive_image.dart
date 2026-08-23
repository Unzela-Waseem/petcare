import 'package:flutter/material.dart';

import 'adaptive_image_stub.dart'
    if (dart.library.io) 'adaptive_image_io.dart'
    as local_media;

class AdaptiveImage extends StatelessWidget {
  const AdaptiveImage({
    required this.source,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    super.key,
  });

  final String source;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    if (local_media.isLocalMedia(source)) {
      return local_media.localImage(
        source: source,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return Image.network(
      source,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

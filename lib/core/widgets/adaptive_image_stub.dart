import 'package:flutter/material.dart';

bool isLocalMedia(String source) => false;

Widget localImage({
  required String source,
  required double? width,
  required double? height,
  required BoxFit fit,
  required AlignmentGeometry alignment,
  required ImageErrorWidgetBuilder errorBuilder,
}) => SizedBox(width: width, height: height);

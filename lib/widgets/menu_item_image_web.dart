import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

class MenuItemImageImpl extends StatelessWidget {
  final String imageUrl;
  final double height;
  final double width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const MenuItemImageImpl({
    super.key,
    required this.imageUrl,
    required this.height,
    required this.width,
    required this.fit,
    required this.borderRadius,
    required this.placeholder,
    required this.errorWidget,
  });

  bool get _isNetwork =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  bool get _isDataImage => imageUrl.startsWith('data:image/');

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isNetwork) {
      child = CachedNetworkImage(
        imageUrl: imageUrl,
        height: height,
        width: width,
        fit: fit,
        placeholder: (_, __) => placeholder ?? const SizedBox.shrink(),
        errorWidget: (_, __, ___) => errorWidget ?? const SizedBox.shrink(),
      );
    } else if (_isDataImage) {
      final commaIndex = imageUrl.indexOf(',');
      final dataPart = commaIndex >= 0
          ? imageUrl.substring(commaIndex + 1)
          : '';
      final bytes = base64Decode(dataPart);
      child = Image.memory(
        bytes,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => errorWidget ?? const SizedBox.shrink(),
      );
    } else {
      // Unknown format on web.
      child = errorWidget ?? const SizedBox.shrink();
    }

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }

    return child;
  }
}

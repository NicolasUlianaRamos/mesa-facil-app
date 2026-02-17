import 'package:flutter/widgets.dart';

/// Default implementation: just uses Image.network.
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

  @override
  Widget build(BuildContext context) {
    Widget child = Image.network(
      imageUrl,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, __, ___) => errorWidget ?? const SizedBox.shrink(),
    );

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }

    return child;
  }
}

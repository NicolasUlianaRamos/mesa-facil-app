import 'package:flutter/widgets.dart';

import 'menu_item_image_impl.dart'
    if (dart.library.io) 'menu_item_image_io.dart'
    if (dart.library.html) 'menu_item_image_web.dart';

class MenuItemImage extends StatelessWidget {
  final String imageUrl;
  final double height;
  final double width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const MenuItemImage({
    super.key,
    required this.imageUrl,
    required this.height,
    required this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return MenuItemImageImpl(
      imageUrl: imageUrl,
      height: height,
      width: width,
      fit: fit,
      borderRadius: borderRadius,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}

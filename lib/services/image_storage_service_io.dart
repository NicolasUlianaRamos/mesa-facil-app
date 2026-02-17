import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageStorageServiceImpl {
  static Future<String> persistPickedImage(XFile pickedFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final menuImagesDir = Directory('${docsDir.path}/menu_images');
    if (!await menuImagesDir.exists()) {
      await menuImagesDir.create(recursive: true);
    }

    final source = File(pickedFile.path);
    final fileName =
        'menu_${DateTime.now().microsecondsSinceEpoch}_${pickedFile.name}';
    final target = File('${menuImagesDir.path}/$fileName');

    await source.copy(target.path);
    return target.path;
  }
}

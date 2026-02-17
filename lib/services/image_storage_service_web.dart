import 'dart:convert';

import 'package:image_picker/image_picker.dart';

class ImageStorageServiceImpl {
  static Future<String> persistPickedImage(XFile pickedFile) async {
    final bytes = await pickedFile.readAsBytes();

    // Best-effort mime detection based on extension.
    final nameLower = pickedFile.name.toLowerCase();
    final mime = nameLower.endsWith('.png')
        ? 'image/png'
        : nameLower.endsWith('.gif')
        ? 'image/gif'
        : 'image/jpeg';

    final b64 = base64Encode(bytes);
    return 'data:$mime;base64,$b64';
  }
}

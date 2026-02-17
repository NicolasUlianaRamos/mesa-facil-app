import 'package:image_picker/image_picker.dart';

/// Fallback implementation (should be overridden by platform implementations).
class ImageStorageServiceImpl {
  static Future<String> persistPickedImage(XFile pickedFile) async {
    // In the worst case, persist the path (may not be stable on all platforms).
    return pickedFile.path;
  }
}

import 'package:image_picker/image_picker.dart';

import 'image_storage_service_impl.dart'
    if (dart.library.io) 'image_storage_service_io.dart'
    if (dart.library.html) 'image_storage_service_web.dart';

abstract class ImageStorageService {
  /// Returns a value that can be persisted in `MenuItem.imageUrl`.
  ///
  /// - On mobile/desktop (io): copies the file into the app documents directory
  ///   and returns the local file path.
  /// - On web: returns a `data:image/...;base64,...` URL.
  static Future<String> persistPickedImage(XFile pickedFile) {
    return ImageStorageServiceImpl.persistPickedImage(pickedFile);
  }
}

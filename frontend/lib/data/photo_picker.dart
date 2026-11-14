import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'photo_upload.dart';

class PhotoPicker {
  static XFile? _recovered;
  static Future<void> recover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final result = await ImagePicker().retrieveLostData();
      _recovered = result.files?.firstOrNull;
    } catch (_) {
      // A picker recovery failure must not prevent access to existing records.
    }
  }

  static Future<Uint8List?> pick(ImageSource source) async {
    final file =
        _recovered ??
        await ImagePicker().pickImage(
          source: source,
          maxWidth: 2400,
          maxHeight: 2400,
          imageQuality: 85,
          requestFullMetadata: false,
        );
    _recovered = null;
    if (file == null) return null;
    if (await file.length() > 5 * 1024 * 1024) {
      throw const ApiFailure('Gunakan foto maksimal 5 MB.');
    }
    return compute(preparePhotoUpload, await file.readAsBytes());
  }
}

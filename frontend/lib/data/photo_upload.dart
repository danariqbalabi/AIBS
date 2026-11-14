import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'api_client.dart';

const maxUploadPhotoBytes = 4000000;

/// Leave room for multipart headers below Vercel's 4.5 MB request limit.
Uint8List preparePhotoUpload(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
    throw const ApiFailure('Gunakan foto maksimal 5 MB.');
  }
  try {
    final img.Decoder decoder;
    if (img.JpegDecoder().isValidFile(bytes)) {
      decoder = img.JpegDecoder();
    } else if (img.PngDecoder().isValidFile(bytes)) {
      decoder = img.PngDecoder();
    } else {
      throw const ApiFailure('Gunakan foto JPEG atau PNG.');
    }
    final info = decoder.startDecode(bytes);
    if (info == null || info.width * info.height > 16000000) {
      throw const ApiFailure('Gunakan foto maksimal 16 megapiksel.');
    }
    if (bytes.length <= maxUploadPhotoBytes) return bytes;
    final decoded = decoder.decodeFrame(0);
    if (decoded == null) throw const ApiFailure('Foto belum bisa dibaca.');
    var photo = img.bakeOrientation(decoded);
    if (photo.width > 1600 || photo.height > 1600) {
      photo = img.copyResize(
        photo,
        width: photo.width >= photo.height ? 1600 : null,
        height: photo.height > photo.width ? 1600 : null,
      );
    }
    final result = img.encodeJpg(photo, quality: 85);
    if (result.length > maxUploadPhotoBytes) {
      throw const ApiFailure('Perkecil foto lalu coba lagi.');
    }
    return result;
  } on ApiFailure {
    rethrow;
  } catch (_) {
    throw const ApiFailure('Foto belum bisa dibaca. Gunakan JPEG atau PNG.');
  }
}

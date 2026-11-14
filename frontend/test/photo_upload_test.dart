import 'dart:typed_data';

import 'package:aibs_app/data/api_client.dart';
import 'package:aibs_app/data/photo_upload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('large valid PNG is resized to JPEG below the multipart budget', () {
    final original = img.Image(width: 1024, height: 1600, numChannels: 3);
    final png = img.encodePng(original, level: 0);
    expect(png.length, greaterThan(maxUploadPhotoBytes));
    expect(png.length, lessThan(5 * 1024 * 1024));
    final result = preparePhotoUpload(png);
    expect(result.length, lessThanOrEqualTo(maxUploadPhotoBytes));
    final decoded = img.decodeJpg(result)!;
    expect(decoded.width, 1024);
    expect(decoded.height, 1600);
  });

  test('small JPEG is preserved and invalid input fails before upload', () {
    final jpeg = img.encodeJpg(img.Image(width: 12, height: 12));
    expect(preparePhotoUpload(jpeg), same(jpeg));
    expect(
      () => preparePhotoUpload(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<ApiFailure>()),
    );
    expect(
      () => preparePhotoUpload(Uint8List(5 * 1024 * 1024 + 1)),
      throwsA(isA<ApiFailure>()),
    );
  });
}

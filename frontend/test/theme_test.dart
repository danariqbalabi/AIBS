import 'package:flutter_test/flutter_test.dart';

import 'package:aibs_app/core/theme/aibs_theme.dart';
import 'package:aibs_app/core/theme/aibs_tokens.dart';

void main() {
  test('bundled Nunito theme maps all design weights to its variable axis', () {
    final theme = AibsTheme.light;

    expect(theme.textTheme.bodyMedium!.fontFamily, AibsType.family);
    for (final entry in {
      theme.textTheme.bodyMedium!: 600.0,
      theme.textTheme.bodySmall!: 700.0,
      theme.textTheme.headlineLarge!: 800.0,
    }.entries) {
      final variation = entry.key.fontVariations!.single;
      expect(variation.axis, 'wght');
      expect(variation.value, entry.value);
    }
  });
}

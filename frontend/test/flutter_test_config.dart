import 'dart:async';

import 'package:aibs_app/core/sound/aibs_sound.dart';
import 'package:aibs_app/shared/widgets/koala.dart';

/// Runs before every test file in this folder.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // The koala's idle loop never settles, so `pumpAndSettle` would time out.
  Koala.animationsEnabled = false;
  // No audio plugin in widget tests.
  AibsSound.enabled = false;
  await testMain();
}

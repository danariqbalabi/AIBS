import 'dart:js_interop';

@JS('aibsOfflineShell')
external JSPromise<JSAny?> _configure(JSBoolean enabled);
Future<void> offlineShell(bool enabled) async {
  await _configure(enabled.toJS).toDart;
}

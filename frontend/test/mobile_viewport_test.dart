import 'package:aibs_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'desktop keeps routes and capture sheet inside a centered mobile width',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const AibsApp());
      await tester.pumpAndSettle();
      final navigator = find.byType(Navigator);
      expect(tester.getSize(navigator).width, 390);
      expect(tester.getTopLeft(navigator).dx, 405);
      await tester.tap(find.text('Coba Demo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nadia, 21'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tambah catatan'));
      await tester.pumpAndSettle();
      final sheet = find.byType(BottomSheet);
      expect(tester.getSize(sheet).width, 390);
      expect(tester.getTopLeft(sheet).dx, 405);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('narrow phones use all available width', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AibsApp());
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Navigator)).width, 360);
    expect(tester.getTopLeft(find.byType(Navigator)).dx, 0);
    expect(tester.takeException(), isNull);
  });
}

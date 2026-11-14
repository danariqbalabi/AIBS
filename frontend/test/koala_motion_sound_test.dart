import 'package:aibs_app/core/sound/aibs_sound.dart';
import 'package:aibs_app/core/sound/aibs_tap_sounds.dart';
import 'package:aibs_app/core/theme/aibs_theme.dart';
import 'package:aibs_app/shared/widgets/koala.dart';
import 'package:aibs_app/widgets/aibs_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final played = <AibsSfx>[];

  setUp(() {
    played.clear();
    AibsSound.debugOnPlay = played.add;
  });

  tearDown(() {
    AibsSound.debugOnPlay = null;
    Koala.animationsEnabled = false;
  });

  Widget app(Widget child, {bool reduceMotion = false}) => MaterialApp(
    builder: (context, child) => AibsTapSounds(child: child!),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets('animated koala renders layers, moves, and hops on tap', (
    tester,
  ) async {
    Koala.animationsEnabled = true;
    for (final mood in KoalaMood.values) {
      await tester.pumpWidget(app(Koala(mood, size: 160)));
      await tester.pump(const Duration(milliseconds: 400));
      // Layered: many pictures instead of the single brand asset.
      expect(
        find.byType(SvgPicture).evaluate().length,
        greaterThan(6),
        reason: mood.name,
      );
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    }

    played.clear();
    await tester.tap(find.byType(Koala));
    await tester.pump(const Duration(milliseconds: 300));
    expect(played, [AibsSfx.koala]); // no extra button tick
    await tester.pump(const Duration(seconds: 1));

    // Leave no timers behind.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion shows the static brand SVG', (tester) async {
    Koala.animationsEnabled = true;
    await tester.pumpWidget(
      app(const Koala(KoalaMood.senang), reduceMotion: true),
    );
    expect(find.byType(SvgPicture), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('buttons tick, chips pop, disabled buttons and scrolls stay '
      'silent', (tester) async {
    await tester.pumpWidget(
      app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AibsPrimaryButton(label: 'Lanjut', onPressed: () {}),
            const AibsPrimaryButton(label: 'Mati', onPressed: null),
            AibsChoiceChip(label: 'Nasi', selected: false, onTap: () {}),
            const Text('Teks biasa'),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Lanjut'));
    expect(played, [AibsSfx.tap]);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Mati'));
    await tester.tap(find.text('Teks biasa'));
    expect(played, [AibsSfx.tap]);

    await tester.tap(find.text('Nasi'));
    expect(played, [AibsSfx.tap, AibsSfx.pop]);

    await tester.drag(find.text('Lanjut'), const Offset(0, 80));
    expect(played, [AibsSfx.tap, AibsSfx.pop]);
  });

  testWidgets('snackbars chime on success and hum otherwise', (tester) async {
    await tester.pumpWidget(app(const SizedBox()));
    final context = tester.element(find.byType(Scaffold));
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(const SnackBar(content: Text('Catatan tersimpan')));
    await tester.pump(const Duration(milliseconds: 100));
    messenger.showSnackBar(const SnackBar(content: Text('Tulis cerita dulu.')));
    await tester.pump(const Duration(milliseconds: 100));
    messenger.showSnackBar(
      const SnackBar(content: Text('Permintaan belum berhasil.')),
    );

    expect(played, [AibsSfx.success, AibsSfx.notice, AibsSfx.notice]);
    expect(find.text('Catatan tersimpan'), findsOneWidget);
  });

  testWidgets('saved-but-not-sent messages are not celebrated', (tester) async {
    await tester.pumpWidget(app(const SizedBox()));
    final messenger = ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold)),
    );
    const cases = {
      'Draft tersimpan di perangkat. Belum dikirim ke akun.': AibsSfx.notice,
      'Pilihan tampilan belum tersimpan. Coba lagi.': AibsSfx.notice,
      'Tidak dapat membuka aplikasi telepon.': AibsSfx.notice,
      'Ringkasan disalin': AibsSfx.success,
      'Perubahan tersimpan': AibsSfx.success,
    };
    for (final entry in cases.entries) {
      played.clear();
      // Real time passes so the repeat guard doesn't drop the sound.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      messenger.showSnackBar(SnackBar(content: Text(entry.key)));
      expect(played, [entry.value], reason: entry.key);
      await tester.pump();
    }
  });

  testWidgets('checkboxes, switches, and icon buttons tick', (tester) async {
    await tester.pumpWidget(
      app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(value: false, onChanged: (_) {}),
            Switch(value: false, onChanged: (_) {}),
            CheckboxListTile(
              title: const Text('Bawang'),
              value: false,
              onChanged: (_) {},
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.close)),
          ],
        ),
      ),
    );
    for (final finder in [
      find.byType(Checkbox).first,
      find.byType(Switch),
      find.text('Bawang'),
      find.byType(IconButton),
    ]) {
      played.clear();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await tester.tap(finder);
      expect(played, [AibsSfx.tap], reason: '$finder');
      await tester.pump(const Duration(milliseconds: 300));
    }
  });

  testWidgets('animated koala works on the dark theme', (tester) async {
    Koala.animationsEnabled = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: AibsTheme.dark,
        home: const Scaffold(
          body: Center(child: KoalaBubble(text: 'Ada keluhan?')),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('large koalas get a sun by day and a moon by night', (
    tester,
  ) async {
    Widget themed(ThemeData theme, Widget koala) => MaterialApp(
      theme: theme,
      home: Scaffold(body: Center(child: koala)),
    );
    const sun = ValueKey('koala-sun');
    const moon = ValueKey('koala-moon');

    for (final animated in [true, false]) {
      Koala.animationsEnabled = animated;
      await tester.pumpWidget(
        themed(AibsTheme.light, const Koala(KoalaMood.senang, size: 200)),
      );
      expect(find.byKey(sun), findsOneWidget, reason: 'animated $animated');
      expect(find.byKey(moon), findsNothing);

      await tester.pumpWidget(
        themed(AibsTheme.dark, const Koala(KoalaMood.senang, size: 200)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(moon), findsOneWidget, reason: 'animated $animated');
      expect(find.byKey(sun), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }

    // Small koalas, bubbles, and verdict cards stay plain.
    Koala.animationsEnabled = true;
    await tester.pumpWidget(
      themed(
        AibsTheme.dark,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Koala(KoalaMood.mikir, size: 120),
            KoalaBubble(text: 'Ada keluhan?'),
            VerdictCard(mood: KoalaMood.senang, headline: 'Sesuai'),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(sun), findsNothing);
    expect(find.byKey(moon), findsNothing);

    // Opt in or out explicitly.
    await tester.pumpWidget(
      themed(
        AibsTheme.light,
        const Koala(KoalaMood.mikir, size: 90, sky: true),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(sun), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('night koala yawns, rests its eyes, and tolerates a theme '
      'switch mid-animation', (tester) async {
    Koala.animationsEnabled = true;
    final mode = ValueNotifier(ThemeMode.light);
    await tester.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: mode,
        builder: (context, value, _) => MaterialApp(
          theme: AibsTheme.light,
          darkTheme: AibsTheme.dark,
          themeMode: value,
          home: const Scaffold(
            body: Center(child: Koala(KoalaMood.khawatir, size: 200)),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    mode.value = ThemeMode.dark;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byType(Koala));
    // Run through hops, yawns, and lingering blinks.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('koala-moon')), findsOneWidget);
    mode.value = ThemeMode.light;
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('koala-sun')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

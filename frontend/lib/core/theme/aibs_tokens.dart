// AIBS design tokens.
//
// Source of truth: the AIBS Hi-fi canvas (Claude Design), values copied from
// its CSS. Widgets must read colors, sizes, radii, shadows, durations and
// curves from here instead of hardcoding them.
//
// CSS #RRGGBB was converted to Flutter 0xFFRRGGBB; alpha is the first byte.

import 'package:flutter/widgets.dart';

abstract final class AibsColors {
  // Brand
  static const primary = Color(0xFF2F6FED); // selected chips, progress, active
  static const primaryStrong = Color(
    0xFF1F55C8,
  ); // links, gradient end, text on soft
  static const primaryLight = Color(0xFF3B7BF5); // gradient start
  static const sky = Color(
    0xFF78AAFF,
  ); // light gradient end, focus ring (never text)
  static const primarySoft = Color(
    0xFFE8F0FE,
  ); // soft buttons, active nav pill, koala card
  static const primaryTint = Color(0xFFDCE8FF); // sub text on gradient, glow

  // Surfaces
  static const surface = Color(0xFFF5F8FF); // page background
  static const card = Color(0xFFFFFFFF); // cards, sheets, inputs
  static const scrim = Color(0x7314233F); // 45% ink behind sheets/dialogs

  // Text + lines
  static const ink = Color(0xFF14233F);
  static const inkMuted = Color(0xFF5B6A85);
  static const line = Color(0xFFE1E8F4);
  static const trackOff = Color(0xFFCDD5E3); // switch track when off
  static const onPrimary = Color(0xFFFFFFFF);

  // Status: only for food-check results (and destructive for bad)
  static const ok = Color(0xFF22A06B);
  static const okInk = Color(0xFF11774A);
  static const okSoft = Color(0xFFE3F6EC);
  static const warn = Color(0xFFF5A524);
  static const warnInk = Color(0xFF8A5300);
  static const warnSoft = Color(0xFFFFF3DC);
  static const bad = Color(0xFFE5534B);
  static const badInk = Color(0xFFB02B24);
  static const badSoft = Color(0xFFFDE8E6);
  static const unknown = Color(0xFF9AA5B8);
  static const unknownSoft = Color(0xFFEEF1F6);

  // Food photo placeholders (gradient start/end)
  static const foodBlue = [Color(0xFFE8F0FE), Color(0xFFB9D2FF)];
  static const foodPink = [Color(0xFFFFEFF3), Color(0xFFFFC9D7)];
  static const foodGrey = [Color(0xFFEEF1F6), Color(0xFFCDD5E3)];

  // Mascot (illustration only)
  static const koalaFur = Color(0xFF9AA6BA);
  static const koalaBlush = Color(0xFFF5A3BB);
}

abstract final class AibsGradients {
  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight, // CSS 135deg
    colors: [AibsColors.primaryLight, AibsColors.primaryStrong],
  );
  static const hero = LinearGradient(
    begin: Alignment(-0.77, -0.64), // CSS 140deg
    end: Alignment(0.77, 0.64),
    colors: [AibsColors.primarySoft, Color(0xFFC9DCFF)],
  );
  static const glow = RadialGradient(
    center: Alignment(0, 0.2),
    radius: 0.7,
    colors: [AibsColors.primaryTint, AibsColors.primarySoft, Color(0x00F5F8FF)],
    stops: [0, 0.4, 1],
  );
  static LinearGradient food(List<Color> c) => LinearGradient(
    begin: const Alignment(-0.77, -0.64),
    end: const Alignment(0.77, 0.64),
    colors: c,
  );
}

abstract final class AibsSpace {
  static const s2 = 2.0;
  static const s4 = 4.0;
  static const s6 = 6.0;
  static const s8 = 8.0;
  static const s10 = 10.0; // gap between option cards / buttons
  static const s12 = 12.0;
  static const s14 = 14.0;
  static const s16 = 16.0; // card padding
  static const s20 = 20.0; // screen side padding
  static const s24 = 24.0; // gap between sections, content top padding
  static const s28 = 28.0; // tab screen top padding

  static const screen = EdgeInsets.symmetric(horizontal: s20);
  static const topBar = EdgeInsets.fromLTRB(s20, s16, s20, s8);
  static const bottomActions = EdgeInsets.fromLTRB(s20, s12, s20, s24);
}

abstract final class AibsSize {
  static const menuHero = 144.0;
  static const navigationClearance = 40.0;
  static const tapMin = 44.0;
  static const backButton = 44.0;
  static const button = 56.0;
  static const buttonInCard = 44.0;
  static const optionMin = 60.0;
  static const chip = 44.0;
  static const filterChip = 38.0;
  static const input = 56.0;
  static const progress = 8.0;
  static const tabBar = 84.0;
  static const cameraButton = 60.0;
  static const cameraLift = 34.0; // how far the camera button sticks up
  static const cameraRing = 6.0;
  static const koalaHelp = 170.0;
  static const koalaScope = 200.0;
  static const koalaWelcome = 230.0;
  static const verdictKoala = 150.0;
  static const criterionDot = 26.0;
  static const helpStepCircle = 28.0;
  static const navIcon = 22.0;
  static const menuSliderCard = 176.0;
  static const menuSliderImage = 104.0;
  static const menuArtworkIcon = 44.0;
  static const homeSliderHeight = 260.0;
  static const homeGlow = 280.0;
  static const seeAllCard = 120.0;
  static const logTime = 48.0;
  static const thumb = 72.0;
  static const dayDot = 32.0;
  static const scaleDot = 44.0;
  static const scaleDotOn = 54.0;
}

abstract final class AibsRadius {
  static const xs = 12.0; // stepper buttons, icon squares
  static const sm = 14.0; // back button, small inner buttons
  static const md = 16.0; // thumbnails, OTP, Jadwalkan chips, stat tiles
  static const bubble = 18.0; // inputs, koala bubble
  static const lg = 20.0; // cards, option cards, buttons
  static const xl = 24.0; // big choice cards, hero cards
  static const xxl = 28.0; // sheets, tab bar, verdict card
  static const pill = 999.0;

  /// Koala speech bubble: tail at bottom-left.
  static const bubbleShape = BorderRadius.only(
    topLeft: Radius.circular(bubble),
    topRight: Radius.circular(bubble),
    bottomRight: Radius.circular(bubble),
    bottomLeft: Radius.circular(6),
  );
  static const sheetTop = BorderRadius.vertical(top: Radius.circular(xxl));
}

abstract final class AibsShadows {
  /// The one card shadow: 0 8 24 primary@10%.
  static const card = [
    BoxShadow(color: Color(0x1A2F6FED), offset: Offset(0, 8), blurRadius: 24),
  ];

  /// Primary gradient buttons and gradient choice cards: 0 10 24 primary@30%.
  static const glow = [
    BoxShadow(color: Color(0x4D2F6FED), offset: Offset(0, 10), blurRadius: 24),
  ];

  /// Camera button: glow 35% + 6px surface ring.
  static const camera = [
    BoxShadow(color: AibsColors.surface, spreadRadius: AibsSize.cameraRing),
    BoxShadow(color: Color(0x592F6FED), offset: Offset(0, 10), blurRadius: 24),
  ];

  /// Tab bar and pinned bottom bars: 0 -6 24 primary@8%.
  static const bar = [
    BoxShadow(color: Color(0x142F6FED), offset: Offset(0, -6), blurRadius: 24),
  ];

  /// Koala bubble: 0 6 16 primary@10%.
  static const bubble = [
    BoxShadow(color: Color(0x1A2F6FED), offset: Offset(0, 6), blurRadius: 16),
  ];

  /// Danger buttons: 0 10 24 bad@25%.
  static const danger = [
    BoxShadow(color: Color(0x40E5534B), offset: Offset(0, 10), blurRadius: 24),
  ];
}

abstract final class AibsType {
  static const family = 'Nunito'; // weights used: 600, 700, 800

  static const w600 = FontWeight.w600;
  static const w700 = FontWeight.w700;
  static const w800 = FontWeight.w800;

  static TextStyle _t(
    double size,
    double line,
    FontWeight weight, [
    Color color = AibsColors.ink,
  ]) => TextStyle(
    fontFamily: family,
    fontSize: size,
    height: line / size,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
    color: color,
  );

  static final display = _t(32, 38, w800); // welcome title
  static final title = _t(28, 34, w800); // screen main question (h1)
  static final titleDetail = _t(26, 32, w800); // menu / record name
  static final sheetTitle = _t(22, 28, w800);
  static final verdict = _t(20, 26, w800); // result headline, top-bar title
  static final option = _t(17, 22, w800); // option cards, primary button
  static final button = _t(16, 22, w800);
  static final sectionTitle = _t(16, 22, w800);
  static final bodyStrong = _t(15, 22, w800); // list item names
  static final body = _t(15, 22, w600, AibsColors.inkMuted);
  static final label = _t(
    14,
    20,
    w800,
    AibsColors.primaryStrong,
  ); // chips, links
  static final caption = _t(13, 18, w700, AibsColors.inkMuted);
  static final small = _t(
    12,
    16,
    w700,
    AibsColors.inkMuted,
  ); // category above value
  static final badge = _t(12, 16, w800);
  static final micro = _t(
    11,
    14,
    w700,
    AibsColors.inkMuted,
  ); // tabs, disclaimers
  static final greeting = _t(15, 20, w800, AibsColors.primaryStrong);

  /// Counts and times.
  static const tabular = [FontFeature.tabularFigures()];
}

abstract final class AibsMotion {
  static const press = Duration(milliseconds: 90);
  static const release = Duration(milliseconds: 120);
  static const select = Duration(milliseconds: 150);
  static const tab = Duration(milliseconds: 160);
  static const dialog = Duration(milliseconds: 200);
  static const page = Duration(milliseconds: 240);
  static const sheet = Duration(milliseconds: 280);
  static const progress = Duration(milliseconds: 300);
  static const verdict = Duration(milliseconds: 320);
  static const reduced = Duration(milliseconds: 120);

  static const standard = Curves.easeOutCubic;
  static const emphasized = Cubic(0.2, 0, 0, 1);
  static const exit = Curves.easeInCubic;

  static const pressScale = 0.97;
  static const pageSlide = 12.0;
}

// Koala mascot cut into animatable layers.
//
// Shapes are copied 1:1 from assets/brand/koala_{senang,mikir,khawatir}.svg
// (240 × 240 viewBox). Stacked in this order, the layers draw the same picture
// as the source SVG; each layer can then be moved on its own. If the brand
// SVGs change, update these strings too.

import 'dart:math' as math;

const koalaCanvas = 240.0;

const _defs = '''
<defs>
<radialGradient id="fur" cx="38%" cy="28%" r="85%"><stop offset="0" stop-color="#CDD5E3"/><stop offset="1" stop-color="#8C98AE"/></radialGradient>
<radialGradient id="ear" cx="50%" cy="45%" r="60%"><stop offset="0" stop-color="#FFE3EA"/><stop offset="1" stop-color="#F5A3BB"/></radialGradient>
<radialGradient id="belly" cx="50%" cy="30%" r="75%"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#DCE3EF"/></radialGradient>
<linearGradient id="nose" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4B5672"/><stop offset="1" stop-color="#1B2236"/></linearGradient>
<linearGradient id="scarf" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#78AAFF"/><stop offset="1" stop-color="#2F6FED"/></linearGradient>
<linearGradient id="leaf" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#86E0AE"/><stop offset="1" stop-color="#1E9A64"/></linearGradient>
<linearGradient id="drop" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#CFE1FF"/><stop offset="1" stop-color="#78AAFF"/></linearGradient>
</defs>''';

String _svg(String body) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240">'
    '$_defs$body</svg>';

/// Point in koala canvas units (0–240).
typedef KoalaPoint = ({double x, double y});

class KoalaParts {
  const KoalaParts._({
    required this.shadow,
    required this.body,
    required this.earLeft,
    required this.earRight,
    required this.head,
    required this.eyes,
    required this.eyeY,
    required this.yawn,
    required this.scarf,
    this.arm,
    this.armPivot,
    this.wavingArm,
    this.wavingArmPivot,
    this.armRight,
    this.armRightPivot,
    this.leaf,
    this.bubbles = const [],
    this.drop,
  });

  final String shadow;
  final String body;
  final String earLeft;
  final String earRight;

  /// Head fur, cheeks, brows, nose, mouth. Everything on the face but eyes.
  final String head;
  final String eyes;

  /// Vertical center of the eyes, the pivot for blinking.
  final double eyeY;

  /// Open mouth for the night yawn, centered on [yawnCenter]. Covers the
  /// mood's own mouth; scaled from 0 (hidden) to 1.
  final String yawn;
  final String scarf;

  /// Front arm (holding the leaf, at the chin, or the left worried hand).
  final String? arm;
  final KoalaPoint? armPivot;

  /// Raised arm behind the head (senang): waves.
  final String? wavingArm;
  final KoalaPoint? wavingArmPivot;

  /// Second front hand (khawatir).
  final String? armRight;
  final KoalaPoint? armRightPivot;

  /// Leaf in hand (senang): sways.
  final String? leaf;

  /// Thought bubbles, smallest first (mikir): each layer + its center.
  final List<(String, KoalaPoint)> bubbles;

  /// Sweat drop (khawatir): slides down and fades.
  final String? drop;

  static const earLeftPivot = (x: 80.0, y: 82.0);
  static const earRightPivot = (x: 160.0, y: 82.0);
  static const neck = (x: 120.0, y: 165.0);
  static const feet = (x: 120.0, y: 228.0);
  static const yawnCenter = (x: 120.0, y: 151.0);
  static const leafPivot = (x: 60.0, y: 200.0);

  /// Ground shadow for dark backgrounds, where the brand's 10% navy shadow
  /// disappears and the koala looks like it floats.
  static final shadowNight = _svg(
    '<ellipse cx="120" cy="228" rx="60" ry="7" fill="#000000" opacity=".38"/>',
  );

  static KoalaParts get senang => _senang;
  static KoalaParts get mikir => _mikir;
  static KoalaParts get khawatir => _khawatir;
}

const _shadow =
    '<ellipse cx="120" cy="228" rx="60" ry="7" fill="#14233F" opacity=".10"/>';

const _body = '''
<ellipse cx="120" cy="182" rx="58" ry="46" fill="url(#fur)"/>
<ellipse cx="95" cy="222" rx="18" ry="9" fill="#8C98AE"/>
<ellipse cx="145" cy="222" rx="18" ry="9" fill="#8C98AE"/>
<ellipse cx="120" cy="192" rx="34" ry="30" fill="url(#belly)"/>''';

String _earLeft(double dy) =>
    '''
<circle cx="52" cy="${58 + dy}" r="40" fill="url(#fur)"/>
<circle cx="24" cy="${46 + dy * 2}" r="11" fill="#B7C0D0"/>
<circle cx="54" cy="${60 + dy}" r="24" fill="url(#ear)"/>''';

String _earRight(double dy) =>
    '''
<circle cx="188" cy="${58 + dy}" r="40" fill="url(#fur)"/>
<circle cx="216" cy="${46 + dy * 2}" r="11" fill="#B7C0D0"/>
<circle cx="186" cy="${60 + dy}" r="24" fill="url(#ear)"/>''';

const _headFur = '''
<ellipse cx="120" cy="98" rx="76" ry="64" fill="url(#fur)"/>
<ellipse cx="98" cy="54" rx="30" ry="11" fill="#FFFFFF" opacity=".28"/>''';

const _nose = '''
<path d="M120 94 C137 94 141 106 139 118 C137 131 130 138 120 138 C110 138 103 131 101 118 C99 106 103 94 120 94 Z" fill="url(#nose)"/>
<ellipse cx="112" cy="104" rx="7" ry="4" fill="#FFFFFF" opacity=".35"/>''';

const _scarf = '''
<path d="M66 156 Q120 182 174 156 L176 170 Q120 198 64 170 Z" fill="url(#scarf)"/>
<path d="M150 172 L170 202 L151 199 L142 176 Z" fill="#2F6FED"/>''';

final _senang = KoalaParts._(
  shadow: _svg(_shadow),
  body: _svg(_body),
  wavingArm: _svg(
    '<ellipse cx="194" cy="138" rx="14" ry="27" transform="rotate(35 194 138)" fill="url(#fur)"/>',
  ),
  wavingArmPivot: (x: 177.0, y: 158.0),
  earLeft: _svg(_earLeft(0)),
  earRight: _svg(_earRight(0)),
  head: _svg('''
$_headFur
<ellipse cx="74" cy="118" rx="12" ry="8" fill="#F5A3BB" opacity=".75"/>
<ellipse cx="166" cy="118" rx="12" ry="8" fill="#F5A3BB" opacity=".75"/>
$_nose
<path d="M108 145 Q120 160 132 145 Z" fill="#1B2236"/>
<path d="M113 151 Q120 158 127 151 Q120 154 113 151 Z" fill="#F5A3BB"/>'''),
  eyes: _svg('''
<ellipse cx="88" cy="94" rx="9" ry="11" fill="#1B2236"/>
<ellipse cx="152" cy="94" rx="9" ry="11" fill="#1B2236"/>
<circle cx="91" cy="90" r="3.5" fill="#FFFFFF"/>
<circle cx="155" cy="90" r="3.5" fill="#FFFFFF"/>'''),
  eyeY: 94,
  yawn: _svg(_yawn(13)),
  scarf: _svg(_scarf),
  arm: _svg(
    '<ellipse cx="80" cy="190" rx="13" ry="22" transform="rotate(25 80 190)" fill="#97A3B8"/>',
  ),
  armPivot: (x: 88.0, y: 210.0),
  leaf: _svg(
    '''
<path d="M58 202 C53 180 68 162 88 160 C91 180 80 197 58 202 Z" fill="url(#leaf)"/>
<path d="M61 199 L86 163" stroke="#FFFFFF" stroke-opacity=".65" stroke-width="2.5" stroke-linecap="round"/>''',
  ),
);

final _mikir = KoalaParts._(
  shadow: _svg(_shadow),
  body: _svg(_body),
  earLeft: _svg(_earLeft(0)),
  earRight: _svg(_earRight(0)),
  head: _svg(
    '''
$_headFur
<ellipse cx="74" cy="118" rx="12" ry="8" fill="#F5A3BB" opacity=".6"/>
<ellipse cx="166" cy="118" rx="12" ry="8" fill="#F5A3BB" opacity=".6"/>
<path d="M140 72 Q152 66 164 72" stroke="#5B6A85" stroke-width="4" stroke-linecap="round" fill="none"/>
$_nose
<path d="M112 150 Q122 146 130 150" stroke="#1B2236" stroke-width="4" stroke-linecap="round" fill="none"/>''',
  ),
  eyes: _svg('''
<ellipse cx="90" cy="92" rx="9" ry="11" fill="#1B2236"/>
<ellipse cx="154" cy="92" rx="9" ry="11" fill="#1B2236"/>
<circle cx="94" cy="86" r="3.5" fill="#FFFFFF"/>
<circle cx="158" cy="86" r="3.5" fill="#FFFFFF"/>'''),
  eyeY: 92,
  yawn: _svg(_yawn(12)),
  scarf: _svg(_scarf),
  arm: _svg(
    '<ellipse cx="150" cy="168" rx="14" ry="26" transform="rotate(-35 150 168)" fill="#97A3B8"/>',
  ),
  armPivot: (x: 165.0, y: 189.0),
  bubbles: [
    (
      _svg('<circle cx="190" cy="56" r="4" fill="#B9D2FF"/>'),
      (x: 190.0, y: 56.0),
    ),
    (
      _svg('<circle cx="200" cy="40" r="7" fill="#78AAFF"/>'),
      (x: 200.0, y: 40.0),
    ),
    (
      _svg('<circle cx="214" cy="22" r="10" fill="#2F6FED"/>'),
      (x: 214.0, y: 22.0),
    ),
  ],
);

final _khawatir = KoalaParts._(
  shadow: _svg(_shadow),
  body: _svg(_body),
  earLeft: _svg(_earLeft(4)),
  earRight: _svg(_earRight(4)),
  head: _svg(
    '''
$_headFur
<ellipse cx="74" cy="120" rx="12" ry="8" fill="#F5A3BB" opacity=".55"/>
<ellipse cx="166" cy="120" rx="12" ry="8" fill="#F5A3BB" opacity=".55"/>
<path d="M74 80 L98 72" stroke="#5B6A85" stroke-width="4.5" stroke-linecap="round"/>
<path d="M166 80 L142 72" stroke="#5B6A85" stroke-width="4.5" stroke-linecap="round"/>
<path d="M120 96 C137 96 141 108 139 120 C137 132 130 139 120 139 C110 139 103 132 101 120 C99 108 103 96 120 96 Z" fill="url(#nose)"/>
<ellipse cx="112" cy="106" rx="7" ry="4" fill="#FFFFFF" opacity=".35"/>
<path d="M106 151 Q113 145 120 151 Q127 157 134 151" stroke="#1B2236" stroke-width="4" stroke-linecap="round" fill="none"/>''',
  ),
  eyes: _svg('''
<ellipse cx="88" cy="96" rx="8" ry="10" fill="#1B2236"/>
<ellipse cx="152" cy="96" rx="8" ry="10" fill="#1B2236"/>
<circle cx="90" cy="93" r="3" fill="#FFFFFF"/>
<circle cx="154" cy="93" r="3" fill="#FFFFFF"/>'''),
  eyeY: 96,
  yawn: _svg(_yawn(15)),
  scarf: _svg(_scarf),
  drop: _svg(
    '<path d="M190 30 C198 42 202 50 202 56 C202 63 196 68 190 68 C184 68 178 63 178 56 C178 50 182 42 190 30 Z" fill="url(#drop)"/>',
  ),
  arm: _svg(
    '<ellipse cx="82" cy="186" rx="13" ry="22" transform="rotate(-20 82 186)" fill="#97A3B8"/>',
  ),
  armPivot: (x: 76.0, y: 166.0),
  armRight: _svg(
    '<ellipse cx="158" cy="186" rx="13" ry="22" transform="rotate(20 158 186)" fill="#97A3B8"/>',
  ),
  armRightPivot: (x: 164.0, y: 166.0),
);

/// Yawning mouth, wide enough ([halfWidth]) to cover the mood's own mouth.
String _yawn(double halfWidth) =>
    '<ellipse cx="120" cy="151" rx="$halfWidth" ry="12" fill="#1B2236"/>'
    '<ellipse cx="120" cy="157" rx="${halfWidth * 0.55}" ry="4.5" fill="#F5A3BB"/>';

// ---------------------------------------------------------------------------
// Sky: a small sun (light theme) or crescent moon (dark theme) beside large
// koalas. Own 60 × 60 canvas; [KoalaSky] places it in koala canvas units.

String _sky(String body) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 60">$body</svg>';

abstract final class KoalaSky {
  static const canvas = 60.0;

  /// Sky box in koala canvas units: left, top, size. It sits above the left
  /// ear and reaches past the koala's top edge.
  static const left = 4.8, top = -44.0, size = 57.6;

  static const center = (x: 30.0, y: 30.0);
  static const moonCenter = (x: 28.0, y: 31.0);

  static final sunRays = _sky(
    '<g stroke="#FFC14D" stroke-width="3.6" stroke-linecap="round">'
    '${[for (var i = 0; i < 8; i++) _ray(i * math.pi / 4)].join()}'
    '</g>',
  );

  static final sunCore = _sky('''
<defs><radialGradient id="sun" cx="40%" cy="38%" r="65%"><stop offset="0" stop-color="#FFE89A"/><stop offset="1" stop-color="#FFB33F"/></radialGradient></defs>
<circle cx="30" cy="30" r="14" fill="url(#sun)"/>
<ellipse cx="25" cy="24" rx="5" ry="3" fill="#FFFFFF" opacity=".45"/>''');

  /// Crescent: the r16 disc at (28,31) minus the r14 disc at (38,23).
  static final moon = _sky('''
<defs><radialGradient id="glow" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#F6E7B0" stop-opacity=".35"/><stop offset="1" stop-color="#F6E7B0" stop-opacity="0"/></radialGradient></defs>
<circle cx="28" cy="31" r="24" fill="url(#glow)"/>
<path d="M43.2 36 A16 16 0 1 1 26.46 15.07 A14 14 0 0 0 43.2 36 Z" fill="#F6E7B0"/>
<circle cx="20" cy="36" r="2.2" fill="#E2CF8F"/>''');

  static final stars = [
    for (final (x, y, r) in const [
      (50.0, 40.0, 2.2),
      (46.0, 10.0, 1.6),
      (8.0, 10.0, 1.4),
    ])
      _sky(_star(x, y, r)),
  ];

  static String _ray(double a) {
    String n(double v) => v.toStringAsFixed(2);
    return '<line x1="${n(30 + math.cos(a) * 20)}" y1="${n(30 + math.sin(a) * 20)}" '
        'x2="${n(30 + math.cos(a) * 26)}" y2="${n(30 + math.sin(a) * 26)}"/>';
  }

  static String _star(double x, double y, double r) {
    final d = r * 2.2;
    return '<path d="M$x ${y - d} Q$x $y ${x + d} $y Q$x $y $x ${y + d} '
        'Q$x $y ${x - d} $y Q$x $y $x ${y - d} Z" fill="#FFF3C8"/>';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/auth_config.dart';

import '../data/app_services.dart';

import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/aibs_tokens.dart';
import '../shared/widgets/koala.dart';
import '../widgets/aibs_widgets.dart';
import 'profile_setup_flow.dart';

enum _OnboardingStep { welcome, demoProfiles, email, code, consent, profile }

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    required this.onComplete,
    super.key,
    this.onAssess,
    this.onDemo,
    this.onSendCode,
    this.onVerifyCode,
    this.onConsent,
    this.otpLength = emailOtpLength,
  });

  final ProfileSetupComplete onComplete;
  final ScreeningAssessor? onAssess;
  final Future<ProfileSetupAnswers> Function(String template)? onDemo;
  final Future<void> Function(String email)? onSendCode;
  final Future<bool> Function(String email, String code)? onVerifyCode;
  final Future<void> Function(bool ai)? onConsent;
  final int otpLength;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _emailController = TextEditingController();
  late final _codeControllers = List.generate(
    widget.otpLength,
    (_) => TextEditingController(),
  );
  late final _codeFocusNodes = List.generate(
    widget.otpLength,
    (_) => FocusNode(),
  );

  _OnboardingStep _step = _OnboardingStep.welcome;
  bool _aiEnabled = true;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final node in _codeFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _OnboardingStep.profile) {
      return ProfileSetupFlow(
        displayName: _emailController.text.trim().split('@').first,
        email: _emailController.text.trim(),
        aiEnabled: _aiEnabled,
        onComplete: widget.onComplete,
        onBackToAccount: () => setState(() => _step = _OnboardingStep.consent),
        onAssess: widget.onAssess,
      );
    }

    return Scaffold(
      backgroundColor: AibsColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: AibsMotion.page,
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(
                    AibsSpace.s20,
                    AibsSpace.s24,
                    AibsSpace.s20,
                    AibsSpace.s24,
                  ),
                  child: _buildStep(),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AibsSpace.s20,
                  0,
                  AibsSpace.s20,
                  AibsSpace.s8,
                ),
                child: Text(
                  _error!,
                  style: AibsType.caption.copyWith(color: AibsColors.badInk),
                ),
              ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_step == _OnboardingStep.welcome) {
      return const SizedBox(height: AibsSpace.s16);
    }
    return Padding(
      padding: AibsSpace.topBar,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kembali',
            onPressed: _back,
            icon: const Icon(Icons.arrow_back),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildStep() => switch (_step) {
    _OnboardingStep.welcome => _buildWelcome(),
    _OnboardingStep.demoProfiles => _buildDemoProfiles(),
    _OnboardingStep.email => _buildEmail(),
    _OnboardingStep.code => _buildCode(),
    _OnboardingStep.consent => _buildConsent(),
    _OnboardingStep.profile => const SizedBox.shrink(),
  };

  Widget _buildWelcome() {
    return Column(
      children: [
        const SizedBox(height: AibsSpace.s8),
        SizedBox(
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 240,
                height: 240,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AibsGradients.hero,
                ),
              ),
              const Koala(KoalaMood.senang, size: AibsSize.koalaWelcome),
              Positioned(
                right: 12,
                bottom: 20,
                child: SvgPicture.asset(
                  'assets/illustrations/bowl.svg',
                  width: 56,
                  height: 56,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AibsSpace.s16),
        Text('AIBS', style: AibsType.label),
        const SizedBox(height: AibsSpace.s8),
        Text(
          'Makan tenang,\nperut senang',
          textAlign: TextAlign.center,
          style: AibsType.display,
        ),
        const SizedBox(height: AibsSpace.s12),
        Text(
          'Pilih makan sesuai arahan dokter, catat gejala dengan mudah.',
          textAlign: TextAlign.center,
          style: AibsType.body,
        ),
        const SizedBox(height: AibsSpace.s8),
        Text(
          'Bukan pengganti saran dokter.',
          style: AibsType.micro,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDemoProfiles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih profil demo', style: AibsType.title),
        const SizedBox(height: AibsSpace.s20),
        _DemoProfileCard(
          name: 'Nadia, 21',
          role: 'Mahasiswi',
          details: const ['Low FODMAP', 'Alergi udang', 'Rp25rb'],
          onTap: () => _complete(_demoProfile('Nadia', student: true)),
        ),
        const SizedBox(height: AibsSpace.s14),
        _DemoProfileCard(
          name: 'Raka, 24',
          role: 'Karyawan',
          details: const ['Rendah lemak', 'Alergi kacang', 'Rp35rb'],
          onTap: () => _complete(_demoProfile('Raka', student: false)),
        ),
      ],
    );
  }

  Widget _buildEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Masuk ke AIBS', style: AibsType.title),
        const SizedBox(height: AibsSpace.s20),
        Text('Email', style: AibsType.caption),
        const SizedBox(height: AibsSpace.s8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: 'nama@email.com'),
          onChanged: (_) => setState(() => _error = null),
        ),
      ],
    );
  }

  Widget _buildCode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Masukkan kode', style: AibsType.title),
        const SizedBox(height: AibsSpace.s8),
        Text(_emailController.text.trim(), style: AibsType.label),
        const SizedBox(height: AibsSpace.s24),
        Row(
          children: [
            for (var index = 0; index < _codeControllers.length; index++) ...[
              if (index > 0) const SizedBox(width: AibsSpace.s8),
              Expanded(
                child: TextField(
                  controller: _codeControllers[index],
                  focusNode: _codeFocusNodes[index],
                  onTap: () =>
                      _codeControllers[index].selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _codeControllers[index].text.length,
                      ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: widget.otpLength,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofillHints: index == 0
                      ? const [AutofillHints.oneTimeCode]
                      : null,
                  style: AibsType.title,
                  decoration: const InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    if (value.length > 1) {
                      final start = value.length == widget.otpLength
                          ? 0
                          : index;
                      for (
                        var offset = 0;
                        offset < value.length &&
                            start + offset < _codeControllers.length;
                        offset++
                      ) {
                        _codeControllers[start + offset].text = value[offset];
                      }
                      final next = (start + value.length).clamp(
                        0,
                        _codeFocusNodes.length - 1,
                      );
                      _codeFocusNodes[next].requestFocus();
                      setState(() => _error = null);
                      return;
                    }
                    if (value.isNotEmpty &&
                        index < _codeFocusNodes.length - 1) {
                      _codeFocusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _codeFocusNodes[index - 1].requestFocus();
                    }
                    setState(() => _error = null);
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AibsSpace.s16),
        TextButton(
          onPressed: _busy
              ? null
              : () async {
                  await _sendCode();
                  if (!mounted) return;
                  for (final controller in _codeControllers) {
                    controller.clear();
                  }
                  _codeFocusNodes.first.requestFocus();
                },
          child: const Text('Kirim ulang kode'),
        ),
      ],
    );
  }

  Widget _buildConsent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pakai bantuan AI?', style: AibsType.title),
        const SizedBox(height: AibsSpace.s20),
        _ConsentCard(
          title: 'Pakai AI',
          subtitle: 'Foto dan cerita dirapikan otomatis',
          icon: Icons.auto_awesome_outlined,
          selected: _aiEnabled,
          onTap: () => setState(() => _aiEnabled = true),
        ),
        const SizedBox(height: AibsSpace.s10),
        _ConsentCard(
          title: 'Tanpa AI',
          subtitle: 'Semua diisi manual',
          icon: Icons.edit_outlined,
          selected: !_aiEnabled,
          onTap: () => setState(() => _aiEnabled = false),
        ),
        const SizedBox(height: AibsSpace.s16),
        Text(
          'Bisa diubah kapan saja di Profil › Privasi.',
          style: AibsType.micro,
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: AibsSpace.bottomActions,
      child: switch (_step) {
        _OnboardingStep.welcome => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AibsPrimaryButton(
              label: 'Coba Demo',
              onPressed: () =>
                  setState(() => _step = _OnboardingStep.demoProfiles),
            ),
            const SizedBox(height: AibsSpace.s8),
            TextButton(
              onPressed: () => setState(() => _step = _OnboardingStep.email),
              child: const Text('Masuk'),
            ),
          ],
        ),
        _OnboardingStep.demoProfiles => const SizedBox.shrink(),
        _OnboardingStep.email => AibsPrimaryButton(
          label: 'Kirim kode',
          onPressed: _busy ? null : _sendCode,
        ),
        _OnboardingStep.code => AibsPrimaryButton(
          label: 'Lanjut',
          onPressed: _busy ? null : _verifyCode,
        ),
        _OnboardingStep.consent => AibsPrimaryButton(
          label: 'Lanjut',
          onPressed: _busy ? null : _continueConsent,
        ),
        _OnboardingStep.profile => const SizedBox.shrink(),
      },
    );
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (!email.contains('@') || email.startsWith('@') || email.endsWith('@')) {
      setState(() => _error = 'Masukkan email yang valid.');
      return;
    }
    await _perform(() async {
      await widget.onSendCode?.call(email);
      if (mounted) setState(() => _step = _OnboardingStep.code);
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeControllers.map((c) => c.text).join();
    if (!RegExp('^[0-9]{${widget.otpLength}}\$').hasMatch(code)) {
      setState(() => _error = 'Masukkan ${widget.otpLength} digit kode.');
      return;
    }
    await _perform(() async {
      final restored =
          await widget.onVerifyCode?.call(_emailController.text.trim(), code) ??
          false;
      if (mounted && !restored) setState(() => _step = _OnboardingStep.consent);
    });
  }

  Future<void> _continueConsent() => _perform(() async {
    await widget.onConsent?.call(_aiEnabled);
    if (mounted) setState(() => _step = _OnboardingStep.profile);
  });

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = AppServices.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _back() {
    setState(() {
      _error = null;
      _step = switch (_step) {
        _OnboardingStep.demoProfiles ||
        _OnboardingStep.email => _OnboardingStep.welcome,
        _OnboardingStep.code => _OnboardingStep.email,
        _OnboardingStep.consent => _OnboardingStep.code,
        _OnboardingStep.profile => _OnboardingStep.consent,
        _OnboardingStep.welcome => _OnboardingStep.welcome,
      };
    });
  }

  void _complete(ProfileSetupAnswers profile) {
    _perform(() async {
      final connected = widget.onDemo == null
          ? profile
          : await widget.onDemo!(
              profile.displayName.toLowerCase() == 'nadia' ? 'nadia' : 'raka',
            );
      if (mounted) widget.onComplete(connected);
    });
  }

  ProfileSetupAnswers _demoProfile(String name, {required bool student}) =>
      ProfileSetupAnswers(
        displayName: name,
        email: student ? 'nadia@example.com' : 'raka@example.com',
        ageBand: student ? '18–29' : '18–29',
        diagnosis: 'Ya',
        clinicianGuidance: 'Ya',
        redFlags: const ['Tidak', 'Tidak', 'Tidak', 'Tidak', 'Tidak'],
        pattern: const ['Ya', '3–4 hari', '6–12 bulan', 'Ya', 'Ya', 'Tidak'],
        dietType: student ? 'Low FODMAP' : 'Rendah lemak',
        dietPhase: student ? 'Eliminasi' : null,
        avoidedIngredients: student
            ? const ['Bawang putih', 'Bawang bombay', 'Susu sapi', 'Gandum']
            : const ['Gorengan', 'Santan', 'Kulit ayam'],
        portionLimits: const {'Nasi': 1, 'Buah': 1, 'Roti': null},
        allergies: student ? const ['Udang'] : const ['Kacang tanah'],
        tolerances: student ? const ['Santan', 'Kopi'] : const ['Kopi'],
        budget: student ? 'Rp25.000' : 'Rp35.000',
        spicy: student ? 'Sedikit' : 'Sedang',
        preferences: student
            ? const ['Halal', 'Masak ≤ 15 menit']
            : const ['Halal'],
      );
}

class _DemoProfileCard extends StatelessWidget {
  const _DemoProfileCard({
    required this.name,
    required this.role,
    required this.details,
    required this.onTap,
  });

  final String name;
  final String role;
  final List<String> details;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AibsColors.card,
      borderRadius: BorderRadius.circular(AibsRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AibsRadius.xl),
        child: Padding(
          padding: const EdgeInsets.all(AibsSpace.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AibsGradients.brand,
                    ),
                    child: Text(
                      name.substring(0, 1),
                      style: AibsType.title.copyWith(
                        color: AibsColors.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AibsSpace.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AibsType.verdict),
                        Text(role, style: AibsType.caption),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AibsColors.inkMuted),
                ],
              ),
              const SizedBox(height: AibsSpace.s12),
              Wrap(
                spacing: AibsSpace.s8,
                runSpacing: AibsSpace.s8,
                children: [
                  for (final detail in details)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AibsColors.primarySoft,
                        borderRadius: BorderRadius.circular(AibsRadius.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AibsSpace.s10,
                          vertical: AibsSpace.s6,
                        ),
                        child: Text(detail, style: AibsType.small),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AibsColors.primarySoft : AibsColors.card,
      borderRadius: BorderRadius.circular(AibsRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AibsRadius.xl),
        child: Padding(
          padding: const EdgeInsets.all(AibsSpace.s16),
          child: Row(
            children: [
              Icon(icon, color: AibsColors.primaryStrong, size: 28),
              const SizedBox(width: AibsSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AibsType.option),
                    Text(subtitle, style: AibsType.caption),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AibsColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

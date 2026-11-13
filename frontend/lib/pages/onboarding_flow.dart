import 'package:flutter/material.dart';

import '../core/theme/aibs_tokens.dart';
import '../shared/widgets/koala.dart';
import '../widgets/aibs_widgets.dart';
import 'profile_setup_flow.dart';

enum _OnboardingStep { welcome, account, profile }

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({required this.onComplete, super.key, this.onAssess});

  final ProfileSetupComplete onComplete;
  final ScreeningAssessor? onAssess;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  _OnboardingStep _step = _OnboardingStep.welcome;
  bool _isSignIn = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _OnboardingStep.profile) {
      return ProfileSetupFlow(
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        onComplete: widget.onComplete,
        onBackToAccount: () => setState(() => _step = _OnboardingStep.account),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AibsSpace.s24,
                  AibsSpace.s12,
                  AibsSpace.s24,
                  AibsSpace.s24,
                ),
                child: _step == _OnboardingStep.welcome
                    ? _buildWelcome()
                    : _buildAccount(),
              ),
            ),
            Padding(
              padding: AibsSpace.bottomActions,
              child: AibsPrimaryButton(
                label: _step == _OnboardingStep.welcome
                    ? 'Mulai'
                    : _isSignIn
                    ? 'Masuk'
                    : 'Daftar',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_step == _OnboardingStep.welcome) {
      return Padding(
        padding: AibsSpace.topBar,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'AIBS',
            style: AibsType.title.copyWith(color: AibsColors.primaryStrong),
          ),
        ),
      );
    }
    return Padding(
      padding: AibsSpace.topBar,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kembali',
            onPressed: () => setState(() => _step = _OnboardingStep.welcome),
            icon: const Icon(Icons.arrow_back),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Koala(KoalaMood.senang, size: AibsSize.koalaWelcome),
        ),
        const SizedBox(height: AibsSpace.s24),
        Text('Makan lebih tenang.', style: AibsType.display),
        const SizedBox(height: AibsSpace.s12),
        Text(
          'Simpan arahan makan dan catatanmu di satu tempat.',
          style: AibsType.body,
        ),
      ],
    );
  }

  Widget _buildAccount() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isSignIn ? 'Masuk' : 'Buat akun', style: AibsType.title),
          const SizedBox(height: AibsSpace.s16),
          Row(
            children: [
              _modeTab(
                'Daftar',
                !_isSignIn,
                () => setState(() => _isSignIn = false),
              ),
              _modeTab(
                'Masuk',
                _isSignIn,
                () => setState(() => _isSignIn = true),
              ),
            ],
          ),
          const SizedBox(height: AibsSpace.s20),
          if (!_isSignIn) ...[
            _fieldLabel('Nama panggilan'),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'Nadia'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Isi nama panggilan kamu.'
                  : null,
            ),
            const SizedBox(height: AibsSpace.s16),
          ],
          _fieldLabel('Email'),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'nama@email.com'),
            validator: (value) => (value == null || !value.contains('@'))
                ? 'Masukkan email yang valid.'
                : null,
          ),
          const SizedBox(height: AibsSpace.s16),
          _fieldLabel('Password'),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              hintText: 'Minimal 8 karakter',
              suffixIcon: IconButton(
                tooltip: _showPassword
                    ? 'Sembunyikan password'
                    : 'Tampilkan password',
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            validator: (value) => (value == null || value.length < 8)
                ? 'Password minimal 8 karakter.'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _modeTab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: selected
              ? AibsColors.primaryStrong
              : AibsColors.inkMuted,
          textStyle: AibsType.button.copyWith(
            fontWeight: selected ? AibsType.w800 : AibsType.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AibsSpace.s8),
      child: Text(text, style: AibsType.caption),
    );
  }

  void _next() {
    if (_step == _OnboardingStep.welcome) {
      setState(() => _step = _OnboardingStep.account);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _step = _OnboardingStep.profile);
  }
}

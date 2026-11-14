import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/aibs_tokens.dart';
import '../data/app_services.dart';
import '../widgets/aibs_widgets.dart';

class LinkEmailSheet extends StatefulWidget {
  const LinkEmailSheet({
    super.key,
    required this.sendCode,
    required this.verifyCode,
  });
  final Future<void> Function(String) sendCode;
  final Future<void> Function(String, String) verifyCode;
  @override
  State<LinkEmailSheet> createState() => _LinkEmailSheetState();
}

class _LinkEmailSheetState extends State<LinkEmailSheet> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  String? _error;
  int _cooldown = 0;
  Timer? _timer;
  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || _cooldown > 0) return;
    final email = _email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _error = 'Masukkan email yang valid.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.sendCode(email);
      if (!mounted) return;
      setState(() {
        _sent = true;
        _cooldown = 60;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _cooldown <= 1) {
          timer.cancel();
          if (mounted) setState(() => _cooldown = 0);
        } else {
          setState(() => _cooldown--);
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = AppServices.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_busy) return;
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text)) {
      setState(() => _error = 'Masukkan 6 digit kode.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.verifyCode(_email.text.trim(), _code.text);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = AppServices.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        AibsSpace.s20,
        AibsSpace.s20,
        AibsSpace.s20,
        AibsSpace.s24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hubungkan email', style: AibsType.sheetTitle),
            const SizedBox(height: AibsSpace.s12),
            Text(
              'Gunakan email untuk masuk kembali ke catatan yang sama.',
              style: AibsType.body,
            ),
            const SizedBox(height: AibsSpace.s16),
            TextField(
              controller: _email,
              enabled: !_sent && !_busy,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            if (_sent) ...[
              const SizedBox(height: AibsSpace.s16),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Kode OTP'),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AibsSpace.s12),
                child: Text(
                  _error!,
                  style: AibsType.caption.copyWith(color: AibsColors.badInk),
                ),
              ),
            const SizedBox(height: AibsSpace.s16),
            AibsPrimaryButton(
              label: _busy
                  ? 'Tunggu...'
                  : _sent
                  ? 'Verifikasi'
                  : 'Kirim kode',
              onPressed: _busy
                  ? null
                  : _sent
                  ? _verify
                  : _send,
            ),
            if (_sent)
              TextButton(
                onPressed: _busy || _cooldown > 0 ? null : _send,
                child: Text(
                  _cooldown > 0
                      ? 'Kirim ulang ($_cooldown dtk)'
                      : 'Kirim ulang kode',
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

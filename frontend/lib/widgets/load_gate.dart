import 'package:flutter/material.dart';

import '../core/theme/aibs_tokens.dart';
import 'aibs_widgets.dart';

/// Initial loading must not look like a new account or an empty history.
class LoadGate extends StatelessWidget {
  const LoadGate({
    super.key,
    required this.busy,
    required this.message,
    required this.onRetry,
    this.onLogout,
  });
  final bool busy;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AibsSpace.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: AibsSpace.s20),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.aibsText(AibsType.body),
              ),
              if (!busy) ...[
                const SizedBox(height: AibsSpace.s20),
                AibsSecondaryButton(label: 'Coba lagi', onPressed: onRetry),
                if (onLogout != null)
                  TextButton(onPressed: onLogout, child: const Text('Keluar')),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

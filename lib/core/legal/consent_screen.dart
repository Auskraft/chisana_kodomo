import 'package:flutter/material.dart';

import '../storage/game_storage.dart';
import '../theme/app_colors.dart';
import 'legal_texts.dart';
import 'privacy_screen.dart';

/// Экран согласия при первом запуске. Доброжелательный, без юридического
/// давления: коротко о приватности + кнопка «Хорошо!». Записывает согласие в
/// `GameStorage` и зовёт [onAccept].
class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key, required this.onAccept});

  final VoidCallback onAccept;

  Future<void> _accept() async {
    await GameStorage.instance.acceptConsent();
    onAccept();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('🧸', style: TextStyle(fontSize: 84)),
                const SizedBox(height: 12),
                Text(
                  LegalTexts.appName,
                  textAlign: TextAlign.center,
                  style: text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.onBackground,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Развивающие игры для малышей',
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.copyWith(color: colors.primary),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: <Widget>[
                      for (final p in LegalTexts.consentPoints)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(p, style: text.titleMedium),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _accept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    textStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  child: const Text('Хорошо!'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
                  ),
                  child: const Text('Политика конфиденциальности'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

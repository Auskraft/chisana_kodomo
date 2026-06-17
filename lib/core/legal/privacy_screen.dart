import 'package:flutter/material.dart';

import 'legal_texts.dart';

/// Экран с полной политикой конфиденциальности (просто читаемый текст).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Конфиденциальность')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          LegalTexts.privacyPolicy.trim(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
      ),
    );
  }
}

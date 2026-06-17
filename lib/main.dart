import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/menu/lobby_screen.dart';

/// Точка входа «Chisana kodomo» (ちいさなこども — «маленькие дети»).
///
/// Развивающие мини-игры для малышей 3–6 лет: бесплатно, без рекламы и доната,
/// офлайн. Пока это базовый скелет — бутит в лобби-заглушку [LobbyScreen].
void main() {
  runApp(const ChisanaKodomoApp());
}

/// Корень приложения. Светлая тёплая тема [AppTheme.daylight].
class ChisanaKodomoApp extends StatelessWidget {
  const ChisanaKodomoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chisana kodomo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.daylight,
      home: const LobbyScreen(),
    );
  }
}

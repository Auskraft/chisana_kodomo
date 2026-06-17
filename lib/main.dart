import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'core/audio/sfx.dart';
import 'core/feedback/haptics.dart';
import 'core/storage/game_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/voice/voice.dart';
import 'features/menu/lobby_screen.dart';

/// Точка входа «Chisana kodomo» (ちいさなこども — «маленькие дети»).
///
/// Развивающие мини-игры для малышей 3–6 лет: бесплатно, без рекламы и доната,
/// офлайн. Инициализирует хранилище/голос/настройки и бутит в лобби.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GameStorage.init();
  final storage = GameStorage.instance;
  Haptics.enabled = storage.hapticsOn;
  Sfx.enabled = storage.soundOn;
  Voice.instance.enabled = storage.voiceOn;

  await Future.wait(<Future<void>>[
    Voice.instance.init(), // читает настройки голоса, no-op без TTS
    _enableHighRefreshRate(),
  ]);

  runApp(const ChisanaKodomoApp());
}

Future<void> _enableHighRefreshRate() async {
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (_) {
    // Платформа не поддерживает — остаёмся на 60 Гц.
  }
}

/// Корень приложения. Светлая тёплая тема [AppTheme.daylight]
/// (переключение тем — позже, на этапе настроек).
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

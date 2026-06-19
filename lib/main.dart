import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'core/audio/sfx.dart';
import 'core/feedback/haptics.dart';
import 'core/legal/consent_screen.dart';
import 'core/onboarding/gender_screen.dart';
import 'core/storage/game_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/voice/voice.dart';
import 'features/menu/lobby_screen.dart';

/// Точка входа «Chisana kodomo» (ちいさなこども — «маленькие дети»).
///
/// Развивающие мини-игры для малышей 3–6 лет: бесплатно, без рекламы и доната,
/// офлайн. Инициализирует хранилище/голос/настройки и бутит в лобби.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Мгновенный полноэкранный сплэш (та же сова, что в нативном сплэше) — пока
  // идёт инициализация. Переход нативный сплэш → этот → лобби бесшовный.
  runApp(const _SplashApp());

  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[DeviceOrientation.portraitUp],
  );

  await GameStorage.init();
  final storage = GameStorage.instance;
  ThemeController.instance.load(); // активная тема из хранилища
  Haptics.enabled = storage.hapticsOn;
  Sfx.enabled = storage.soundOn;
  Voice.instance.enabled = storage.voiceOn;

  await Future.wait(<Future<void>>[
    Voice.instance.init(
      voiceName: storage.voiceName,
      voiceLocale: storage.voiceLocale,
      usePack: storage.voiceUsePack,
      packVoice: storage.voicePackId,
    ),
    _enableHighRefreshRate(),
    // Минимальная выдержка сплэша, чтобы он не мелькал на быстрых устройствах.
    Future<void>.delayed(const Duration(milliseconds: 1200)),
  ]);

  runApp(const ChisanaKodomoApp());
}

/// Полноэкранный сплэш на время загрузки. Та же картинка-сова, что в нативном
/// сплэше, — переход бесшовный. `BoxFit.cover` растягивает на весь экран.
class _SplashApp extends StatelessWidget {
  const _SplashApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFFFBE6C0),
        body: SizedBox.expand(
          child: Image(
            image: AssetImage('assets/icon/splash.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

Future<void> _enableHighRefreshRate() async {
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (_) {
    // Платформа не поддерживает — остаёмся на 60 Гц.
  }
}

/// Корень приложения. Тема берётся из активного выбора [ThemeController] и
/// пересобирается при смене (живой реколор всего UI через `context.appColors`).
class ChisanaKodomoApp extends StatelessWidget {
  const ChisanaKodomoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: ThemeController.instance.themeId,
      builder: (context, id, _) => MaterialApp(
        title: 'Chisana kodomo',
        debugShowCheckedModeBanner: false,
        theme: AppThemes.byId(id).theme,
        home: const _RootGate(),
      ),
    );
  }
}

/// При первом запуске показывает экран согласия (офлайн, без сбора данных),
/// затем — лобби. Согласие хранится в `GameStorage`.
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  late bool _consent = GameStorage.instance.consentAccepted;
  late bool _genderAsked = GameStorage.instance.genderAsked;

  @override
  Widget build(BuildContext context) {
    if (!_consent) {
      return ConsentScreen(onAccept: () => setState(() => _consent = true));
    }
    if (!_genderAsked) {
      return GenderScreen(onDone: () => setState(() => _genderAsked = true));
    }
    return const LobbyScreen();
  }
}

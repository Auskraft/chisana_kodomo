import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

/// Единое хранилище на `shared_preferences`: прогресс (открытые наборы + звёзды
/// по каждой игре), выбранная тема, согласие и настройки (звук/голос/вибро).
///
/// Инициализируется один раз в `main()` до запуска приложения.
class GameStorage {
  GameStorage._(this._prefs);

  final SharedPreferences _prefs;
  static GameStorage? _instance;

  /// Доступ к синглтону. Бросит, если не вызвали [init].
  static GameStorage get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('GameStorage.init() не был вызван');
    }
    return i;
  }

  static Future<GameStorage> init() async {
    return _instance ??= GameStorage._(await SharedPreferences.getInstance());
  }

  /// Сброс синглтона между тестами (после `setMockInitialValues`).
  @visibleForTesting
  static void debugReset() => _instance = null;

  // ── Согласие (экран при первом запуске) ────────────────────────────────────
  static const String _consentKey = 'consent_accepted_v1';
  bool get consentAccepted => _prefs.getBool(_consentKey) ?? false;
  Future<void> acceptConsent() => _prefs.setBool(_consentKey, true);

  // ── Настройки (по умолчанию всё включено) ──────────────────────────────────
  bool get soundOn => _prefs.getBool('sound_on') ?? true;
  Future<void> setSoundOn(bool v) => _prefs.setBool('sound_on', v);

  bool get voiceOn => _prefs.getBool('voice_on') ?? true;
  Future<void> setVoiceOn(bool v) => _prefs.setBool('voice_on', v);

  bool get hapticsOn => _prefs.getBool('haptics_on') ?? true;
  Future<void> setHapticsOn(bool v) => _prefs.setBool('haptics_on', v);

  // ── Выбранная визуальная тема (id из AppThemes) ─────────────────────────────
  String get themeId => _prefs.getString('theme_id') ?? 'daylight';
  Future<void> setThemeId(String id) => _prefs.setString('theme_id', id);

  // ── Выбранный системный голос TTS (имя + локаль движка) ─────────────────────
  String? get voiceName => _prefs.getString('voice_name');
  String? get voiceLocale => _prefs.getString('voice_locale');
  Future<void> setVoiceChoice(String name, String locale) async {
    await _prefs.setString('voice_name', name);
    await _prefs.setString('voice_locale', locale);
  }

  /// Использовать встроенный голосовой пак (офлайн) вместо системного TTS.
  bool get voiceUsePack => _prefs.getBool('voice_use_pack') ?? false;
  Future<void> setVoiceUsePack(bool v) => _prefs.setBool('voice_use_pack', v);

  // ── Выбранный фон главного экрана (0-based) ─────────────────────────────────
  int get backgroundIndex => _prefs.getInt('bg_index') ?? 0;
  Future<void> setBackgroundIndex(int i) => _prefs.setInt('bg_index', i);

  // ── Прогресс по играм: открытые наборы + звёзды за набор ────────────────────
  // Ключи живут по id игры (= папка/feature), как и в сборнике-эталоне.

  /// Сколько наборов открыто в игре (минимум 1 — первый всегда доступен).
  int unlockedSets(String gameId) => _prefs.getInt('sets_$gameId') ?? 1;

  /// Открыть наборы до [count] (только вверх — прогресс не откатывается).
  Future<void> unlockSets(String gameId, int count) async {
    if (count > unlockedSets(gameId)) {
      await _prefs.setInt('sets_$gameId', count);
    }
  }

  /// Звёзды за набор (0..3).
  int setStars(String gameId, int setIndex) =>
      _prefs.getInt('stars_${gameId}_$setIndex') ?? 0;

  /// Сохранить звёзды за набор, если их больше прежнего. true — улучшение.
  Future<bool> recordSetStars(String gameId, int setIndex, int stars) async {
    final clamped = stars.clamp(0, 3);
    if (clamped > setStars(gameId, setIndex)) {
      await _prefs.setInt('stars_${gameId}_$setIndex', clamped);
      return true;
    }
    return false;
  }

  /// Сумма звёзд по [setCount] наборам игры (для витрины/наград).
  int totalStars(String gameId, int setCount) {
    var total = 0;
    for (var i = 0; i < setCount; i++) {
      total += setStars(gameId, i);
    }
    return total;
  }
}

import 'dart:math';

/// Поощрение: тёплые фразы похвалы + правило начисления звёзд за набор.
///
/// Чистая логика (только `dart:math`) — тестируется. Голос/UI берут фразу
/// отсюда, прогрессия — звёзды.
class Praise {
  const Praise._();

  /// Короткие добрые фразы для голоса/попапа после успеха.
  static const List<String> phrases = <String>[
    'Молодец!',
    'Умница!',
    'Здорово!',
    'Верно!',
    'Супер!',
    'Класс!',
    'Получилось!',
    'Ты справился!',
  ];

  /// Случайная фраза похвалы (детерминирована по [random] — удобно для тестов).
  static String pick(Random random) => phrases[random.nextInt(phrases.length)];

  /// Звёзды за пройденный набор по числу ошибок. «Без проигрышей»: даже с
  /// ошибками всегда минимум 1 звезда — набор всё равно пройден.
  static int starsForMistakes(int mistakes) {
    if (mistakes <= 0) return 3;
    if (mistakes <= 2) return 2;
    return 1;
  }
}

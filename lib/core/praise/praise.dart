import 'dart:math';

/// Пол ребёнка для согласования обращения. `neutral` — по умолчанию (обходим
/// «справился/справилась» нейтральной формулировкой).
enum Gender {
  neutral('neutral'),
  boy('boy'),
  girl('girl');

  const Gender(this.id);

  /// Стабильный ключ для хранения в `GameStorage`.
  final String id;

  static Gender fromId(String? id) =>
      Gender.values.firstWhere((Gender g) => g.id == id, orElse: () => Gender.neutral);
}

/// Поощрение: тёплые фразы похвалы + правило начисления звёзд за набор.
///
/// Чистая логика (только `dart:math`) — тестируется. Голос/UI берут фразу
/// отсюда, прогрессия — звёзды.
class Praise {
  const Praise._();

  /// Короткие добрые фразы для голоса/попапа после успеха. Все **нейтральны по
  /// роду** — подходят и мальчику, и девочке.
  static const List<String> phrases = <String>[
    'Молодец!',
    'Умница!',
    'Здорово!',
    'Верно!',
    'Супер!',
    'Класс!',
    'Получилось!',
    'Отлично!',
  ];

  /// Случайная фраза похвалы (детерминирована по [random] — удобно для тестов).
  static String pick(Random random) => phrases[random.nextInt(phrases.length)];

  /// Финальная похвала за набор, согласованная по [gender]. Нейтральная форма
  /// обходит «справился/справилась».
  static String setDone(Gender gender) {
    switch (gender) {
      case Gender.boy:
        return 'Молодец! Ты справился!';
      case Gender.girl:
        return 'Молодец! Ты справилась!';
      case Gender.neutral:
        return 'Молодец! Всё получилось!';
    }
  }

  /// Звёзды за пройденный набор по числу ошибок. «Без проигрышей»: даже с
  /// ошибками всегда минимум 1 звезда — набор всё равно пройден.
  static int starsForMistakes(int mistakes) {
    if (mistakes <= 0) return 3;
    if (mistakes <= 2) return 2;
    return 1;
  }
}

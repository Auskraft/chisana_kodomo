import 'package:flutter/material.dart';

import '../feedback/haptics.dart';
import '../praise/praise.dart';
import '../storage/game_storage.dart';
import '../theme/app_colors.dart';

/// Экран первого запуска «Кто играет?» — чтобы хвалить в нужном роде. Выбор
/// необязателен: «Пропустить» оставляет нейтральное обращение. Меняется потом
/// в Настройках.
class GenderScreen extends StatelessWidget {
  const GenderScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  Future<void> _pick(Gender g) async {
    Haptics.select();
    await GameStorage.instance.setChildGender(g.id);
    onDone();
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
                Text(
                  'Кто играет?',
                  style: text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Чтобы хвалить правильно 🙂',
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.copyWith(
                    color: colors.onBackground.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _Choice(emoji: '👦', label: 'Мальчик', colors: colors, onTap: () => _pick(Gender.boy)),
                    const SizedBox(width: 20),
                    _Choice(emoji: '👧', label: 'Девочка', colors: colors, onTap: () => _pick(Gender.girl)),
                  ],
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () => _pick(Gender.neutral),
                  child: const Text('Пропустить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.emoji,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 132,
        height: 152,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.onBackground.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

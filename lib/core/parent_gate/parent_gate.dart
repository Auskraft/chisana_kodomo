import 'dart:math';

import 'package:flutter/material.dart';

import '../feedback/haptics.dart';
import '../theme/app_colors.dart';

/// Задачка-гейт «только для взрослых»: умножение однозначных — малышам 3–6 не
/// под силу, взрослому легко. Стоит перед внешними действиями (почта/оценка).
///
/// Чистая логика (только `dart:math`) — тестируется.
class ParentGateChallenge {
  const ParentGateChallenge({
    required this.a,
    required this.b,
    required this.options,
  });

  final int a;
  final int b;

  /// Варианты ответа (содержат верный, перемешаны).
  final List<int> options;

  int get answer => a * b;

  String get question => '$a × $b';

  bool isCorrect(int choice) => choice == answer;

  /// Сгенерировать задачу: a,b ∈ 3..9; 4 различных положительных варианта.
  static ParentGateChallenge generate(Random r) {
    final a = 3 + r.nextInt(7);
    final b = 3 + r.nextInt(7);
    final answer = a * b;
    final options = <int>{answer};
    while (options.length < 4) {
      final delta = r.nextInt(11) - 5; // -5..5
      final cand = answer + delta;
      if (cand > 0 && cand != answer) options.add(cand);
    }
    return ParentGateChallenge(
      a: a,
      b: b,
      options: options.toList()..shuffle(r),
    );
  }
}

/// Показать родительский гейт. Возвращает `true`, если задача решена.
/// Неверный ответ не наказывает — даёт новую задачу.
Future<bool> showParentGate(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ParentGateDialog(),
  );
  return ok ?? false;
}

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog();

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  final Random _rng = Random();
  late ParentGateChallenge _ch = ParentGateChallenge.generate(_rng);
  bool _wrong = false;

  void _choose(int value) {
    if (_ch.isCorrect(value)) {
      Haptics.success();
      Navigator.of(context).pop(true);
    } else {
      Haptics.select();
      setState(() {
        _wrong = true;
        _ch = ParentGateChallenge.generate(_rng);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      title: Row(
        children: <Widget>[
          Icon(Icons.lock_rounded, color: colors.onSurface.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          const Expanded(child: Text('Только для взрослых')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Реши пример, чтобы продолжить:',
            style: text.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_ch.question} = ?',
            style: text.displaySmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: <Widget>[
              for (final opt in _ch.options)
                SizedBox(
                  width: 72,
                  child: ElevatedButton(
                    onPressed: () => _choose(opt),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    child: Text('$opt'),
                  ),
                ),
            ],
          ),
          if (_wrong) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Не то — попробуйте ещё',
              style: text.bodySmall?.copyWith(color: colors.primary),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
      ],
    );
  }
}

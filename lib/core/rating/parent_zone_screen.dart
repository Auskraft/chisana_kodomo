import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../legal/legal_texts.dart';
import '../legal/privacy_screen.dart';
import '../storage/game_storage.dart';

/// «Родительская зона» — показывается ПОСЛЕ родительского гейта (см.
/// `showParentGate`). Внешние действия: написать разработчику, оценить
/// приложение, политика. Оценка станет доступна после публикации в сторе.
class ParentZoneScreen extends StatelessWidget {
  const ParentZoneScreen({super.key});

  /// URL страницы в сторе — заполнить при публикации (RuStore/Google Play).
  static const String storeUrl = '';

  Future<void> _email(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: LegalTexts.contactEmail,
      query: 'subject=${Uri.encodeComponent('${LegalTexts.appName} — отзыв')}',
    );
    await _launch(context, uri, 'Почтовый клиент не найден');
  }

  Future<void> _rate(BuildContext context) async {
    if (storeUrl.isEmpty) {
      _toast(context, 'Оценка появится после публикации в сторе 🙂');
      return;
    }
    await _launch(context, Uri.parse(storeUrl), 'Не удалось открыть стор');
  }

  Future<void> _launch(BuildContext context, Uri uri, String onError) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) _toast(context, onError);
    } catch (_) {
      if (context.mounted) _toast(context, onError);
    }
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _resetProgress(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Сбросить прогресс?'),
        content: const Text(
          'Звёзды, наклейки и открытые уровни обнулятся. Настройки сохранятся. '
          'Это нельзя отменить.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (yes ?? false) {
      await GameStorage.instance.resetProgress();
      if (context.mounted) _toast(context, 'Прогресс сброшен');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Для родителей')),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.mail_outline_rounded),
            title: const Text('Написать разработчику'),
            subtitle: const Text(LegalTexts.contactEmail),
            onTap: () => _email(context),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline_rounded),
            title: const Text('Оценить приложение'),
            onTap: () => _rate(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Политика конфиденциальности'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
            title: const Text('Сбросить прогресс'),
            subtitle: const Text('Звёзды и наклейки начнутся заново'),
            onTap: () => _resetProgress(context),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Благодарности',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(LegalTexts.credits, style: text.bodyMedium),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${LegalTexts.appName} · версия ${LegalTexts.appVersion}\n'
              '${LegalTexts.operator}\n${LegalTexts.city}',
              style: text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

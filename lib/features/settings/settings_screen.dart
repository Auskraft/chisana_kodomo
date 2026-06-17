import 'package:flutter/material.dart';

import '../../core/audio/sfx.dart';
import '../../core/feedback/haptics.dart';
import '../../core/parent_gate/parent_gate.dart';
import '../../core/praise/praise.dart';
import '../../core/rating/parent_zone_screen.dart';
import '../../core/storage/game_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/voice/voice.dart';

/// Экран настроек: тумблеры (голос/звук/вибро) + выбор системного голоса
/// помощника. «Живые» встроенные голоса добавятся в этот же список позже.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GameStorage _s = GameStorage.instance;

  late bool _voiceOn = _s.voiceOn;
  late bool _soundOn = _s.soundOn;
  late bool _hapticsOn = _s.hapticsOn;
  late Gender _gender = Gender.fromId(_s.childGender);

  List<VoiceOption> _voices = const <VoiceOption>[];
  String? _selected = GameStorage.instance.voiceName;
  bool _usePack = GameStorage.instance.voiceUsePack;
  int _bgIndex = GameStorage.instance.backgroundIndex;
  bool _loading = true;

  static const int _bgCount = 9;

  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    final v = await Voice.instance.russianVoices();
    if (!mounted) return;
    setState(() {
      _voices = v;
      _loading = false;
    });
  }

  Future<void> _pick(VoiceOption v) async {
    await Voice.instance.applyVoice(v.name, v.locale);
    Voice.instance.setUsePack(false);
    await _s.setVoiceChoice(v.name, v.locale);
    await _s.setVoiceUsePack(false);
    Haptics.select();
    setState(() {
      _selected = v.name;
      _usePack = false;
    });
    await Voice.instance.say('Привет! Давай посчитаем!', flush: true);
  }

  Future<void> _pickPack() async {
    Voice.instance.setUsePack(true);
    await _s.setVoiceUsePack(true);
    Haptics.select();
    setState(() => _usePack = true);
    await Voice.instance.say('Привет! Давай посчитаем!', flush: true);
  }

  /// «Для родителей» — за родительским гейтом (внешние действия, политика).
  Future<void> _openParentZone() async {
    final ok = await showParentGate(context);
    if (ok && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ParentZoneScreen()),
      );
    }
  }

  void _setGender(Gender g) {
    _s.setChildGender(g.id);
    Haptics.select();
    setState(() => _gender = g);
  }

  String _genderLabel(Gender g) {
    switch (g) {
      case Gender.boy:
        return 'Мальчик';
      case Gender.girl:
        return 'Девочка';
      case Gender.neutral:
        return 'Нейтрально (по умолчанию)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: <Widget>[
          SwitchListTile(
            value: _voiceOn,
            secondary: const Icon(Icons.record_voice_over_rounded),
            title: const Text('Голос'),
            onChanged: (bool v) {
              setState(() => _voiceOn = v);
              _s.setVoiceOn(v);
              Voice.instance.enabled = v;
            },
          ),
          SwitchListTile(
            value: _soundOn,
            secondary: const Icon(Icons.music_note_rounded),
            title: const Text('Звук'),
            onChanged: (bool v) {
              setState(() => _soundOn = v);
              _s.setSoundOn(v);
              Sfx.enabled = v;
            },
          ),
          SwitchListTile(
            value: _hapticsOn,
            secondary: const Icon(Icons.vibration_rounded),
            title: const Text('Вибрация'),
            onChanged: (bool v) {
              setState(() => _hapticsOn = v);
              _s.setHapticsOn(v);
              Haptics.enabled = v;
            },
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Обращение к ребёнку',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          for (final g in Gender.values)
            ListTile(
              onTap: () => _setGender(g),
              leading: Icon(
                _gender == g ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: _gender == g
                    ? colors.primary
                    : colors.onSurface.withValues(alpha: 0.35),
              ),
              title: Text(_genderLabel(g)),
            ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Фон главного экрана',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _bgCount,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final selected = i == _bgIndex;
                return GestureDetector(
                  onTap: () {
                    GameStorage.instance.setBackgroundIndex(i);
                    Haptics.select();
                    setState(() => _bgIndex = i);
                  },
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? colors.primary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.asset(
                        'assets/backgrounds/${i + 1}.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            ColoredBox(color: colors.surface),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Голос помощника',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Нажми голос, чтобы услышать. «Встроенный» работает офлайн (озвучку добавляем отдельно).',
              style: text.bodySmall?.copyWith(
                color: colors.onBackground.withValues(alpha: 0.6),
              ),
            ),
          ),
          // Встроенный (офлайн) — всегда доступен; пока нет клипов, звучит через TTS.
          ListTile(
            onTap: _pickPack,
            leading: Icon(
              _usePack ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: _usePack
                  ? colors.primary
                  : colors.onSurface.withValues(alpha: 0.35),
            ),
            title: const Text('Встроенный голос (офлайн)'),
            subtitle: const Text('Без интернета, одинаково на всех'),
            trailing: const Icon(Icons.volume_up_rounded),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Голоса телефона
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_voices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Русские голоса на телефоне не найдены. Их можно поставить в '
                'настройках телефона: «Синтез речи» → русский язык.',
                style: text.bodyMedium?.copyWith(
                  color: colors.onBackground.withValues(alpha: 0.7),
                ),
              ),
            )
          else
            for (final VoiceOption v in _voices)
              ListTile(
                onTap: () => _pick(v),
                leading: Icon(
                  (!_usePack && v.name == _selected)
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: (!_usePack && v.name == _selected)
                      ? colors.primary
                      : colors.onSurface.withValues(alpha: 0.35),
                ),
                title: Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(v.locale),
                trailing: const Icon(Icons.volume_up_rounded),
              ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.family_restroom_rounded),
            title: const Text('Для родителей'),
            subtitle: const Text('Связь, оценка, политика, сброс прогресса'),
            trailing: const Icon(Icons.lock_outline_rounded),
            onTap: _openParentZone,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/audio/sfx.dart';
import '../../core/feedback/haptics.dart';
import '../../core/parent_gate/parent_gate.dart';
import '../../core/praise/praise.dart';
import '../../core/rating/parent_zone_screen.dart';
import '../../core/storage/game_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/voice/voice.dart';
import 'theme_gallery_screen.dart';

/// Экран настроек — редизайн «Цветные секции» (вариант B, Claude Design):
/// тёплые секции-карточки (звук/голос · кто играет · внешний вид · голос
/// помощника · для родителей). Функционал прежний; цвета — через [AppColors].
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final GameStorage _s = GameStorage.instance;

  late bool _voiceOn = _s.voiceOn;
  late bool _soundOn = _s.soundOn;
  late bool _hapticsOn = _s.hapticsOn;
  late Gender _gender = Gender.fromId(_s.childGender);

  List<VoiceOption> _voices = const <VoiceOption>[];
  String? _selected = GameStorage.instance.voiceName;
  bool _usePack = GameStorage.instance.voiceUsePack;
  String _packVoice = GameStorage.instance.voicePackId;
  bool _loading = true;

  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  Future<void> _loadVoices() async {
    final v = await Voice.instance.russianVoices();
    if (!mounted) return;
    setState(() {
      _voices = v;
      _loading = false;
    });
  }

  Future<void> _refreshVoices() async {
    Haptics.select();
    setState(() => _loading = true);
    await _loadVoices();
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

  Future<void> _pickPack(String voiceId) async {
    Voice.instance.setUsePack(true);
    Voice.instance.setPackVoice(voiceId);
    await _s.setVoiceUsePack(true);
    await _s.setVoicePackId(voiceId);
    Haptics.select();
    setState(() {
      _usePack = true;
      _packVoice = voiceId;
    });
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final pad =
        (MediaQuery.of(context).size.width * 0.04).clamp(12.0, 18.0).toDouble();
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _Header(
              colors: colors,
              bob: _bob,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(pad, 14, pad, 36),
                children: <Widget>[
                  _soundSection(colors),
                  _whoSection(colors),
                  _appearanceSection(colors),
                  _voiceSection(colors),
                  _parentsCard(colors),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Chisana kodomo · офлайн, без рекламы',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Секция 1: Звук и голос ──────────────────────────────────────────────────
  Widget _soundSection(AppColors colors) {
    return _SectionCard(
      colors: colors,
      tint: colors.primary,
      emoji: '🔊',
      title: 'Звук и голос',
      child: Column(
        children: <Widget>[
          _toggleRow(
            colors, '🗣️', 'Голос', 'Подсказки и озвучка заданий', _voiceOn,
            (bool v) {
              setState(() => _voiceOn = v);
              _s.setVoiceOn(v);
              Voice.instance.enabled = v;
            },
          ),
          _rowDivider(colors),
          _toggleRow(
            colors, '🎵', 'Звук', 'Музыка и звуковые эффекты', _soundOn,
            (bool v) {
              setState(() => _soundOn = v);
              _s.setSoundOn(v);
              Sfx.enabled = v;
            },
          ),
          _rowDivider(colors),
          _toggleRow(
            colors, '📳', 'Вибрация', 'Лёгкий отклик при касании', _hapticsOn,
            (bool v) {
              setState(() => _hapticsOn = v);
              _s.setHapticsOn(v);
              Haptics.enabled = v;
            },
          ),
        ],
      ),
    );
  }

  Widget _rowDivider(AppColors colors) => Divider(
        height: 18,
        thickness: 1,
        color: colors.onSurface.withValues(alpha: 0.07),
      );

  Widget _toggleRow(AppColors colors, String emoji, String title, String desc,
      bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Toggle(value: value, colors: colors),
          ],
        ),
      ),
    );
  }

  // ── Секция 2: Кто играет ────────────────────────────────────────────────────
  Widget _whoSection(AppColors colors) {
    return _SectionCard(
      colors: colors,
      tint: colors.accent,
      emoji: '🧒',
      title: 'Кто играет',
      subtitle: 'Как обращаться к ребёнку в игре',
      child: Row(
        children: <Widget>[
          _genderPill(colors, Gender.boy, '👦', 'Мальчик'),
          const SizedBox(width: 9),
          _genderPill(colors, Gender.girl, '👧', 'Девочка'),
          const SizedBox(width: 9),
          _genderPill(colors, Gender.neutral, '🙂', 'Нейтрально'),
        ],
      ),
    );
  }

  Widget _genderPill(AppColors colors, Gender g, String emoji, String label) {
    final selected = _gender == g;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setGender(g),
        child: Stack(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? colors.primary
                    : colors.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                boxShadow: selected
                    ? <BoxShadow>[
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? colors.onPrimary
                          : colors.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.check_circle_rounded,
                    size: 18, color: colors.success),
              ),
          ],
        ),
      ),
    );
  }

  // ── Секция 3: Внешний вид ───────────────────────────────────────────────────
  Widget _appearanceSection(AppColors colors) {
    return _SectionCard(
      colors: colors,
      tint: colors.success,
      emoji: '🎨',
      title: 'Внешний вид',
      subtitle: 'Тема оформления',
      child: _themeTile(colors),
    );
  }

  /// Текущая тема + переход в галерею выбора (живой реколор при выборе).
  Widget _themeTile(AppColors colors) {
    return ValueListenableBuilder<String>(
      valueListenable: ThemeController.instance.themeId,
      builder: (context, id, _) {
        final current = AppThemes.byId(id);
        final dots = <Color>[
          current.colors.primary,
          current.colors.secondary,
          current.colors.accent,
          current.colors.success,
        ];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Haptics.select();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ThemeGalleryScreen(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          current.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${AppThemes.all.length} тем — выбрать',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final c in dots)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded,
                      color: colors.onSurface.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Секция 4: Голос помощника ───────────────────────────────────────────────
  Widget _voiceSection(AppColors colors) {
    return _SectionCard(
      colors: colors,
      tint: colors.secondary,
      emoji: '🎙️',
      title: 'Голос помощника',
      trailing: GestureDetector(
        onTap: _loading ? null : _refreshVoices,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.refresh_rounded, size: 16, color: colors.secondary),
            const SizedBox(width: 3),
            Text(
              'Обновить',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.secondary,
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'ВСТРОЕННЫЕ ГОЛОСА · ОФЛАЙН',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: colors.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          _builtinList(colors),
          const SizedBox(height: 12),
          Text(
            'ОНЛАЙН-ГОЛОСА · НУЖЕН ИНТЕРНЕТ',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: colors.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          _voiceList(colors),
        ],
      ),
    );
  }

  Widget _builtinList(AppColors colors) {
    return Column(
      children: <Widget>[
        for (final pv in Voice.packVoices) _builtinTile(colors, pv),
      ],
    );
  }

  Widget _builtinTile(AppColors colors, PackVoice pv) {
    final selected = _usePack && _packVoice == pv.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _pickPack(pv.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.12)
                : colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? colors.primary
                  : colors.onSurface.withValues(alpha: 0.10),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Text(pv.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pv.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'Офлайн',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.play_arrow_rounded,
                        size: 16, color: colors.secondary),
                    const SizedBox(width: 2),
                    Text(
                      'Послушать',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: colors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) ...<Widget>[
                const SizedBox(width: 6),
                Icon(Icons.check_circle_rounded,
                    size: 20, color: colors.success),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _voiceList(AppColors colors) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: colors.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Загружаем голоса телефона…',
              style: TextStyle(
                fontSize: 12.5,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }
    final shown = _voices
        .where((v) =>
            Voice.systemVoiceLabels.containsKey(v.name.toLowerCase()))
        .toList();
    if (shown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('🔍', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Онлайн-голоса недоступны',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Это сетевые голоса Google — нужен Google TTS и интернет. '
                    'Встроенные голоса выше работают офлайн.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: <Widget>[
        for (final v in shown) _voiceTile(colors, v),
      ],
    );
  }

  Widget _voiceTile(AppColors colors, VoiceOption v) {
    final selected = !_usePack && v.name == _selected;
    final label = Voice.systemVoiceLabels[v.name.toLowerCase()] ?? v.name;
    final initial = label.isNotEmpty ? label.substring(0, 1).toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _pick(v),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? colors.success
                  : colors.onSurface.withValues(alpha: 0.10),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initial,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'Онлайн · нужен интернет',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.play_arrow_rounded,
                        size: 16, color: colors.secondary),
                    const SizedBox(width: 2),
                    Text(
                      'Послушать',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: colors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.check_circle_rounded,
                      size: 18, color: colors.success),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Секция 5: Для родителей ─────────────────────────────────────────────────
  Widget _parentsCard(AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            colors.primary.withValues(alpha: 0.16),
            colors.accent.withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary.withValues(alpha: 0.30), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openParentZone,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text('🔒', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Для родителей',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        'Под защитой · откроется после примера',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: colors.onSurface.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Липкая шапка экрана: «назад» + заголовок/подзаголовок + маскот 🎈 (покачивание).
class _Header extends StatelessWidget {
  const _Header({required this.colors, required this.bob, required this.onBack});

  final AppColors colors;
  final AnimationController bob;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: colors.background,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.onBackground.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            elevation: 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onBack,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.chevron_left_rounded, color: colors.onSurface),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Настройки',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  'Здесь всё настраивает взрослый',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: bob,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -4 + 8 * Curves.easeInOut.transform(bob.value)),
              child: child,
            ),
            child: const Text('🎈', style: TextStyle(fontSize: 30)),
          ),
        ],
      ),
    );
  }
}

/// Секция-карточка варианта B: лёгкая заливка оттенком [tint], бейдж-иконка,
/// заголовок (+ подзаголовок/действие справа) и содержимое.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.colors,
    required this.tint,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  final AppColors colors;
  final Color tint;
  final String emoji;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.onBackground.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Тумблер варианта B: трек 52×30, белый «knob» едет при включении (primary).
class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.colors});

  final bool value;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 52,
      height: 30,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? colors.primary : colors.onSurface.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.onBackground.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

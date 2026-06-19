// СГЕНЕРИРОВАНО tool/gen_themes.py — не редактировать вручную.
// Палитры портированы из rotating_shift (светлые/детские темы) и смапплены
// в роли AppColors. success фиксирован зелёным; onPrimary — под контраст.
// Перегенерация: python tool/gen_themes.py
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme.dart';

/// Портированные палитры (после дефолтных трёх в [AppThemes.all]).
const List<AppThemeOption> kPortedThemes = <AppThemeOption>[
  AppThemeOption(
    id: 'rs_paper', name: 'Бумага', category: 'Нейтральные',
    colors: AppColors(
      background: Color(0xFFF3EFE6), surface: Color(0xFFFAF7F0),
      primary: Color(0xFF3A3A3A), secondary: Color(0xFF3A3A3A),
      accent: Color(0xFF8A6B2E), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF2B2B2B), onSurface: Color(0xFF2B2B2B),
      onPrimary: Color(0xFFFFFFFF),
    ),
  ),
  AppThemeOption(
    id: 'rs_azure', name: 'Лазурный берег', category: 'Нейтральные',
    colors: AppColors(
      background: Color(0xFFF2F8FC), surface: Color(0xFFFFFFFF),
      primary: Color(0xFF5BC0EB), secondary: Color(0xFF5BC0EB),
      accent: Color(0xFF4A90E2), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF1E2A32), onSurface: Color(0xFF1E2A32),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_linen', name: 'Лён', category: 'Нейтральные',
    colors: AppColors(
      background: Color(0xFFF8F5EF), surface: Color(0xFFFEFCF8),
      primary: Color(0xFFC69C6D), secondary: Color(0xFFC69C6D),
      accent: Color(0xFF8F6C42), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF2F2A24), onSurface: Color(0xFF2F2A24),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_oatmilk', name: 'Овсяное молоко', category: 'Нейтральные',
    colors: AppColors(
      background: Color(0xFFFFFBF5), surface: Color(0xFFFFFEFB),
      primary: Color(0xFFD9A86C), secondary: Color(0xFFD9A86C),
      accent: Color(0xFF9B7543), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF332C25), onSurface: Color(0xFF332C25),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_premiumlight', name: 'Премиум светлая', category: 'Нейтральные',
    colors: AppColors(
      background: Color(0xFFF8F7F4), surface: Color(0xFFFFFFFF),
      primary: Color(0xFFC6A756), secondary: Color(0xFFC6A756),
      accent: Color(0xFFB8963A), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF1C1C1A), onSurface: Color(0xFF1C1C1A),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_dustyteal', name: 'Пыльный teal', category: 'Нейтральные',
    colors: AppColors(
      background: Color(0xFFF2F8F8), surface: Color(0xFFF9FCFC),
      primary: Color(0xFF4FB3BF), secondary: Color(0xFF4FB3BF),
      accent: Color(0xFF4D8080), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF223233), onSurface: Color(0xFF223233),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_light', name: 'Светлая', category: 'Нейтральные',
    colors: AppColors(
      background: Color(0xFFF7F7F5), surface: Color(0xFFFFFFFF),
      primary: Color(0xFF3A7BD5), secondary: Color(0xFF3A7BD5),
      accent: Color(0xFFC49010), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF1A1A18), onSurface: Color(0xFF1A1A18),
      onPrimary: Color(0xFFFFFFFF),
    ),
  ),
  AppThemeOption(
    id: 'rs_ivorynavy', name: 'Слоновая кость', category: 'Нейтральные',
    colors: AppColors(
      background: Color(0xFFFFFCF5), surface: Color(0xFFFFFFFB),
      primary: Color(0xFF355C7D), secondary: Color(0xFF355C7D),
      accent: Color(0xFF7B6741), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF252C3A), onSurface: Color(0xFF252C3A),
      onPrimary: Color(0xFFFFFFFF),
    ),
  ),
  AppThemeOption(
    id: 'rs_calm', name: 'Спокойная', category: 'Нейтральные',
    colors: AppColors(
      background: Color(0xFFECEFF1), surface: Color(0xFFF7F9FA),
      primary: Color(0xFF2F80ED), secondary: Color(0xFF2F80ED),
      accent: Color(0xFF5C6B75), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF1F2A33), onSurface: Color(0xFF1F2A33),
      onPrimary: Color(0xFFFFFFFF),
    ),
  ),
  AppThemeOption(
    id: 'rs_morning', name: 'Утренний свет', category: 'Нейтральные',
    colors: AppColors(
      background: Color(0xFFFFFBE6), surface: Color(0xFFFFFFFF),
      primary: Color(0xFFFFD84D), secondary: Color(0xFFFFD84D),
      accent: Color(0xFF9A8700), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF3A3520), onSurface: Color(0xFF3A3520),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_champagne', name: 'Шампань', category: 'Нейтральные',
    colors: AppColors(
      background: Color(0xFFFFFAF3), surface: Color(0xFFFFFDF9),
      primary: Color(0xFFFFC857), secondary: Color(0xFFFFC857),
      accent: Color(0xFF9B7622), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF322A1E), onSurface: Color(0xFF322A1E),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_peachpop', name: 'Peach Pop', category: 'Пастельные / Дофаминовые',
    colors: AppColors(
      background: Color(0xFFFFF5F0), surface: Color(0xFFFFFCFA),
      primary: Color(0xFFFF7F50), secondary: Color(0xFFFF7F50),
      accent: Color(0xFFC65B30), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF37251F), onSurface: Color(0xFF37251F),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_bubblegum', name: 'Баблгам', category: 'Пастельные / Дофаминовые',
    colors: AppColors(
      background: Color(0xFFFFF2FA), surface: Color(0xFFFFFAFD),
      primary: Color(0xFFFF4DB8), secondary: Color(0xFFFF4DB8),
      accent: Color(0xFFC53B88), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF3A2030), onSurface: Color(0xFF3A2030),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_barbiecore', name: 'Барбикор', category: 'Пастельные / Дофаминовые',
    colors: AppColors(
      background: Color(0xFFFFEFF8), surface: Color(0xFFFFFBFD),
      primary: Color(0xFFFF1493), secondary: Color(0xFFFF1493),
      accent: Color(0xFFC21874), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF391B2D), onSurface: Color(0xFF391B2D),
      onPrimary: Color(0xFFFFFFFF),
    ),
  ),
  AppThemeOption(
    id: 'rs_smokelavender', name: 'Дымчатая лаванда', category: 'Пастельные / Дофаминовые',
    colors: AppColors(
      background: Color(0xFFF7F6FA), surface: Color(0xFFFCFBFE),
      primary: Color(0xFFA084E8), secondary: Color(0xFFA084E8),
      accent: Color(0xFF7866A5), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF2A2635), onSurface: Color(0xFF2A2635),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_unicorn', name: 'Единорог', category: 'Пастельные / Дофаминовые',
    colors: AppColors(
      background: Color(0xFFFAF5FF), surface: Color(0xFFFFFCFF),
      primary: Color(0xFFC56CFF), secondary: Color(0xFFC56CFF),
      accent: Color(0xFF9A4DCC), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF31253A), onSurface: Color(0xFF31253A),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_jellybean', name: 'Желейка', category: 'Пастельные / Дофаминовые',
    colors: AppColors(
      background: Color(0xFFFFF8F2), surface: Color(0xFFFFFDFC),
      primary: Color(0xFFFF8A00), secondary: Color(0xFFFF8A00),
      accent: Color(0xFFC96B1F), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF38271F), onSurface: Color(0xFF38271F),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_strawberrymilk', name: 'Клубничное молоко', category: 'Пастельные / Дофаминовые',
    colors: AppColors(
      background: Color(0xFFFFF4F6), surface: Color(0xFFFFFBFC),
      primary: Color(0xFFFF5C8A), secondary: Color(0xFFFF5C8A),
      accent: Color(0xFFC44E74), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF38242B), onSurface: Color(0xFF38242B),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_coralmilk', name: 'Коралловое молоко', category: 'Пастельные / Дофаминовые',
    colors: AppColors(
      background: Color(0xFFFFF6F3), surface: Color(0xFFFFFCFA),
      primary: Color(0xFFFF8C69), secondary: Color(0xFFFF8C69),
      accent: Color(0xFFC56C4D), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF352722), onSurface: Color(0xFF352722),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_magnolia', name: 'Магнолия', category: 'Пастельные / Дофаминовые',
    colors: AppColors(
      background: Color(0xFFFFF8FA), surface: Color(0xFFFFFCFD),
      primary: Color(0xFFFF6FA5), secondary: Color(0xFFFF6FA5),
      accent: Color(0xFFB85C7A), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF33252B), onSurface: Color(0xFF33252B),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_girly', name: 'Милая', category: 'Пастельные / Дофаминовые',
    colors: AppColors(
      background: Color(0xFFFFF5FA), surface: Color(0xFFFFFCFE),
      primary: Color(0xFFE05090), secondary: Color(0xFFE05090),
      accent: Color(0xFFB8860B), success: Color(0xFF7AC74F),
      onBackground: Color(0xFFC0457A), onSurface: Color(0xFFC0457A),
      onPrimary: Color(0xFFFFFFFF),
    ),
  ),
  AppThemeOption(
    id: 'rs_milkblue', name: 'Молочный синий', category: 'Пастельные / Дофаминовые',
    colors: AppColors(
      background: Color(0xFFF6F9FF), surface: Color(0xFFFCFDFF),
      primary: Color(0xFF7BA7FF), secondary: Color(0xFF7BA7FF),
      accent: Color(0xFF5674B5), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF243040), onSurface: Color(0xFF243040),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_fairydust', name: 'Пыльца феи', category: 'Пастельные / Дофаминовые',
    colors: AppColors(
      background: Color(0xFFFFF7FD), surface: Color(0xFFFFFCFE),
      primary: Color(0xFFFF5FD2), secondary: Color(0xFFFF5FD2),
      accent: Color(0xFFC84CA4), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF38263A), onSurface: Color(0xFF38263A),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_sakura', name: 'Сакура', category: 'Пастельные / Дофаминовые',
    colors: AppColors(
      background: Color(0xFFFAF4F6), surface: Color(0xFFFFFBFC),
      primary: Color(0xFFFF5C8A), secondary: Color(0xFFFF5C8A),
      accent: Color(0xFFC45A78), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF33252B), onSurface: Color(0xFF33252B),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_lilac', name: 'Сирень', category: 'Пастельные / Дофаминовые',
    colors: AppColors(
      background: Color(0xFFF7F3FC), surface: Color(0xFFFCFAFF),
      primary: Color(0xFFA26BFF), secondary: Color(0xFFA26BFF),
      accent: Color(0xFF8A63B8), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF2B2435), onSurface: Color(0xFF2B2435),
      onPrimary: Color(0xFFFFFFFF),
    ),
  ),
  AppThemeOption(
    id: 'rs_cottoncandy', name: 'Сладкая вата', category: 'Пастельные / Дофаминовые',
    colors: AppColors(
      background: Color(0xFFFFF5FF), surface: Color(0xFFFFFCFF),
      primary: Color(0xFFFF66CC), secondary: Color(0xFFFF66CC),
      accent: Color(0xFFC54DA0), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF32243B), onSurface: Color(0xFF32243B),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_alpine', name: 'Альпийский луг', category: 'Природные зелёные',
    colors: AppColors(
      background: Color(0xFFF5FBF4), surface: Color(0xFFFBFFFA),
      primary: Color(0xFF7BC96F), secondary: Color(0xFF7BC96F),
      accent: Color(0xFF5D8A39), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF273321), onSurface: Color(0xFF273321),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_matcha', name: 'Матча', category: 'Природные зелёные',
    colors: AppColors(
      background: Color(0xFFF4F7F2), surface: Color(0xFFFFFFFF),
      primary: Color(0xFF6A9F7A), secondary: Color(0xFF6A9F7A),
      accent: Color(0xFFB88A2A), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF2F3A2F), onSurface: Color(0xFF2F3A2F),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_mint', name: 'Мята', category: 'Природные зелёные',
    colors: AppColors(
      background: Color(0xFFF2FCF7), surface: Color(0xFFF9FFFC),
      primary: Color(0xFF34D399), secondary: Color(0xFF34D399),
      accent: Color(0xFF3F9A72), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF23352D), onSurface: Color(0xFF23352D),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_pine', name: 'Сосна', category: 'Природные зелёные',
    colors: AppColors(
      background: Color(0xFFF4F8F5), surface: Color(0xFFFAFDFB),
      primary: Color(0xFF2F855A), secondary: Color(0xFF2F855A),
      accent: Color(0xFF48735A), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF223029), onSurface: Color(0xFF223029),
      onPrimary: Color(0xFFFFFFFF),
    ),
  ),
  AppThemeOption(
    id: 'rs_pistachio', name: 'Фисташка', category: 'Природные зелёные',
    colors: AppColors(
      background: Color(0xFFF7FBF2), surface: Color(0xFFFCFFF9),
      primary: Color(0xFF9BC53D), secondary: Color(0xFF9BC53D),
      accent: Color(0xFF698A3E), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF293121), onSurface: Color(0xFF293121),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_eucalyptus', name: 'Эвкалипт', category: 'Природные зелёные',
    colors: AppColors(
      background: Color(0xFFF3FAF7), surface: Color(0xFFF9FEFC),
      primary: Color(0xFF52B788), secondary: Color(0xFF52B788),
      accent: Color(0xFF4C8A72), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF22332D), onSurface: Color(0xFF22332D),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_watermelon', name: 'Арбузная', category: 'Фруктовые светлые',
    colors: AppColors(
      background: Color(0xFFFFF1F3), surface: Color(0xFFFFFFFF),
      primary: Color(0xFFFF4D6D), secondary: Color(0xFFFF4D6D),
      accent: Color(0xFFC9184A), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF2A1A1C), onSurface: Color(0xFF2A1A1C),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_guava', name: 'Гуава', category: 'Фруктовые светлые',
    colors: AppColors(
      background: Color(0xFFFFF4F6), surface: Color(0xFFFFFAFB),
      primary: Color(0xFFFF5F87), secondary: Color(0xFFFF5F87),
      accent: Color(0xFFC14F74), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF33252B), onSurface: Color(0xFF33252B),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_coconut', name: 'Кокос', category: 'Фруктовые светлые',
    colors: AppColors(
      background: Color(0xFFF8F6F1), surface: Color(0xFFFEFCF8),
      primary: Color(0xFF6FA8DC), secondary: Color(0xFF6FA8DC),
      accent: Color(0xFF9B6B3D), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF2F2A24), onSurface: Color(0xFF2F2A24),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_lychee', name: 'Личи', category: 'Фруктовые светлые',
    colors: AppColors(
      background: Color(0xFFFFF7F4), surface: Color(0xFFFFFCFA),
      primary: Color(0xFFFF7A59), secondary: Color(0xFFFF7A59),
      accent: Color(0xFFC46B4D), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF372923), onSurface: Color(0xFF372923),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_raspberry', name: 'Малина', category: 'Фруктовые светлые',
    colors: AppColors(
      background: Color(0xFFFFF2F6), surface: Color(0xFFFFFAFC),
      primary: Color(0xFFFF4F8B), secondary: Color(0xFFFF4F8B),
      accent: Color(0xFFB8426E), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF321F29), onSurface: Color(0xFF321F29),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_mango', name: 'Манго', category: 'Фруктовые светлые',
    colors: AppColors(
      background: Color(0xFFFFF4E8), surface: Color(0xFFFFFFFF),
      primary: Color(0xFFFF9F1C), secondary: Color(0xFFFF9F1C),
      accent: Color(0xFFC96A00), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF3B2618), onSurface: Color(0xFF3B2618),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_peach', name: 'Персик', category: 'Фруктовые светлые',
    colors: AppColors(
      background: Color(0xFFFFF5EE), surface: Color(0xFFFFFBF7),
      primary: Color(0xFFFF9B54), secondary: Color(0xFFFF9B54),
      accent: Color(0xFFC96A2B), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF34271F), onSurface: Color(0xFF34271F),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_pitaya', name: 'Питайя', category: 'Фруктовые светлые',
    colors: AppColors(
      background: Color(0xFFFFF5FA), surface: Color(0xFFFFFBFD),
      primary: Color(0xFFFF4FC3), secondary: Color(0xFFFF4FC3),
      accent: Color(0xFFC1498E), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF352632), onSurface: Color(0xFF352632),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_pomelo', name: 'Помело', category: 'Фруктовые светлые',
    colors: AppColors(
      background: Color(0xFFFFFAEF), surface: Color(0xFFFFFDF8),
      primary: Color(0xFFFFC93C), secondary: Color(0xFFFFC93C),
      accent: Color(0xFF9E841F), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF322D1F), onSurface: Color(0xFF322D1F),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_blueberry', name: 'Черника', category: 'Фруктовые светлые',
    colors: AppColors(
      background: Color(0xFFF5F5FF), surface: Color(0xFFFCFCFF),
      primary: Color(0xFF6C7BFF), secondary: Color(0xFF6C7BFF),
      accent: Color(0xFF5C63B8), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF232B3A), onSurface: Color(0xFF232B3A),
      onPrimary: Color(0xFFFFFFFF),
    ),
  ),
  AppThemeOption(
    id: 'rs_paper_day', name: 'Бумажный день', category: 'Эстетики',
    colors: AppColors(
      background: Color(0xFFFFFFFF), surface: Color(0xFFFFFFFF),
      primary: Color(0xFFFF7A59), secondary: Color(0xFFFF7A59),
      accent: Color(0xFFB08968), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF1A1A1A), onSurface: Color(0xFF1A1A1A),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_coffee_mood', name: 'Кофейное утро', category: 'Эстетики',
    colors: AppColors(
      background: Color(0xFFF4ECE2), surface: Color(0xFFFFFFFF),
      primary: Color(0xFFC27A3A), secondary: Color(0xFFC27A3A),
      accent: Color(0xFFD9A066), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF2B1F1A), onSurface: Color(0xFF2B1F1A),
      onPrimary: Color(0xFFFFFFFF),
    ),
  ),
  AppThemeOption(
    id: 'rs_subway_lemonade', name: 'Подводный лимонад', category: 'Эстетики',
    colors: AppColors(
      background: Color(0xFFF6FAF2), surface: Color(0xFFFFFFFF),
      primary: Color(0xFF00B4D8), secondary: Color(0xFF00B4D8),
      accent: Color(0xFFFFD400), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF1A1A1A), onSurface: Color(0xFF1A1A1A),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_scandi_minimal', name: 'Скандинавский минимализм', category: 'Эстетики',
    colors: AppColors(
      background: Color(0xFFF7F7F5), surface: Color(0xFFFFFFFF),
      primary: Color(0xFF5C7AEA), secondary: Color(0xFF5C7AEA),
      accent: Color(0xFFB08968), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF1F1F1F), onSurface: Color(0xFF1F1F1F),
      onPrimary: Color(0xFFFFFFFF),
    ),
  ),
  AppThemeOption(
    id: 'rs_calm_space', name: 'Спокойный космос', category: 'Эстетики',
    colors: AppColors(
      background: Color(0xFFF6F8FF), surface: Color(0xFFFFFFFF),
      primary: Color(0xFF7E8CFF), secondary: Color(0xFF7E8CFF),
      accent: Color(0xFF6FA8FF), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF1B1B2A), onSurface: Color(0xFF1B1B2A),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
  AppThemeOption(
    id: 'rs_focus_mode', name: 'Фокус', category: 'Эстетики',
    colors: AppColors(
      background: Color(0xFFF2F4F8), surface: Color(0xFFFFFFFF),
      primary: Color(0xFF1FA2FF), secondary: Color(0xFF1FA2FF),
      accent: Color(0xFF5B8CFF), success: Color(0xFF7AC74F),
      onBackground: Color(0xFF1A1A1A), onSurface: Color(0xFF1A1A1A),
      onPrimary: Color(0xFF4E342E),
    ),
  ),
];

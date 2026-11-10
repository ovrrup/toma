import 'package:flutter/material.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/animated_pressable.dart';
import '../../../../shared/widgets/frosted_glass_card.dart';

class ThemeOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const ThemeOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

/// Serene Ambiance & Theme selector without commercial store clutter or coin barriers.
class ShopScreen extends StatefulWidget {
  final Function(String themeId)? onThemeEquipped;

  const ShopScreen({
    super.key,
    this.onThemeEquipped,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const List<ThemeOption> _themes = [
    ThemeOption(
      id: 'default',
      name: 'Calm Crimson',
      description: 'Serene warm red, obsidian burgundy, and soft rose ambient glow.',
      icon: Icons.palette_outlined,
    ),
    ThemeOption(
      id: 'monochrome',
      name: 'Monochrome Minimalist',
      description: 'Pure obsidian and silver high-contrast fluid ink aesthetic.',
      icon: Icons.contrast,
    ),
  ];

  void _selectTheme(String themeId) async {
    await DatabaseService.instance.setActiveTheme(themeId);
    widget.onThemeEquipped?.call(themeId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = DatabaseService.instance.getActiveTheme();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Ambiance',
            style: AppTypography.headlineMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select your visual environment for tranquil, focused contemplation.',
            style: TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          ..._themes.map((theme) {
            final isActive = activeTheme == theme.id ||
                (theme.id == 'default' && activeTheme != 'monochrome');

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AnimatedPressable(
                onTap: () => _selectTheme(theme.id),
                child: FrostedGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  customFill: isActive
                      ? AppColors.darkPrimary.withValues(alpha: 0.16)
                      : AppColors.darkSurfaceGlass,
                  customBorder: isActive
                      ? AppColors.darkPrimary.withValues(alpha: 0.6)
                      : AppColors.darkBorderGlass,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppColors.darkPrimary.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.05),
                        ),
                        child: Icon(
                          theme.icon,
                          size: 22,
                          color: isActive ? AppColors.darkPrimary : AppColors.darkSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  theme.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (isActive) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkSuccess.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.darkSuccess.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(
                                        color: AppColors.darkSuccess,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              theme.description,
                              style: const TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

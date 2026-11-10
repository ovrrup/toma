import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/database/database_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/community/presentation/screens/community_screen.dart';
import 'features/connectivity/presentation/cubit/connectivity_cubit.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/shop/presentation/screens/shop_screen.dart';
import 'features/stats/presentation/screens/stats_screen.dart';
import 'features/timer/presentation/bloc/timer_bloc.dart';
import 'features/timer/presentation/screens/timer_screen.dart';
import 'shared/widgets/frosted_glass_card.dart';
import 'shared/widgets/scaffold_with_lava.dart';

class TomaApp extends StatefulWidget {
  const TomaApp({super.key});

  @override
  State<TomaApp> createState() => _TomaAppState();
}

class _TomaAppState extends State<TomaApp> {
  TomaThemeVariant _currentTheme = TomaThemeVariant.dark;
  int _currentIndex = 0;
  bool _showingProfile = false;

  void _onThemeChanged(String themeId) {
    setState(() {
      if (themeId == 'monochrome') {
        _currentTheme = TomaThemeVariant.monochrome;
      } else {
        _currentTheme = TomaThemeVariant.dark;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData;
    switch (_currentTheme) {
      case TomaThemeVariant.monochrome:
        themeData = AppTheme.monochromeTheme;
        break;
      case TomaThemeVariant.light:
        themeData = AppTheme.lightTheme;
        break;
      case TomaThemeVariant.dark:
      default:
        themeData = AppTheme.darkTheme;
        break;
    }

    final initialStreak = DatabaseService.instance.getStreakDays();

    return MultiBlocProvider(
      providers: [
        BlocProvider<TimerBloc>(
          create: (_) => TimerBloc(streakDays: initialStreak),
        ),
        BlocProvider<ConnectivityCubit>(
          create: (_) => ConnectivityCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'Toma',
        debugShowCheckedModeBanner: false,
        theme: themeData,
        home: ScaffoldWithLava(
          themeVariant: _currentTheme,
          body: _buildCurrentBody(),
          bottomNavigationBar: _showingProfile ? null : _buildBottomNav(),
        ),
      ),
    );
  }

  Widget _buildCurrentBody() {
    if (_showingProfile) {
      return ProfileScreen(
        onBack: () => setState(() => _showingProfile = false),
      );
    }

    switch (_currentIndex) {
      case 0:
        return TimerScreen(
          onOpenProfile: () => setState(() => _showingProfile = true),
          onOpenSettings: () {
            // Toggle theme preview
            setState(() {
              _currentTheme = _currentTheme == TomaThemeVariant.dark
                  ? TomaThemeVariant.monochrome
                  : TomaThemeVariant.dark;
            });
          },
        );
      case 1:
        return const StatsScreen();
      case 2:
        return ShopScreen(
          onThemeEquipped: _onThemeChanged,
        );
      case 3:
        return const CommunityScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: FrostedGlassCard(
        borderRadius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.timer_outlined, Icons.timer, 'Timer'),
            _buildNavItem(1, Icons.bar_chart_outlined, Icons.bar_chart, 'Stats'),
            _buildNavItem(2, Icons.palette_outlined, Icons.palette, 'Ambiance'),
            _buildNavItem(3, Icons.forum_outlined, Icons.forum, 'Community'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    final primaryColor = _currentTheme == TomaThemeVariant.monochrome
        ? AppColors.monoPrimary
        : AppColors.darkPrimary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showingProfile = false;
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? primaryColor : AppColors.darkTextSecondary,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

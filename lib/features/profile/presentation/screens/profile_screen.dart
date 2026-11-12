import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/services/nostr_service.dart';
import '../../../../shared/widgets/animated_pressable.dart';
import '../../../../shared/widgets/frosted_glass_card.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onBack;

  const ProfileScreen({super.key, required this.onBack});

  String _formatTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  String _truncatePubkey(String? key) {
    if (key == null || key.isEmpty) return 'Anonymous';
    if (key.length <= 16) return key;
    return '${key.substring(0, 10)}...${key.substring(key.length - 6)}';
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final streak = db.getStreakDays();
    final focusMinutes = db.getTotalFocusMinutes();
    final totalSessions = db.getTodaySessionsCount(); // or total completed

    final npub = NostrService.instance.npub ?? '';
    final recoveryPhrase = NostrService.instance.recoveryPhrase ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView(
        children: [
          const SizedBox(height: AppSpacing.sm),

          // Back Navigation Bar
          Row(
            children: [
              AnimatedPressable(
                onTap: onBack,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Profile',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // User Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.darkPrimary.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    color: AppColors.darkPrimary.withValues(alpha: 0.12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_outline,
                      size: 34,
                      color: AppColors.darkPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _truncatePubkey(npub),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Minimalist Focus Stats Card
          FrostedGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatPill(_formatTime(focusMinutes), 'Focus Time', Icons.schedule, Colors.white),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                _buildStatPill('$totalSessions', 'Today', Icons.check_circle_outline, AppColors.darkSecondary),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                _buildStatPill('${streak}d', 'Streak', Icons.local_fire_department, AppColors.darkAccent),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Cryptographic Recovery Card
          FrostedGlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.security, size: 16, color: AppColors.darkSecondary),
                    SizedBox(width: 8),
                    Text(
                      'Account & Recovery',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your decentralized Nostr keys live on this device. Save your 12-word pass to restore access anytime.',
                  style: TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AnimatedPressable(
                        onTap: () {
                          if (npub.isNotEmpty) {
                            Clipboard.setData(ClipboardData(text: npub));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Public key (npub) copied to clipboard'),
                                backgroundColor: AppColors.darkPrimary,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.darkBorderGlass),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.key, size: 14, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Copy npub',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AnimatedPressable(
                        onTap: () {
                          if (recoveryPhrase.isNotEmpty) {
                            Clipboard.setData(ClipboardData(text: recoveryPhrase));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('12-Word Recovery Pass copied to clipboard'),
                                backgroundColor: AppColors.darkPrimary,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy, size: 14, color: AppColors.darkTextSecondary),
                                SizedBox(width: 6),
                                Text(
                                  'Copy 12 Words',
                                  style: TextStyle(
                                    color: AppColors.darkTextSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatPill(String val, String label, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              val,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

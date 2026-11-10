import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/animated_pressable.dart';
import '../../../../shared/widgets/coin_pill.dart';
import '../../../../shared/widgets/frosted_glass_card.dart';

class ShopScreen extends StatefulWidget {
  final int initialCoins;
  final Function(String themeId)? onThemeEquipped;

  const ShopScreen({
    super.key,
    this.initialCoins = 240,
    this.onThemeEquipped,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late int _coins;
  final Set<String> _unlockedItems = {'default'};
  String _activeTheme = 'default';

  @override
  void initState() {
    super.initState();
    _coins = widget.initialCoins;
  }

  void _purchaseItem(String id, int price) {
    if (_unlockedItems.contains(id)) {
      // Already owned: Equip it
      setState(() => _activeTheme = id);
      widget.onThemeEquipped?.call(id);
      _showSnackbar('Equipped theme!');
      return;
    }

    if (_coins >= price) {
      setState(() {
        _coins -= price;
        _unlockedItems.add(id);
        _activeTheme = id;
      });
      widget.onThemeEquipped?.call(id);
      _showSnackbar('Unlocked and equipped!');
    } else {
      _showSnackbar('Need more Coins! Complete more focus sessions 🍅');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.darkPrimary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMonoOwned = _unlockedItems.contains('monochrome');
    final isMonoActive = _activeTheme == 'monochrome';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView(
        children: [
          const SizedBox(height: AppSpacing.sm),

          // Header with Live Coins Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aesthetics Shop',
                style: AppTypography.headlineMedium.copyWith(color: Colors.white),
              ),
              CoinPill(coins: _coins),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // FEATURED ITEM: Monochrome Theme
          FrostedGlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            customFill: const Color(0x22FFFFFF),
            customBorder: Colors.white.withValues(alpha: 0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '⭐ FEATURED AESTHETIC',
                        style: TextStyle(
                          color: AppColors.darkSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    if (isMonoActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.darkSuccess.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.darkSuccess),
                        ),
                        child: const Text(
                          'EQUIPPED',
                          style: TextStyle(
                            color: AppColors.darkSuccess,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  '⬛ Monochrome Minimalist Theme',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'High-contrast pure obsidian & silver aesthetic with custom liquid ink fluid shader, frosted glass, and pure white accents.',
                  style: TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Buy / Equip Button
                AnimatedPressable(
                  onTap: () => _purchaseItem('monochrome', 200),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isMonoActive
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isMonoActive
                            ? 'Currently Equipped'
                            : isMonoOwned
                                ? 'Equip Theme'
                                : 'Unlock Theme · 200 🪙',
                        style: TextStyle(
                          color: isMonoActive ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Additional Shaders Category
          const Text(
            'Liquid Shaders',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildItemRow(
            icon: '🌊',
            name: 'Ocean Blue Fluid',
            subtitle: 'Deep oceanic currents and cyan blobs',
            price: 150,
            id: 'ocean',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildItemRow(
            icon: '🌅',
            name: 'Sunset Blaze Fluid',
            subtitle: 'Twilight amber and warm coral metaballs',
            price: 150,
            id: 'sunset',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildItemRow(
            icon: '🌌',
            name: 'Aurora Borealis',
            subtitle: 'Mystical violet and neon emerald currents',
            price: 250,
            id: 'aurora',
          ),

          const SizedBox(height: AppSpacing.lg),

          // Timer Rings Category
          const Text(
            'Timer Rings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildItemRow(
            icon: '⚡',
            name: 'Neon Pulse Ring',
            subtitle: 'Electrified glowing progress stroke',
            price: 100,
            id: 'ring_neon',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildItemRow(
            icon: '🌿',
            name: 'Organic Vine Ring',
            subtitle: 'Living botanical growth indicator',
            price: 120,
            id: 'ring_vine',
          ),

          const SizedBox(height: 100), // Bottom nav padding
        ],
      ),
    );
  }

  Widget _buildItemRow({
    required String icon,
    required String name,
    required String subtitle,
    required int price,
    required String id,
  }) {
    final isOwned = _unlockedItems.contains(id);

    return FrostedGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          AnimatedPressable(
            onTap: () => _purchaseItem(id, price),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isOwned
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.darkSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOwned
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.darkSecondary,
                ),
              ),
              child: Text(
                isOwned ? 'Owned' : '$price 🪙',
                style: TextStyle(
                  color: isOwned ? Colors.white70 : AppColors.darkSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

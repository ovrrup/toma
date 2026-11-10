import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'lava_lamp_background.dart';

/// Base scaffold with background lava animation and layered foreground.
class ScaffoldWithLava extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final TomaThemeVariant themeVariant;
  final bool reducedMotion;

  const ScaffoldWithLava({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.themeVariant = TomaThemeVariant.dark,
    this.reducedMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Shader Layer (Isolated via RepaintBoundary)
          LavaLampBackground(
            themeVariant: themeVariant,
            reducedMotion: reducedMotion,
          ),

          // Foreground Interactive Content
          SafeArea(
            child: body,
          ),
        ],
      ),
    );
  }
}

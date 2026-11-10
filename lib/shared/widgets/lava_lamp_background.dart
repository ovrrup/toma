import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Hardware-accelerated fluid lava lamp / liquid ink background.
///
/// Executes `shaders/lava_lamp.frag` directly on the GPU. Automatically halts
/// animation tickers when the app is paused or inactive to conserve battery.
class LavaLampBackground extends StatefulWidget {
  final TomaThemeVariant themeVariant;
  final bool reducedMotion;

  const LavaLampBackground({
    super.key,
    this.themeVariant = TomaThemeVariant.dark,
    this.reducedMotion = false,
  });

  @override
  State<LavaLampBackground> createState() => _LavaLampBackgroundState();
}

class _LavaLampBackgroundState extends State<LavaLampBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  ui.FragmentProgram? _program;
  late final AnimationController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/lava_lamp.frag');
      if (mounted) {
        setState(() => _program = program);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _controller.stop(); // Stop GPU ticker immediately
    } else if (state == AppLifecycleState.resumed && !widget.reducedMotion) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LavaLampBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.reducedMotion && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  List<double> get _colorA {
    switch (widget.themeVariant) {
      case TomaThemeVariant.monochrome:
        return AppColors.shaderMonoColorA;
      case TomaThemeVariant.light:
      case TomaThemeVariant.dark:
      default:
        return AppColors.shaderFireColorA;
    }
  }

  List<double> get _colorB {
    switch (widget.themeVariant) {
      case TomaThemeVariant.monochrome:
        return AppColors.shaderMonoColorB;
      case TomaThemeVariant.light:
      case TomaThemeVariant.dark:
      default:
        return AppColors.shaderFireColorB;
    }
  }

  List<double> get _bgColor {
    switch (widget.themeVariant) {
      case TomaThemeVariant.monochrome:
        return AppColors.shaderMonoBg;
      case TomaThemeVariant.light:
        return [0.98, 0.95, 0.92]; // Light cream
      case TomaThemeVariant.dark:
      default:
        return AppColors.shaderFireBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If reduced motion or shader error, fallback to clean static gradient
    if (widget.reducedMotion || _hasError || _program == null) {
      return _buildFallbackGradient();
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _LavaPainter(
            shader: _program!.fragmentShader(),
            time: _controller.value * 20.0,
            colorA: _colorA,
            colorB: _colorB,
            bgColor: _bgColor,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  Widget _buildFallbackGradient() {
    final colors = widget.themeVariant == TomaThemeVariant.monochrome
        ? [const Color(0xFF080808), const Color(0xFF1E1E1E)]
        : widget.themeVariant == TomaThemeVariant.light
            ? [const Color(0xFFFFF8F0), const Color(0xFFFFE0D0)]
            : [const Color(0xFF0A0A14), const Color(0xFF1E0E28)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }
}

class _LavaPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;
  final List<double> colorA;
  final List<double> colorB;
  final List<double> bgColor;

  _LavaPainter({
    required this.shader,
    required this.time,
    required this.colorA,
    required this.colorB,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Uniforms:
    // 0, 1: uResolution (vec2)
    // 2: uTime (float)
    // 3, 4, 5: uColorA (vec3)
    // 6, 7, 8: uColorB (vec3)
    // 9, 10, 11: uBgColor (vec3)
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);

    shader.setFloat(3, colorA[0]);
    shader.setFloat(4, colorA[1]);
    shader.setFloat(5, colorA[2]);

    shader.setFloat(6, colorB[0]);
    shader.setFloat(7, colorB[1]);
    shader.setFloat(8, colorB[2]);

    shader.setFloat(9, bgColor[0]);
    shader.setFloat(10, bgColor[1]);
    shader.setFloat(11, bgColor[2]);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _LavaPainter old) => old.time != time;
}

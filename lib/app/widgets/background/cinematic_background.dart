import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';

/// Cinematic background: animated gradient mesh + vignette.
/// Colors shift based on SceneDirector's blendedConfig.
class CinematicBackground extends StatefulWidget {
  const CinematicBackground({super.key});

  @override
  State<CinematicBackground> createState() => _CinematicBackgroundState();
}

class _CinematicBackgroundState extends State<CinematicBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animController;
  Offset _mouseOffset = Offset.zero;

  late SceneConfig _config;
  late Worker _configWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    final sceneDirector = Get.find<SceneDirector>();
    _config = sceneDirector.blendedConfig.value;
    _configWorker = ever(sceneDirector.blendedConfig, (cfg) {
      _config = cfg;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _configWorker.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) {
      _animController.stop();
    } else if (state == AppLifecycleState.resumed) {
      _animController.repeat();
    }
  }

  void _onMouseMove(PointerEvent event) {
    final size = context.size;
    if (size == null) return;
    // Normalized -1 to 1
    _mouseOffset = Offset(
      (event.localPosition.dx / size.width - 0.5) * 2,
      (event.localPosition.dy / size.height - 0.5) * 2,
    );
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Listener(
      onPointerHover: _onMouseMove,
      onPointerMove: _onMouseMove,
      behavior: HitTestBehavior.translucent,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return CustomPaint(
              painter: _MeshGradientPainter(
                animValue: _animController.value,
                gradient1: _config.gradient1,
                gradient2: _config.gradient2,
                gradient3: _config.gradient3,
                mouseOffset: _mouseOffset,
                vignetteIntensity: _config.vignetteIntensity,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    ),
  );
}

class _MeshGradientPainter extends CustomPainter {
  _MeshGradientPainter({
    required this.animValue,
    required this.gradient1,
    required this.gradient2,
    required this.gradient3,
    required this.mouseOffset,
    required this.vignetteIntensity,
  });

  final double animValue;
  final Color gradient1;
  final Color gradient2;
  final Color gradient3;
  final Offset mouseOffset;
  final double vignetteIntensity;

  static final _basePaint = Paint();
  static final _blobPaint = Paint()..blendMode = BlendMode.screen;
  static final _vignettePaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Solid dark base
    _basePaint.color = AppColors.background;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _basePaint);

    // Toggle blendMode depending on light or dark theme
    _blobPaint.blendMode = Get.isDarkMode ? BlendMode.screen : BlendMode.srcOver;

    final t = animValue * math.pi * 2;

    // 4 animated blob positions (organic Lissajous-like movement)
    final dx1 = size.width * 0.25 + size.width * 0.15 * math.sin(t + 0.5) + mouseOffset.dx * 20;
    final dy1 = size.height * 0.25 + size.height * 0.1 * math.cos(t * 1.5) + mouseOffset.dy * 20;

    final dx2 = size.width * 0.75 + size.width * 0.1 * math.cos(t * 0.8) - mouseOffset.dx * 15;
    final dy2 = size.height * 0.3 + size.height * 0.12 * math.sin(t * 1.2) - mouseOffset.dy * 15;

    final dx3 = size.width * 0.35 + size.width * 0.12 * math.cos(t * 1.1 + math.pi / 2) + mouseOffset.dx * 10;
    final dy3 = size.height * 0.75 + size.height * 0.08 * math.sin(t * 0.9) + mouseOffset.dy * 10;

    final dx4 = size.width * 0.7 + size.width * 0.1 * math.sin(t * 1.3 - 0.2) - mouseOffset.dx * 12;
    final dy4 = size.height * 0.7 + size.height * 0.1 * math.cos(t * 0.7) - mouseOffset.dy * 12;

    final blobs = [
      _BlobConfig(
        center: Offset(dx1, dy1),
        radius: size.width * 0.5,
        color: gradient1.withValues(alpha: 0.35),
      ),
      _BlobConfig(
        center: Offset(dx2, dy2),
        radius: size.width * 0.45,
        color: gradient2.withValues(alpha: 0.3),
      ),
      _BlobConfig(
        center: Offset(dx3, dy3),
        radius: size.width * 0.42,
        color: gradient3.withValues(alpha: 0.25),
      ),
      _BlobConfig(
        center: Offset(dx4, dy4),
        radius: size.width * 0.4,
        color: gradient1.withValues(alpha: 0.2),
      ),
    ];

    // Draw blobs as radial gradients
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    for (final blob in blobs) {
      _blobPaint.shader = ui.Gradient.radial(
        blob.center,
        blob.radius,
        [blob.color, blob.color.withValues(alpha: 0)],
        [0.0, 1.0],
      );
      canvas.drawRect(fullRect, _blobPaint);
    }

    // Vignette overlay
    _vignettePaint.shader = ui.Gradient.radial(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.7,
      [
        Colors.transparent,
        Colors.black.withValues(alpha: vignetteIntensity * 0.5),
        Colors.black.withValues(alpha: vignetteIntensity),
      ],
      [0.3, 0.7, 1.0],
    );
    canvas.drawRect(fullRect, _vignettePaint);
  }

  @override
  bool shouldRepaint(_MeshGradientPainter old) =>
      animValue != old.animValue ||
      gradient1 != old.gradient1 ||
      gradient2 != old.gradient2 ||
      gradient3 != old.gradient3 ||
      vignetteIntensity != old.vignetteIntensity;
}

class _BlobConfig {
  const _BlobConfig({
    required this.center,
    required this.radius,
    required this.color,
  });
  final Offset center;
  final double radius;
  final Color color;
}

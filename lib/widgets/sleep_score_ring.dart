// Sleep Score Ring Widget — Animated circular score display
// SDG 3 Impact: Visual sleep quality feedback motivates users to improve
// sleep patterns for better physical and mental health (SDG 3.4).
import 'package:flutter/material.dart';
import 'dart:math';
import '../core/theme.dart';

class SleepScoreRing extends StatefulWidget {
  final int score;
  final double size;
  final bool animate;

  const SleepScoreRing({
    super.key,
    required this.score,
    this.size = 180,
    this.animate = true,
  });

  @override
  State<SleepScoreRing> createState() => _SleepScoreRingState();
}

class _SleepScoreRingState extends State<SleepScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SleepScoreRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score && widget.animate) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = ZzenTheme.scoreColor(widget.score);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedScore = (widget.score * _animation.value).round();
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: 1.0,
                  color: ZzenTheme.surface,
                  strokeWidth: 12,
                ),
              ),
              // Score ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: (widget.score / 100) * _animation.value,
                  color: scoreColor,
                  strokeWidth: 12,
                  hasShadow: true,
                ),
              ),
              // Score text in center
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$animatedScore',
                    style: TextStyle(
                      fontSize: widget.size * 0.28,
                      fontWeight: FontWeight.w900,
                      color: scoreColor,
                      fontFamily: 'Inter',
                      height: 1,
                    ),
                  ),
                  Text(
                    'sleep score',
                    style: TextStyle(
                      fontSize: widget.size * 0.09,
                      fontWeight: FontWeight.w400,
                      color: ZzenTheme.textMuted,
                      fontFamily: 'Inter',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool hasShadow;

  _RingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 12,
    this.hasShadow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (hasShadow) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final shadowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..strokeWidth = strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        shadowPaint,
      );

      paint.maskFilter = null;
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

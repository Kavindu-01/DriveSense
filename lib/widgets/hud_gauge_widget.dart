import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Automotive style circular speedometer gauge with glowing sweep arc.
class HudSpeedometerGauge extends StatelessWidget {
  final double currentSpeed;
  final double maxSpeed;
  final double gForce;

  const HudSpeedometerGauge({
    super.key,
    required this.currentSpeed,
    this.maxSpeed = 160.0,
    required this.gForce,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: CustomPaint(
          painter: _SpeedGaugePainter(
            speedPercent: (currentSpeed / maxSpeed).clamp(0.0, 1.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "SPEED",
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    currentSpeed.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "KM/H",
                    style: TextStyle(
                      color: AppTheme.cyanAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (gForce > 0.5 ? AppTheme.amberWarning : AppTheme.cyanAccent).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (gForce > 0.5 ? AppTheme.amberWarning : AppTheme.cyanAccent).withOpacity(0.4),
                  ),
                ),
                child: Text(
                  "${gForce.toStringAsFixed(2)} G-FORCE",
                  style: TextStyle(
                    color: gForce > 0.5 ? AppTheme.amberWarning : AppTheme.cyanAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedGaugePainter extends CustomPainter {
  final double speedPercent;

  _SpeedGaugePainter({required this.speedPercent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;

    const startAngle = 135 * (pi / 180);
    const sweepAngle = 270 * (pi / 180);

    // Background track arc
    final trackPaint = Paint()
      ..color = AppTheme.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active speed sweep arc with gradient
    final activePaint = Paint()
      ..shader = const SweepGradient(
        colors: [AppTheme.cyanAccent, AppTheme.amberWarning, AppTheme.redDanger],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * speedPercent,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeedGaugePainter oldDelegate) {
    return oldDelegate.speedPercent != speedPercent;
  }
}

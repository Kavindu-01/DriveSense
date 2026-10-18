import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/mock_data_service.dart';

/// Critical Crash SOS Dialog that ONLY triggers upon high-G impact / crash detection.
/// Provides an automated 10-second cancel window before dispatching emergency SMS/calls.
class CrashSosOverlay extends StatefulWidget {
  final double detectedGForce;
  final VoidCallback onDismiss;

  const CrashSosOverlay({
    super.key,
    required this.detectedGForce,
    required this.onDismiss,
  });

  /// Helper static method to display this dialog from anywhere in the app.
  static Future<void> show(BuildContext context, {double gForce = 3.4}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CrashSosOverlay(
        detectedGForce: gForce,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<CrashSosOverlay> createState() => _CrashSosOverlayState();
}

class _CrashSosOverlayState extends State<CrashSosOverlay>
    with SingleTickerProviderStateMixin {
  int _countdown = 10;
  Timer? _timer;
  late AnimationController _pulseController;
  bool _isDispatched = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      lowerBound: 0.85,
      upperBound: 1.15,
    )..repeat(reverse: true);

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        setState(() {
          _isDispatched = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driver = MockDataService.currentDriver;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1F0B0B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.redDanger, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.redDanger.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsating Danger Beacon
            ScaleTransition(
              scale: _pulseController,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: AppTheme.redDanger,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.car_crash_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              "CRITICAL IMPACT DETECTED",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.redDanger,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              "Inertial Shock: ${widget.detectedGForce.toStringAsFixed(1)}G (Threshold > 2.5G)",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),

            // Status message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Text(
                    _isDispatched
                        ? "🚨 EMERGENCY SERVICES & SMS DISPATCHED!"
                        : "Dispatching Emergency SOS in $_countdown Seconds",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isDispatched ? AppTheme.amberWarning : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "GPS: 6.8402° N, 80.0034° E • NSBM Expressway Approach",
                    style: TextStyle(
                      color: AppTheme.cyanAccent,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Emergency Contacts Preview
            Row(
              children: [
                const Icon(Icons.contact_phone_outlined,
                    size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Contact: ${driver.emergencyContactName} (${driver.emergencyContactPhone})",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onDismiss();
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text("I AM OK - CANCEL SOS ($_countdown s)"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _isDispatched = true);
                    // TODO: Team Member: Trigger telephony / twilio / SMS intent here
                  },
                  icon: const Icon(Icons.emergency, color: AppTheme.redDanger),
                  label: const Text(
                    "DISPATCH NOW (POLICE 119 / AMBULANCE 1990)",
                    style: TextStyle(
                      color: AppTheme.redDanger,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.redDanger),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

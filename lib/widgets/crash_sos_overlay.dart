import 'dart:async';

import 'package:flutter/material.dart';

import '../services/mock_data_service.dart';
import '../theme/app_theme.dart';

/// Crash SOS demonstration dialog.
///
/// This demo does not send real SMS messages or phone calls.
class CrashSosOverlay extends StatefulWidget {
  final double detectedGForce;
  final VoidCallback onDismiss;

  const CrashSosOverlay({
    super.key,
    required this.detectedGForce,
    required this.onDismiss,
  });

  /// Opens the dialog from anywhere in the app.
  static Future<void> show(
    BuildContext context, {
    double gForce = 3.4,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CrashSosOverlay(
        detectedGForce: gForce,
        onDismiss: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  @override
  State<CrashSosOverlay> createState() => _CrashSosOverlayState();
}

class _CrashSosOverlayState extends State<CrashSosOverlay>
    with SingleTickerProviderStateMixin {
  static const int _cancelWindowSeconds = 10;

  int _countdown = _cancelWindowSeconds;
  Timer? _timer;
  late final AnimationController _pulseController;

  bool _isCancelled = false;
  bool _isSimulationComplete = false;

  bool get _isWaiting => !_isCancelled && !_isSimulationComplete;

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
      if (!mounted || !_isWaiting) {
        timer.cancel();
        return;
      }

      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _countdown = 0;
          _isSimulationComplete = true;
        });
      }
    });
  }

  void _cancelSos() {
    if (!_isWaiting) return;

    _timer?.cancel();
    setState(() {
      _isCancelled = true;
    });
  }

  void _simulateDispatchNow() {
    if (!_isWaiting) return;

    _timer?.cancel();
    setState(() {
      _countdown = 0;
      _isSimulationComplete = true;
    });

    // Demo only: this does not send a real SMS or place a call.
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

    final String statusText;
    final Color statusColor;

    if (_isCancelled) {
      statusText = 'SOS CANCELLED — No alert was sent.';
      statusColor = AppTheme.cyanAccent;
    } else if (_isSimulationComplete) {
      statusText = 'DEMO: SOS dispatch simulated.';
      statusColor = AppTheme.amberWarning;
    } else {
      statusText = 'Emergency SOS will be sent in $_countdown seconds.';
      statusColor = Colors.white;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1F0B0B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.redDanger,
            width: 2,
          ),
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
              'CRITICAL IMPACT DETECTED',
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
              'Inertial Shock: '
              '${widget.detectedGForce.toStringAsFixed(1)}G '
              '(Threshold > 2.5G)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),

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
                    statusText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isWaiting
                        ? 'Press “I AM OK” to cancel the countdown.'
                        : 'DEMO ONLY — No SMS or phone call was sent.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.amberWarning,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'GPS: 6.8402° N, 80.0034° E • NSBM Expressway Approach',
                    textAlign: TextAlign.center,
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

            Row(
              children: [
                const Icon(
                  Icons.contact_phone_outlined,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contact: ${driver.emergencyContactName} '
                    '(${driver.emergencyContactPhone})',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isWaiting) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _cancelSos,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('I AM OK - CANCEL SOS ($_countdown s)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _simulateDispatchNow,
                  icon: const Icon(
                    Icons.emergency,
                    color: AppTheme.redDanger,
                  ),
                  label: const Text(
                    'DISPATCH NOW (POLICE 119 / AMBULANCE 1990)',
                    textAlign: TextAlign.center,
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
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onDismiss,
                  child: const Text('CLOSE'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
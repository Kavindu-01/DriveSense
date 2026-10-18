import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/mock_data_service.dart';
import '../../widgets/background_service_card.dart';

class DrowsinessMonitorScreen extends StatefulWidget {
  const DrowsinessMonitorScreen({super.key});

  @override
  State<DrowsinessMonitorScreen> createState() => _DrowsinessMonitorScreenState();
}

class _DrowsinessMonitorScreenState extends State<DrowsinessMonitorScreen> {
  bool _isBackgroundWatchdogActive =
      MockDataService.isBackgroundDrowsinessWatchdogActive;
  bool _isEyesClosedSimulated = false;
  double _earScore = 0.34; // Eye Aspect Ratio (Normal > 0.22)
  int _blinkRatePerMin = 14;
  double _headPitchAngle = 4.2; // degrees
  String _alertLevel = "ALERT & ATTENTIVE";
  Color _alertColor = AppTheme.greenEco;

  void _simulateFatigueState() {
    setState(() {
      _isEyesClosedSimulated = !_isEyesClosedSimulated;
      if (_isEyesClosedSimulated) {
        _earScore = 0.14; // Closed eyes
        _headPitchAngle = 18.5; // Head drooping downward
        _blinkRatePerMin = 28;
        _alertLevel = "CRITICAL: MICROSLEEP DETECTED (>1.5s)";
        _alertColor = AppTheme.redDanger;
      } else {
        _earScore = 0.34;
        _headPitchAngle = 4.2;
        _blinkRatePerMin = 14;
        _alertLevel = "ALERT & ATTENTIVE";
        _alertColor = AppTheme.greenEco;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.visibility_outlined, color: AppTheme.amberWarning, size: 22),
            SizedBox(width: 8),
            Text("Driver Fatigue & Drowsiness AI"),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Background Watchdog Service Card (Tiered Wake-up)
              BackgroundServiceCard(
                title: "Tiered Background Watchdog",
                description: _isBackgroundWatchdogActive
                    ? "Battery-optimized: IMU swerve triggers 1 FPS camera bursts in background."
                    : "Standby. Background camera sampling inactive.",
                isRunning: _isBackgroundWatchdogActive,
                activeColor: AppTheme.amberWarning,
                onToggle: (val) {
                  setState(() {
                    _isBackgroundWatchdogActive = val;
                    MockDataService.isBackgroundDrowsinessWatchdogActive = val;
                  });
                  // TODO: Team Member: Connect battery-saving background camera service
                },
              ),
              const SizedBox(height: 16),

              // 2. Optical Vision Viewfinder HUD
              Container(
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isEyesClosedSimulated ? AppTheme.redDanger : AppTheme.borderSubtle,
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Simulated Driver Face Silhouette & Mesh
                    Icon(
                      _isEyesClosedSimulated
                          ? Icons.face_retouching_off_outlined
                          : Icons.face_outlined,
                      size: 140,
                      color: (_isEyesClosedSimulated
                              ? AppTheme.redDanger
                              : AppTheme.cyanAccent)
                          .withOpacity(0.4),
                    ),

                    // Facial Mesh Bounding Box Overlay
                    Positioned(
                      top: 40,
                      child: Container(
                        width: 170,
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _alertColor.withOpacity(0.6),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    // Top Status Badge
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: _alertColor, size: 8),
                            const SizedBox(width: 6),
                            const Text(
                              "Front Infrared Camera Stream",
                              style: TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Alert Banner
                    Positioned(
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: _alertColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _alertLevel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Biometric Telemetry Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "OPHTHALMIC & POSE BIOMETRICS",
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // EAR Metric Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Eye Aspect Ratio (EAR)"),
                          Text(
                            "${_earScore.toStringAsFixed(2)} (Safe > 0.22)",
                            style: TextStyle(
                              color: _earScore < 0.22 ? AppTheme.redDanger : AppTheme.greenEco,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_earScore / 0.45).clamp(0.0, 1.0),
                          backgroundColor: AppTheme.borderSubtle,
                          valueColor: AlwaysStoppedAnimation(
                            _earScore < 0.22 ? AppTheme.redDanger : AppTheme.cyanAccent,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Blink Rate & Head Tilt
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _miniStat("BLINK FREQ", "$_blinkRatePerMin / min", Icons.remove_red_eye_outlined),
                          _miniStat("HEAD PITCH", "${_headPitchAngle.toStringAsFixed(1)}°", Icons.airline_seat_recline_normal),
                          _miniStat("LIGHTING", "340 Lux", Icons.wb_sunny_outlined),
                        ],
                      ),
                      const Divider(height: 24, color: AppTheme.borderSubtle),

                      // Interactive Simulation Controls for Team Testing
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _simulateFatigueState,
                              icon: Icon(
                                _isEyesClosedSimulated ? Icons.refresh : Icons.warning_amber_rounded,
                                color: _isEyesClosedSimulated ? Colors.white : AppTheme.amberWarning,
                              ),
                              label: Text(
                                _isEyesClosedSimulated ? "Reset to Alert" : "Simulate Drowsy Eyes",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Ophthalmic baseline calibrated for current driver."),
                                  backgroundColor: AppTheme.surfaceDark,
                                ),
                              );
                            },
                            icon: const Icon(Icons.tune, size: 18),
                            label: const Text("Calibrate", style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surfaceDark,
                              foregroundColor: AppTheme.cyanAccent,
                              side: const BorderSide(color: AppTheme.cyanAccent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String title, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(height: 4),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

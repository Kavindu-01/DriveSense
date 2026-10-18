import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/mock_data_service.dart';
import '../../widgets/hud_gauge_widget.dart';
import '../../widgets/background_service_card.dart';
import '../../widgets/crash_sos_overlay.dart';

class LiveHudScreen extends StatefulWidget {
  const LiveHudScreen({super.key});

  @override
  State<LiveHudScreen> createState() => _LiveHudScreenState();
}

class _LiveHudScreenState extends State<LiveHudScreen> {
  double _currentSpeed = 58.0;
  double _gForce = 0.18;
  int _safetyScore = 94;
  String _drivingStatus = "Optimal Highway Cruising";
  Color _statusColor = AppTheme.greenEco;
  bool _isBackgroundServiceActive = MockDataService.isBackgroundTelematicsActive;
  Timer? _telemetrySimTimer;

  @override
  void initState() {
    super.initState();
    _startSimulatedStream();
  }

  void _startSimulatedStream() {
    // Dynamic micro-jitter to simulate live in-car GPS & IMU telematics
    _telemetrySimTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (!mounted) return;
      setState(() {
        _currentSpeed = (_currentSpeed + (t.tick % 2 == 0 ? 2 : -1.5)).clamp(45.0, 72.0);
        _gForce = (0.15 + (t.tick % 3) * 0.08);
        if (_gForce > 0.3) {
          _drivingStatus = "Moderate Acceleration";
          _statusColor = AppTheme.amberWarning;
        } else {
          _drivingStatus = "Optimal Highway Cruising";
          _statusColor = AppTheme.greenEco;
        }
        _safetyScore = (94 - (_gForce > 0.3 ? 2 : 0));
      });
    });
  }

  @override
  void dispose() {
    _telemetrySimTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.speed_rounded, color: AppTheme.cyanAccent, size: 22),
            SizedBox(width: 8),
            Text("Live Telematics HUD"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.car_crash_outlined, color: AppTheme.redDanger),
            tooltip: "Simulate Severe Impact (>2.5G)",
            onPressed: () {
              // Demonstrates the Crash SOS popup as requested by user
              CrashSosOverlay.show(context, gForce: 3.8);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Background Service Banner Toggle
              BackgroundServiceCard(
                title: "Background Telematics Service",
                description: _isBackgroundServiceActive
                    ? "Continuously sampling GPS velocity & IMU shock in background."
                    : "Suspended. Telematics only active when app is on-screen.",
                isRunning: _isBackgroundServiceActive,
                activeColor: AppTheme.cyanAccent,
                onToggle: (val) {
                  setState(() {
                    _isBackgroundServiceActive = val;
                    MockDataService.isBackgroundTelematicsActive = val;
                  });
                  // TODO: Team Member: Connect flutter_background_service start/stop
                },
              ),
              const SizedBox(height: 16),

              // 2. High-Tech Speedometer & G-Force Gauge
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    HudSpeedometerGauge(
                      currentSpeed: _currentSpeed,
                      gForce: _gForce,
                    ),
                    const SizedBox(height: 12),

                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statusColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        _drivingStatus,
                        style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sub-metrics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _subStat("TRIP DIST", "14.8 km", Icons.route),
                        _subStat("ELAPSED", "22m 14s", Icons.timer_outlined),
                        _subStat("HEADING", "042° NE", Icons.explore_outlined),
                        _subStat("SAFETY", "$_safetyScore/100", Icons.shield_outlined),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Telematics Diagnostic Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "SENSOR TELEMETRY PIPELINE",
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.greenEco.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "HEALTHY",
                              style: TextStyle(
                                color: AppTheme.greenEco,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _pipelineRow("GPS Hardware Receiver", "Locked • 14 Satellites Fixed (±2.1m)"),
                      _pipelineRow("Linear User Accelerometer", "X: +0.04  Y: -0.18  Z: +0.02 m/s²"),
                      _pipelineRow("Gyroscope Yaw Stability", "0.02 rad/s • Steady Lane Tracking"),
                      _pipelineRow("High-G Shock Trigger", "Armed (Threshold: > 2.5G Peak)"),
                      const Divider(height: 20, color: AppTheme.borderSubtle),

                      // Manual Crash Simulation trigger for testing
                      ElevatedButton.icon(
                        onPressed: () {
                          CrashSosOverlay.show(context, gForce: 3.4);
                        },
                        icon: const Icon(Icons.warning_amber_rounded, color: Colors.black),
                        label: const Text("TEST HARDWARE CRASH SOS POPUP"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.amberWarning,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 44),
                        ),
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

  Widget _subStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _pipelineRow(String name, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
            status,
            style: const TextStyle(
              color: AppTheme.cyanAccent,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

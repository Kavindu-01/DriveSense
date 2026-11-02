import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/trip_model.dart';
import '../../services/mock_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/background_service_card.dart';
import '../../widgets/crash_sos_overlay.dart';
import '../../widgets/hud_gauge_widget.dart';

class LiveHudScreen extends StatefulWidget {
  const LiveHudScreen({super.key});

  @override
  State<LiveHudScreen> createState() => _LiveHudScreenState();
}

class _LiveHudScreenState extends State<LiveHudScreen> {
  double _currentSpeed = 0;
  double _gForce = 0.18;
  int _safetyScore = 94;
  String _drivingStatus = 'Ready to drive';
  Color _statusColor = AppTheme.cyanAccent;

  bool _isDriving = false;
  bool _isBackgroundServiceActive =
      MockDataService.isBackgroundTelematicsActive;

  Timer? _telemetrySimTimer;
  Timer? _tripTimer;

  int _elapsedSeconds = 0;
  double _tripDistanceKm = 0;
  double _topSpeedKmh = 0;
  DateTime? _tripStartTime;

  final List<String> _tripEvents = [];
  final List<TripRoutePoint> _routePoints = [];
  final List<TripSafetyEvent> _safetyEvents = [];

  @override
  void dispose() {
    _telemetrySimTimer?.cancel();
    _tripTimer?.cancel();
    super.dispose();
  }

  void _startDrive() {
    if (_isDriving) return;

    setState(() {
      _isDriving = true;
      _currentSpeed = 45;
      _topSpeedKmh = 45;
      _elapsedSeconds = 0;
      _tripDistanceKm = 0;
      _tripStartTime = DateTime.now();
      _tripEvents.clear();
      _safetyEvents.clear();

      _routePoints
        ..clear()
        ..add(
          const TripRoutePoint(
            latitude: 6.8402,
            longitude: 80.0034,
          ),
        );

      _drivingStatus = 'Trip in progress';
      _statusColor = AppTheme.greenEco;
      _safetyScore = 94;
    });

    _startSimulatedTelemetry();

    _tripTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isDriving) return;

      setState(() {
        _elapsedSeconds++;
        // Demo distance calculation based on the displayed speed.
        _tripDistanceKm += _currentSpeed / 3600;
      });
    });
  }

  void _startSimulatedTelemetry() {
    _telemetrySimTimer?.cancel();

    _telemetrySimTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || !_isDriving) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentSpeed = (_currentSpeed + (timer.tick.isEven ? 2 : -1.5))
            .clamp(35.0, 72.0)
            .toDouble();

        if (_currentSpeed > _topSpeedKmh) {
          _topSpeedKmh = _currentSpeed;
        }

        // Create a sample route point near the starting coordinate.
        final pointNumber = _routePoints.length;
        _routePoints.add(
          TripRoutePoint(
            latitude: 6.8402 + (pointNumber * 0.0003),
            longitude: 80.0034 + (pointNumber * 0.0002),
          ),
        );

        _gForce = 0.15 + (timer.tick % 3) * 0.08;

        if (_gForce > 0.3) {
          _drivingStatus = 'Moderate Acceleration';
          _statusColor = AppTheme.amberWarning;
          _recordTripEvent('Moderate acceleration detected');
        } else {
          _drivingStatus = 'Smooth Driving';
          _statusColor = AppTheme.greenEco;
        }

        _safetyScore = _gForce > 0.3 ? 92 : 94;
      });
    });
  }

  void _recordTripEvent(String event) {
    // Keep one entry per event type in this demo.
    if (!_tripEvents.contains(event)) {
      _tripEvents.add(event);
    }
  }

  void _endDrive() {
    if (!_isDriving) return;

    _telemetrySimTimer?.cancel();
    _tripTimer?.cancel();

    final endTime = DateTime.now();
    final startTime = _tripStartTime ?? endTime;
    final durationHours = endTime.difference(startTime).inSeconds / 3600.0;
    final averageSpeed =
        durationHours > 0 ? _tripDistanceKm / durationHours : 0.0;

    final rapidAccelerationCount = _tripEvents
        .where((event) => event == 'Moderate acceleration detected')
        .length;

    final eventLocation = _routePoints.isNotEmpty
        ? _routePoints[_routePoints.length ~/ 2]
        : const TripRoutePoint(
            latitude: 6.8402,
            longitude: 80.0034,
          );

    if (_tripEvents.isNotEmpty) {
      _safetyEvents.add(
        TripSafetyEvent(
          title: 'Moderate acceleration',
          description: 'Demo acceleration event detected during the trip.',
          latitude: eventLocation.latitude,
          longitude: eventLocation.longitude,
        ),
      );
    }

    final completedTrip = TripModel(
      id: 'TRIP-${endTime.millisecondsSinceEpoch}',
      routeName: 'Demo trip from current location',
      startTime: startTime,
      endTime: endTime,
      distanceKm: _tripDistanceKm,
      avgSpeedKmh: averageSpeed,
      topSpeedKmh: _topSpeedKmh,
      ecoScore: _safetyScore,
      harshBrakes: 0,
      rapidAccels: rapidAccelerationCount,
      sharpTurns: 0,
      estimatedFuelLiters: _tripDistanceKm * 0.06,
      routePoints: List<TripRoutePoint>.unmodifiable(_routePoints),
      safetyEvents: List<TripSafetyEvent>.unmodifiable(_safetyEvents),
    );

    MockDataService.addCompletedTrip(completedTrip);

    setState(() {
      _isDriving = false;
      _currentSpeed = 0;
      _drivingStatus = 'Trip complete';
      _statusColor = AppTheme.cyanAccent;
    });

    _showTripSummary();
  }

  void _showTripSummary() {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    final eventsForSummary = List<String>.from(_tripEvents);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Trip Summary'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Demo trip completed.'),
                const SizedBox(height: 16),
                Text('Distance: ${_tripDistanceKm.toStringAsFixed(2)} km'),
                Text('Duration: $minutes min $seconds sec'),
                Text('Safety score: $_safetyScore/100'),
                const SizedBox(height: 16),
                const Text(
                  'Driving Events',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (eventsForSummary.isEmpty)
                  const Text('No driving events recorded.')
                else
                  for (final event in eventsForSummary)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('•  $event'),
                    ),
                const SizedBox(height: 8),
                const Text(
                  'Trip data, route, and events are simulated for this demo.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  String _formatElapsedTime() {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(
              Icons.speed_rounded,
              color: AppTheme.cyanAccent,
              size: 22,
            ),
            SizedBox(width: 8),
            Text('Live Telematics HUD'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.car_crash_outlined,
              color: AppTheme.redDanger,
            ),
            tooltip: 'Simulate Severe Impact (>2.5G)',
            onPressed: () {
              CrashSosOverlay.show(context, gForce: 3.8);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BackgroundServiceCard(
                title: 'Background Telematics Service',
                description: _isBackgroundServiceActive
                    ? 'Continuously sampling GPS velocity & IMU shock in background.'
                    : 'Suspended. Telematics only active when app is on-screen.',
                isRunning: _isBackgroundServiceActive,
                activeColor: AppTheme.cyanAccent,
                onToggle: (value) {
                  setState(() {
                    _isBackgroundServiceActive = value;
                    MockDataService.isBackgroundTelematicsActive = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _statusColor.withOpacity(0.4),
                        ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _subStat(
                          'TRIP DIST',
                          '${_tripDistanceKm.toStringAsFixed(2)} km',
                          Icons.route,
                        ),
                        _subStat(
                          'ELAPSED',
                          _formatElapsedTime(),
                          Icons.timer_outlined,
                        ),
                        _subStat(
                          'HEADING',
                          '042° NE',
                          Icons.explore_outlined,
                        ),
                        _subStat(
                          'SAFETY',
                          '$_safetyScore/100',
                          Icons.shield_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isDriving ? _endDrive : _startDrive,
                        icon: Icon(
                          _isDriving ? Icons.stop_rounded : Icons.play_arrow,
                        ),
                        label: Text(
                          _isDriving ? 'END DRIVE' : 'START DRIVE',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isDriving
                              ? AppTheme.redDanger
                              : AppTheme.greenEco,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                            'SENSOR TELEMETRY PIPELINE',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.greenEco.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'DEMO',
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
                      _pipelineRow(
                        'GPS Hardware Receiver',
                        'Demo location • ±2.1m',
                      ),
                      _pipelineRow(
                        'Linear User Accelerometer',
                        'X: +0.04  Y: -0.18  Z: +0.02 m/s²',
                      ),
                      _pipelineRow(
                        'Gyroscope Yaw Stability',
                        '0.02 rad/s • Demo data',
                      ),
                      _pipelineRow(
                        'High-G Shock Trigger',
                        'Armed (Threshold: > 2.5G Peak)',
                      ),
                      const Divider(
                        height: 20,
                        color: AppTheme.borderSubtle,
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          CrashSosOverlay.show(context, gForce: 3.4);
                        },
                        icon: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.black,
                        ),
                        label: const Text(
                          'TEST HARDWARE CRASH SOS POPUP',
                        ),
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
        Icon(
          icon,
          color: AppTheme.textMuted,
          size: 18,
        ),
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
          Text(
            name,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              status,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.cyanAccent,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
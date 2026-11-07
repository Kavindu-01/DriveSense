import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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
  String _gpsStatus = 'Waiting for trip';

  bool _isDriving = false;
  Timer? _telemetrySimTimer;
  Timer? _tripTimer;
  Timer? _demoRouteTimer;
  StreamSubscription<Position>? _positionSubscription;

  Position? _lastPosition;
  int _elapsedSeconds = 0;
  double _tripDistanceKm = 0;
  double _topSpeedKmh = 0;
  DateTime? _tripStartTime;
  int _demoRouteStep = 0;

  final List<String> _tripEvents = [];
  final List<TripRoutePoint> _routePoints = [];
  final List<TripSafetyEvent> _safetyEvents = [];

  @override
  void dispose() {
    _telemetrySimTimer?.cancel();
    _tripTimer?.cancel();
    _demoRouteTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<bool> _requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showMessage('Turn on location services, then try again.');
      return false;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showMessage('Location permission was denied.');
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage(
        'Location permission is blocked. Enable it in your device settings.',
      );
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> _startDrive() async {
    if (_isDriving) return;

    try {
      final hasPermission = await _requestLocationPermission();
      if (!hasPermission || !mounted) return;

      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _isDriving = true;
        _currentSpeed = _speedInKmh(initialPosition);
        _topSpeedKmh = _currentSpeed;
        _elapsedSeconds = 0;
        _tripDistanceKm = 0;
        _tripStartTime = DateTime.now();
        _tripEvents.clear();
        _safetyEvents.clear();
        _lastPosition = initialPosition;
        _demoRouteStep = 0;

        _routePoints
          ..clear()
          ..add(
            TripRoutePoint(
              latitude: initialPosition.latitude,
              longitude: initialPosition.longitude,
            ),
          );

        _drivingStatus = 'Trip in progress';
        _statusColor = AppTheme.greenEco;
        _safetyScore = 94;
        _gpsStatus = 'GPS tracking active';
      });

      _startLocationStream();
      _startSimulatedAcceleration();
      _startDemoRoute();

      _tripTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_isDriving) return;

        setState(() {
          _elapsedSeconds++;
        });
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not get your location: $error');
    }
  }

  double _speedInKmh(Position position) {
    if (!position.speed.isFinite || position.speed < 0) return 0;
    return position.speed * 3.6;
  }

  void _startLocationStream() {
    _positionSubscription?.cancel();

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1,
          ),
        ).listen(
          _handlePosition,
          onError: (Object error) {
            if (!mounted) return;

            setState(() {
              _gpsStatus = 'GPS update unavailable';
            });
            _showMessage('GPS tracking error: $error');
          },
        );
  }

  void _handlePosition(Position position) {
    if (!mounted || !_isDriving) return;

    final previousPosition = _lastPosition;
    var addedDistanceKm = 0.0;
    var movedFromPreviousFix = false;

    if (previousPosition != null) {
      final distanceMeters = Geolocator.distanceBetween(
        previousPosition.latitude,
        previousPosition.longitude,
        position.latitude,
        position.longitude,
      );

      if (distanceMeters.isFinite && distanceMeters >= 0.5) {
        addedDistanceKm = distanceMeters / 1000.0;
        movedFromPreviousFix = true;
      }
    }

    final speedKmh = _speedInKmh(position);

    setState(() {
      _lastPosition = position;
      _tripDistanceKm += addedDistanceKm;
      _currentSpeed = speedKmh;

      if (speedKmh > _topSpeedKmh) {
        _topSpeedKmh = speedKmh;
      }

      if (movedFromPreviousFix) {
        _routePoints.add(
          TripRoutePoint(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
      }

      _gpsStatus =
          'GPS tracking active • Accuracy ±${position.accuracy.toStringAsFixed(0)} m';
    });
  }

  void _startDemoRoute() {
    _demoRouteTimer?.cancel();

    _demoRouteTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_isDriving || _routePoints.isEmpty) return;

      final start = _routePoints.first;
      _demoRouteStep++;

      final simulatedPoint = TripRoutePoint(
        latitude: start.latitude + (_demoRouteStep * 0.00015),
        longitude: start.longitude + (_demoRouteStep * 0.00012),
      );

      setState(() {
        _routePoints.add(simulatedPoint);
        _gpsStatus = 'Demo route active • browser GPS may be fixed';
      });
    });
  }

  void _startSimulatedAcceleration() {
    _telemetrySimTimer?.cancel();

    _telemetrySimTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || !_isDriving) {
        timer.cancel();
        return;
      }

      setState(() {
        // Acceleration is simulated; it is not read from a real motion sensor.
        _gForce = 0.15 + (timer.tick % 3) * 0.08;

        if (_gForce > 0.3) {
          _drivingStatus = 'Moderate Acceleration';
          _statusColor = AppTheme.amberWarning;
          _recordTripEvent('Moderate acceleration detected');
        } else {
          _drivingStatus = 'Trip in progress';
          _statusColor = AppTheme.greenEco;
        }

        _safetyScore = _gForce > 0.3 ? 92 : 94;
      });
    });
  }

  void _recordTripEvent(String event) {
    if (!_tripEvents.contains(event)) {
      _tripEvents.add(event);
    }
  }

  Future<void> _endDrive() async {
    if (!_isDriving) return;

    _telemetrySimTimer?.cancel();
    _tripTimer?.cancel();
    _demoRouteTimer?.cancel();

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    final endTime = DateTime.now();
    final startTime = _tripStartTime ?? endTime;
    final duration = endTime.difference(startTime);
    final durationHours = duration.inSeconds / 3600.0;
    final averageSpeed = durationHours > 0
        ? _tripDistanceKm / durationHours
        : 0.0;

    final rapidAccelerationCount = _tripEvents
        .where((event) => event == 'Moderate acceleration detected')
        .length;

    if (_tripEvents.isNotEmpty && _routePoints.isNotEmpty) {
      final eventLocation = _routePoints[_routePoints.length ~/ 2];

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
      routeName: 'GPS trip (demo route)',
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

    await MockDataService.addCompletedTrip(completedTrip);
    if (!mounted) return;

    setState(() {
      _isDriving = false;
      _currentSpeed = 0;
      _lastPosition = null;
      _drivingStatus = 'Trip complete';
      _statusColor = AppTheme.cyanAccent;
      _gpsStatus = 'GPS tracking stopped';
    });

    _showTripSummary(duration, averageSpeed);
  }

  void _showTripSummary(Duration duration, double averageSpeed) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
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
                const Text(
                  'Trip completed. Route points may include simulated demo data.',
                ),
                const SizedBox(height: 16),
                Text('Distance: ${_tripDistanceKm.toStringAsFixed(2)} km'),
                Text('Duration: $minutes min $seconds sec'),
                Text('Average speed: ${averageSpeed.toStringAsFixed(1)} km/h'),
                Text('Safety score: $_safetyScore/100'),
                Text('Route points: ${_routePoints.length}'),
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
                      child: Text('•  $event (simulated)'),
                    ),
                const SizedBox(height: 8),
                const Text(
                  'Acceleration and demo route points may be simulated. Real GPS data depends on device permission and signal.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.speed_rounded, color: AppTheme.cyanAccent, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Live HUD · demo sensors',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BackgroundServiceCard(
                title: 'Trip Location Tracking',
                description: _isDriving
                    ? 'Recording GPS and demo route points while this trip is active.'
                    : 'Location tracking starts when you start a trip.',
                isRunning: _isDriving,
                activeColor: AppTheme.cyanAccent,
                onToggle: (value) {
                  if (value && !_isDriving) {
                    _startDrive();
                  } else if (!value && _isDriving) {
                    _endDrive();
                  }
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
                    const SizedBox(height: 8),
                    Text(
                      _gpsStatus,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.spaceAround,
                      runSpacing: 16,
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
                          'GPS POINTS',
                          '${_routePoints.length}',
                          Icons.location_on_outlined,
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
                        label: Text(_isDriving ? 'END DRIVE' : 'START DRIVE'),
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
                              'GPS + DEMO SENSORS',
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
                      _pipelineRow('GPS Receiver', _gpsStatus),
                      _pipelineRow(
                        'GPS-derived speed',
                        '${_currentSpeed.toStringAsFixed(1)} km/h',
                      ),
                      _pipelineRow(
                        'Acceleration monitor',
                        'Demo data • ${_gForce.toStringAsFixed(2)}G',
                      ),
                      _pipelineRow(
                        'Recorded route points',
                        '${_routePoints.length}',
                      ),
                      const Divider(height: 20, color: AppTheme.borderSubtle),
                      ElevatedButton.icon(
                        onPressed: () {
                          CrashSosOverlay.show(context, gForce: 3.4);
                        },
                        icon: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.black,
                        ),
                        label: const Text('PREVIEW CRASH SOS'),
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
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 64) / 2,
      child: Column(
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
      ),
    );
  }

  Widget _pipelineRow(String name, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
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

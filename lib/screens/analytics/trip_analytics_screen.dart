import 'package:flutter/material.dart';

import '../../models/trip_model.dart';
import '../../services/mock_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/background_service_card.dart';

class TripAnalyticsScreen extends StatefulWidget {
  const TripAnalyticsScreen({super.key});

  @override
  State<TripAnalyticsScreen> createState() => _TripAnalyticsScreenState();
}

class _TripAnalyticsScreenState extends State<TripAnalyticsScreen> {
  bool _isBackgroundLogging = MockDataService.isBackgroundLoggingActive;
  List<TripModel> _trips = MockDataService.getRecentTrips();

  @override
  void initState() {
    super.initState();
    MockDataService.tripsChanged.addListener(_refreshTrips);
  }

  void _refreshTrips() {
    if (!mounted) return;
    setState(() => _trips = MockDataService.getRecentTrips());
  }

  @override
  void dispose() {
    MockDataService.tripsChanged.removeListener(_refreshTrips);
    super.dispose();
  }

  void _showTripDetails(TripModel trip) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(trip.routeName),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _TripRoutePreview(trip: trip),
                const SizedBox(height: 16),
                _detailRow('Distance', '${trip.distanceKm.toStringAsFixed(2)} km'),
                _detailRow('Duration', '${trip.duration.inMinutes} min'),
                _detailRow('Average speed', '${trip.avgSpeedKmh.toStringAsFixed(0)} km/h'),
                _detailRow('Top speed', '${trip.topSpeedKmh.toStringAsFixed(0)} km/h'),
                _detailRow('Eco score', '${trip.ecoScore}/100'),
                _detailRow('Estimated fuel', '${trip.estimatedFuelLiters.toStringAsFixed(1)} L'),
                const SizedBox(height: 16),
                const Text(
                  'SAFETY EVENTS',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                if (trip.safetyEvents.isEmpty)
                  const Text(
                    'No safety-event details recorded for this trip.',
                    style: TextStyle(color: AppTheme.textMuted),
                  )
                else
                  ...trip.safetyEvents.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              color: AppTheme.amberWarning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            event.description,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'Location: ${event.latitude.toStringAsFixed(5)}, '
                            '${event.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              color: AppTheme.cyanAccent,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Route and event data may be simulated for this demo.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted)),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const overallEcoScore = 93;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.eco_rounded, color: AppTheme.greenEco, size: 22),
            SizedBox(width: 8),
            Text('Trip Analytics & Eco-Drive'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BackgroundServiceCard(
                title: 'Background Trip Logger',
                description: _isBackgroundLogging
                    ? 'Recording GPS waypoints, fuel economy & harsh events in background.'
                    : 'Logging paused. Trip data only records while app is in foreground.',
                isRunning: _isBackgroundLogging,
                activeColor: AppTheme.greenEco,
                onToggle: (value) {
                  setState(() {
                    _isBackgroundLogging = value;
                    MockDataService.isBackgroundLoggingActive = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildEcoScoreCard(overallEcoScore),
              const SizedBox(height: 16),
              _buildMetricsCard(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'LOGGED TRIP SESSIONS',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '${_trips.length} recent',
                    style: const TextStyle(
                      color: AppTheme.cyanAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_trips.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No trips recorded yet.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                )
              else
                for (final trip in _trips) _buildTripCard(trip),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEcoScoreCard(int score) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.greenEco.withOpacity(0.18),
            AppTheme.surfaceDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.greenEco.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OVERALL ECO-EFFICIENCY SCORE',
                style: TextStyle(
                  color: AppTheme.greenEco,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'EXCELLENT',
                style: TextStyle(
                  color: AppTheme.greenEco,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '/ 100',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Your smooth braking and steady cruising saved approx. '
            '1.8 Liters of fuel this week, reducing carbon emissions by 4.2 kg CO₂.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DRIVING TELEMATICS METRICS',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 14),
            _metricProgressBar(
              'Smooth Acceleration Index',
              0.92,
              AppTheme.cyanAccent,
            ),
            const SizedBox(height: 10),
            _metricProgressBar(
              'Progressive Braking Stability',
              0.95,
              AppTheme.greenEco,
            ),
            const SizedBox(height: 10),
            _metricProgressBar(
              'Speed Limit Compliance',
              0.88,
              AppTheme.amberWarning,
            ),
            const Divider(height: 24, color: AppTheme.borderSubtle),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _EventPill(
                  title: 'Harsh Brakes',
                  count: '3',
                  icon: Icons.car_crash_outlined,
                  color: AppTheme.amberWarning,
                ),
                _EventPill(
                  title: 'Rapid Accel',
                  count: '4',
                  icon: Icons.speed,
                  color: AppTheme.cyanAccent,
                ),
                _EventPill(
                  title: 'Sharp Swerves',
                  count: '1',
                  icon: Icons.turn_sharp_right,
                  color: AppTheme.redDanger,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(TripModel trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showTripDetails(trip),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.routeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    'Eco: ${trip.ecoScore}',
                    style: const TextStyle(
                      color: AppTheme.greenEco,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _tripInfoItem(
                    'Distance',
                    '${trip.distanceKm.toStringAsFixed(2)} km',
                  ),
                  _tripInfoItem(
                    'Duration',
                    '${trip.duration.inMinutes} mins',
                  ),
                  _tripInfoItem(
                    'Avg Speed',
                    '${trip.avgSpeedKmh.toStringAsFixed(0)} km/h',
                  ),
                  _tripInfoItem(
                    'Fuel Used',
                    '${trip.estimatedFuelLiters.toStringAsFixed(1)} L',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _TripRoutePreview(trip: trip),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'TAP FOR TRIP DETAILS',
                  style: TextStyle(
                    color: AppTheme.cyanAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricProgressBar(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              '${(percent * 100).toInt()}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: AppTheme.borderSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _tripInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _EventPill extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _EventPill({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          title,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}

class _TripRoutePreview extends StatelessWidget {
  final TripModel trip;

  const _TripRoutePreview({required this.trip});

  @override
  Widget build(BuildContext context) {
    if (trip.routePoints.length < 2) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: const Text(
          'Route preview unavailable for this trip',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      );
    }

    return Container(
      height: 110,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: CustomPaint(
        painter: _TripRoutePainter(trip),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _TripRoutePainter extends CustomPainter {
  final TripModel trip;

  const _TripRoutePainter(this.trip);

  @override
  void paint(Canvas canvas, Size size) {
    final points = trip.routePoints;
    if (points.length < 2) return;

    const padding = 16.0;
    final usableWidth = size.width - padding * 2;
    final usableHeight = size.height - padding * 2;

    final minLat = points.map((p) => p.latitude).reduce(
          (a, b) => a < b ? a : b,
        );
    final maxLat = points.map((p) => p.latitude).reduce(
          (a, b) => a > b ? a : b,
        );
    final minLon = points.map((p) => p.longitude).reduce(
          (a, b) => a < b ? a : b,
        );
    final maxLon = points.map((p) => p.longitude).reduce(
          (a, b) => a > b ? a : b,
        );

    final latRange = maxLat - minLat;
    final lonRange = maxLon - minLon;

    Offset toOffset(double latitude, double longitude) {
      final xRatio = lonRange == 0 ? 0.5 : (longitude - minLon) / lonRange;
      final yRatio = latRange == 0 ? 0.5 : (latitude - minLat) / latRange;

      return Offset(
        padding + xRatio * usableWidth,
        size.height - padding - yRatio * usableHeight,
      );
    }

    final gridPaint = Paint()
      ..color = AppTheme.borderSubtle.withOpacity(0.45)
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final x = size.width * i / 4;
      final y = size.height * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final routePath = Path();
    for (var i = 0; i < points.length; i++) {
      final offset = toOffset(points[i].latitude, points[i].longitude);
      if (i == 0) {
        routePath.moveTo(offset.dx, offset.dy);
      } else {
        routePath.lineTo(offset.dx, offset.dy);
      }
    }

    final routePaint = Paint()
      ..color = AppTheme.cyanAccent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(routePath, routePaint);

    final start = toOffset(points.first.latitude, points.first.longitude);
    final finish = toOffset(points.last.latitude, points.last.longitude);

    canvas.drawCircle(start, 5, Paint()..color = AppTheme.greenEco);
    canvas.drawCircle(finish, 5, Paint()..color = AppTheme.cyanAccent);

    for (final event in trip.safetyEvents) {
      final marker = toOffset(event.latitude, event.longitude);
      canvas.drawCircle(marker, 7, Paint()..color = AppTheme.amberWarning);
      canvas.drawCircle(marker, 3, Paint()..color = AppTheme.surfaceDark);
    }
  }

  @override
  bool shouldRepaint(covariant _TripRoutePainter oldDelegate) {
    return oldDelegate.trip != trip;
  }
}
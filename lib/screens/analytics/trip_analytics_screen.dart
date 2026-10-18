import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/trip_model.dart';
import '../../services/mock_data_service.dart';
import '../../widgets/background_service_card.dart';

class TripAnalyticsScreen extends StatefulWidget {
  const TripAnalyticsScreen({super.key});

  @override
  State<TripAnalyticsScreen> createState() => _TripAnalyticsScreenState();
}

class _TripAnalyticsScreenState extends State<TripAnalyticsScreen> {
  bool _isBackgroundLogging = MockDataService.isBackgroundLoggingActive;
  final List<TripModel> _trips = MockDataService.getRecentTrips();

  @override
  Widget build(BuildContext context) {
    const overallEcoScore = 93;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.eco_rounded, color: AppTheme.greenEco, size: 22),
            SizedBox(width: 8),
            Text("Trip Analytics & Eco-Drive"),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Background Trip Logging Service Card
              BackgroundServiceCard(
                title: "Background Trip Logger",
                description: _isBackgroundLogging
                    ? "Recording GPS waypoints, fuel economy & harsh events in background."
                    : "Logging paused. Trip data only records while app is in foreground.",
                isRunning: _isBackgroundLogging,
                activeColor: AppTheme.greenEco,
                onToggle: (val) {
                  setState(() {
                    _isBackgroundLogging = val;
                    MockDataService.isBackgroundLoggingActive = val;
                  });
                  // TODO: Team Member: Connect background location persistence (SQLite / Hive)
                },
              ),
              const SizedBox(height: 16),

              // 2. Eco-Score Hero Card
              Container(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "OVERALL ECO-EFFICIENCY SCORE",
                          style: TextStyle(
                            color: AppTheme.greenEco,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.greenEco.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "EXCELLENT",
                            style: TextStyle(
                              color: AppTheme.greenEco,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: const [
                        Text(
                          "$overallEcoScore",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          "/ 100",
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
                      "Your smooth braking and steady cruising saved approx. 1.8 Liters of fuel this week, reducing carbon emissions by 4.2 kg CO₂.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Telematics Harsh Events Breakdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "DRIVING TELEMATICS METRICS",
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _metricProgressBar("Smooth Acceleration Index", 0.92, AppTheme.cyanAccent),
                      const SizedBox(height: 10),
                      _metricProgressBar("Progressive Braking Stability", 0.95, AppTheme.greenEco),
                      const SizedBox(height: 10),
                      _metricProgressBar("Speed Limit Compliance", 0.88, AppTheme.amberWarning),
                      const Divider(height: 24, color: AppTheme.borderSubtle),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _harshEventPill("Harsh Brakes", "3", Icons.car_crash_outlined, AppTheme.amberWarning),
                          _harshEventPill("Rapid Accel", "4", Icons.speed, AppTheme.cyanAccent),
                          _harshEventPill("Sharp Swerves", "1", Icons.turn_sharp_right, AppTheme.redDanger),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Past Logged Trips History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "LOGGED TRIP SESSIONS",
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    "${_trips.length} recent",
                    style: const TextStyle(color: AppTheme.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _trips.length,
                itemBuilder: (context, i) {
                  final trip = _trips[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.greenEco.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Eco: ${trip.ecoScore}",
                                  style: const TextStyle(
                                    color: AppTheme.greenEco,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _tripInfoItem("Distance", "${trip.distanceKm} km"),
                              _tripInfoItem("Duration", "${trip.duration.inMinutes} mins"),
                              _tripInfoItem("Avg Speed", "${trip.avgSpeedKmh.toInt()} km/h"),
                              _tripInfoItem("Fuel Used", "${trip.estimatedFuelLiters} L"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(
              "${(percent * 100).toInt()}%",
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
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _harshEventPill(String title, String count, IconData icon, Color color) {
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

  Widget _tripInfoItem(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          v,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

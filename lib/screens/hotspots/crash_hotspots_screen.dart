import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/hotspot_model.dart';
import '../../services/mock_data_service.dart';

class CrashHotspotsScreen extends StatefulWidget {
  const CrashHotspotsScreen({super.key});

  @override
  State<CrashHotspotsScreen> createState() => _CrashHotspotsScreenState();
}

class _CrashHotspotsScreenState extends State<CrashHotspotsScreen> {
  final List<CrashHotspotModel> _hotspots = MockDataService.getSampleHotspots();
  bool _audioWarningsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final imminentHotspot = _hotspots.firstWhere(
      (h) => h.distanceMeters < 1000,
      orElse: () => _hotspots.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.radar_rounded, color: AppTheme.purpleRadar, size: 22),
            SizedBox(width: 8),
            Text("Crash Hotspot Warning System"),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _audioWarningsEnabled ? Icons.volume_up : Icons.volume_off,
              color: _audioWarningsEnabled ? AppTheme.cyanAccent : AppTheme.textMuted,
            ),
            tooltip: "Toggle Audio Proximity Chimes",
            onPressed: () {
              setState(() => _audioWarningsEnabled = !_audioWarningsEnabled);
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
              // 1. High-Priority Imminent Proximity Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.redDanger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.redDanger, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppTheme.redDanger,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "APPROACHING BLACKSPOT",
                                style: TextStyle(
                                  color: AppTheme.redDanger,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                "${imminentHotspot.distanceMeters.toInt()}m AHEAD",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            imminentHotspot.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Advisory: Reduce speed to ${imminentHotspot.recommendedSpeedKmh.toInt()} km/h. ${imminentHotspot.primaryRiskReason}.",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Geofence Radar Simulation Card
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Radar Concentric Circles
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.purpleRadar.withOpacity(0.3), width: 1),
                      ),
                    ),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.purpleRadar.withOpacity(0.5), width: 1.5),
                      ),
                    ),
                    // User Vehicle Center Marker
                    const Icon(Icons.navigation, color: AppTheme.cyanAccent, size: 28),

                    // Hazard Ping Markers
                    const Positioned(
                      top: 35,
                      left: 130,
                      child: Icon(Icons.fmd_bad, color: AppTheme.redDanger, size: 22),
                    ),
                    const Positioned(
                      bottom: 45,
                      right: 110,
                      child: Icon(Icons.fmd_bad, color: AppTheme.amberWarning, size: 18),
                    ),

                    Positioned(
                      bottom: 8,
                      left: 12,
                      child: Row(
                        children: [
                          Icon(Icons.satellite_alt, size: 12, color: AppTheme.cyanAccent),
                          const SizedBox(width: 4),
                          const Text(
                            "Live Geofence Radar Range: 5.0 km",
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Nearby Blackspots Directory
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "DOCUMENTED ACCIDENT BLACKSPOTS",
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    "${_hotspots.length} nearby",
                    style: const TextStyle(color: AppTheme.purpleRadar, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _hotspots.length,
                itemBuilder: (context, i) {
                  final h = _hotspots[i];
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
                                  h.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              _severityChip(h.severity),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            h.locationName,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.near_me, size: 14, color: AppTheme.cyanAccent),
                                  const SizedBox(width: 4),
                                  Text(
                                    h.distanceMeters > 1000
                                        ? "${(h.distanceMeters / 1000).toStringAsFixed(1)} km away"
                                        : "${h.distanceMeters.toInt()} m away",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.history, size: 14, color: AppTheme.amberWarning),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${h.historicalCrashes} recorded incidents",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 18, color: AppTheme.borderSubtle),
                          Text(
                            "Primary Factor: ${h.primaryRiskReason}",
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
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

  Widget _severityChip(HazardSeverity s) {
    Color color;
    String label;
    switch (s) {
      case HazardSeverity.critical:
        color = AppTheme.redDanger;
        label = "CRITICAL RISK";
        break;
      case HazardSeverity.severe:
        color = Colors.deepOrange;
        label = "HIGH RISK";
        break;
      case HazardSeverity.moderate:
        color = AppTheme.amberWarning;
        label = "MODERATE";
        break;
      case HazardSeverity.low:
        color = AppTheme.cyanAccent;
        label = "CAUTION";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

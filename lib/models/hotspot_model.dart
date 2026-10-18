enum HazardSeverity { low, moderate, severe, critical }

/// Model representing a geofenced accident blackspot or hazardous intersection.
class CrashHotspotModel {
  final String id;
  final String title;
  final String locationName;
  final double latitude;
  final double longitude;
  final double distanceMeters; // Live proximity from user
  final HazardSeverity severity;
  final int historicalCrashes;
  final String primaryRiskReason; // e.g. "Blind Curve + High Speed", "Unregulated T-Junction"
  final double recommendedSpeedKmh;

  CrashHotspotModel({
    required this.id,
    required this.title,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.severity,
    required this.historicalCrashes,
    required this.primaryRiskReason,
    required this.recommendedSpeedKmh,
  });
}

/// One GPS point recorded during a trip.
class TripRoutePoint {
  final double latitude;
  final double longitude;

  const TripRoutePoint({
    required this.latitude,
    required this.longitude,
  });
}

/// A safety event recorded during a trip.
class TripSafetyEvent {
  final String title;
  final String description;
  final double latitude;
  final double longitude;

  const TripSafetyEvent({
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
  });
}

/// Model representing a driving session log for Trip Analytics & Eco-Drive.
class TripModel {
  final String id;
  final String routeName;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final double avgSpeedKmh;
  final double topSpeedKmh;
  final int ecoScore;
  final int harshBrakes;
  final int rapidAccels;
  final int sharpTurns;
  final double estimatedFuelLiters;

  /// GPS points used to draw the trip route.
  final List<TripRoutePoint> routePoints;

  /// Safety events associated with this trip.
  final List<TripSafetyEvent> safetyEvents;

  TripModel({
    required this.id,
    required this.routeName,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.avgSpeedKmh,
    required this.topSpeedKmh,
    required this.ecoScore,
    required this.harshBrakes,
    required this.rapidAccels,
    required this.sharpTurns,
    required this.estimatedFuelLiters,
    this.routePoints = const [],
    this.safetyEvents = const [],
  });

  Duration get duration => endTime.difference(startTime);
}
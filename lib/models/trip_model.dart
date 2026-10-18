/// Model representing a driving session log for Trip Analytics & Eco-Drive.
class TripModel {
  final String id;
  final String routeName;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final double avgSpeedKmh;
  final double topSpeedKmh;
  final int ecoScore; // 0 to 100
  final int harshBrakes;
  final int rapidAccels;
  final int sharpTurns;
  final double estimatedFuelLiters;

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
  });

  Duration get duration => endTime.difference(startTime);
}

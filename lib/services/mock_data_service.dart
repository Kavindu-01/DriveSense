import '../models/driver_profile_model.dart';
import '../models/hotspot_model.dart';
import '../models/trip_model.dart';
import 'package:flutter/foundation.dart';

/// Centralized repository providing mock telemetry, active trip data,
/// and background service hooks for team development.
class MockDataService {
  // Background service simulated states.
  static bool isBackgroundTelematicsActive = true;
  static bool isBackgroundDrowsinessWatchdogActive = false;
  static bool isBackgroundLoggingActive = true;

  // Completed trips created during this app session.
  static final List<TripModel> _completedTrips = [];

  // Notifies screens when a completed trip is added.
  static final ValueNotifier<int> tripsChanged = ValueNotifier<int>(0);

  static void addCompletedTrip(TripModel trip) {
    _completedTrips.insert(0, trip);
    tripsChanged.value++;
  }

  // Active driver profile.
  static DriverProfileModel currentDriver = DriverProfileModel(
    uid: 'DRV-90412',
    fullName: 'Diluka Wijesinghe',
    email: 'diluka.w@nsbm.ac.lk',
    phone: '+94 77 123 4567',
    vehicleModel: 'Toyota Aqua Hybrid (2020)',
    licensePlate: 'WP CBH-4892',
    emergencyContactName: 'Dr. K. Perera (Spouse)',
    emergencyContactPhone: '+94 71 987 6543',
    overallSafetyScore: 94,
    totalLoggedKm: 1420.5,
    totalTrips: 68,
    safetyTierBadge: 'Elite Safe Driver (Tier 1)',
  );

  // Crash hotspots list.
  static List<CrashHotspotModel> getSampleHotspots() {
    return [
      CrashHotspotModel(
        id: 'HS-01',
        title: 'Pitipana - High Level T-Junction',
        locationName: 'Homagama - NSBM Green Road',
        latitude: 6.8402,
        longitude: 80.0034,
        distanceMeters: 450,
        severity: HazardSeverity.critical,
        historicalCrashes: 24,
        primaryRiskReason:
            'High-speed highway merger with blind pedestrian crossing',
        recommendedSpeedKmh: 40.0,
      ),
      CrashHotspotModel(
        id: 'HS-02',
        title: 'Moragahahena Hairpin Curve',
        locationName: 'Horana Bypass Km 12',
        latitude: 6.7820,
        longitude: 80.0450,
        distanceMeters: 1850,
        severity: HazardSeverity.severe,
        historicalCrashes: 18,
        primaryRiskReason:
            'Reverse camber bend + wet surface aquaplaning risk',
        recommendedSpeedKmh: 35.0,
      ),
      CrashHotspotModel(
        id: 'HS-03',
        title: 'Kottawa Expressway Flyover Exit',
        locationName: 'Southern Expressway E01 Interlink',
        latitude: 6.8621,
        longitude: 79.9723,
        distanceMeters: 4200,
        severity: HazardSeverity.moderate,
        historicalCrashes: 11,
        primaryRiskReason:
            'Sudden deceleration tailbacks at toll approach',
        recommendedSpeedKmh: 60.0,
      ),
      CrashHotspotModel(
        id: 'HS-04',
        title: 'Maharagama Town Bus Terminal',
        locationName: 'Old High Level Road',
        latitude: 6.8491,
        longitude: 79.9272,
        distanceMeters: 7500,
        severity: HazardSeverity.low,
        historicalCrashes: 7,
        primaryRiskReason:
            'Heavy three-wheeler lane switching and bus congestion',
        recommendedSpeedKmh: 30.0,
      ),
    ];
  }

  // Recent trips for Eco-Drive & Analytics.
  static List<TripModel> getRecentTrips() {
    final sampleTrips = <TripModel>[
      TripModel(
        id: 'TRIP-108',
        routeName: 'Homagama to NSBM University Campus',
        startTime: DateTime.now().subtract(const Duration(minutes: 45)),
        endTime: DateTime.now().subtract(const Duration(minutes: 18)),
        distanceKm: 14.8,
        avgSpeedKmh: 42.5,
        topSpeedKmh: 68.0,
        ecoScore: 96,
        harshBrakes: 0,
        rapidAccels: 1,
        sharpTurns: 0,
        estimatedFuelLiters: 0.9,
      ),
      TripModel(
        id: 'TRIP-107',
        routeName: 'Colombo Fort to Kottawa Multimodal Hub',
        startTime: DateTime.now().subtract(
          const Duration(days: 1, hours: 3),
        ),
        endTime: DateTime.now().subtract(
          const Duration(days: 1, hours: 2),
        ),
        distanceKm: 22.4,
        avgSpeedKmh: 38.0,
        topSpeedKmh: 75.0,
        ecoScore: 88,
        harshBrakes: 2,
        rapidAccels: 3,
        sharpTurns: 1,
        estimatedFuelLiters: 1.6,
      ),
      TripModel(
        id: 'TRIP-106',
        routeName: 'Horana Town to Pitipana Technology Park',
        startTime: DateTime.now().subtract(
          const Duration(days: 2, hours: 5),
        ),
        endTime: DateTime.now().subtract(
          const Duration(days: 2, hours: 4, minutes: 20),
        ),
        distanceKm: 18.2,
        avgSpeedKmh: 46.0,
        topSpeedKmh: 72.0,
        ecoScore: 92,
        harshBrakes: 1,
        rapidAccels: 1,
        sharpTurns: 0,
        estimatedFuelLiters: 1.2,
      ),
    ];

    return <TripModel>[
      ..._completedTrips,
      ...sampleTrips,
    ];
  }
}
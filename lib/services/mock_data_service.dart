import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/driver_profile_model.dart';
import '../models/hotspot_model.dart';
import '../models/trip_model.dart';

/// Stores demo data and completed trips for DriveSense.
class MockDataService {
  static const String _completedTripsKey = 'drivesense_completed_trips';

  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static bool isBackgroundTelematicsActive = true;
  static bool isBackgroundDrowsinessWatchdogActive = false;
  static bool isBackgroundLoggingActive = true;

  static final List<TripModel> _completedTrips = [];

  /// Screens can listen to this and refresh when trips are added.
  static final ValueNotifier<int> tripsChanged = ValueNotifier<int>(0);
  static final ValueNotifier<int> driverChanged = ValueNotifier<int>(0);
  static String? tripStorageError;
  static bool tripsLoading = false;

  /// Load saved trips before showing the app.
  static Future<void> initialize() async {
    tripsLoading = true;
    tripStorageError = null;
    try {
      final savedJson = await _preferences.getString(_completedTripsKey);

      if (savedJson == null || savedJson.isEmpty) return;

      final decoded = jsonDecode(savedJson);
      if (decoded is! List) return;

      _completedTrips
        ..clear()
        ..addAll(
          decoded.whereType<Map>().map(
            (item) => _tripFromJson(Map<String, dynamic>.from(item)),
          ),
        );
    } catch (error) {
      tripStorageError = 'Saved trip history could not be loaded.';
      debugPrint('Could not load saved trips: $error');
    } finally {
      tripsLoading = false;
      tripsChanged.value++;
    }
  }

  /// Add a trip to this session and save it on this device.
  static Future<void> addCompletedTrip(TripModel trip) async {
    _completedTrips.insert(0, trip);
    tripsChanged.value++;

    try {
      final encodedTrips = jsonEncode(
        _completedTrips.map(_tripToJson).toList(),
      );
      await _preferences.setString(_completedTripsKey, encodedTrips);
      tripStorageError = null;
      tripsChanged.value++;
    } catch (error) {
      tripStorageError = 'This trip was added for this session but could not be saved on this device.';
      tripsChanged.value++;
      debugPrint('Could not save completed trip: $error');
    }
  }

  static Map<String, dynamic> _tripToJson(TripModel trip) {
    return {
      'id': trip.id,
      'routeName': trip.routeName,
      'startTime': trip.startTime.toIso8601String(),
      'endTime': trip.endTime.toIso8601String(),
      'distanceKm': trip.distanceKm,
      'avgSpeedKmh': trip.avgSpeedKmh,
      'topSpeedKmh': trip.topSpeedKmh,
      'ecoScore': trip.ecoScore,
      'harshBrakes': trip.harshBrakes,
      'rapidAccels': trip.rapidAccels,
      'sharpTurns': trip.sharpTurns,
      'estimatedFuelLiters': trip.estimatedFuelLiters,
      'routePoints': trip.routePoints
          .map(
            (point) => {
              'latitude': point.latitude,
              'longitude': point.longitude,
            },
          )
          .toList(),
      'safetyEvents': trip.safetyEvents
          .map(
            (event) => {
              'title': event.title,
              'description': event.description,
              'latitude': event.latitude,
              'longitude': event.longitude,
            },
          )
          .toList(),
    };
  }

  static TripModel _tripFromJson(Map<String, dynamic> json) {
    final routePointsJson = json['routePoints'];
    final safetyEventsJson = json['safetyEvents'];

    final routePoints = routePointsJson is List
        ? routePointsJson.whereType<Map>().map((item) {
            final point = Map<String, dynamic>.from(item);
            return TripRoutePoint(
              latitude: (point['latitude'] as num).toDouble(),
              longitude: (point['longitude'] as num).toDouble(),
            );
          }).toList()
        : <TripRoutePoint>[];

    final safetyEvents = safetyEventsJson is List
        ? safetyEventsJson.whereType<Map>().map((item) {
            final event = Map<String, dynamic>.from(item);
            return TripSafetyEvent(
              title: event['title'] as String,
              description: event['description'] as String,
              latitude: (event['latitude'] as num).toDouble(),
              longitude: (event['longitude'] as num).toDouble(),
            );
          }).toList()
        : <TripSafetyEvent>[];

    return TripModel(
      id: json['id'] as String,
      routeName: json['routeName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      avgSpeedKmh: (json['avgSpeedKmh'] as num).toDouble(),
      topSpeedKmh: (json['topSpeedKmh'] as num).toDouble(),
      ecoScore: (json['ecoScore'] as num).toInt(),
      harshBrakes: (json['harshBrakes'] as num).toInt(),
      rapidAccels: (json['rapidAccels'] as num).toInt(),
      sharpTurns: (json['sharpTurns'] as num).toInt(),
      estimatedFuelLiters: (json['estimatedFuelLiters'] as num).toDouble(),
      routePoints: routePoints,
      safetyEvents: safetyEvents,
    );
  }

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

  /// Update the local demo profile after registration. Authentication and
  /// profile data are stored locally only; this app has no backend yet.
  static void registerDemoDriver({
    required String fullName,
    required String email,
    required String vehicleModel,
    required String licensePlate,
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) {
    currentDriver = DriverProfileModel(
      uid: 'DEMO-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      email: email,
      phone: emergencyContactPhone,
      vehicleModel: vehicleModel,
      licensePlate: licensePlate,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      overallSafetyScore: 100,
      totalLoggedKm: 0,
      totalTrips: 0,
      safetyTierBadge: 'New Driver (Demo)',
    );
    driverChanged.value++;
  }

  /// Update the in-session demo profile from the profile editor.
  static void updateDemoDriver({
    required String fullName,
    required String email,
    required String phone,
    required String vehicleModel,
    required String licensePlate,
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) {
    final driver = currentDriver;
    currentDriver = DriverProfileModel(
      uid: driver.uid,
      fullName: fullName,
      email: email,
      phone: phone,
      vehicleModel: vehicleModel,
      licensePlate: licensePlate,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      overallSafetyScore: driver.overallSafetyScore,
      totalLoggedKm: driver.totalLoggedKm,
      totalTrips: driver.totalTrips,
      safetyTierBadge: driver.safetyTierBadge,
    );
    driverChanged.value++;
  }

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
        primaryRiskReason: 'Reverse camber bend + wet surface aquaplaning risk',
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
        primaryRiskReason: 'Sudden deceleration tailbacks at toll approach',
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
        startTime: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        endTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
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
        startTime: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
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

    return <TripModel>[..._completedTrips, ...sampleTrips];
  }
}

/// Model for driver identity, vehicle credentials, and emergency dispatch contact.
class DriverProfileModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String vehicleModel;
  final String licensePlate;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final int overallSafetyScore; // 0 to 100
  final double totalLoggedKm;
  final int totalTrips;
  final String safetyTierBadge; // e.g. "Gold Driver", "Safe Commuter"

  DriverProfileModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.vehicleModel,
    required this.licensePlate,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.overallSafetyScore,
    required this.totalLoggedKm,
    required this.totalTrips,
    required this.safetyTierBadge,
  });
}

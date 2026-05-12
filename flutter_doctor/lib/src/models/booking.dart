import 'package:google_maps_flutter/google_maps_flutter.dart';

class BookingLocation {
  final double? latitude;
  final double? longitude;
  final String addressText;

  BookingLocation({
    this.latitude,
    this.longitude,
    this.addressText = '',
  });

  factory BookingLocation.fromJson(Map<String, dynamic> json) {
    return BookingLocation(
      latitude: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      longitude: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      addressText: json['addressText']?.toString() ?? '',
    );
  }

  LatLng? toLatLng() {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    return null;
  }

  bool get hasValidCoordinates => latitude != null && longitude != null;
}

class BookingTreatment {
  final String type;
  final String reason;
  final String details;
  final DateTime date;
  final String time;

  BookingTreatment({
    required this.type,
    required this.reason,
    required this.details,
    required this.date,
    required this.time,
  });

  factory BookingTreatment.fromJson(Map<String, dynamic> json) {
    return BookingTreatment(
      type: json['type']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      date: json['date'] != null ? DateTime.parse(json['date'].toString()) : DateTime.now(),
      time: json['time']?.toString() ?? '',
    );
  }
}

class BookingUser {
  final String id;
  final String name;
  final String email;
  final String phone;

  BookingUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory BookingUser.fromJson(Map<String, dynamic> json) {
    return BookingUser(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}

class DoctorBooking {
  final String id;
  final String userId;
  final String doctorId;
  final String visitType;
  final BookingTreatment treatment;
  final BookingLocation location;
  final String status;
  final DateTime? newTime;
  final DateTime createdAt;
  final BookingUser? user;

  DoctorBooking({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.visitType,
    required this.treatment,
    required this.location,
    required this.status,
    this.newTime,
    required this.createdAt,
    this.user,
  });

  factory DoctorBooking.fromJson(Map<String, dynamic> json) {
    return DoctorBooking(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      visitType: json['visitType']?.toString() ?? 'Clinic Visit',
      treatment: BookingTreatment.fromJson(
        json['treatment'] is Map ? json['treatment'] as Map<String, dynamic> : {},
      ),
      location: BookingLocation.fromJson(
        json['location'] is Map ? json['location'] as Map<String, dynamic> : {},
      ),
      status: json['status']?.toString() ?? 'PENDING',
      newTime: json['newTime'] != null ? DateTime.parse(json['newTime'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
      user: json['userId'] is Map ? BookingUser.fromJson(json['userId'] as Map<String, dynamic>) : null,
    );
  }
}

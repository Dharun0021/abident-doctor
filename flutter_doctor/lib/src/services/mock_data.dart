import 'package:flutter/material.dart';

enum AppointmentStatus { pending, confirmed, completed, cancelled }

class MockAppointment {
  const MockAppointment({
    required this.id,
    required this.patientName,
    required this.time,
    required this.status,
    this.notes = '',
  });

  final String id;
  final String patientName;
  final DateTime time;
  final AppointmentStatus status;
  final String notes;
}

class MockPatient {
  const MockPatient({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.dob,
    required this.lastVisit,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final DateTime dob;
  final DateTime? lastVisit;
}

class MockTreatment {
  const MockTreatment({
    required this.id,
    required this.date,
    required this.diagnosis,
    required this.notes,
    required this.medication,
    required this.nextVisit,
  });

  final String id;
  final DateTime date;
  final String diagnosis;
  final String notes;
  final String medication;
  final DateTime? nextVisit;
}

class MockNotificationItem {
  const MockNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.at,
    required this.read,
  });

  final String id;
  final String title;
  final String message;
  final DateTime at;
  final bool read;
}

class MockMapPatient {
  const MockMapPatient({
    required this.name,
    required this.address,
    required this.offset,
  });

  final String name;
  final String address;
  final Offset offset;
}

class MockRepository {
  MockRepository._();
  static final instance = MockRepository._();

  final doctorName = 'Dr. Sarah Mitchell';
  final clinicName = 'Abident Dental Studio';
  final clinicAddress = '221B Baker Street, London';

  late final List<MockAppointment> todayAppointments = [
    MockAppointment(
      id: 'a1',
      patientName: 'James Cole',
      time: DateTime.now().copyWith(hour: 9, minute: 30, second: 0, millisecond: 0),
      status: AppointmentStatus.confirmed,
    ),
    MockAppointment(
      id: 'a2',
      patientName: 'Emma Wilson',
      time: DateTime.now().copyWith(hour: 11, minute: 0, second: 0, millisecond: 0),
      status: AppointmentStatus.pending,
    ),
    MockAppointment(
      id: 'a3',
      patientName: 'Oliver Grant',
      time: DateTime.now().copyWith(hour: 14, minute: 15, second: 0, millisecond: 0),
      status: AppointmentStatus.confirmed,
    ),
  ];

  late final List<MockAppointment> upcomingAppointments = [
    MockAppointment(
      id: 'u1',
      patientName: 'Sophie Turner',
      time: DateTime.now().add(const Duration(days: 1, hours: 2)),
      status: AppointmentStatus.pending,
    ),
    MockAppointment(
      id: 'u2',
      patientName: 'Noah Patel',
      time: DateTime.now().add(const Duration(days: 2, hours: 4)),
      status: AppointmentStatus.confirmed,
    ),
  ];

  late final List<MockAppointment> pastAppointments = [
    MockAppointment(
      id: 'p1',
      patientName: 'Ava Chen',
      time: DateTime.now().subtract(const Duration(days: 1)),
      status: AppointmentStatus.completed,
    ),
    MockAppointment(
      id: 'p2',
      patientName: 'Liam Brooks',
      time: DateTime.now().subtract(const Duration(days: 3)),
      status: AppointmentStatus.cancelled,
    ),
  ];

  late final List<MockPatient> patients = [
    MockPatient(
      id: 'pt1',
      name: 'James Cole',
      phone: '+44 7700 900123',
      email: 'james.cole@email.com',
      dob: DateTime(1990, 4, 12),
      lastVisit: DateTime.now().subtract(const Duration(days: 14)),
    ),
    MockPatient(
      id: 'pt2',
      name: 'Emma Wilson',
      phone: '+44 7700 900456',
      email: 'emma.w@email.com',
      dob: DateTime(1988, 11, 2),
      lastVisit: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MockPatient(
      id: 'pt3',
      name: 'Oliver Grant',
      phone: '+44 7700 900789',
      email: 'oliver.grant@email.com',
      dob: DateTime(1995, 7, 21),
      lastVisit: null,
    ),
  ];

  late final Map<String, List<MockAppointment>> patientAppointments = {
    'pt1': [todayAppointments.first, pastAppointments.first],
    'pt2': [todayAppointments[1]],
    'pt3': [todayAppointments[2]],
  };

  late final Map<String, List<MockTreatment>> patientTreatments = {
    'pt1': [
      MockTreatment(
        id: 't1',
        date: DateTime.now().subtract(const Duration(days: 30)),
        diagnosis: 'Mild gingivitis',
        notes: 'Recommended improved flossing routine.',
        medication: 'Chlorhexidine rinse 0.12%',
        nextVisit: DateTime.now().add(const Duration(days: 60)),
      ),
      MockTreatment(
        id: 't2',
        date: DateTime.now().subtract(const Duration(days: 120)),
        diagnosis: 'Routine cleaning',
        notes: 'No caries detected.',
        medication: '—',
        nextVisit: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ],
    'pt2': [],
    'pt3': [],
  };

  late final List<MockNotificationItem> notifications = [
    MockNotificationItem(
      id: 'n1',
      title: 'New appointment request',
      message: 'Emma Wilson requested a slot tomorrow at 11:00.',
      at: DateTime.now().subtract(const Duration(minutes: 12)),
      read: false,
    ),
    MockNotificationItem(
      id: 'n2',
      title: 'Lab results ready',
      message: 'Crown fabrication for James Cole is ready for pickup.',
      at: DateTime.now().subtract(const Duration(hours: 2)),
      read: false,
    ),
    MockNotificationItem(
      id: 'n3',
      title: 'Weekly summary',
      message: 'You completed 42 appointments this week.',
      at: DateTime.now().subtract(const Duration(days: 1)),
      read: true,
    ),
  ];

  late final List<MockMapPatient> mapPatients = const [
    MockMapPatient(
      name: 'James Cole',
      address: '12 Regents Park Rd',
      offset: Offset(0.32, 0.38),
    ),
    MockMapPatient(
      name: 'Emma Wilson',
      address: '88 Camden High St',
      offset: Offset(0.58, 0.52),
    ),
    MockMapPatient(
      name: 'Oliver Grant',
      address: '5 Marylebone Ln',
      offset: Offset(0.44, 0.62),
    ),
  ];

  /// Simple series for mock charts (last 7 days).
  List<int> get appointmentsPerDay => [8, 12, 9, 14, 11, 10, 13];
  List<int> get completedPerDay => [7, 11, 8, 13, 10, 9, 12];
  List<int> get cancelledPerDay => [1, 1, 1, 1, 1, 1, 1];
}

extension DateTimeCopy on DateTime {
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
    );
  }
}

/// A single time slot, e.g. slot1: { startTime: "09:00", endTime: "10:00" }
class AvailabilitySlot {
  final String startTime;
  final String endTime;

  AvailabilitySlot({required this.startTime, required this.endTime});

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'startTime': startTime,
        'endTime': endTime,
      };
}

/// One document per doctor per date.
/// slots: { "slot1": AvailabilitySlot, "slot2": AvailabilitySlot, ... }
class Availability {
  final String? id;
  final String doctorId;
  final DateTime date;
  final Map<String, AvailabilitySlot> slots;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Availability({
    this.id,
    required this.doctorId,
    required this.date,
    required this.slots,
    this.isAvailable = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    // slots comes as a plain Map from MongoDB
    final rawSlots = json['slots'] as Map<String, dynamic>? ?? {};
    final parsedSlots = rawSlots.map(
      (key, value) => MapEntry(
        key,
        AvailabilitySlot.fromJson(value as Map<String, dynamic>),
      ),
    );

    return Availability(
      id: json['_id'] as String?,
      doctorId: json['doctorId'] is String
          ? json['doctorId'] as String
          : (json['doctorId'] as Map<String, dynamic>)['_id'] as String,
      date: DateTime.parse(json['date'] as String),
      slots: parsedSlots,
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'doctorId': doctorId,
        'date': date.toIso8601String(),
        'slots': slots.map((k, v) => MapEntry(k, v.toJson())),
        'isAvailable': isAvailable,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  /// Returns slots sorted by key: slot1, slot2, slot3 ...
  List<MapEntry<String, AvailabilitySlot>> get sortedSlots {
    final entries = slots.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }
}

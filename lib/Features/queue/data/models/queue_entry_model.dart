import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum QueueStatus { waiting, inProgress, done, cancelled }

class QueueEntry extends Equatable {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final QueueStatus status;
  final DateTime timestamp;
  final int? queueNumber; // Optional queue number for ordering
  final DateTime? joinedAt; // When patient joined the queue
  final DateTime? updatedAt; // Last status update time

  const QueueEntry({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.status,
    required this.timestamp,
    this.queueNumber,
    this.joinedAt,
    this.updatedAt,
  });

  factory QueueEntry.fromJson(Map<String, dynamic> json) {
    // Handle timestamp field which could be Timestamp, String, or DateTime
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        try {
          return DateTime.parse(timestamp as String);
        } catch (e) {
          print('Warning: Could not parse timestamp string: $timestamp');
          return DateTime.now();
        }
      } else if (timestamp is DateTime) {
        return timestamp;
      } else {
        // Fallback to current time if timestamp is invalid
        return DateTime.now();
      }
    }

    // Parse required fields
    final id = json['id'] as String? ?? '';
    final patientId = json['patientId'] as String? ?? '';
    final patientName = json['patientName'] as String? ?? '';
    final doctorId = json['doctorId'] as String? ?? '';

    // Parse status with fallback
    QueueStatus status;
    try {
      status = QueueStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => QueueStatus.waiting,
      );
    } catch (e) {
      status = QueueStatus.waiting;
    }

    // Parse timestamps
    final timestamp = parseTimestamp(json['timestamp'] ?? json['createdAt']);
    final joinedAt = json['joinedAt'] != null
        ? parseTimestamp(json['joinedAt'])
        : timestamp;
    final updatedAt = json['updatedAt'] != null
        ? parseTimestamp(json['updatedAt'])
        : timestamp;

    // Parse queue number
    final queueNumber = json['queueNumber'] as int?;

    return QueueEntry(
      id: id,
      patientId: patientId,
      patientName: patientName,
      doctorId: doctorId,
      status: status,
      timestamp: timestamp,
      queueNumber: queueNumber,
      joinedAt: joinedAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'queueNumber': queueNumber,
      'joinedAt': joinedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    patientId,
    patientName,
    doctorId,
    status,
    timestamp,
    queueNumber,
    joinedAt,
    updatedAt,
  ];

  QueueEntry copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? doctorId,
    QueueStatus? status,
    DateTime? timestamp,
    int? queueNumber,
    DateTime? joinedAt,
    DateTime? updatedAt,
  }) {
    return QueueEntry(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      queueNumber: queueNumber ?? this.queueNumber,
      joinedAt: joinedAt ?? this.joinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case QueueStatus.waiting:
        return 'في الانتظار';
      case QueueStatus.inProgress:
        return 'قيد المعالجة';
      case QueueStatus.done:
        return 'مكتمل';
      case QueueStatus.cancelled:
        return 'ملغي';
    }
  }

  bool get isActive =>
      status == QueueStatus.waiting || status == QueueStatus.inProgress;

  /// Get display queue number (fallback to position if not set)
  int get displayQueueNumber => queueNumber ?? 0;

  /// Check if this entry has valid data
  bool get isValid =>
      id.isNotEmpty &&
      patientId.isNotEmpty &&
      patientName.isNotEmpty &&
      doctorId.isNotEmpty;
}

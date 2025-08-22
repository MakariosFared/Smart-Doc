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

  const QueueEntry({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.status,
    required this.timestamp,
  });

  factory QueueEntry.fromJson(Map<String, dynamic> json) {
    // Handle timestamp field which could be Timestamp, String, or DateTime
    DateTime timestamp;
    if (json['timestamp'] is Timestamp) {
      timestamp = (json['timestamp'] as Timestamp).toDate();
    } else if (json['timestamp'] is String) {
      timestamp = DateTime.parse(json['timestamp'] as String);
    } else if (json['timestamp'] is DateTime) {
      timestamp = json['timestamp'] as DateTime;
    } else {
      // Fallback to current time if timestamp is invalid
      timestamp = DateTime.now();
    }

    return QueueEntry(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      doctorId: json['doctorId'] as String,
      status: QueueStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => QueueStatus.waiting,
      ),
      timestamp: timestamp,
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
      // Add additional fields that might be used by the doctor repository
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
  ];

  QueueEntry copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? doctorId,
    QueueStatus? status,
    DateTime? timestamp,
  }) {
    return QueueEntry(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
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
}

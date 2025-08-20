import 'package:equatable/equatable.dart';

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
    return QueueEntry(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      doctorId: json['doctorId'] as String,
      status: QueueStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => QueueStatus.waiting,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
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

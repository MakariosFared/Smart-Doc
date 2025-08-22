import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../queue/data/models/queue_entry_model.dart';
import '../../../patient/data/models/survey_model.dart';

class DoctorQueuePatient extends Equatable {
  final String id;
  final String patientId;
  final String patientName;
  final int queueNumber;
  final QueueStatus status;
  final DateTime joinedAt;
  final Survey? questionnaire;
  final String? currentSymptoms;
  final String? medicalHistory;

  const DoctorQueuePatient({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.queueNumber,
    required this.status,
    required this.joinedAt,
    this.questionnaire,
    this.currentSymptoms,
    this.medicalHistory,
  });

  factory DoctorQueuePatient.fromQueueEntry(
    QueueEntry entry,
    int queueNumber, {
    Survey? questionnaire,
    String? currentSymptoms,
    String? medicalHistory,
  }) {
    return DoctorQueuePatient(
      id: entry.id,
      patientId: entry.patientId,
      patientName: entry.patientName,
      queueNumber: queueNumber,
      status: entry.status,
      joinedAt: entry.timestamp,
      questionnaire: questionnaire,
      currentSymptoms: currentSymptoms,
      medicalHistory: medicalHistory,
    );
  }

  DoctorQueuePatient copyWith({
    String? id,
    String? patientId,
    String? patientName,
    int? queueNumber,
    QueueStatus? status,
    DateTime? joinedAt,
    Survey? questionnaire,
    String? currentSymptoms,
    String? medicalHistory,
  }) {
    return DoctorQueuePatient(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      queueNumber: queueNumber ?? this.queueNumber,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      questionnaire: questionnaire ?? this.questionnaire,
      currentSymptoms: currentSymptoms ?? this.currentSymptoms,
      medicalHistory: medicalHistory ?? this.medicalHistory,
    );
  }

  @override
  List<Object?> get props => [
    id,
    patientId,
    patientName,
    queueNumber,
    status,
    joinedAt,
    questionnaire,
    currentSymptoms,
    medicalHistory,
  ];

  bool get isWaiting => status == QueueStatus.waiting;
  bool get isInProgress => status == QueueStatus.inProgress;
  bool get isDone => status == QueueStatus.done;
  bool get isCancelled => status == QueueStatus.cancelled;

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

  Color get statusColor {
    switch (status) {
      case QueueStatus.waiting:
        return Colors.orange;
      case QueueStatus.inProgress:
        return Colors.blue;
      case QueueStatus.done:
        return Colors.green;
      case QueueStatus.cancelled:
        return Colors.red;
    }
  }
}

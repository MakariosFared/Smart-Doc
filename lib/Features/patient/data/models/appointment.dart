import 'package:equatable/equatable.dart';

enum AppointmentStatus { pending, confirmed, completed, cancelled }

class Appointment extends Equatable {
  final String id;
  final String patientId;
  final String doctorId;
  final String timeSlot;
  final DateTime appointmentDate;
  final AppointmentStatus status;
  final String? notes;
  final DateTime createdAt;
  final Map<String, dynamic>? questionnaireAnswers;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.timeSlot,
    required this.appointmentDate,
    this.status = AppointmentStatus.pending,
    this.notes,
    required this.createdAt,
    this.questionnaireAnswers,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      doctorId: json['doctorId'] as String,
      timeSlot: json['timeSlot'] as String,
      appointmentDate: DateTime.parse(json['appointmentDate'] as String),
      status: AppointmentStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      questionnaireAnswers:
          json['questionnaireAnswers'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'timeSlot': timeSlot,
      'appointmentDate': appointmentDate.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'questionnaireAnswers': questionnaireAnswers,
    };
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? timeSlot,
    DateTime? appointmentDate,
    AppointmentStatus? status,
    String? notes,
    DateTime? createdAt,
    Map<String, dynamic>? questionnaireAnswers,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      timeSlot: timeSlot ?? this.timeSlot,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      questionnaireAnswers: questionnaireAnswers ?? this.questionnaireAnswers,
    );
  }

  @override
  List<Object?> get props => [
    id,
    patientId,
    doctorId,
    timeSlot,
    appointmentDate,
    status,
    notes,
    createdAt,
    questionnaireAnswers,
  ];
}

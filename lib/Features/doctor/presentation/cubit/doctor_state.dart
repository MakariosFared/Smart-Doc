import 'package:equatable/equatable.dart';
import '../../data/models/doctor_queue_patient.dart';
import '../../../patient/data/models/survey_model.dart';

abstract class DoctorState extends Equatable {
  const DoctorState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DoctorInitial extends DoctorState {
  const DoctorInitial();
}

/// Loading state
class DoctorLoading extends DoctorState {
  const DoctorLoading();
}

/// Queue loaded successfully
class QueueLoaded extends DoctorState {
  final List<DoctorQueuePatient> patients;
  final DoctorQueuePatient? currentPatient;
  final Map<String, dynamic> statistics;

  const QueueLoaded({
    required this.patients,
    this.currentPatient,
    required this.statistics,
  });

  @override
  List<Object?> get props => [patients, currentPatient, statistics];
}

/// Patient action in progress
class PatientActionInProgress extends DoctorState {
  final String patientId;
  final String action;

  const PatientActionInProgress({
    required this.patientId,
    required this.action,
  });

  @override
  List<Object?> get props => [patientId, action];
}

/// Patient action completed successfully
class PatientActionCompleted extends DoctorState {
  final String patientId;
  final String action;
  final String message;

  const PatientActionCompleted({
    required this.patientId,
    required this.action,
    required this.message,
  });

  @override
  List<Object?> get props => [patientId, action, message];
}

/// Patient questionnaire loaded
class PatientQuestionnaireLoaded extends DoctorState {
  final DoctorQueuePatient patient;
  final Survey questionnaire;
  final Map<String, dynamic>? medicalHistory;

  const PatientQuestionnaireLoaded({
    required this.patient,
    required this.questionnaire,
    this.medicalHistory,
  });

  @override
  List<Object?> get props => [patient, questionnaire, medicalHistory];
}

/// Doctor error state
class DoctorError extends DoctorState {
  final String message;
  final String? code;

  const DoctorError(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Queue empty state
class QueueEmpty extends DoctorState {
  final String message;

  const QueueEmpty(this.message);

  @override
  List<Object?> get props => [message];
}

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_doc/Core/di/app_dependency_injection.dart';
import '../../data/repositories/doctor_repository.dart';
import '../../data/models/doctor_queue_patient.dart';
import '../../../patient/data/models/survey_model.dart';
import 'doctor_state.dart';

class DoctorCubit extends Cubit<DoctorState> {
  final DoctorRepository _doctorRepository;
  StreamSubscription<List<DoctorQueuePatient>>? _queueSubscription;
  StreamSubscription<Map<String, dynamic>>? _statsSubscription;

  DoctorCubit({DoctorRepository? doctorRepository})
    : _doctorRepository =
          doctorRepository ?? AppDependencyInjection.doctorRepository,
      super(const DoctorInitial());

  @override
  Future<void> close() {
    _queueSubscription?.cancel();
    _statsSubscription?.cancel();
    return super.close();
  }

  /// Start listening to doctor's queue updates
  void startListeningToQueue(String doctorId) {
    emit(const DoctorLoading());

    _queueSubscription = _doctorRepository
        .getDoctorQueueStream(doctorId)
        .listen(
          (patients) async {
            try {
              if (patients.isEmpty) {
                emit(const QueueEmpty('لا يوجد مرضى في الطابور حالياً'));
                return;
              }

              // Get current patient being served
              final currentPatient = await _doctorRepository.getCurrentPatient(
                doctorId,
              );

              // Get queue statistics
              final statistics = await _doctorRepository.getQueueStatistics(
                doctorId,
              );

              emit(
                QueueLoaded(
                  patients: patients,
                  currentPatient: currentPatient,
                  statistics: statistics,
                ),
              );
            } catch (e) {
              print('⚠️ Error in queue stream processing: $e');
              // Emit error state but continue listening to stream
              emit(DoctorError('فشل في معالجة بيانات الطابور: $e'));
            }
          },
          onError: (error) {
            print('❌ Error in queue stream: $error');
            emit(DoctorError('فشل في تحميل الطابور: $error'));
          },
        );
  }

  /// Start serving a patient
  Future<void> startServingPatient(String doctorId, String patientId) async {
    try {
      emit(
        PatientActionInProgress(patientId: patientId, action: 'start_serving'),
      );

      await _doctorRepository.startServingPatient(doctorId, patientId);

      emit(
        PatientActionCompleted(
          patientId: patientId,
          action: 'start_serving',
          message: 'تم بدء خدمة المريض بنجاح',
        ),
      );
    } catch (e) {
      emit(DoctorError('فشل في بدء خدمة المريض: $e'));
    }
  }

  /// Complete serving a patient
  Future<void> completePatient(String doctorId, String patientId) async {
    try {
      emit(PatientActionInProgress(patientId: patientId, action: 'complete'));

      await _doctorRepository.completePatient(doctorId, patientId);

      emit(
        PatientActionCompleted(
          patientId: patientId,
          action: 'complete',
          message: 'تم إكمال خدمة المريض بنجاح',
        ),
      );
    } catch (e) {
      emit(DoctorError('فشل في إكمال خدمة المريض: $e'));
    }
  }

  /// Skip a patient
  Future<void> skipPatient(String doctorId, String patientId) async {
    try {
      emit(PatientActionInProgress(patientId: patientId, action: 'skip'));

      await _doctorRepository.skipPatient(doctorId, patientId);

      emit(
        PatientActionCompleted(
          patientId: patientId,
          action: 'skip',
          message: 'تم تخطي المريض بنجاح',
        ),
      );
    } catch (e) {
      emit(DoctorError('فشل في تخطي المريض: $e'));
    }
  }

  /// Load patient questionnaire and medical history
  Future<void> loadPatientDetails(
    String patientId,
    String doctorId,
    DoctorQueuePatient patient,
  ) async {
    try {
      emit(const DoctorLoading());

      // Load questionnaire and medical history in parallel
      final results = await Future.wait([
        _doctorRepository.getPatientQuestionnaire(patientId, doctorId),
        _doctorRepository.getPatientMedicalHistory(patientId),
      ]);

      final questionnaire = results[0] as Survey?;
      final medicalHistory = results[1] as Map<String, dynamic>?;

      if (questionnaire == null) {
        emit(DoctorError('لم يتم العثور على استبيان للمريض'));
        return;
      }

      emit(
        PatientQuestionnaireLoaded(
          patient: patient,
          questionnaire: questionnaire,
          medicalHistory: medicalHistory,
        ),
      );
    } catch (e) {
      emit(DoctorError('فشل في تحميل تفاصيل المريض: $e'));
    }
  }

  /// Update patient status
  Future<void> updatePatientStatus(
    String doctorId,
    String patientId,
    String status,
  ) async {
    try {
      emit(
        PatientActionInProgress(patientId: patientId, action: 'update_status'),
      );

      await _doctorRepository.updatePatientStatus(doctorId, patientId, status);

      emit(
        PatientActionCompleted(
          patientId: patientId,
          action: 'update_status',
          message: 'تم تحديث حالة المريض بنجاح',
        ),
      );
    } catch (e) {
      emit(DoctorError('فشل في تحديث حالة المريض: $e'));
    }
  }

  /// Get next patient in queue
  DoctorQueuePatient? getNextPatient() {
    if (state is QueueLoaded) {
      final currentState = state as QueueLoaded;
      final waitingPatients = currentState.patients
          .where((patient) => patient.isWaiting)
          .toList();

      if (waitingPatients.isNotEmpty) {
        return waitingPatients.first;
      }
    }
    return null;
  }

  /// Get current patient being served
  DoctorQueuePatient? getCurrentPatient() {
    if (state is QueueLoaded) {
      final currentState = state as QueueLoaded;
      return currentState.currentPatient;
    }
    return null;
  }

  /// Get queue statistics
  Map<String, dynamic>? getQueueStatistics() {
    if (state is QueueLoaded) {
      final currentState = state as QueueLoaded;
      return currentState.statistics;
    }
    return null;
  }

  /// Clear error state
  void clearError() {
    if (state is DoctorError) {
      // Reload the queue if we have a doctor ID
      // This would need to be passed from the UI
    }
  }

  /// Stop listening to queue updates
  void stopListeningToQueue() {
    _queueSubscription?.cancel();
    _statsSubscription?.cancel();
    emit(const DoctorInitial());
  }
}

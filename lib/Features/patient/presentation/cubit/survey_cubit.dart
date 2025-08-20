import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_doc/Core/di/app_dependency_injection.dart';
import '../../data/repositories/survey_repository.dart';
import '../../data/models/survey_model.dart';
import 'survey_state.dart';

class SurveyCubit extends Cubit<SurveyState> {
  final SurveyRepository _surveyRepository;

  SurveyCubit({SurveyRepository? surveyRepository})
    : _surveyRepository =
          surveyRepository ?? AppDependencyInjection.surveyRepository,
      super(const SurveyInitial());

  /// Submit survey response
  Future<void> submitSurvey({
    required String patientId,
    required String doctorId,
    required SurveyData surveyData,
  }) async {
    try {
      emit(const SurveySubmitting());

      final survey = await _surveyRepository.submitSurvey(
        patientId: patientId,
        doctorId: doctorId,
        surveyData: surveyData,
      );

      emit(SurveySubmitted(survey));
    } catch (e) {
      emit(SurveyFailure('فشل في إرسال الاستبيان: $e'));
    }
  }

  /// Check if patient has completed survey for a specific doctor
  Future<void> checkSurveyCompletion({
    required String patientId,
    required String doctorId,
  }) async {
    try {
      emit(const SurveyChecking());

      final hasCompleted = await _surveyRepository.hasCompletedSurvey(
        patientId: patientId,
        doctorId: doctorId,
      );

      if (hasCompleted) {
        final survey = await _surveyRepository.getSurveyResponse(
          patientId: patientId,
          doctorId: doctorId,
        );
        emit(SurveyAlreadyCompleted(survey!));
      } else {
        emit(const SurveyNotCompleted());
      }
    } catch (e) {
      emit(SurveyFailure('فشل في التحقق من الاستبيان: $e'));
    }
  }

  /// Get survey response for a specific patient and doctor
  Future<void> getSurveyResponse({
    required String patientId,
    required String doctorId,
  }) async {
    try {
      emit(const SurveyLoading());

      final survey = await _surveyRepository.getSurveyResponse(
        patientId: patientId,
        doctorId: doctorId,
      );

      if (survey != null) {
        emit(SurveyLoaded(survey));
      } else {
        emit(const SurveyNotFound());
      }
    } catch (e) {
      emit(SurveyFailure('فشل في جلب الاستبيان: $e'));
    }
  }

  /// Get all surveys for a patient
  Future<void> getPatientSurveys(String patientId) async {
    try {
      emit(const SurveyLoading());

      final surveys = await _surveyRepository.getPatientSurveys(patientId);
      emit(PatientSurveysLoaded(surveys));
    } catch (e) {
      emit(SurveyFailure('فشل في جلب استبيانات المريض: $e'));
    }
  }

  /// Get all surveys for a doctor
  Future<void> getDoctorSurveys(String doctorId) async {
    try {
      emit(const SurveyLoading());

      final surveys = await _surveyRepository.getDoctorSurveys(doctorId);
      emit(DoctorSurveysLoaded(surveys));
    } catch (e) {
      emit(SurveyFailure('فشل في جلب استبيانات الطبيب: $e'));
    }
  }

  /// Reset to initial state
  void reset() {
    emit(const SurveyInitial());
  }

  /// Clear error state
  void clearError() {
    if (state is SurveyFailure) {
      emit(const SurveyInitial());
    }
  }
}

import 'package:equatable/equatable.dart';
import '../../data/models/survey.dart';

abstract class SurveyState extends Equatable {
  const SurveyState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SurveyInitial extends SurveyState {
  const SurveyInitial();
}

/// Loading survey
class SurveyLoading extends SurveyState {
  const SurveyLoading();
}

/// Survey loaded successfully
class SurveyLoaded extends SurveyState {
  final Survey survey;

  const SurveyLoaded(this.survey);

  @override
  List<Object?> get props => [survey];
}

/// Survey not found
class SurveyNotFound extends SurveyState {
  const SurveyNotFound();
}

/// Survey already completed
class SurveyAlreadyCompleted extends SurveyState {
  final Survey survey;

  const SurveyAlreadyCompleted(this.survey);

  @override
  List<Object?> get props => [survey];
}

/// Survey not completed
class SurveyNotCompleted extends SurveyState {
  const SurveyNotCompleted();
}

/// Submitting survey
class SurveySubmitting extends SurveyState {
  const SurveySubmitting();
}

/// Survey submitted successfully
class SurveySubmitted extends SurveyState {
  final Survey survey;

  const SurveySubmitted(this.survey);

  @override
  List<Object?> get props => [survey];
}

/// Checking survey completion
class SurveyChecking extends SurveyState {
  const SurveyChecking();
}

/// Patient surveys loaded successfully
class PatientSurveysLoaded extends SurveyState {
  final List<Survey> surveys;

  const PatientSurveysLoaded(this.surveys);

  @override
  List<Object?> get props => [surveys];
}

/// Doctor surveys loaded successfully
class DoctorSurveysLoaded extends SurveyState {
  final List<Survey> surveys;

  const DoctorSurveysLoaded(this.surveys);

  @override
  List<Object?> get props => [surveys];
}

/// Survey failure
class SurveyFailure extends SurveyState {
  final String message;

  const SurveyFailure(this.message);

  @override
  List<Object?> get props => [message];
}

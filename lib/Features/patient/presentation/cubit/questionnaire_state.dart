import 'package:equatable/equatable.dart';
import '../../data/models/questionnaire.dart';

abstract class QuestionnaireState extends Equatable {
  const QuestionnaireState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class QuestionnaireInitial extends QuestionnaireState {
  const QuestionnaireInitial();
}

/// Loading questionnaire
class QuestionnaireLoading extends QuestionnaireState {
  const QuestionnaireLoading();
}

/// Questionnaire loaded successfully
class QuestionnaireLoaded extends QuestionnaireState {
  final Questionnaire questionnaire;
  final Map<String, dynamic> answers;

  const QuestionnaireLoaded(this.questionnaire, {this.answers = const {}});

  @override
  List<Object?> get props => [questionnaire, answers];

  QuestionnaireLoaded copyWith({
    Questionnaire? questionnaire,
    Map<String, dynamic>? answers,
  }) {
    return QuestionnaireLoaded(
      questionnaire ?? this.questionnaire,
      answers: answers ?? this.answers,
    );
  }
}

/// Submitting questionnaire
class QuestionnaireSubmitting extends QuestionnaireState {
  const QuestionnaireSubmitting();
}

/// Questionnaire submitted successfully
class QuestionnaireSubmitted extends QuestionnaireState {
  final QuestionnaireResponse response;

  const QuestionnaireSubmitted(this.response);

  @override
  List<Object?> get props => [response];
}

/// Questionnaire failure
class QuestionnaireFailure extends QuestionnaireState {
  final String message;

  const QuestionnaireFailure(this.message);

  @override
  List<Object?> get props => [message];
}

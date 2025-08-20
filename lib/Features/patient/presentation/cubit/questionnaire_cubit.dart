import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_doc/Core/di/app_dependency_injection.dart';
import '../../data/repositories/questionnaire_repository.dart';
import 'questionnaire_state.dart';

class QuestionnaireCubit extends Cubit<QuestionnaireState> {
  final QuestionnaireRepository _questionnaireRepository;

  // Public getter for the repository
  QuestionnaireRepository get questionnaireRepository =>
      _questionnaireRepository;

  QuestionnaireCubit({QuestionnaireRepository? questionnaireRepository})
    : _questionnaireRepository =
          questionnaireRepository ??
          AppDependencyInjection.questionnaireRepository,
      super(const QuestionnaireInitial());

  /// Load the medical questionnaire
  Future<void> loadQuestionnaire() async {
    try {
      emit(const QuestionnaireLoading());
      final questionnaire = await _questionnaireRepository
          .getMedicalQuestionnaire();
      emit(QuestionnaireLoaded(questionnaire));
    } catch (e) {
      emit(QuestionnaireFailure('فشل في تحميل الاستبيان: $e'));
    }
  }

  /// Load questionnaire summary for a patient
  Future<void> loadQuestionnaireSummary(String patientId) async {
    try {
      emit(const QuestionnaireLoading());

      // Load both the questionnaire template and the latest response
      final questionnaire = await _questionnaireRepository
          .getMedicalQuestionnaire();
      final response = await _questionnaireRepository
          .getLatestQuestionnaireResponse(patientId);

      if (response != null) {
        emit(QuestionnaireSummaryLoaded(response, questionnaire));
      } else {
        emit(const QuestionnaireFailure('لم يتم العثور على استبيان مكتمل'));
      }
    } catch (e) {
      emit(QuestionnaireFailure('فشل في تحميل ملخص الاستبيان: $e'));
    }
  }

  /// Update answer for a specific question
  void updateAnswer(String questionId, dynamic answer) {
    if (state is QuestionnaireLoaded) {
      final currentState = state as QuestionnaireLoaded;
      final updatedAnswers = Map<String, dynamic>.from(currentState.answers);

      if (answer is List) {
        // Handle checkbox questions
        updatedAnswers[questionId] = answer;
      } else {
        // Handle radio and text questions
        updatedAnswers[questionId] = answer;
      }

      emit(
        QuestionnaireLoaded(
          currentState.questionnaire,
          answers: updatedAnswers,
        ),
      );
    }
  }

  /// Check if all required questions are answered
  bool get isQuestionnaireComplete {
    if (state is QuestionnaireLoaded) {
      final currentState = state as QuestionnaireLoaded;
      final questionnaire = currentState.questionnaire;
      final answers = currentState.answers;

      for (final question in questionnaire.questions) {
        if (question.isRequired) {
          if (!answers.containsKey(question.id) ||
              answers[question.id] == null ||
              (answers[question.id] is String &&
                  answers[question.id].toString().trim().isEmpty) ||
              (answers[question.id] is List && answers[question.id].isEmpty)) {
            return false;
          }
        }
      }
      return true;
    }
    return false;
  }

  /// Get current answers
  Map<String, dynamic> get currentAnswers {
    if (state is QuestionnaireLoaded) {
      final currentState = state as QuestionnaireLoaded;
      return Map<String, dynamic>.from(currentState.answers);
    }
    return {};
  }

  /// Submit questionnaire
  Future<void> submitQuestionnaire(String patientId) async {
    if (!isQuestionnaireComplete) {
      emit(
        const QuestionnaireFailure('يرجى الإجابة على جميع الأسئلة المطلوبة'),
      );
      return;
    }

    try {
      emit(const QuestionnaireSubmitting());

      final response = await _questionnaireRepository.submitQuestionnaire(
        patientId: patientId,
        answers: currentAnswers,
      );

      emit(QuestionnaireSubmitted(response));
    } catch (e) {
      emit(QuestionnaireFailure('فشل في إرسال الاستبيان: $e'));
    }
  }

  /// Reset questionnaire
  void resetQuestionnaire() {
    if (state is QuestionnaireLoaded) {
      final currentState = state as QuestionnaireLoaded;
      emit(QuestionnaireLoaded(currentState.questionnaire, answers: {}));
    }
  }

  /// Clear error state
  void clearError() {
    if (state is QuestionnaireFailure) {
      if (state is QuestionnaireLoaded) {
        final currentState = state as QuestionnaireLoaded;
        emit(
          QuestionnaireLoaded(
            currentState.questionnaire,
            answers: currentState.answers,
          ),
        );
      } else {
        emit(const QuestionnaireInitial());
      }
    }
  }

  /// Get questionnaire progress (0.0 to 1.0)
  double get progress {
    if (state is QuestionnaireLoaded) {
      final currentState = state as QuestionnaireLoaded;
      final questionnaire = currentState.questionnaire;
      final answers = currentState.answers;

      int answeredQuestions = 0;
      int totalQuestions = questionnaire.questions.length;

      for (final question in questionnaire.questions) {
        if (answers.containsKey(question.id) &&
                answers[question.id] != null &&
                (answers[question.id] is String &&
                    answers[question.id].toString().trim().isNotEmpty) ||
            (answers[question.id] is List && answers[question.id].isNotEmpty)) {
          answeredQuestions++;
        }
      }

      return totalQuestions > 0 ? answeredQuestions / totalQuestions : 0.0;
    }
    return 0.0;
  }
}

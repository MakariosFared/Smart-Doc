import 'package:equatable/equatable.dart';

enum QuestionType { radio, checkbox, text, number }

class Question extends Equatable {
  final String id;
  final String text;
  final QuestionType type;
  final List<String>? options;
  final bool isRequired;
  final String? hint;
  final int? maxLines;

  const Question({
    required this.id,
    required this.text,
    required this.type,
    this.options,
    this.isRequired = true,
    this.hint,
    this.maxLines,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      type: QuestionType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => QuestionType.text,
      ),
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : null,
      isRequired: json['isRequired'] as bool? ?? true,
      hint: json['hint'] as String?,
      maxLines: json['maxLines'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type.name,
      'options': options,
      'isRequired': isRequired,
      'hint': hint,
      'maxLines': maxLines,
    };
  }

  @override
  List<Object?> get props => [
    id,
    text,
    type,
    options,
    isRequired,
    hint,
    maxLines,
  ];
}

class Questionnaire extends Equatable {
  final String id;
  final String title;
  final String description;
  final List<Question> questions;
  final DateTime createdAt;

  const Questionnaire({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    required this.createdAt,
  });

  factory Questionnaire.fromJson(Map<String, dynamic> json) {
    return Questionnaire(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, description, questions, createdAt];
}

class QuestionnaireResponse extends Equatable {
  final String id;
  final String questionnaireId;
  final String patientId;
  final Map<String, dynamic> answers;
  final DateTime submittedAt;

  const QuestionnaireResponse({
    required this.id,
    required this.questionnaireId,
    required this.patientId,
    required this.answers,
    required this.submittedAt,
  });

  factory QuestionnaireResponse.fromJson(Map<String, dynamic> json) {
    return QuestionnaireResponse(
      id: json['id'] as String,
      questionnaireId: json['questionnaireId'] as String,
      patientId: json['patientId'] as String,
      answers: Map<String, dynamic>.from(json['answers'] as Map),
      submittedAt: DateTime.parse(json['submittedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionnaireId': questionnaireId,
      'patientId': patientId,
      'answers': answers,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    questionnaireId,
    patientId,
    answers,
    submittedAt,
  ];
}

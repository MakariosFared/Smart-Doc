import '../../domain/repositories/questionnaire_repository.dart';
import '../models/questionnaire.dart';

class MockQuestionnaireRepositoryImpl implements QuestionnaireRepository {
  // Mock medical questionnaire
  final Questionnaire _mockQuestionnaire = Questionnaire(
    id: 'medical_questionnaire_001',
    title: 'الاستبيان الطبي',
    description:
        'يرجى الإجابة على جميع الأسئلة بدقة لمساعدتنا في تقديم أفضل رعاية طبية',
    questions: const [
      Question(
        id: 'q1',
        text: 'الجنس',
        type: QuestionType.radio,
        options: ['ذكر', 'أنثى'],
        isRequired: true,
      ),
      Question(
        id: 'q2',
        text: 'الفئة العمرية',
        type: QuestionType.radio,
        options: ['18-25', '26-35', '36-45', '46-55', '56+'],
        isRequired: true,
      ),
      Question(
        id: 'q3',
        text: 'هل لديك حساسية معروفة؟',
        type: QuestionType.text,
        hint: 'مثال: حساسية من البنسلين، الغبار، إلخ',
        isRequired: false,
        maxLines: 3,
      ),
      Question(
        id: 'q4',
        text: 'هل تتناول أي أدوية حالياً؟',
        type: QuestionType.text,
        hint: 'اذكر أسماء الأدوية والجرعات',
        isRequired: false,
        maxLines: 3,
      ),
      Question(
        id: 'q5',
        text: 'هل لديك أمراض مزمنة؟',
        type: QuestionType.text,
        hint: 'مثال: السكري، الضغط، الربو، إلخ',
        isRequired: false,
        maxLines: 3,
      ),
      Question(
        id: 'q6',
        text: 'اختر جميع الأعراض التي تنطبق عليك:',
        type: QuestionType.checkbox,
        options: [
          'حمى',
          'صداع',
          'إرهاق',
          'فقدان الشهية',
          'ألم في العضلات',
          'سعال',
          'ضيق في التنفس',
          'غثيان',
          'قيء',
          'إسهال',
        ],
        isRequired: false,
      ),
      Question(
        id: 'q7',
        text: 'هل تدخن؟',
        type: QuestionType.radio,
        options: ['نعم', 'لا', 'أقلعت عن التدخين'],
        isRequired: true,
      ),
      Question(
        id: 'q8',
        text: 'هل تشرب الكحول؟',
        type: QuestionType.radio,
        options: ['نعم', 'لا', 'أحياناً'],
        isRequired: true,
      ),
      Question(
        id: 'q9',
        text: 'هل تمارس الرياضة بانتظام؟',
        type: QuestionType.radio,
        options: ['نعم', 'لا', 'أحياناً'],
        isRequired: true,
      ),
      Question(
        id: 'q10',
        text: 'هل لديك تاريخ عائلي لأمراض معينة؟',
        type: QuestionType.text,
        hint: 'اذكر الأمراض التي تنتشر في عائلتك',
        isRequired: false,
        maxLines: 3,
      ),
    ],
    createdAt: DateTime.now(),
  );

  final List<QuestionnaireResponse> _mockResponses = [];

  @override
  Future<Questionnaire> getMedicalQuestionnaire() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockQuestionnaire;
  }

  @override
  Future<QuestionnaireResponse> submitQuestionnaire({
    required String patientId,
    required Map<String, dynamic> answers,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final response = QuestionnaireResponse(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      questionnaireId: _mockQuestionnaire.id,
      patientId: patientId,
      answers: answers,
      submittedAt: DateTime.now(),
    );

    _mockResponses.add(response);
    return response;
  }

  @override
  Future<QuestionnaireResponse?> getQuestionnaireResponse(
    String responseId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      return _mockResponses.firstWhere((response) => response.id == responseId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<QuestionnaireResponse>> getPatientQuestionnaireResponses(
    String patientId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockResponses
        .where((response) => response.patientId == patientId)
        .toList();
  }
}

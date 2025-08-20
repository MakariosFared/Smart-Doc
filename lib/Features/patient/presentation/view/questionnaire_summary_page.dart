import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_doc/Features/patient/data/models/questionnaire.dart';
import '../../../auth/presentation/view/widgets/common_app_bar.dart';
import '../../../auth/presentation/view/widgets/custom_button.dart';
import '../cubit/questionnaire_cubit.dart';
import '../cubit/questionnaire_state.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class QuestionnaireSummaryPage extends StatefulWidget {
  final String doctorId;
  final String timeSlot;
  final DateTime appointmentDate;
  final bool isNewBooking;

  const QuestionnaireSummaryPage({
    super.key,
    required this.doctorId,
    required this.timeSlot,
    required this.appointmentDate,
    this.isNewBooking = false,
  });

  @override
  State<QuestionnaireSummaryPage> createState() =>
      _QuestionnaireSummaryPageState();
}

class _QuestionnaireSummaryPageState extends State<QuestionnaireSummaryPage> {
  @override
  void initState() {
    super.initState();
    _loadQuestionnaireSummary();
  }

  void _loadQuestionnaireSummary() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final patientId = await context.read<AuthCubit>().getCurrentUser();
      if (patientId?.id != null) {
        // Try to load questionnaire summary first
        context.read<QuestionnaireCubit>().loadQuestionnaireSummary(
          patientId!.id,
        );

        // If no summary exists, load the questionnaire template to show empty state
        context.read<QuestionnaireCubit>().loadQuestionnaire();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "ملخص الاستبيان الطبي",
        backgroundColor: Colors.purple,
        automaticallyImplyLeading: false,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<QuestionnaireCubit, QuestionnaireState>(
            listener: (context, state) {
              if (state is QuestionnaireFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          BlocListener<BookingCubit, BookingState>(
            listener: (context, state) {
              if (state is AppointmentCreated) {
                _showAppointmentSuccess(state.appointment);
              } else if (state is BookingFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<QuestionnaireCubit, QuestionnaireState>(
          builder: (context, state) {
            if (state is QuestionnaireLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is QuestionnaireSummaryLoaded) {
              return _buildSummaryContent(state);
            } else if (state is QuestionnaireLoaded) {
              // Show questionnaire template with empty answers
              return _buildEmptyQuestionnaireContent(state.questionnaire);
            } else if (state is QuestionnaireFailure) {
              return _buildErrorPage(state.message);
            } else {
              return const Center(child: Text('جاري التحميل...'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryContent(QuestionnaireSummaryLoaded state) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildSubmissionInfo(state.response),
                const SizedBox(height: 24),
                _buildAnswersSummary(state.response, state.questionnaire),
                const SizedBox(height: 30),
                if (widget.isNewBooking) _buildActionButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyQuestionnaireContent(Questionnaire questionnaire) {
    return Column(
      children: [
        _buildEmptyHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildEmptyAnswersSummary(questionnaire),
                const SizedBox(height: 30),
                _buildEmptyActionButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.assignment_turned_in,
            size: 50,
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          const Text(
            "تم إرسال الاستبيان بنجاح!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "مراجعة إجاباتك على الاستبيان الطبي",
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.quiz, size: 50, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            "لا توجد إجابات للاستبيان",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "لم يتم العثور على إجابات سابقة للاستبيان الطبي",
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionInfo(QuestionnaireResponse response) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                const Text(
                  "معلومات الإرسال",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow("معرف الاستبيان:", response.id),
            _buildInfoRow(
              "تاريخ الإرسال:",
              _formatDateTime(response.submittedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswersSummary(
    QuestionnaireResponse response,
    Questionnaire questionnaire,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.question_answer,
                  color: Colors.purple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  "إجابات الاستبيان",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...questionnaire.questions.map((question) {
              final answer = response.answers[question.id];
              return _buildAnswerItem(question, answer);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAnswersSummary(Questionnaire questionnaire) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.question_answer,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  "أسئلة الاستبيان",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...questionnaire.questions.map((question) {
              return _buildAnswerItem(question, null);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerItem(Question question, dynamic answer) {
    String answerText = '';

    if (answer == null ||
        answer.toString().isEmpty ||
        (answer is String && answer.trim().isEmpty) ||
        (answer is List && answer.isEmpty)) {
      answerText = 'لا توجد إجابة';
    } else if (answer is List) {
      answerText = answer.join(', ');
    } else {
      answerText = answer.toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                question.text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (question.isRequired)
                const Text(
                  " *",
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Text(
              answerText,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: "متابعة إلى الحجز",
          onPressed: _proceedToBooking,
          type: ButtonType.success,
          icon: Icons.arrow_forward,
          height: 56,
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: "إلغاء الحجز",
          onPressed: _cancelBooking,
          type: ButtonType.danger,
          icon: Icons.cancel,
          height: 50,
        ),
      ],
    );
  }

  Widget _buildEmptyActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: "الذهاب إلى الاستبيان",
          onPressed: () => Navigator.pushNamed(context, '/patient/survey'),
          type: ButtonType.primary,
          icon: Icons.quiz,
          height: 56,
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: "العودة للرئيسية",
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/patient-home'),
          type: ButtonType.secondary,
          icon: Icons.home,
          height: 50,
        ),
      ],
    );
  }

  Widget _buildErrorPage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            "حدث خطأ",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: "إعادة المحاولة",
            onPressed: _loadQuestionnaireSummary,
            type: ButtonType.primary,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _proceedToBooking() {
    // Navigate to booking page or create appointment directly
    if (widget.isNewBooking) {
      // Create appointment with the questionnaire answers
      _createAppointmentWithQuestionnaire();
    }
  }

  void _createAppointmentWithQuestionnaire() async {
    final patientId = await context.read<AuthCubit>().getCurrentUser();
    if (patientId?.id != null) {
      // Get the latest questionnaire response
      final response = await context
          .read<QuestionnaireCubit>()
          .questionnaireRepository
          .getLatestQuestionnaireResponse(patientId!.id);

      if (response != null) {
        context.read<BookingCubit>().createAppointment(
          patientId: patientId.id,
          doctorId: widget.doctorId,
          timeSlot: widget.timeSlot,
          appointmentDate: widget.appointmentDate,
          questionnaireAnswers: response.answers,
        );
      }
    }
  }

  void _showAppointmentSuccess(dynamic appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("تم إنشاء الحجز بنجاح! رقم الحجز: ${appointment.id}"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );

    // Navigate back to patient home after successful appointment creation
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/patient-home');
      }
    });
  }

  void _cancelBooking() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("إلغاء الحجز"),
        content: const Text(
          "هل أنت متأكد من إلغاء الحجز؟ سيتم فقدان جميع البيانات المدخلة.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("لا"),
          ),
          CustomButton(
            text: "نعم، إلغاء",
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/patient-home');
            },
            type: ButtonType.danger,
            isFullWidth: false,
            width: 120,
            height: 40,
          ),
        ],
      ),
    );
  }
}

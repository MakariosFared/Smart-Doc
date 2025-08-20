// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/view/widgets/common_app_bar.dart';
import '../../../auth/presentation/view/widgets/custom_button.dart';
import '../cubit/questionnaire_cubit.dart';
import '../cubit/questionnaire_state.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import '../../data/models/questionnaire.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import 'questionnaire_summary_page.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final Map<String, dynamic> _answers = {};
  bool _isNewBooking = false;
  String? _doctorId;
  String? _timeSlot;
  DateTime? _appointmentDate;
  bool _isCreatingAppointment = false;

  @override
  void initState() {
    super.initState();
    // Load questionnaire when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuestionnaireCubit>().loadQuestionnaire();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Extract arguments from navigation
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _isNewBooking = args['isNewBooking'] ?? false;
      _doctorId = args['doctorId'];
      _timeSlot = args['timeSlot'];
      _appointmentDate = args['date'];
    }

    return Scaffold(
      appBar: CommonAppBar(
        title: "الاستبيان الطبي",
        backgroundColor: Colors.purple,
        automaticallyImplyLeading: false, // Prevent back navigation
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<QuestionnaireCubit, QuestionnaireState>(
            listener: (context, state) {
              if (state is QuestionnaireSubmitted) {
                if (_isNewBooking) {
                  // Create the appointment with questionnaire answers
                  _createAppointmentWithQuestionnaire(state.response.answers);
                } else {
                  // Show success message and navigate back
                  _showSuccessMessage();
                }
              } else if (state is QuestionnaireFailure) {
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
              if (state is AppointmentCreating) {
                // Show loading state for appointment creation
                setState(() {
                  _isCreatingAppointment = true;
                });
              } else if (state is AppointmentCreated) {
                setState(() {
                  _isCreatingAppointment = false;
                });
                _showAppointmentSuccess(state.appointment);
              } else if (state is BookingFailure) {
                setState(() {
                  _isCreatingAppointment = false;
                });
                _showAppointmentError(state.message);
              }
            },
          ),
        ],
        child: BlocBuilder<QuestionnaireCubit, QuestionnaireState>(
          builder: (context, questionnaireState) {
            // Show loading for questionnaire
            if (questionnaireState is QuestionnaireLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            // Show loading for questionnaire submission
            else if (questionnaireState is QuestionnaireSubmitting) {
              return _buildSubmittingPage();
            }
            // Show loading for appointment creation
            else if (_isCreatingAppointment) {
              return _buildAppointmentCreatingPage();
            }
            // Show questionnaire form when loaded
            else if (questionnaireState is QuestionnaireLoaded) {
              return _buildQuestionnaireForm(
                questionnaireState.questionnaire,
                questionnaireState.answers,
              );
            }
            // Show error for questionnaire
            else if (questionnaireState is QuestionnaireFailure) {
              return _buildErrorPage(questionnaireState.message);
            }
            // Default loading state
            else {
              return const Center(child: Text('جاري التحميل...'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildQuestionnaireForm(
    Questionnaire questionnaire,
    Map<String, dynamic> answers,
  ) {
    return Column(
      children: [
        _buildHeader(questionnaire),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildProgressIndicator(questionnaire, answers),
                const SizedBox(height: 30),
                ...questionnaire.questions.map(
                  (question) =>
                      _buildQuestionWidget(question, answers[question.id]),
                ),
                const SizedBox(height: 30),
                _buildSubmitButton(questionnaire, answers),
                const SizedBox(height: 20),
                if (_isNewBooking) _buildCancelButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Questionnaire questionnaire) {
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
          const Icon(Icons.quiz, size: 50, color: Colors.purple),
          const SizedBox(height: 16),
          Text(
            questionnaire.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            questionnaire.description,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          if (_isNewBooking) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "يجب إكمال هذا الاستبيان لتأكيد حجز الموعد",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    Questionnaire questionnaire,
    Map<String, dynamic> answers,
  ) {
    final progress = context.read<QuestionnaireCubit>().progress;
    final answeredCount = (progress * questionnaire.questions.length).round();
    final totalCount = questionnaire.questions.length;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "التقدم: $answeredCount من $totalCount",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "${(progress * 100).round()}%",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(Question question, dynamic currentAnswer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  ),
                ),
                if (question.isRequired)
                  const Text(
                    " *",
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAnswerWidget(question, currentAnswer),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerWidget(Question question, dynamic currentAnswer) {
    switch (question.type) {
      case QuestionType.radio:
        return _buildRadioOptions(question, currentAnswer);
      case QuestionType.checkbox:
        return _buildCheckboxOptions(question, currentAnswer);
      case QuestionType.text:
        return _buildTextInput(question, currentAnswer);
      case QuestionType.number:
        return _buildNumberInput(question, currentAnswer);
    }
  }

  Widget _buildRadioOptions(Question question, dynamic currentAnswer) {
    return Column(
      children: question.options!.map((option) {
        return RadioListTile<String>(
          title: Text(option),
          value: option,
          groupValue: currentAnswer,
          onChanged: (value) {
            context.read<QuestionnaireCubit>().updateAnswer(question.id, value);
          },
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildCheckboxOptions(Question question, dynamic currentAnswer) {
    final selectedOptions = currentAnswer is List
        ? List<String>.from(currentAnswer)
        : <String>[];

    return Column(
      children: question.options!.map((option) {
        return CheckboxListTile(
          title: Text(option),
          value: selectedOptions.contains(option),
          onChanged: (checked) {
            final newOptions = List<String>.from(selectedOptions);
            if (checked == true) {
              newOptions.add(option);
            } else {
              newOptions.remove(option);
            }
            context.read<QuestionnaireCubit>().updateAnswer(
              question.id,
              newOptions,
            );
          },
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildTextInput(Question question, dynamic currentAnswer) {
    return TextFormField(
      initialValue: currentAnswer ?? '',
      onChanged: (value) {
        context.read<QuestionnaireCubit>().updateAnswer(question.id, value);
      },
      decoration: InputDecoration(
        hintText: question.hint,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.1),
      ),
      maxLines: question.maxLines ?? 3,
    );
  }

  Widget _buildNumberInput(Question question, dynamic currentAnswer) {
    return TextFormField(
      initialValue: currentAnswer?.toString() ?? '',
      onChanged: (value) {
        final number = int.tryParse(value);
        context.read<QuestionnaireCubit>().updateAnswer(question.id, number);
      },
      decoration: InputDecoration(
        hintText: question.hint,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.1),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildSubmitButton(
    Questionnaire questionnaire,
    Map<String, dynamic> answers,
  ) {
    final isComplete = context
        .read<QuestionnaireCubit>()
        .isQuestionnaireComplete;

    return CustomButton(
      text: _isNewBooking ? "إكمال الحجز" : "إرسال الاستبيان",
      onPressed: isComplete ? _submitQuestionnaire : null,
      type: ButtonType.success,
      icon: Icons.send,
      height: 56,
    );
  }

  Widget _buildCancelButton() {
    return CustomButton(
      text: "إلغاء الحجز",
      onPressed: _cancelBooking,
      type: ButtonType.danger,
      icon: Icons.cancel,
      height: 50,
    );
  }

  Widget _buildSubmittingPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("جاري إرسال الاستبيان...", style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildAppointmentCreatingPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("جاري إنشاء الموعد...", style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text(
            "يرجى الانتظار",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
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
            onPressed: () {
              context.read<QuestionnaireCubit>().loadQuestionnaire();
            },
            type: ButtonType.primary,
          ),
        ],
      ),
    );
  }

  void _submitQuestionnaire() async {
    final patientId = await context.read<AuthCubit>().getCurrentUser();
    if (patientId?.id != null) {
      context.read<QuestionnaireCubit>().submitQuestionnaire(patientId!.id);
    }
  }

  void _createAppointmentWithQuestionnaire(
    Map<String, dynamic> questionnaireAnswers,
  ) async {
    final patientId = await context.read<AuthCubit>().getCurrentUser();
    if (patientId?.id != null &&
        _doctorId != null &&
        _timeSlot != null &&
        _appointmentDate != null) {
      context.read<BookingCubit>().createAppointment(
        patientId: patientId!.id,
        doctorId: _doctorId!,
        timeSlot: _timeSlot!,
        appointmentDate: _appointmentDate!,
        questionnaireAnswers: questionnaireAnswers,
      );
    }
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

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم إرسال الاستبيان بنجاح"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate to questionnaire summary page
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionnaireSummaryPage(
              doctorId: 'temp',
              timeSlot: 'temp',
              appointmentDate: DateTime.now(),
              isNewBooking: false,
            ),
          ),
        );
      }
    });
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

  void _showAppointmentError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("فشل إنشاء الحجز: $message"),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

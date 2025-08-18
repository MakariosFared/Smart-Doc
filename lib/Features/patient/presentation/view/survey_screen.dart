import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/view/widgets/common_app_bar.dart';
import '../../../auth/presentation/view/widgets/custom_button.dart';
import '../cubit/survey_cubit.dart';
import '../cubit/survey_state.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import '../../domain/entities/survey.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    _formData['hasChronicDiseases'] = false;
    _formData['chronicDiseasesDetails'] = '';
    _formData['isTakingMedications'] = false;
    _formData['medicationsDetails'] = '';
    _formData['hasAllergies'] = false;
    _formData['allergiesDetails'] = '';
    _formData['symptoms'] = '';
    _formData['symptomsDuration'] = '';
  }

  @override
  Widget build(BuildContext context) {
    // Extract arguments from navigation
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final doctorId = args?['doctorId'] as String?;
    final timeSlot = args?['timeSlot'] as String?;
    final appointmentDate = args?['date'] as DateTime?;

    if (doctorId == null || timeSlot == null || appointmentDate == null) {
      return _buildErrorPage('بيانات الحجز غير صحيحة');
    }

    return Scaffold(
      appBar: CommonAppBar(
        title: "الاستبيان الطبي",
        backgroundColor: Colors.purple,
        automaticallyImplyLeading: false, // Prevent back navigation
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<SurveyCubit, SurveyState>(
            listener: (context, state) {
              if (state is SurveySubmitted) {
                setState(() {
                  _isSubmitting = false;
                });
                _showSurveySuccessAndContinue(
                  doctorId,
                  timeSlot,
                  appointmentDate,
                  state.survey,
                );
              } else if (state is SurveyFailure) {
                setState(() {
                  _isSubmitting = false;
                });
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
        child: BlocBuilder<SurveyCubit, SurveyState>(
          builder: (context, state) {
            if (state is SurveySubmitting) {
              return _buildSubmittingPage();
            } else if (state is SurveyFailure) {
              return _buildErrorPage(state.message);
            } else {
              return _buildSurveyForm(doctorId, timeSlot, appointmentDate);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSurveyForm(
    String doctorId,
    String timeSlot,
    DateTime appointmentDate,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildChronicDiseasesSection(),
                  SizedBox(height: 24),
                  _buildMedicationsSection(),
                  SizedBox(height: 24),
                  _buildAllergiesSection(),
                  SizedBox(height: 24),
                  _buildSymptomsSection(),
                  SizedBox(height: 24),
                  _buildSubmitButton(doctorId, timeSlot, appointmentDate),
                  const SizedBox(height: 20),
                  _buildCancelButton(),
                ],
              ),
            ),
          ),
        ],
      ),
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
          const Icon(Icons.medical_services, size: 50, color: Colors.purple),
          const SizedBox(height: 16),
          const Text(
            "الاستبيان الطبي",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "يرجى الإجابة على جميع الأسئلة بدقة لمساعدتنا في تقديم أفضل رعاية طبية",
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
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
      ),
    );
  }

  Widget _buildChronicDiseasesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "الأمراض المزمنة",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text("نعم"),
                    value: true,
                    groupValue: _formData['hasChronicDiseases'],
                    onChanged: (value) {
                      setState(() {
                        _formData['hasChronicDiseases'] = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text("لا"),
                    value: false,
                    groupValue: _formData['hasChronicDiseases'],
                    onChanged: (value) {
                      setState(() {
                        _formData['hasChronicDiseases'] = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            if (_formData['hasChronicDiseases'] == true) ...[
              SizedBox(height: 12),
              TextFormField(
                initialValue: _formData['chronicDiseasesDetails'],
                onChanged: (value) {
                  _formData['chronicDiseasesDetails'] = value;
                },
                decoration: InputDecoration(
                  hintText: "اذكر الأمراض المزمنة التي تعاني منها",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                ),
                maxLines: 3,
                validator: (value) {
                  if (_formData['hasChronicDiseases'] == true &&
                      (value == null || value.trim().isEmpty)) {
                    return "يرجى تحديد الأمراض المزمنة";
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "الأدوية الحالية",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text("نعم"),
                    value: true,
                    groupValue: _formData['isTakingMedications'],
                    onChanged: (value) {
                      setState(() {
                        _formData['isTakingMedications'] = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text("لا"),
                    value: false,
                    groupValue: _formData['isTakingMedications'],
                    onChanged: (value) {
                      setState(() {
                        _formData['isTakingMedications'] = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            if (_formData['isTakingMedications'] == true) ...[
              SizedBox(height: 12),
              TextFormField(
                initialValue: _formData['medicationsDetails'],
                onChanged: (value) {
                  _formData['medicationsDetails'] = value;
                },
                decoration: InputDecoration(
                  hintText: "اذكر أسماء الأدوية والجرعات",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                ),
                maxLines: 3,
                validator: (value) {
                  if (_formData['isTakingMedications'] == true &&
                      (value == null || value.trim().isEmpty)) {
                    return "يرجى تحديد الأدوية التي تتناولها";
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllergiesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "الحساسية",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text("نعم"),
                    value: true,
                    groupValue: _formData['hasAllergies'],
                    onChanged: (value) {
                      setState(() {
                        _formData['hasAllergies'] = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text("لا"),
                    value: false,
                    groupValue: _formData['hasAllergies'],
                    onChanged: (value) {
                      setState(() {
                        _formData['hasAllergies'] = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            if (_formData['hasAllergies'] == true) ...[
              SizedBox(height: 12),
              TextFormField(
                initialValue: _formData['allergiesDetails'],
                onChanged: (value) {
                  _formData['allergiesDetails'] = value;
                },
                decoration: InputDecoration(
                  hintText: "اذكر أنواع الحساسية التي تعاني منها",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                ),
                maxLines: 3,
                validator: (value) {
                  if (_formData['hasAllergies'] == true &&
                      (value == null || value.trim().isEmpty)) {
                    return "يرجى تحديد أنواع الحساسية";
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "الأعراض الحالية",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _formData['symptoms'],
              onChanged: (value) {
                _formData['symptoms'] = value;
              },
              decoration: InputDecoration(
                hintText: "اذكر الأعراض التي تعاني منها حالياً",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "يرجى تحديد الأعراض الحالية";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _formData['symptomsDuration'],
              onChanged: (value) {
                _formData['symptomsDuration'] = value;
              },
              decoration: InputDecoration(
                hintText: "منذ متى تعاني من هذه الأعراض؟",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "يرجى تحديد مدة الأعراض";
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(
    String doctorId,
    String timeSlot,
    DateTime appointmentDate,
  ) {
    return CustomButton(
      text: "إكمال الحجز",
      onPressed: _isSubmitting
          ? null
          : () => _submitSurvey(doctorId, timeSlot, appointmentDate),
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
              context.read<SurveyCubit>().clearError();
            },
            type: ButtonType.primary,
          ),
        ],
      ),
    );
  }

  void _submitSurvey(
    String doctorId,
    String timeSlot,
    DateTime appointmentDate,
  ) async {
    if (_formKey.currentState?.validate() == true) {
      setState(() {
        _isSubmitting = true;
      });

      final patientId = await context.read<AuthCubit>().getCurrentUser();
      if (patientId?.id != null) {
        final surveyData = SurveyData(
          hasChronicDiseases: _formData['hasChronicDiseases'],
          chronicDiseasesDetails: _formData['chronicDiseasesDetails'],
          isTakingMedications: _formData['isTakingMedications'],
          medicationsDetails: _formData['medicationsDetails'],
          hasAllergies: _formData['hasAllergies'],
          allergiesDetails: _formData['allergiesDetails'],
          symptoms: _formData['symptoms'],
          symptomsDuration: _formData['symptomsDuration'],
        );

        context.read<SurveyCubit>().submitSurvey(
          patientId: patientId!.id,
          doctorId: doctorId,
          surveyData: surveyData,
        );
      }
    }
  }

  void _showSurveySuccessAndContinue(
    String doctorId,
    String timeSlot,
    DateTime appointmentDate,
    Survey survey,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم إرسال الاستبيان بنجاح! جاري إنشاء الموعد..."),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Continue with appointment creation
    _createAppointment(doctorId, timeSlot, appointmentDate, survey);
  }

  void _createAppointment(
    String doctorId,
    String timeSlot,
    DateTime appointmentDate,
    Survey survey,
  ) async {
    final patientId = await context.read<AuthCubit>().getCurrentUser();
    if (patientId?.id != null) {
      // Convert survey data to questionnaire answers format for compatibility
      final questionnaireAnswers = {
        'surveyId': survey.id,
        'hasChronicDiseases': survey.data.hasChronicDiseases,
        'chronicDiseasesDetails': survey.data.chronicDiseasesDetails,
        'isTakingMedications': survey.data.isTakingMedications,
        'medicationsDetails': survey.data.medicationsDetails,
        'hasAllergies': survey.data.hasAllergies,
        'allergiesDetails': survey.data.allergiesDetails,
        'symptoms': survey.data.symptoms,
        'symptomsDuration': survey.data.symptomsDuration,
        'submittedAt': survey.timestamp.toIso8601String(),
      };

      context.read<BookingCubit>().createAppointment(
        patientId: patientId!.id,
        doctorId: doctorId,
        timeSlot: timeSlot,
        appointmentDate: appointmentDate,
        questionnaireAnswers: questionnaireAnswers,
      );
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

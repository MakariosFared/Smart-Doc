import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_doc/Features/auth/data/models/app_user.dart';
import '../../../auth/presentation/view/widgets/common_app_bar.dart';
import '../../../auth/presentation/view/widgets/custom_button.dart';
import '../cubit/doctor_cubit.dart';
import '../cubit/doctor_state.dart';
import '../../data/models/doctor_queue_patient.dart';
import '../../../patient/data/models/survey_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class PatientQuestionnairePage extends StatefulWidget {
  final DoctorQueuePatient patient;

  const PatientQuestionnairePage({super.key, required this.patient});

  @override
  State<PatientQuestionnairePage> createState() =>
      _PatientQuestionnairePageState();
}

class _PatientQuestionnairePageState extends State<PatientQuestionnairePage> {
  AppUser? _currentDoctor;

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
  }

  Future<void> _loadDoctorInfo() async {
    final doctor = await context.read<AuthCubit>().getCurrentUser();
    if (doctor != null && mounted) {
      setState(() {
        _currentDoctor = doctor;
      });
      // Load patient details
      context.read<DoctorCubit>().loadPatientDetails(
        widget.patient.patientId,
        doctor.id,
        widget.patient,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "استبيان المريض",
        backgroundColor: Colors.blue,
      ),
      body: BlocConsumer<DoctorCubit, DoctorState>(
        listener: (context, state) {
          if (state is DoctorError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DoctorLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PatientQuestionnaireLoaded) {
            return _buildQuestionnaireContent(state);
          } else if (state is DoctorError) {
            return _buildErrorState(state.message);
          } else {
            return const Center(child: Text('جاري التحميل...'));
          }
        },
      ),
    );
  }

  Widget _buildQuestionnaireContent(PatientQuestionnaireLoaded state) {
    final patient = state.patient;
    final questionnaire = state.questionnaire;
    final medicalHistory = state.medicalHistory;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientHeader(patient),
          const SizedBox(height: 24),
          _buildQuestionnaireSection(questionnaire),
          const SizedBox(height: 24),
          if (medicalHistory != null) ...[
            _buildMedicalHistorySection(medicalHistory),
            const SizedBox(height: 24),
          ],
          _buildActionButtons(patient),
        ],
      ),
    );
  }

  Widget _buildPatientHeader(DoctorQueuePatient patient) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.shade600,
                child: Text(
                  "${patient.queueNumber}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.patientName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "رقم الطابور: ${patient.queueNumber}",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "انضم في: ${_formatTime(patient.joinedAt)}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: patient.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: patient.statusColor),
            ),
            child: Text(
              patient.statusDisplayName,
              style: TextStyle(
                color: patient.statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionnaireSection(Survey questionnaire) {
    final data = questionnaire.data;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.quiz, color: Colors.purple.shade600, size: 24),
                const SizedBox(width: 12),
                Text(
                  "الاستبيان الطبي",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildQuestionnaireItem(
              "الأمراض المزمنة",
              data.hasChronicDiseases ? "نعم" : "لا",
              data.hasChronicDiseases ? Colors.orange : Colors.green,
            ),
            if (data.hasChronicDiseases &&
                data.chronicDiseasesDetails != null) ...[
              const SizedBox(height: 8),
              _buildDetailItem("تفاصيل الأمراض:", data.chronicDiseasesDetails!),
            ],
            const SizedBox(height: 16),
            _buildQuestionnaireItem(
              "الأدوية الحالية",
              data.isTakingMedications ? "نعم" : "لا",
              data.isTakingMedications ? Colors.orange : Colors.green,
            ),
            if (data.isTakingMedications &&
                data.medicationsDetails != null) ...[
              const SizedBox(height: 8),
              _buildDetailItem("تفاصيل الأدوية:", data.medicationsDetails!),
            ],
            const SizedBox(height: 16),
            _buildQuestionnaireItem(
              "الحساسية",
              data.hasAllergies ? "نعم" : "لا",
              data.hasAllergies ? Colors.red : Colors.green,
            ),
            if (data.hasAllergies && data.allergiesDetails != null) ...[
              const SizedBox(height: 8),
              _buildDetailItem("تفاصيل الحساسية:", data.allergiesDetails!),
            ],
            const SizedBox(height: 16),
            _buildQuestionnaireItem(
              "الأعراض الحالية",
              data.symptoms,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildQuestionnaireItem(
              "مدة الأعراض",
              data.symptomsDuration,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildQuestionnaireItem(
              "تاريخ الإرسال",
              _formatDateTime(questionnaire.timestamp),
              Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionnaireItem(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHistorySection(Map<String, dynamic> medicalHistory) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medical_information,
                  color: Colors.teal.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  "التاريخ الطبي",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildMedicalHistoryItem(
              "آخر زيارة",
              medicalHistory['lastVisit'] != null
                  ? _formatDateTime(medicalHistory['lastVisit'])
                  : "لا توجد زيارات سابقة",
            ),
            const SizedBox(height: 16),
            _buildMedicalHistoryItem(
              "الأمراض المزمنة",
              medicalHistory['chronicConditions'] != null &&
                      (medicalHistory['chronicConditions'] as List).isNotEmpty
                  ? (medicalHistory['chronicConditions'] as List).join(', ')
                  : "لا توجد",
            ),
            const SizedBox(height: 16),
            _buildMedicalHistoryItem(
              "الحساسية",
              medicalHistory['allergies'] != null &&
                      (medicalHistory['allergies'] as List).isNotEmpty
                  ? (medicalHistory['allergies'] as List).join(', ')
                  : "لا توجد",
            ),
            const SizedBox(height: 16),
            _buildMedicalHistoryItem(
              "الأدوية",
              medicalHistory['medications'] != null &&
                      (medicalHistory['medications'] as List).isNotEmpty
                  ? (medicalHistory['medications'] as List).join(', ')
                  : "لا توجد",
            ),
            const SizedBox(height: 16),
            _buildMedicalHistoryItem(
              "ملاحظات",
              medicalHistory['notes'] ?? "لا توجد ملاحظات",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistoryItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.teal.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(DoctorQueuePatient patient) {
    if (_currentDoctor == null) return const SizedBox.shrink();

    return Column(
      children: [
        if (patient.isWaiting) ...[
          CustomButton(
            text: "بدء الخدمة",
            onPressed: () => _startServingPatient(patient),
            type: ButtonType.success,
            icon: Icons.play_arrow,
            height: 56,
          ),
          const SizedBox(height: 16),
        ],
        if (patient.isInProgress) ...[
          CustomButton(
            text: "إنهاء الخدمة",
            onPressed: () => _completePatient(patient),
            type: ButtonType.success,
            icon: Icons.check,
            height: 56,
          ),
          const SizedBox(height: 16),
        ],
        CustomButton(
          text: "تخطي المريض",
          onPressed: () => _skipPatient(patient),
          type: ButtonType.secondary,
          icon: Icons.skip_next,
          height: 50,
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: "العودة للطابور",
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/doctor/queue'),
          type: ButtonType.primary,
          icon: Icons.arrow_back,
          height: 50,
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
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
              if (_currentDoctor != null) {
                context.read<DoctorCubit>().loadPatientDetails(
                  widget.patient.patientId,
                  _currentDoctor!.id,
                  widget.patient,
                );
              }
            },
            type: ButtonType.primary,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return "الآن";
    } else if (difference.inMinutes < 60) {
      return "منذ ${difference.inMinutes} دقيقة";
    } else if (difference.inHours < 24) {
      return "منذ ${difference.inHours} ساعة";
    } else {
      return "منذ ${difference.inDays} يوم";
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _startServingPatient(DoctorQueuePatient patient) {
    if (_currentDoctor != null) {
      context.read<DoctorCubit>().startServingPatient(
        _currentDoctor!.id,
        patient.patientId,
      );
      Navigator.pushReplacementNamed(context, '/doctor/queue');
    }
  }

  void _completePatient(DoctorQueuePatient patient) {
    if (_currentDoctor != null) {
      context.read<DoctorCubit>().completePatient(
        _currentDoctor!.id,
        patient.patientId,
      );
      Navigator.pushReplacementNamed(context, '/doctor/queue');
    }
  }

  void _skipPatient(DoctorQueuePatient patient) {
    if (_currentDoctor != null) {
      context.read<DoctorCubit>().skipPatient(
        _currentDoctor!.id,
        patient.patientId,
      );
      Navigator.pushReplacementNamed(context, '/doctor/queue');
    }
  }
}

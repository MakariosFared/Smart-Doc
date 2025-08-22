import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/view/widgets/common_app_bar.dart';
import '../../../auth/presentation/view/widgets/custom_button.dart';
import '../cubit/doctor_cubit.dart';
import '../cubit/doctor_state.dart';
import '../../data/models/doctor_queue_patient.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/data/models/app_user.dart';

class DoctorHomePage extends StatefulWidget {
  final String? doctorId;

  const DoctorHomePage({super.key, this.doctorId});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  AppUser? _currentDoctor;
  DoctorCubit? _doctorCubit; // Store reference to cubit

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store reference to cubit when dependencies change
    _doctorCubit = context.read<DoctorCubit>();
  }

  Future<void> _loadDoctorInfo() async {
    // Use the passed doctorId if available, otherwise get the current logged-in doctor
    String targetDoctorId;

    if (widget.doctorId != null) {
      targetDoctorId = widget.doctorId!;
      // For now, we'll still get the current user for display purposes
      // In a real app, you might want to fetch the target doctor's info
      final doctor = await context.read<AuthCubit>().getCurrentUser();
      if (doctor != null && mounted) {
        setState(() {
          _currentDoctor = doctor;
        });
      }
    } else {
      // Get the current logged-in doctor
      final doctor = await context.read<AuthCubit>().getCurrentUser();
      if (doctor != null && mounted) {
        setState(() {
          _currentDoctor = doctor;
        });
        targetDoctorId = doctor.id;
      } else {
        return;
      }
    }

    // Start listening to queue updates for the target doctor
    context.read<DoctorCubit>().startListeningToQueue(targetDoctorId);
  }

  @override
  void dispose() {
    // Use stored reference instead of context.read
    _doctorCubit?.stopListeningToQueue();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "لوحة تحكم الدكتور",
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
      ),
      body: BlocConsumer<DoctorCubit, DoctorState>(
        listener: (context, state) {
          if (state is PatientActionCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is DoctorError) {
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
          } else if (state is QueueLoaded) {
            return _buildQueueContent(state);
          } else if (state is QueueEmpty) {
            return _buildEmptyQueue(state.message);
          } else if (state is DoctorError) {
            return _buildErrorState(state.message);
          } else {
            return const Center(child: Text('جاري التحميل...'));
          }
        },
      ),
    );
  }

  Widget _buildQueueContent(QueueLoaded state) {
    return Column(
      children: [
        _buildHeader(state),
        const SizedBox(height: 16),
        _buildCurrentPatientSection(state.currentPatient),
        const SizedBox(height: 16),
        _buildQueueList(state.patients),
      ],
    );
  }

  Widget _buildHeader(QueueLoaded state) {
    final stats = state.statistics;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "مرحباً د. ${_currentDoctor?.name ?? 'الدكتور'}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "إحصائيات الطابور",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "${state.patients.length}",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    Text(
                      "مريض",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatisticsRow(stats),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "في الانتظار",
            "${stats['waitingPatients'] ?? 0}",
            Colors.orange,
            Icons.pending,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            "قيد المعالجة",
            "${stats['inProgressPatients'] ?? 0}",
            Colors.blue,
            Icons.medical_services,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            "مكتمل",
            "${stats['completedPatients'] ?? 0}",
            Colors.green,
            Icons.check_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPatientSection(DoctorQueuePatient? currentPatient) {
    if (currentPatient == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Text(
            "لا يوجد مريض قيد المعالجة حالياً",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.medical_services,
                color: Colors.blue.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                "المريض الحالي",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.blue.shade600,
                child: Text(
                  "${currentPatient.queueNumber}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentPatient.patientName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "انضم في: ${_formatTime(currentPatient.joinedAt)}",
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
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: "عرض الاستبيان",
                  onPressed: () => _viewPatientQuestionnaire(currentPatient),
                  type: ButtonType.primary,
                  icon: Icons.quiz,
                  height: 45,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: "إنهاء الخدمة",
                  onPressed: () => _completePatient(currentPatient),
                  type: ButtonType.success,
                  icon: Icons.check,
                  height: 45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList(List<DoctorQueuePatient> patients) {
    final waitingPatients = patients.where((p) => p.isWaiting).toList();

    if (waitingPatients.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.queue, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "لا يوجد مرضى في الانتظار",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  "المرضى في الانتظار (${waitingPatients.length})",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: waitingPatients.length,
              itemBuilder: (context, index) {
                final patient = waitingPatients[index];
                return _buildQueueItem(patient, index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(DoctorQueuePatient patient, int position) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              "${patient.queueNumber}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          patient.patientName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          "انضم في: ${_formatTime(patient.joinedAt)}",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _viewPatientQuestionnaire(patient),
              icon: Icon(Icons.quiz, color: Colors.blue.shade600),
              tooltip: "عرض الاستبيان",
            ),
            IconButton(
              onPressed: () => _startServingPatient(patient),
              icon: Icon(Icons.play_arrow, color: Colors.green.shade600),
              tooltip: "بدء الخدمة",
            ),
            IconButton(
              onPressed: () => _skipPatient(patient),
              icon: Icon(Icons.skip_next, color: Colors.orange.shade600),
              tooltip: "تخطي المريض",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQueue(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            "حدث خطأ",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: "إعادة المحاولة",
            onPressed: () {
              if (_currentDoctor != null) {
                context.read<DoctorCubit>().startListeningToQueue(
                  _currentDoctor!.id,
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

  void _viewPatientQuestionnaire(DoctorQueuePatient patient) {
    Navigator.pushNamed(
      context,
      '/doctor/patient-questionnaire',
      arguments: patient,
    );
  }

  void _startServingPatient(DoctorQueuePatient patient) {
    if (_currentDoctor != null) {
      context.read<DoctorCubit>().startServingPatient(
        _currentDoctor!.id,
        patient.patientId,
      );
    }
  }

  void _completePatient(DoctorQueuePatient patient) {
    if (_currentDoctor != null) {
      context.read<DoctorCubit>().completePatient(
        _currentDoctor!.id,
        patient.patientId,
      );
    }
  }

  void _skipPatient(DoctorQueuePatient patient) {
    if (_currentDoctor != null) {
      context.read<DoctorCubit>().skipPatient(
        _currentDoctor!.id,
        patient.patientId,
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/view/widgets/common_app_bar.dart';
import '../../../auth/presentation/view/widgets/custom_button.dart';
import '../cubit/doctor_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../queue/presentation/cubit/queue_cubit.dart';
import '../../../queue/presentation/cubit/queue_state.dart' as queue_state;
import '../../../queue/data/models/queue_entry_model.dart';

class DoctorHomePage extends StatefulWidget {
  final String? doctorId;

  const DoctorHomePage({super.key, this.doctorId});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  AppUser? _currentDoctor;
  DoctorCubit? _doctorCubit;
  QueueCubit? _queueCubit;
  String? _targetDoctorId;
  List<QueueEntry> _lastKnownQueueEntries = []; // Store last known queue data

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store references to cubits when dependencies change
    _doctorCubit = context.read<DoctorCubit>();
    _queueCubit = context.read<QueueCubit>();
  }

  Future<void> _loadDoctorInfo() async {
    try {
      // Use the passed doctorId if available, otherwise get the current logged-in doctor
      if (widget.doctorId != null) {
        _targetDoctorId = widget.doctorId!;
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
            _targetDoctorId = doctor.id;
          });
        } else {
          return;
        }
      }

      // Start listening to real-time queue updates for the target doctor
      if (_targetDoctorId != null) {
        context.read<QueueCubit>().startListeningToQueue(_targetDoctorId!);
      }
    } catch (e) {
      print('❌ Error loading doctor info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحميل بيانات الدكتور: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Use stored references instead of context.read
    _doctorCubit?.stopListeningToQueue();
    _queueCubit?.stopListeningToQueue();
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
      body: RefreshIndicator(
        onRefresh: () async {
          if (_targetDoctorId != null) {
            context.read<QueueCubit>().refreshQueue();
          }
        },
        child: BlocConsumer<QueueCubit, queue_state.QueueState>(
          listener: (context, state) {
            if (state is queue_state.QueueActionCompleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            } else if (state is queue_state.QueueError) {
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
            if (state is queue_state.QueueLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري تحميل الطابور...'),
                  ],
                ),
              );
            } else if (state is queue_state.QueueActionInProgress) {
              // Show loading overlay while action is in progress
              return Stack(
                children: [
                  // Show the last known queue state if available, or a placeholder
                  _buildQueueContent(
                    _lastKnownQueueEntries.isNotEmpty
                        ? _lastKnownQueueEntries
                        : [],
                  ),
                  // Loading overlay
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else if (state is queue_state.QueueLoaded) {
              // Store the latest queue entries for use during loading states
              _lastKnownQueueEntries = state.entries;
              return _buildQueueContent(state.entries);
            } else if (state is queue_state.QueueEmpty) {
              return _buildEmptyQueue(state.message);
            } else if (state is queue_state.QueueError) {
              return _buildErrorState(state.message);
            } else {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.queue, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('جاري التحميل...'),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildQueueContent(List<QueueEntry> entries) {
    // Filter out invalid entries
    final validEntries = entries.where((e) => e.isValid).toList();

    if (validEntries.isEmpty) {
      return _buildEmptyQueue('لا يوجد مرضى صالحين في الطابور');
    }

    return Column(
      children: [
        _buildHeader(validEntries),
        const SizedBox(height: 16),
        _buildCurrentPatientSection(validEntries),
        const SizedBox(height: 16),
        _buildQueueList(validEntries),
      ],
    );
  }

  Widget _buildHeader(List<QueueEntry> entries) {
    final waitingCount = entries
        .where((e) => e.status == QueueStatus.waiting)
        .length;
    final inProgressCount = entries
        .where((e) => e.status == QueueStatus.inProgress)
        .length;
    final completedCount = entries
        .where((e) => e.status == QueueStatus.done)
        .length;

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
                      "${entries.length}",
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
          _buildStatisticsRow(waitingCount, inProgressCount, completedCount),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow(int waiting, int inProgress, int completed) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "في الانتظار",
            "$waiting",
            Colors.orange,
            Icons.pending,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            "قيد المعالجة",
            "$inProgress",
            Colors.blue,
            Icons.medical_services,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            "مكتمل",
            "$completed",
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

  Widget _buildCurrentPatientSection(List<QueueEntry> entries) {
    final currentPatient = entries.firstWhere(
      (e) => e.status == QueueStatus.inProgress,
      orElse: () => QueueEntry(
        id: '',
        patientId: '',
        patientName: '',
        doctorId: '',
        status: QueueStatus.waiting,
        timestamp: DateTime.now(),
      ),
    );

    if (currentPatient.id.isEmpty) {
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
                  "${currentPatient.displayQueueNumber}",
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
                      "انضم في: ${_formatTime(currentPatient.timestamp)}",
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
          BlocBuilder<QueueCubit, queue_state.QueueState>(
            builder: (context, queueState) {
              final isActionInProgress =
                  queueState is queue_state.QueueActionInProgress;

              return Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: "عرض الاستبيان",
                      onPressed: () =>
                          _viewPatientQuestionnaire(currentPatient),
                      type: ButtonType.primary,
                      icon: Icons.quiz,
                      height: 45,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: isActionInProgress ? "جاري..." : "إنهاء الخدمة",
                      onPressed: isActionInProgress
                          ? null
                          : () => _completePatient(currentPatient),
                      type: ButtonType.success,
                      icon: isActionInProgress
                          ? Icons.hourglass_empty
                          : Icons.check,
                      height: 45,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList(List<QueueEntry> entries) {
    final waitingPatients = entries
        .where((p) => p.status == QueueStatus.waiting)
        .toList();

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

  Widget _buildQueueItem(QueueEntry patient, int position) {
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
              "${patient.displayQueueNumber}",
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
          "انضم في: ${_formatTime(patient.timestamp)}",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: BlocBuilder<QueueCubit, queue_state.QueueState>(
          builder: (context, queueState) {
            final isActionInProgress =
                queueState is queue_state.QueueActionInProgress;
            final isCurrentPatientAction =
                isActionInProgress &&
                (queueState as queue_state.QueueActionInProgress).message
                    .contains('المريض');

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _viewPatientQuestionnaire(patient),
                  icon: Icon(Icons.quiz, color: Colors.blue.shade600),
                  tooltip: "عرض الاستبيان",
                ),
                IconButton(
                  onPressed: isActionInProgress
                      ? null
                      : () => _startServingPatient(patient),
                  icon: isActionInProgress && isCurrentPatientAction
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green.shade600,
                            ),
                          ),
                        )
                      : Icon(Icons.play_arrow, color: Colors.green.shade600),
                  tooltip: "بدء الخدمة",
                ),
                IconButton(
                  onPressed: isActionInProgress
                      ? null
                      : () => _skipPatient(patient),
                  icon: isActionInProgress && isCurrentPatientAction
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange.shade600,
                            ),
                          ),
                        )
                      : Icon(Icons.skip_next, color: Colors.orange.shade600),
                  tooltip: "تخطي المريض",
                ),
              ],
            );
          },
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
              if (_targetDoctorId != null) {
                context.read<QueueCubit>().startListeningToQueue(
                  _targetDoctorId!,
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

  void _viewPatientQuestionnaire(QueueEntry patient) {
    // TODO: Implement questionnaire view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("عرض استبيان المريض: ${patient.patientName}"),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _startServingPatient(QueueEntry patient) {
    if (_targetDoctorId != null) {
      context.read<QueueCubit>().updatePatientStatus(
        _targetDoctorId!,
        patient.patientId,
        QueueStatus.inProgress,
      );
    }
  }

  void _completePatient(QueueEntry patient) {
    if (_targetDoctorId != null) {
      context.read<QueueCubit>().updatePatientStatus(
        _targetDoctorId!,
        patient.patientId,
        QueueStatus.done,
      );
    }
  }

  void _skipPatient(QueueEntry patient) {
    if (_targetDoctorId != null) {
      context.read<QueueCubit>().updatePatientStatus(
        _targetDoctorId!,
        patient.patientId,
        QueueStatus.cancelled,
      );
    }
  }
}

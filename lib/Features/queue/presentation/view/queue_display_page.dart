import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_doc/Core/di/app_dependency_injection.dart';
import '../../../auth/presentation/view/widgets/common_app_bar.dart';
import '../../../auth/presentation/view/widgets/custom_button.dart';
import '../cubit/queue_cubit.dart';
import '../cubit/queue_state.dart';
import '../../data/models/queue_entry_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import 'dart:async';

class QueueDisplayPage extends StatefulWidget {
  final String doctorId;
  final String? doctorName;

  const QueueDisplayPage({super.key, required this.doctorId, this.doctorName});

  @override
  State<QueueDisplayPage> createState() => _QueueDisplayPageState();
}

class _QueueDisplayPageState extends State<QueueDisplayPage> {
  String? _currentPatientId;
  String? _currentPatientName;
  int _currentPosition = -1;
  List<QueueEntry> _queueList = [];
  Timer? _positionUpdateTimer;
  StreamSubscription<List<QueueEntry>>? _queueSubscription;

  @override
  void initState() {
    super.initState();
    _initializePatientInfo();
    _startPositionUpdates();
  }

  @override
  void dispose() {
    _positionUpdateTimer?.cancel();
    _queueSubscription?.cancel();
    super.dispose();
  }

  void _startPositionUpdates() {
    // Update position every 10 seconds
    _positionUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _currentPatientId != null) {
        _updateCurrentPosition();
      }
    });
  }

  Future<void> _updateCurrentPosition() async {
    if (_currentPatientId == null) return;

    try {
      final queueRepository = AppDependencyInjection.queueRepository;
      final queueList = await queueRepository.getDoctorQueue(widget.doctorId);

      if (mounted) {
        setState(() {
          _queueList = queueList;
        });

        // Update current position
        final newPosition = queueList.indexWhere(
          (entry) => entry.patientId == _currentPatientId,
        );
        if (newPosition >= 0) {
          final newPositionNumber = newPosition + 1;

          // Check if position changed and show notification
          if (newPositionNumber != _currentPosition && _currentPosition > 0) {
            _showPositionChangeNotification(
              _currentPosition,
              newPositionNumber,
            );
          }

          setState(() {
            _currentPosition = newPositionNumber;
          });
        }
      }
    } catch (e) {
      print('Error updating position: $e');
    }
  }

  void _showPositionChangeNotification(int oldPosition, int newPosition) {
    String message;
    Color backgroundColor;

    if (newPosition < oldPosition) {
      message =
          "ممتاز! تقدمت في الطابور من رقم $oldPosition إلى رقم $newPosition";
      backgroundColor = Colors.green.shade600;
    } else if (newPosition > oldPosition) {
      message =
          "انتبه! تأخرت في الطابور من رقم $oldPosition إلى رقم $newPosition";
      backgroundColor = Colors.orange.shade600;
    } else {
      return; // No change
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                newPosition < oldPosition
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _initializePatientInfo() async {
    final authCubit = context.read<AuthCubit>();
    final currentUser = await authCubit.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        _currentPatientId = currentUser.id;
        _currentPatientName = currentUser.name;
      });

      // Check if patient is already in queue
      final queueCubit = context.read<QueueCubit>();
      final existingEntry = await queueCubit.getPatientQueuePosition(
        widget.doctorId,
        currentUser.id,
      );

      if (existingEntry != null) {
        // Patient is already in queue, start listening
        await _startQueueMonitoring();
      }
    }
  }

  Future<void> _startQueueMonitoring() async {
    if (_currentPatientId == null) return;

    final queueCubit = context.read<QueueCubit>();

    // Get current position
    final position = await queueCubit.getPatientQueuePositionNumber(
      widget.doctorId,
      _currentPatientId!,
    );

    if (position > 0) {
      setState(() {
        _currentPosition = position;
      });
    }

    // Get initial queue data using the repository directly
    final queueRepository = AppDependencyInjection.queueRepository;
    final queueList = await queueRepository.getDoctorQueue(widget.doctorId);
    setState(() {
      _queueList = queueList;
    });

    // Update current position
    final newPosition = queueList.indexWhere(
      (entry) => entry.patientId == _currentPatientId,
    );
    if (newPosition >= 0) {
      setState(() {
        _currentPosition = newPosition + 1;
      });
    }
  }

  Future<void> _joinQueue() async {
    if (_currentPatientId == null || _currentPatientName == null) return;

    final queueCubit = context.read<QueueCubit>();
    await queueCubit.joinQueue(
      widget.doctorId,
      _currentPatientId!,
      _currentPatientName!,
    );

    // Start monitoring after joining
    await _startQueueMonitoring();
  }

  Future<void> _leaveQueue() async {
    if (_currentPatientId == null) return;

    final queueCubit = context.read<QueueCubit>();
    await queueCubit.leaveQueue(widget.doctorId, _currentPatientId!);

    setState(() {
      _currentPosition = -1;
      _queueList = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "طابور ${widget.doctorName ?? 'الطبيب'}",
        backgroundColor: Colors.blue,
      ),
      body: BlocConsumer<QueueCubit, QueueState>(
        listener: (context, state) {
          if (state is QueueError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentStatusCard(state),
                const SizedBox(height: 20),
                _buildQueueList(),
                const SizedBox(height: 20),
                _buildActionButtons(state),
              ],
            ),
          );
        },
      ),
      // Floating action button to show current position
      floatingActionButton: _currentPosition > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                _showPositionDetails();
              },
              backgroundColor: Colors.orange.shade600,
              icon: const Icon(Icons.queue, color: Colors.white),
              label: Text(
                "موقعك: رقم $_currentPosition",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
          : null,
    );
  }

  void _showPositionDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.queue, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text("تفاصيل موقعك في الطابور"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPositionInfoRow(
              "الموقع الحالي",
              "رقم $_currentPosition",
              Colors.orange.shade600,
            ),
            const SizedBox(height: 12),
            _buildPositionInfoRow(
              "إجمالي المرضى",
              "${_queueList.length}",
              Colors.blue.shade600,
            ),
            const SizedBox(height: 12),
            _buildPositionInfoRow(
              "الحالة",
              "في الانتظار",
              Colors.green.shade600,
            ),
            const SizedBox(height: 12),
            _buildPositionInfoRow(
              "انضم منذ",
              _formatTime(
                _queueList
                    .firstWhere(
                      (entry) => entry.patientId == _currentPatientId,
                      orElse: () => QueueEntry(
                        id: '',
                        patientId: '',
                        patientName: '',
                        doctorId: '',
                        status: QueueStatus.waiting,
                        timestamp: DateTime.now(),
                      ),
                    )
                    .timestamp,
              ),
              Colors.grey.shade600,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("إغلاق"),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionInfoRow(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStatusCard(QueueState state) {
    if (_currentPosition > 0) {
      final estimatedWaitTime = _calculateEstimatedWaitTime();

      return Card(
        elevation: 4,
        color: Colors.blue.shade50,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.queue, size: 48, color: Colors.blue.shade700),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "أنت في الطابور",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        "طابور الدكتور ${widget.doctorId}",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Position information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatusItem(
                      "الموقع",
                      "رقم $_currentPosition",
                      Icons.format_list_numbered,
                      Colors.orange.shade700,
                    ),
                    _buildStatusItem(
                      "إجمالي المرضى",
                      "${_queueList.length}",
                      Icons.people,
                      Colors.blue.shade700,
                    ),
                    _buildStatusItem(
                      "الوقت المتوقع",
                      estimatedWaitTime,
                      Icons.access_time,
                      Colors.green.shade700,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Progress indicator
              if (_queueList.length > 1)
                Column(
                  children: [
                    Text(
                      "تقدم الطابور",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (_currentPosition - 1) / (_queueList.length - 1),
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.shade600,
                      ),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${_currentPosition - 1} من ${_queueList.length - 1} مريض أمامك",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        elevation: 4,
        color: Colors.grey.shade50,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.queue_outlined, size: 48, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text(
                "أنت لست في الطابور",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "انضم للطابور لرؤية الطبيب",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildStatusItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
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
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  String _calculateEstimatedWaitTime() {
    if (_queueList.length <= 1) return "فوراً";

    // Estimate 5 minutes per patient
    final estimatedMinutes = (_currentPosition - 1) * 5;

    if (estimatedMinutes < 60) {
      return "$estimatedMinutes دقيقة";
    } else {
      final hours = estimatedMinutes ~/ 60;
      final minutes = estimatedMinutes % 60;
      if (minutes == 0) {
        return "$hours ساعة";
      } else {
        return "$hours ساعة و $minutes دقيقة";
      }
    }
  }

  Widget _buildQueueList() {
    if (_queueList.isEmpty) {
      return Card(
        elevation: 2,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "لا يوجد مرضى في الطابور",
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  "قائمة الطابور (${_queueList.length} مريض)",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _queueList.length,
            itemBuilder: (context, index) {
              final entry = _queueList[index];
              final isCurrentPatient = entry.patientId == _currentPatientId;
              final position = index + 1;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isCurrentPatient ? Colors.blue.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrentPatient
                        ? Colors.blue.shade300
                        : Colors.grey.shade200,
                    width: isCurrentPatient ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrentPatient
                        ? Colors.blue.shade600
                        : Colors.grey.shade400,
                    child: Text(
                      "$position",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    entry.patientName,
                    style: TextStyle(
                      fontWeight: isCurrentPatient
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCurrentPatient
                          ? Colors.blue.shade800
                          : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    "انضم: ${_formatTime(entry.timestamp)}",
                    style: TextStyle(
                      color: isCurrentPatient
                          ? Colors.blue.shade600
                          : Colors.grey.shade600,
                    ),
                  ),
                  trailing: isCurrentPatient
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "أنت",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(QueueState state) {
    if (_currentPosition > 0) {
      // Patient is in queue
      return CustomButton(
        text: "مغادرة الطابور",
        onPressed: state is QueueLoading ? null : _leaveQueue,
        isLoading: state is QueueLoading,
        type: ButtonType.danger,
        icon: Icons.exit_to_app,
      );
    } else {
      // Patient is not in queue
      return CustomButton(
        text: "انضم للطابور",
        onPressed: state is QueueLoading ? null : _joinQueue,
        isLoading: state is QueueLoading,
        type: ButtonType.success,
        icon: Icons.queue,
      );
    }
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
      return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    }
  }
}

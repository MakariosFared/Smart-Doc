import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/view/widgets/common_app_bar.dart';
import '../cubit/queue_cubit.dart';
import '../../data/models/queue_entry_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/data/models/app_user.dart';
import 'dart:async';

class QueueDisplayPage extends StatefulWidget {
  final String doctorId;
  final String? doctorName;

  const QueueDisplayPage({super.key, required this.doctorId, this.doctorName});

  @override
  State<QueueDisplayPage> createState() => _QueueDisplayPageState();
}

class _QueueDisplayPageState extends State<QueueDisplayPage> {
  AppUser? _currentPatient;
  Timer? _positionUpdateTimer;
  StreamSubscription<List<QueueEntry>>? _queueSubscription;
  int _currentPatientPosition = -1;
  List<QueueEntry> _currentQueue = [];

  @override
  void initState() {
    super.initState();
    _initializePatientInfo();
    _startPositionUpdates();
    _listenToQueueUpdates();
  }

  @override
  void dispose() {
    _positionUpdateTimer?.cancel();
    _queueSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializePatientInfo() async {
    final patient = await context.read<AuthCubit>().getCurrentUser();
    if (patient != null && mounted) {
      setState(() {
        _currentPatient = patient;
      });
      _updateCurrentPosition();
    }
  }

  void _startPositionUpdates() {
    // Update position every 10 seconds for real-time updates
    _positionUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _updateCurrentPosition();
      }
    });
  }

  void _listenToQueueUpdates() {
    // Listen to real-time queue updates using the new QueueCubit
    context.read<QueueCubit>().startListeningToQueue(widget.doctorId);

    // TODO: Update this to use BlocListener for real-time updates
    // For now, we'll use a timer to refresh data
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _loadQueueData();
      }
    });
  }

  Future<void> _updateCurrentPosition() async {
    if (_currentPatient == null) return;

    try {
      // TODO: Implement position calculation when method is available
      // For now, use a placeholder value
      final position = 1;

      if (mounted) {
        setState(() {
          _currentPatientPosition = position;
        });
      }
    } catch (e) {
      print('Error updating position: $e');
    }
  }

  Future<void> _loadQueueData() async {
    // TODO: Implement queue data loading when method is available
    // For now, this is a placeholder
    print('Loading queue data...');
  }

  void _checkForNotifications() {
    if (_currentPatientPosition > 0 && _currentPatientPosition <= 3) {
      // Patient is within 3 positions of being served
      _showPositionChangeNotification();
    }
  }

  void _showPositionChangeNotification() {
    if (_currentPatientPosition == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "🎉 دورك الآن! يرجى التوجه للدكتور",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (_currentPatientPosition == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "⚠️ دورك قريب! يرجى الاستعداد",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (_currentPatientPosition == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "📋 دورك قادم قريباً - يرجى الاستعداد",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: "طابور الدكتور ${widget.doctorName ?? widget.doctorId}",
        backgroundColor: Colors.blue,
      ),
      body: _currentPatient == null
          ? const Center(child: CircularProgressIndicator())
          : _buildQueueContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPositionDetails,
        icon: const Icon(Icons.info_outline, color: Colors.white),
        label: Text(
          "موقعي: ${_currentPatientPosition > 0 ? 'رقم $_currentPatientPosition' : 'غير محدد'}",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildQueueContent() {
    return Column(
      children: [
        _buildCurrentStatusCard(),
        const SizedBox(height: 16),
        _buildQueueList(),
      ],
    );
  }

  Widget _buildCurrentStatusCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
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
                    "مرحباً ${_currentPatient?.name ?? 'المريض'}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "موقعك في الطابور",
                    style: TextStyle(fontSize: 14, color: Colors.blue.shade700),
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
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _currentPatientPosition > 0
                          ? "$_currentPatientPosition"
                          : "?",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      "رقم",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressIndicator(),
          const SizedBox(height: 16),
          _buildEstimatedWaitTime(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalInQueue = _currentQueue.length;
    final progress = totalInQueue > 0
        ? (_currentPatientPosition - 1) / totalInQueue
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "التقدم في الطابور",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
            Text(
              "$_currentPatientPosition من $totalInQueue",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.blue.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildEstimatedWaitTime() {
    // Simple estimation: 10 minutes per patient
    final estimatedMinutes = (_currentPatientPosition - 1) * 10;

    if (estimatedMinutes <= 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              "دورك الآن!",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.orange.shade600, size: 20),
          const SizedBox(width: 8),
          Text(
            "الوقت المتوقع: $estimatedMinutes دقيقة",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList() {
    if (_currentQueue.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.queue, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "الطابور فارغ",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "لا يوجد مرضى في الطابور حالياً",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
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
                Icon(Icons.people, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  "المرضى في الطابور (${_currentQueue.length})",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _currentQueue.length,
              itemBuilder: (context, index) {
                final entry = _currentQueue[index];
                final position = index + 1;
                final isCurrentPatient = entry.patientId == _currentPatient?.id;

                return _buildQueueItem(entry, position, isCurrentPatient);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(
    QueueEntry entry,
    int position,
    bool isCurrentPatient,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentPatient ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentPatient ? Colors.blue.shade300 : Colors.grey.shade300,
          width: isCurrentPatient ? 2 : 1,
        ),
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
            color: isCurrentPatient
                ? Colors.blue.shade600
                : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              "$position",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          entry.patientName,
          style: TextStyle(
            fontWeight: isCurrentPatient ? FontWeight.bold : FontWeight.w500,
            color: isCurrentPatient ? Colors.blue.shade700 : Colors.black87,
          ),
        ),
        subtitle: Text(
          "الحالة: ${entry.statusDisplayName}",
          style: TextStyle(color: _getStatusColor(entry.status), fontSize: 12),
        ),
        trailing: isCurrentPatient
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
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
  }

  Color _getStatusColor(QueueStatus status) {
    switch (status) {
      case QueueStatus.waiting:
        return Colors.orange;
      case QueueStatus.inProgress:
        return Colors.blue;
      case QueueStatus.done:
        return Colors.green;
      case QueueStatus.cancelled:
        return Colors.red;
    }
  }

  void _showPositionDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تفاصيل موقعك في الطابور"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow("اسم المريض:", _currentPatient?.name ?? "غير محدد"),
            _buildDetailRow(
              "رقم الطابور:",
              _currentPatientPosition > 0
                  ? "$_currentPatientPosition"
                  : "غير محدد",
            ),
            _buildDetailRow("إجمالي المرضى:", "${_currentQueue.length}"),
            _buildDetailRow("الحالة:", _getCurrentPatientStatus()),
            if (_currentPatientPosition > 1)
              _buildDetailRow(
                "الوقت المتوقع:",
                "${(_currentPatientPosition - 1) * 10} دقيقة",
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إغلاق"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getCurrentPatientStatus() {
    if (_currentPatientPosition <= 0) return "غير محدد";
    if (_currentPatientPosition == 1) return "دورك الآن";
    if (_currentPatientPosition <= 3) return "قريب جداً";
    if (_currentPatientPosition <= 5) return "قريب";
    return "في الانتظار";
  }
}

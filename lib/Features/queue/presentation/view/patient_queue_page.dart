import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_doc/Core/di/app_dependency_injection.dart';
import '../../../auth/presentation/view/widgets/custom_button.dart';
import '../../../queue/data/models/queue_entry_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../queue/presentation/view/queue_display_page.dart';
import '../../../queue/data/repositories/queue_repository.dart';

class PatientQueuePage extends StatefulWidget {
  const PatientQueuePage({super.key});

  @override
  State<PatientQueuePage> createState() => _PatientQueuePageState();
}

class _PatientQueuePageState extends State<PatientQueuePage> {
  String? _currentPatientId;
  String? _currentPatientName;
  List<QueueEntry> _allQueues = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  final QueueRepository _queueRepository =
      AppDependencyInjection.queueRepository;

  @override
  void initState() {
    super.initState();
    _initializePatientInfo();
    _startAutoRefresh();
    _checkIndexStatus();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh queue data every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _currentPatientId != null) {
        _loadPatientQueues();
      }
    });
  }

  Future<void> _initializePatientInfo() async {
    final authCubit = context.read<AuthCubit>();
    final currentUser = await authCubit.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        _currentPatientId = currentUser.id;
        _currentPatientName = currentUser.name;
      });

      // Load all queues for this patient
      await _loadPatientQueues();
    }
  }

  Future<void> _loadPatientQueues() async {
    if (_currentPatientId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get all doctors' queues where this patient is present
      // We'll need to search through all queues to find this patient
      await _searchPatientInAllQueues();
    } catch (e) {
      print('Error loading patient queues: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchPatientInAllQueues() async {
    try {
      // Use the new repository method to find all queues for this patient
      final patientQueues = await _queueRepository.findPatientQueues(
        _currentPatientId!,
      );

      setState(() {
        _allQueues = patientQueues;
      });

      // Show success message if queues were found
      if (patientQueues.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم العثور على ${patientQueues.length} طابور نشط'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error searching patient in queues: $e');
      setState(() {
        _allQueues = [];
      });

      // Show error message to user
      if (mounted) {
        String errorMessage = 'فشل في تحميل بيانات الطابور';

        if (e.toString().contains('failed-precondition') ||
            e.toString().contains('فشل في الشرط المسبق')) {
          errorMessage =
              'يتم تحديث قاعدة البيانات. يرجى المحاولة مرة أخرى في غضون دقائق.';
        } else if (e.toString().contains('ALTERNATIVE_QUERY_FAILED')) {
          errorMessage = 'فشل في البحث عن الطوابير. يرجى المحاولة مرة أخرى.';
        } else {
          errorMessage = 'فشل في تحميل بيانات الطابور: $e';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              onPressed: _loadPatientQueues,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  Future<void> _checkIndexStatus() async {
    try {
      final isIndexAvailable = await _queueRepository
          .isCollectionGroupIndexAvailable();
      if (!isIndexAvailable) {
        print(
          '⚠️ Firestore index not available - using alternative query method',
        );
        print('Index creation instructions:');
        print(_queueRepository.getIndexCreationInstructions());
      }
    } catch (e) {
      print('Error checking index status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("حالة الطابور"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (_allQueues.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${_allQueues.length}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      floatingActionButton: _allQueues.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/patient/book-appointment');
              },
              backgroundColor: Colors.green.shade600,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "انضم لطابور جديد",
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildContent() {
    if (_allQueues.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPatientQueues,
        child: _buildNoQueuesMessage(),
      );
    } else {
      return RefreshIndicator(
        onRefresh: _loadPatientQueues,
        child: Column(
          children: [
            _buildSummaryCard(),
            Expanded(child: _buildQueuesList()),
          ],
        ),
      );
    }
  }

  Widget _buildSummaryCard() {
    final activeQueues = _allQueues.where((q) => q.isActive).length;
    final waitingQueues = _allQueues
        .where((q) => q.status == QueueStatus.waiting)
        .length;
    final inProgressQueues = _allQueues
        .where((q) => q.status == QueueStatus.inProgress)
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.queue, size: 32, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ملخص الطوابير",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "مرحباً ${_currentPatientName ?? 'المريض'}",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                "إجمالي الطوابير",
                "$activeQueues",
                Icons.list_alt,
              ),
              _buildSummaryItem(
                "في الانتظار",
                "$waitingQueues",
                Icons.schedule,
              ),
              _buildSummaryItem(
                "قيد المعالجة",
                "$inProgressQueues",
                Icons.medical_services,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.white.withOpacity(0.9)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNoQueuesMessage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.queue_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          Text(
            "لا توجد طوابير نشطة",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "أنت لست منضم لأي طابور حالياً",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildInstructionsCard(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  "كيفية الانضمام للطابور",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInstructionStep(
              "1",
              "اختر الدكتور",
              "اذهب إلى صفحة حجز موعد واختر الدكتور المناسب",
              Icons.person_search,
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
              "2",
              "أكمل الاستبيان",
              "أجب على جميع الأسئلة الطبية المطلوبة",
              Icons.quiz,
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
              "3",
              "انضم للطابور تلقائياً",
              "سيتم إضافتك للطابور تلقائياً بعد إكمال الاستبيان",
              Icons.queue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(
    String number,
    String title,
    String description,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: "تحديث حالة الطابور",
          onPressed: _loadPatientQueues,
          type: ButtonType.primary,
          icon: Icons.refresh,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: "حجز موعد جديد",
          onPressed: () =>
              Navigator.pushNamed(context, '/patient/book-appointment'),
          type: ButtonType.success,
          icon: Icons.calendar_today,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: "العودة للصفحة الرئيسية",
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/patient-home'),
          type: ButtonType.secondary,
          icon: Icons.home,
        ),
      ],
    );
  }

  Widget _buildQueuesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allQueues.length + 1, // +1 for the header
      itemBuilder: (context, index) {
        if (index == 0) {
          // Header with refresh info
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "طوابيرك النشطة",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        "يتم التحديث تلقائياً كل 30 ثانية",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadPatientQueues,
                  icon: Icon(Icons.refresh, color: Colors.blue.shade600),
                  tooltip: "تحديث الطوابير",
                ),
              ],
            ),
          );
        }

        final queueEntry = _allQueues[index - 1];
        return _buildQueueCard(queueEntry);
      },
    );
  }

  Widget _buildQueueCard(QueueEntry queueEntry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _getStatusColor(
                    queueEntry.status,
                  ).withOpacity(0.2),
                  child: Icon(
                    _getStatusIcon(queueEntry.status),
                    color: _getStatusColor(queueEntry.status),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "طابور الدكتور ${queueEntry.doctorId}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "الحالة: ${queueEntry.statusDisplayName}",
                        style: TextStyle(
                          color: _getStatusColor(queueEntry.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                // Queue position badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: FutureBuilder<int>(
                    future: _getQueuePosition(
                      queueEntry.doctorId,
                      queueEntry.patientId,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        );
                      }

                      final position = snapshot.data ?? -1;
                      if (position > 0) {
                        return Text(
                          "رقم $position",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        );
                      } else {
                        return const Text(
                          "غير محدد",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Additional queue information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "انضم: ${_formatTime(queueEntry.timestamp)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "معرف الطابور: ${queueEntry.id}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QueueDisplayPage(
                            doctorId: queueEntry.doctorId,
                            doctorName: null,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, color: Colors.white),
                    label: const Text(
                      "عرض تفاصيل الطابور",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get queue position
  Future<int> _getQueuePosition(String doctorId, String patientId) async {
    try {
      return await _queueRepository.getPatientQueuePositionNumber(
        doctorId,
        patientId,
      );
    } catch (e) {
      print('Error getting queue position: $e');
      return -1;
    }
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

  IconData _getStatusIcon(QueueStatus status) {
    switch (status) {
      case QueueStatus.waiting:
        return Icons.schedule;
      case QueueStatus.inProgress:
        return Icons.medical_services;
      case QueueStatus.done:
        return Icons.check_circle;
      case QueueStatus.cancelled:
        return Icons.cancel;
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

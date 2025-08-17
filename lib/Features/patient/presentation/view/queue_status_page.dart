import 'package:flutter/material.dart';
import '../../../auth/presentation/view/widgets/common_app_bar.dart';
import '../../../auth/presentation/view/widgets/custom_button.dart';

class QueueStatusPage extends StatefulWidget {
  const QueueStatusPage({super.key});

  @override
  State<QueueStatusPage> createState() => _QueueStatusPageState();
}

class _QueueStatusPageState extends State<QueueStatusPage> {
  bool _isRefreshing = false;
  int _currentPosition = 5;
  int _estimatedWaitTime = 25;

  void _refreshQueueStatus() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _currentPosition = 4; // Simulate position change
        _estimatedWaitTime = 20; // Simulate time change
        _isRefreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم تحديث حالة الطابور"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: "حالة الطابور",
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildQueueStatusCard(),
            const SizedBox(height: 30),
            _buildQueueInfoCard(),
            const SizedBox(height: 30),
            _buildEstimatedTimeCard(),
            const Spacer(),
            CustomButton(
              text: "تحديث",
              onPressed: _isRefreshing ? null : _refreshQueueStatus,
              isLoading: _isRefreshing,
              type: ButtonType.primary,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueStatusCard() {
    return Card(
      elevation: 8,
      color: Colors.orange,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.queue, size: 60, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              "موقعك في الطابور",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "#$_currentPosition",
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  "معلومات الطابور",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              icon: Icons.person,
              label: "إجمالي الأشخاص في الطابور",
              value: "15",
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.access_time,
              label: "متوسط وقت الانتظار لكل شخص",
              value: "5 دقائق",
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.location_on,
              label: "موقع العيادة",
              value: "الطابق الأول - غرفة 101",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimatedTimeCard() {
    return Card(
      elevation: 4,
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                const Text(
                  "الوقت المتوقع للانتظار",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    "$_estimatedWaitTime دقيقة",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "هذا الوقت تقديري وقد يتغير حسب الظروف",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

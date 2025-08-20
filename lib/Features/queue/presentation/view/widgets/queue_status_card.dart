import 'package:flutter/material.dart';
import 'package:smart_doc/Features/queue/data/models/queue_entry_model.dart';

class QueueStatusCard extends StatelessWidget {
  final QueueEntry queueEntry;
  final int? queuePosition;
  final VoidCallback? onLeaveQueue;
  final bool showLeaveButton;

  const QueueStatusCard({
    super.key,
    required this.queueEntry,
    this.queuePosition,
    this.onLeaveQueue,
    this.showLeaveButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildQueueInfo(),
            const SizedBox(height: 20),
            _buildStatusIndicator(),
            if (showLeaveButton && onLeaveQueue != null) ...[
              const SizedBox(height: 20),
              _buildLeaveButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.queue, size: 32, color: Colors.blue.shade700),
        const SizedBox(width: 12),
        Text(
          "حالة الطابور",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildQueueInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoItem(
          icon: Icons.numbers,
          label: "رقم الطابور",
          value: queuePosition != null ? "#$queuePosition" : "غير محدد",
          color: Colors.orange,
        ),
        _buildInfoItem(
          icon: Icons.access_time,
          label: "وقت الانضمام",
          value: _formatTime(queueEntry.timestamp),
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildStatusIndicator() {
    Color statusColor;
    IconData statusIcon;

    switch (queueEntry.status) {
      case QueueStatus.waiting:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case QueueStatus.inProgress:
        statusColor = Colors.green;
        statusIcon = Icons.play_circle_outline;
        break;
      case QueueStatus.done:
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        break;
      case QueueStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 8),
          Text(
            queueEntry.statusDisplayName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onLeaveQueue,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red.shade700,
          side: BorderSide(color: Colors.red.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.exit_to_app),
        label: const Text(
          "مغادرة الطابور",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
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
      return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    }
  }
}

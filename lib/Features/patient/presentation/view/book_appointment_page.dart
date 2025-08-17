import 'package:flutter/material.dart';
import '../../../auth/presentation/view/widgets/common_app_bar.dart';
import '../../../auth/presentation/view/widgets/custom_button.dart';

class BookAppointmentPage extends StatelessWidget {
  const BookAppointmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: "حجز موعد",
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "اختر الدكتور",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "اضغط على زر الحجز لحجز موعد مع الدكتور المطلوب",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _dummyDoctors.length,
                itemBuilder: (context, index) {
                  final doctor = _dummyDoctors[index];
                  return _DoctorCard(doctor: doctor);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final _DummyDoctor doctor;

  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.green.withOpacity(0.1),
              child: Icon(
                Icons.medical_services,
                size: 30,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialization,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        doctor.rating.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "متاح ${doctor.availability}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            CustomButton(
              text: "حجز",
              onPressed: () => _showBookingDialog(context, doctor),
              type: ButtonType.success,
              isFullWidth: false,
              width: 80,
              height: 40,
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context, _DummyDoctor doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("حجز موعد مع ${doctor.name}"),
        content: const Text(
          "سيتم إرسال طلب الحجز إلى الدكتور. ستصلك رسالة تأكيد قريباً.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          CustomButton(
            text: "تأكيد الحجز",
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar(context);
            },
            type: ButtonType.success,
            isFullWidth: false,
            width: 120,
            height: 40,
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم إرسال طلب الحجز بنجاح!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _DummyDoctor {
  final String name;
  final String specialization;
  final double rating;
  final String availability;

  const _DummyDoctor({
    required this.name,
    required this.specialization,
    required this.rating,
    required this.availability,
  });
}

final List<_DummyDoctor> _dummyDoctors = [
  const _DummyDoctor(
    name: "د. أحمد محمد",
    specialization: "طب عام",
    rating: 4.8,
    availability: "اليوم",
  ),
  const _DummyDoctor(
    name: "د. فاطمة علي",
    specialization: "أمراض القلب",
    rating: 4.9,
    availability: "غداً",
  ),
  const _DummyDoctor(
    name: "د. محمد حسن",
    specialization: "طب الأطفال",
    rating: 4.7,
    availability: "اليوم",
  ),
  const _DummyDoctor(
    name: "د. سارة أحمد",
    specialization: "طب النساء",
    rating: 4.6,
    availability: "غداً",
  ),
  const _DummyDoctor(
    name: "د. علي محمود",
    specialization: "طب العظام",
    rating: 4.5,
    availability: "اليوم",
  ),
];

import 'package:smart_doc/Features/patient/data/repositories/booking_repository.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';

class MockBookingRepositoryImpl implements BookingRepository {
  // Mock data
  final List<Doctor> _mockDoctors = [
    const Doctor(
      id: '1',
      name: 'د. أحمد محمد',
      specialization: 'طب عام',
      rating: 4.8,
      availability: 'اليوم',
      description: 'طبيب عام ذو خبرة 15 سنة في مجال الطب العام',
      availableTimeSlots: ['09:00', '10:00', '11:00', '14:00', '15:00'],
    ),
    const Doctor(
      id: '2',
      name: 'د. فاطمة علي',
      specialization: 'أمراض القلب',
      rating: 4.9,
      availability: 'غداً',
      description: 'أخصائية أمراض القلب والأوعية الدموية',
      availableTimeSlots: ['08:00', '09:00', '10:00', '13:00', '14:00'],
    ),
    const Doctor(
      id: '3',
      name: 'د. محمد حسن',
      specialization: 'طب الأطفال',
      rating: 4.7,
      availability: 'اليوم',
      description: 'طبيب أطفال متخصص في رعاية الرضع والأطفال',
      availableTimeSlots: ['09:30', '10:30', '11:30', '14:30', '15:30'],
    ),
    const Doctor(
      id: '4',
      name: 'د. سارة أحمد',
      specialization: 'طب النساء',
      rating: 4.6,
      availability: 'غداً',
      description: 'أخصائية أمراض النساء والتوليد',
      availableTimeSlots: ['08:30', '09:30', '10:30', '13:30', '14:30'],
    ),
    const Doctor(
      id: '5',
      name: 'د. علي محمود',
      specialization: 'طب العظام',
      rating: 4.5,
      availability: 'اليوم',
      description: 'أخصائي جراحة العظام والمفاصل',
      availableTimeSlots: ['09:00', '10:00', '11:00', '14:00', '15:00'],
    ),
  ];

  final List<Appointment> _mockAppointments = [];

  @override
  Future<List<Doctor>> getAvailableDoctors() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockDoctors;
  }

  @override
  Future<Doctor?> getDoctorById(String doctorId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockDoctors.firstWhere((doctor) => doctor.id == doctorId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<String>> getAvailableTimeSlots(
    String doctorId,
    DateTime date,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final doctor = await getDoctorById(doctorId);
    if (doctor == null) return [];

    // Filter out already booked slots
    final bookedSlots = _mockAppointments
        .where(
          (appointment) =>
              appointment.doctorId == doctorId &&
              appointment.appointmentDate.day == date.day &&
              appointment.appointmentDate.month == date.month &&
              appointment.appointmentDate.year == date.year,
        )
        .map((appointment) => appointment.timeSlot)
        .toList();

    return doctor.availableTimeSlots
        .where((slot) => !bookedSlots.contains(slot))
        .toList();
  }

  @override
  Future<Appointment> createAppointment({
    required String patientId,
    required String doctorId,
    required String timeSlot,
    required DateTime appointmentDate,
    required Map<String, dynamic> questionnaireAnswers,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final appointment = Appointment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: patientId,
      doctorId: doctorId,
      timeSlot: timeSlot,
      appointmentDate: appointmentDate,
      status: AppointmentStatus.pending,
      createdAt: DateTime.now(),
      questionnaireAnswers: questionnaireAnswers,
    );

    _mockAppointments.add(appointment);
    return appointment;
  }

  @override
  Future<List<Appointment>> getPatientAppointments(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockAppointments
        .where((appointment) => appointment.patientId == patientId)
        .toList();
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _mockAppointments.removeWhere(
      (appointment) => appointment.id == appointmentId,
    );
  }

  @override
  Future<Appointment> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final appointmentIndex = _mockAppointments.indexWhere(
      (appointment) => appointment.id == appointmentId,
    );

    if (appointmentIndex == -1) {
      throw const BookingException('Appointment not found');
    }

    final appointment = _mockAppointments[appointmentIndex];
    final updatedAppointment = appointment.copyWith(
      status: AppointmentStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => AppointmentStatus.pending,
      ),
    );

    _mockAppointments[appointmentIndex] = updatedAppointment;
    return updatedAppointment;
  }
}

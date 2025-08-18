import '../../data/models/appointment.dart';
import '../../data/models/doctor.dart';

abstract class BookingRepository {
  /// Get all available doctors
  Future<List<Doctor>> getAvailableDoctors();

  /// Get doctor by ID
  Future<Doctor?> getDoctorById(String doctorId);

  /// Get available time slots for a specific doctor and date
  Future<List<String>> getAvailableTimeSlots(String doctorId, DateTime date);

  /// Create a new appointment with questionnaire answers
  Future<Appointment> createAppointment({
    required String patientId,
    required String doctorId,
    required String timeSlot,
    required DateTime appointmentDate,
    required Map<String, dynamic> questionnaireAnswers,
  });

  /// Get appointments for a patient
  Future<List<Appointment>> getPatientAppointments(String patientId);

  /// Cancel an appointment
  Future<void> cancelAppointment(String appointmentId);

  /// Update appointment status
  Future<Appointment> updateAppointmentStatus(
    String appointmentId,
    String status,
  );
}

/// Custom exception for booking errors
class BookingException implements Exception {
  final String message;
  final String? code;

  const BookingException(this.message, {this.code});

  @override
  String toString() =>
      'BookingException: $message${code != null ? ' (Code: $code)' : ''}';
}

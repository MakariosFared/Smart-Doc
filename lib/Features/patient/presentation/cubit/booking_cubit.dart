import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../data/models/appointment.dart';
import '../../data/models/doctor.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final BookingRepository _bookingRepository;

  BookingCubit({required BookingRepository bookingRepository})
    : _bookingRepository = bookingRepository,
      super(const BookingInitial());

  /// Load available doctors
  Future<void> loadAvailableDoctors() async {
    try {
      emit(const BookingLoading());
      final doctors = await _bookingRepository.getAvailableDoctors();
      emit(DoctorsLoaded(doctors));
    } catch (e) {
      emit(BookingFailure('فشل في تحميل قائمة الأطباء: $e'));
    }
  }

  /// Load available time slots for a doctor
  Future<void> loadAvailableTimeSlots(String doctorId, DateTime date) async {
    try {
      emit(const TimeSlotsLoading());
      final timeSlots = await _bookingRepository.getAvailableTimeSlots(
        doctorId,
        date,
      );
      emit(TimeSlotsLoaded(timeSlots));
    } catch (e) {
      emit(BookingFailure('فشل في تحميل المواعيد المتاحة: $e'));
    }
  }

  /// Select a doctor for booking
  void selectDoctor(Doctor doctor) {
    emit(DoctorSelected(doctor));
  }

  /// Select a time slot
  void selectTimeSlot(String timeSlot, DateTime date) {
    if (state is DoctorSelected) {
      final currentState = state as DoctorSelected;
      emit(
        TimeSlotSelected(
          doctor: currentState.doctor,
          timeSlot: timeSlot,
          date: date,
        ),
      );
    }
  }

  /// Create appointment with questionnaire answers
  Future<void> createAppointment({
    required String patientId,
    required String doctorId,
    required String timeSlot,
    required DateTime appointmentDate,
    required Map<String, dynamic> questionnaireAnswers,
  }) async {
    try {
      emit(const AppointmentCreating());

      final appointment = await _bookingRepository.createAppointment(
        patientId: patientId,
        doctorId: doctorId,
        timeSlot: timeSlot,
        appointmentDate: appointmentDate,
        questionnaireAnswers: questionnaireAnswers,
      );

      emit(AppointmentCreated(appointment));
    } catch (e) {
      emit(BookingFailure('فشل في إنشاء الموعد: $e'));
    }
  }

  /// Load patient appointments
  Future<void> loadPatientAppointments(String patientId) async {
    try {
      emit(const AppointmentsLoading());
      final appointments = await _bookingRepository.getPatientAppointments(
        patientId,
      );
      emit(AppointmentsLoaded(appointments));
    } catch (e) {
      emit(BookingFailure('فشل في تحميل المواعيد: $e'));
    }
  }

  /// Cancel appointment
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      emit(const AppointmentCancelling());
      await _bookingRepository.cancelAppointment(appointmentId);

      // Reload appointments if we have a current state with appointments
      if (state is AppointmentsLoaded) {
        final currentState = state as AppointmentsLoaded;
        final updatedAppointments = currentState.appointments
            .where((appointment) => appointment.id != appointmentId)
            .toList();
        emit(AppointmentsLoaded(updatedAppointments));
      }
    } catch (e) {
      emit(BookingFailure('فشل في إلغاء الموعد: $e'));
    }
  }

  /// Update appointment status
  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      emit(const AppointmentUpdating());
      final updatedAppointment = await _bookingRepository
          .updateAppointmentStatus(appointmentId, status);

      // Update the appointment in the current state if we have appointments loaded
      if (state is AppointmentsLoaded) {
        final currentState = state as AppointmentsLoaded;
        final updatedAppointments = currentState.appointments.map((
          appointment,
        ) {
          if (appointment.id == appointmentId) {
            return updatedAppointment;
          }
          return appointment;
        }).toList();
        emit(AppointmentsLoaded(updatedAppointments));
      }
    } catch (e) {
      emit(BookingFailure('فشل في تحديث حالة الموعد: $e'));
    }
  }

  /// Reset to initial state
  void reset() {
    emit(const BookingInitial());
  }

  /// Clear error state
  void clearError() {
    if (state is BookingFailure) {
      emit(const BookingInitial());
    }
  }
}

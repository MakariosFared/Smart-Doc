import 'package:equatable/equatable.dart';
import '../../data/models/appointment.dart';
import '../../data/models/doctor.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class BookingInitial extends BookingState {
  const BookingInitial();
}

/// Loading state
class BookingLoading extends BookingState {
  const BookingLoading();
}

/// Doctors loaded successfully
class DoctorsLoaded extends BookingState {
  final List<Doctor> doctors;

  const DoctorsLoaded(this.doctors);

  @override
  List<Object?> get props => [doctors];
}

/// Doctor selected for booking
class DoctorSelected extends BookingState {
  final Doctor doctor;

  const DoctorSelected(this.doctor);

  @override
  List<Object?> get props => [doctor];
}

/// Time slots loading
class TimeSlotsLoading extends BookingState {
  const TimeSlotsLoading();
}

/// Time slots loaded successfully
class TimeSlotsLoaded extends BookingState {
  final List<String> timeSlots;

  const TimeSlotsLoaded(this.timeSlots);

  @override
  List<Object?> get props => [timeSlots];
}

/// Time slot selected
class TimeSlotSelected extends BookingState {
  final Doctor doctor;
  final String timeSlot;
  final DateTime date;

  const TimeSlotSelected({
    required this.doctor,
    required this.timeSlot,
    required this.date,
  });

  @override
  List<Object?> get props => [doctor, timeSlot, date];
}

/// Appointment creation in progress
class AppointmentCreating extends BookingState {
  const AppointmentCreating();
}

/// Appointment created successfully
class AppointmentCreated extends BookingState {
  final Appointment appointment;

  const AppointmentCreated(this.appointment);

  @override
  List<Object?> get props => [appointment];
}

/// Appointments loading
class AppointmentsLoading extends BookingState {
  const AppointmentsLoading();
}

/// Appointments loaded successfully
class AppointmentsLoaded extends BookingState {
  final List<Appointment> appointments;

  const AppointmentsLoaded(this.appointments);

  @override
  List<Object?> get props => [appointments];
}

/// Appointment cancellation in progress
class AppointmentCancelling extends BookingState {
  const AppointmentCancelling();
}

/// Appointment update in progress
class AppointmentUpdating extends BookingState {
  const AppointmentUpdating();
}

/// Booking failure
class BookingFailure extends BookingState {
  final String message;

  const BookingFailure(this.message);

  @override
  List<Object?> get props => [message];
}

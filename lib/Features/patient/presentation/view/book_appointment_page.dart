import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/view/widgets/common_app_bar.dart';
import '../../../auth/presentation/view/widgets/custom_button.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import '../../data/models/doctor.dart';
import 'package:intl/intl.dart';

class BookAppointmentPage extends StatefulWidget {
  const BookAppointmentPage({super.key});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  DateTime _selectedDate = DateTime.now();
  Doctor? _selectedDoctor;
  String? _selectedTimeSlot;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Load available doctors when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctors();
    });
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await context.read<BookingCubit>().loadAvailableDoctors();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: "حجز موعد",
        backgroundColor: Colors.green,
      ),
      body: BlocConsumer<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is AppointmentCreated) {
            // Navigate to questionnaire after successful appointment creation
            Navigator.pushReplacementNamed(
              context,
              '/patient/questionnaire-screen',
              arguments: {
                'doctorId': _selectedDoctor!.id,
                'timeSlot': _selectedTimeSlot!,
                'date': _selectedDate,
                'appointmentId': state.appointment.id,
              },
            );
          } else if (state is BookingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BookingLoading && !_isRefreshing) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DoctorsLoaded) {
            return _buildDoctorsList(state.doctors);
          } else if (state is DoctorSelected) {
            return _buildTimeSlotSelection(state.doctor);
          } else if (state is TimeSlotsLoading) {
            return _buildTimeSlotSelection(_selectedDoctor!);
          } else if (state is TimeSlotsLoaded) {
            return _buildTimeSlotSelection(_selectedDoctor!);
          } else if (state is TimeSlotSelected) {
            return _buildConfirmationPage(
              state.doctor,
              state.timeSlot,
              state.date,
            );
          } else if (state is AppointmentCreating) {
            return _buildLoadingPage();
          } else if (state is BookingFailure) {
            return _buildErrorState(state.message);
          } else {
            return _buildDoctorsList([]);
          }
        },
      ),
    );
  }

  Widget _buildDoctorsList(List<Doctor> doctors) {
    return RefreshIndicator(
      onRefresh: _loadDoctors,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "اختر الدكتور",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (_isRefreshing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              doctors.isEmpty
                  ? "جاري البحث عن الأطباء المتاحين..."
                  : "تم العثور على ${doctors.length} طبيب متاح",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (doctors.isEmpty && !_isRefreshing)
              _buildEmptyDoctorsState()
            else if (doctors.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    return _DoctorCard(
                      doctor: doctor,
                      onTap: () => _selectDoctor(doctor),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDoctorsState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "لا يوجد أطباء متاحين",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "يرجى المحاولة مرة أخرى لاحقاً",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: "إعادة المحاولة",
              onPressed: _loadDoctors,
              type: ButtonType.primary,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            "حدث خطأ",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: "إعادة المحاولة",
            onPressed: _loadDoctors,
            type: ButtonType.primary,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotSelection(Doctor doctor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDoctorInfo(doctor),
          const SizedBox(height: 24),
          const Text(
            "اختر التاريخ والوقت",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          _buildDateSelector(),
          const SizedBox(height: 24),
          const Text(
            "المواعيد المتاحة:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildTimeSlotsGrid(doctor)),
        ],
      ),
    );
  }

  Widget _buildDoctorInfo(Doctor doctor) {
    return Card(
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "التاريخ:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('EEEE, d MMMM yyyy', 'ar').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today),
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotsGrid(Doctor doctor) {
    return FutureBuilder<List<String>>(
      future: _getAvailableTimeSlots(doctor.id, _selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('خطأ في تحميل المواعيد: ${snapshot.error}'),
          );
        }

        final timeSlots = snapshot.data ?? [];
        if (timeSlots.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد مواعيد متاحة في هذا التاريخ',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: timeSlots.length,
          itemBuilder: (context, index) {
            final timeSlot = timeSlots[index];
            final isSelected = _selectedTimeSlot == timeSlot;

            return InkWell(
              onTap: () => _selectTimeSlot(timeSlot),
              child: Card(
                elevation: isSelected ? 4 : 2,
                color: isSelected ? Colors.green.withOpacity(0.1) : null,
                child: Container(
                  decoration: BoxDecoration(
                    border: isSelected
                        ? Border.all(color: Colors.green, width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      timeSlot,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.green : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConfirmationPage(Doctor doctor, String timeSlot, DateTime date) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDoctorInfo(doctor),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "تفاصيل الموعد",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow("الدكتور:", doctor.name),
                  _buildDetailRow("التخصص:", doctor.specialization),
                  _buildDetailRow(
                    "التاريخ:",
                    DateFormat('EEEE, d MMMM yyyy', 'ar').format(date),
                  ),
                  _buildDetailRow("الوقت:", timeSlot),
                  const SizedBox(height: 24),
                  const Text(
                    "ملاحظة: ستحتاج إلى إكمال استبيان طبي قبل تأكيد الموعد",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          CustomButton(
            text: "متابعة إلى الاستبيان",
            onPressed: () => _proceedToQuestionnaire(doctor, timeSlot, date),
            type: ButtonType.success,
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("جاري إنشاء الموعد...", style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  void _selectDoctor(Doctor doctor) {
    setState(() {
      _selectedDoctor = doctor;
      _selectedTimeSlot = null;
    });
    context.read<BookingCubit>().selectDoctor(doctor);
  }

  void _selectTimeSlot(String timeSlot) {
    setState(() {
      _selectedTimeSlot = timeSlot;
    });
    if (_selectedDoctor != null) {
      context.read<BookingCubit>().selectTimeSlot(timeSlot, _selectedDate);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('ar'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
      });

      if (_selectedDoctor != null) {
        context.read<BookingCubit>().loadAvailableTimeSlots(
          _selectedDoctor!.id,
          _selectedDate,
        );
      }
    }
  }

  Future<List<String>> _getAvailableTimeSlots(
    String doctorId,
    DateTime date,
  ) async {
    try {
      return await context.read<BookingCubit>().getAvailableTimeSlotsDirect(
        doctorId,
        date,
      );
    } catch (e) {
      // Fallback to default time slots if there's an error
      return ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'];
    }
  }

  void _proceedToQuestionnaire(Doctor doctor, String timeSlot, DateTime date) {
    // Navigate to survey screen before confirming the appointment
    Navigator.pushReplacementNamed(
      context,
      '/patient/survey',
      arguments: {
        'doctorId': doctor.id,
        'timeSlot': timeSlot,
        'date': date,
        'isNewBooking': true,
      },
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;

  const _DoctorCard({required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
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
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

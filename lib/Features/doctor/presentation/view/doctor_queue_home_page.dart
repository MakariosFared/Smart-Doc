import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/view/widgets/common_app_bar.dart';
import '../../../auth/presentation/view/widgets/custom_button.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/data/models/app_user.dart';
import 'doctor_home_page.dart';

class DoctorQueueHomePage extends StatefulWidget {
  const DoctorQueueHomePage({super.key});

  @override
  State<DoctorQueueHomePage> createState() => _DoctorQueueHomePageState();
}

class _DoctorQueueHomePageState extends State<DoctorQueueHomePage> {
  List<AppUser> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final doctors = await context.read<AuthCubit>().getAllDoctors();

      if (mounted) {
        setState(() {
          _doctors = doctors;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل في تحميل قائمة الأطباء: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: "إدارة الطابور",
        backgroundColor: Colors.green,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadDoctors,
        backgroundColor: Colors.green,
        child: const Icon(Icons.refresh, color: Colors.white),
        tooltip: "تحديث القائمة",
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_doctors.isEmpty) {
      return _buildEmptyState();
    }

    return _buildDoctorsList();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            "حدث خطأ",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: "إعادة المحاولة",
            onPressed: _loadDoctors,
            type: ButtonType.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "لا يوجد أطباء",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "لم يتم العثور على أطباء في النظام",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.medical_services,
                color: Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "الأطباء المتاحون (${_doctors.length})",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _doctors.length,
            itemBuilder: (context, index) {
              final doctor = _doctors[index];
              return _buildDoctorCard(doctor, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorCard(AppUser doctor, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _openDoctorQueue(doctor),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green.shade600,
                child: Text(
                  "${index}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "البريد الإلكتروني: ${doctor.emailOrPhone}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "الدور: ${doctor.roleDisplayName}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.queue, color: Colors.green.shade600, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _openDoctorQueue(AppUser doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorHomePage(doctorId: doctor.id),
      ),
    );
  }
}

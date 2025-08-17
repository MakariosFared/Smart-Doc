import 'package:flutter/material.dart';
import '../../../auth/presentation/view/widgets/common_app_bar.dart';
import '../../../auth/presentation/view/widgets/custom_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  bool _isSaving = false;

  // Dummy patient data
  String _patientName = "أحمد محمد";
  String _patientEmail = "ahmed.mohamed@email.com";
  String _patientPhone = "+966 50 123 4567";
  String _patientAge = "28";
  String _patientGender = "ذكر";
  String _patientAddress = "الرياض، المملكة العربية السعودية";

  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _patientName);
    _emailController = TextEditingController(text: _patientEmail);
    _phoneController = TextEditingController(text: _patientPhone);
    _ageController = TextEditingController(text: _patientAge);
    _addressController = TextEditingController(text: _patientAddress);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: "الملف الشخصي",
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 30),
            _buildProfileInfo(),
            const SizedBox(height: 30),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.teal,
            child: Text(
              _patientName.split(' ').map((e) => e[0]).join(''),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _patientName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "مريض",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.teal, size: 24),
                const SizedBox(width: 12),
                const Text(
                  "المعلومات الشخصية",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoField(
              icon: Icons.person,
              label: "الاسم الكامل",
              value: _isEditing ? null : _patientName,
              controller: _isEditing ? _nameController : null,
            ),
            const SizedBox(height: 20),
            _buildInfoField(
              icon: Icons.email,
              label: "البريد الإلكتروني",
              value: _isEditing ? null : _patientEmail,
              controller: _isEditing ? _emailController : null,
            ),
            const SizedBox(height: 20),
            _buildInfoField(
              icon: Icons.phone,
              label: "رقم الهاتف",
              value: _isEditing ? null : _patientPhone,
              controller: _isEditing ? _phoneController : null,
            ),
            const SizedBox(height: 20),
            _buildInfoField(
              icon: Icons.cake,
              label: "العمر",
              value: _isEditing ? null : "$_patientAge سنة",
              controller: _isEditing ? _ageController : null,
            ),
            const SizedBox(height: 20),
            _buildInfoField(
              icon: Icons.person_outline,
              label: "الجنس",
              value: _patientGender,
              isReadOnly: true,
            ),
            const SizedBox(height: 20),
            _buildInfoField(
              icon: Icons.location_on,
              label: "العنوان",
              value: _isEditing ? null : _patientAddress,
              controller: _isEditing ? _addressController : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required IconData icon,
    required String label,
    String? value,
    TextEditingController? controller,
    bool isReadOnly = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (_isEditing && controller != null && !isReadOnly)
                TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                )
              else
                Text(
                  value ?? "",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: _isEditing ? "حفظ التغييرات" : "تعديل",
            onPressed: _isEditing ? _saveChanges : _startEditing,
            isLoading: _isSaving,
            type: _isEditing ? ButtonType.success : ButtonType.primary,
            icon: _isEditing ? Icons.save : Icons.edit,
          ),
        ),
        if (_isEditing) ...[
          const SizedBox(width: 16),
          Expanded(
            child: CustomButton(
              text: "إلغاء",
              onPressed: _cancelEditing,
              type: ButtonType.secondary,
              icon: Icons.cancel,
            ),
          ),
        ],
      ],
    );
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      // Reset controllers to current values
      _nameController.text = _patientName;
      _emailController.text = _patientEmail;
      _phoneController.text = _patientPhone;
      _ageController.text = _patientAge;
      _addressController.text = _patientAddress;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
  }

  void _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;

        // Update the displayed values
        _patientName = _nameController.text;
        _patientEmail = _emailController.text;
        _patientPhone = _phoneController.text;
        _patientAge = _ageController.text;
        _patientAddress = _addressController.text;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم حفظ التغييرات بنجاح"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

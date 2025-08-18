import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/view/widgets/common_app_bar.dart';
import '../../../auth/presentation/view/widgets/custom_button.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/data/models/app_user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  bool _isSaving = false;
  AppUser? _currentUser;

  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await context.read<AuthCubit>().getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _currentUser = user;
        _nameController.text = user.name;
        _emailController.text = user.emailOrPhone;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: "الملف الشخصي",
        backgroundColor: Colors.teal,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AuthSuccess && _currentUser != null) {
            return _buildProfileContent();
          } else if (state is AuthUnauthenticated) {
            return _buildNotAuthenticated();
          } else {
            return _buildLoadingState();
          }
        },
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_currentUser == null) return _buildLoadingState();

    return SingleChildScrollView(
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
    );
  }

  Widget _buildProfileHeader() {
    if (_currentUser == null) return const SizedBox.shrink();

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
              _currentUser!.name.split(' ').map((e) => e[0]).join(''),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentUser!.roleDisplayName,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    if (_currentUser == null) return const SizedBox.shrink();

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
              value: _isEditing ? null : _currentUser!.name,
              controller: _isEditing ? _nameController : null,
            ),
            const SizedBox(height: 20),
            _buildInfoField(
              icon: Icons.email,
              label: "البريد الإلكتروني",
              value: _isEditing ? null : _currentUser!.emailOrPhone,
              controller: _isEditing ? _emailController : null,
            ),
            const SizedBox(height: 20),
            _buildInfoField(
              icon: Icons.vpn_key,
              label: "معرف المستخدم",
              value: _currentUser!.id,
              isReadOnly: true,
            ),
            const SizedBox(height: 20),
            _buildInfoField(
              icon: Icons.verified_user,
              label: "نوع الحساب",
              value: _currentUser!.roleDisplayName,
              isReadOnly: true,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "سيتم إضافة المزيد من المعلومات (العمر، الجنس، العنوان) في التحديثات القادمة",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
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
    if (_currentUser == null) return const SizedBox.shrink();

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
    if (_currentUser == null) return;

    setState(() {
      _isEditing = true;
      // Reset controllers to current values
      _nameController.text = _currentUser!.name;
      _emailController.text = _currentUser!.emailOrPhone;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
  }

  void _saveChanges() async {
    if (_currentUser == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Here you would typically call an API to update the user profile
      // For now, we'll just simulate the update
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditing = false;

          // Update the current user with new values
          _currentUser = _currentUser!.copyWith(
            name: _nameController.text,
            emailOrPhone: _emailController.text,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم حفظ التغييرات بنجاح"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("فشل في حفظ التغييرات: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildNotAuthenticated() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "غير مسجل الدخول",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "يرجى تسجيل الدخول لعرض الملف الشخصي",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: "تسجيل الدخول",
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
            type: ButtonType.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("جاري تحميل البيانات...", style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

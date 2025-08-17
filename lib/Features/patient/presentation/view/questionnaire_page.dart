import 'package:flutter/material.dart';
import '../../../auth/presentation/view/widgets/common_app_bar.dart';
import '../../../auth/presentation/view/widgets/custom_button.dart';

class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key});

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Form controllers
  String _selectedGender = '';
  String _selectedAgeGroup = '';
  List<String> _selectedSymptoms = [];
  String _selectedAllergies = '';
  String _selectedMedications = '';
  String _selectedChronicDiseases = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: "الاستبيان الطبي",
        backgroundColor: Colors.purple,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildPersonalInfoSection(),
              const SizedBox(height: 30),
              _buildMedicalHistorySection(),
              const SizedBox(height: 30),
              _buildSymptomsSection(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.quiz, size: 50, color: Colors.purple),
          const SizedBox(height: 16),
          const Text(
            "الاستبيان الطبي",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "يرجى الإجابة على جميع الأسئلة بدقة لمساعدتنا في تقديم أفضل رعاية طبية",
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("المعلومات الشخصية", Icons.person),
            const SizedBox(height: 20),
            _buildRadioQuestion(
              title: "الجنس",
              options: ["ذكر", "أنثى"],
              value: _selectedGender,
              onChanged: (value) => setState(() => _selectedGender = value!),
            ),
            const SizedBox(height: 20),
            _buildRadioQuestion(
              title: "الفئة العمرية",
              options: ["18-25", "26-35", "36-45", "46-55", "56+"],
              value: _selectedAgeGroup,
              onChanged: (value) => setState(() => _selectedAgeGroup = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistorySection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("التاريخ الطبي", Icons.medical_services),
            const SizedBox(height: 20),
            _buildTextQuestion(
              title: "هل لديك حساسية معروفة؟",
              hint: "مثال: حساسية من البنسلين، الغبار، إلخ",
              value: _selectedAllergies,
              onChanged: (value) => setState(() => _selectedAllergies = value),
            ),
            const SizedBox(height: 20),
            _buildTextQuestion(
              title: "هل تتناول أي أدوية حالياً؟",
              hint: "اذكر أسماء الأدوية والجرعات",
              value: _selectedMedications,
              onChanged: (value) =>
                  setState(() => _selectedMedications = value),
            ),
            const SizedBox(height: 20),
            _buildTextQuestion(
              title: "هل لديك أمراض مزمنة؟",
              hint: "مثال: السكري، الضغط، الربو، إلخ",
              value: _selectedChronicDiseases,
              onChanged: (value) =>
                  setState(() => _selectedChronicDiseases = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("الأعراض الحالية", Icons.healing),
            const SizedBox(height: 20),
            const Text(
              "اختر جميع الأعراض التي تنطبق عليك:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildCheckboxQuestion(
              title: "أعراض عامة",
              options: [
                "حمى",
                "صداع",
                "إرهاق",
                "فقدان الشهية",
                "ألم في العضلات",
              ],
              selectedValues: _selectedSymptoms,
              onChanged: (values) => setState(() => _selectedSymptoms = values),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: CustomButton(
        text: "إرسال الاستبيان",
        onPressed: _isSubmitting ? null : _submitQuestionnaire,
        isLoading: _isSubmitting,
        type: ButtonType.success,
        icon: Icons.send,
        height: 56,
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.purple, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildRadioQuestion({
    required String title,
    required List<String> options,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...options.map(
          (option) => RadioListTile<String>(
            title: Text(option),
            value: option,
            groupValue: value,
            onChanged: onChanged,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildTextQuestion({
    required String title,
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey.withOpacity(0.1),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildCheckboxQuestion({
    required String title,
    required List<String> options,
    required List<String> selectedValues,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...options.map(
          (option) => CheckboxListTile(
            title: Text(option),
            value: selectedValues.contains(option),
            onChanged: (checked) {
              final newValues = List<String>.from(selectedValues);
              if (checked == true) {
                newValues.add(option);
              } else {
                newValues.remove(option);
              }
              onChanged(newValues);
            },
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  void _submitQuestionnaire() async {
    final formState = _formKey.currentState;
    if (formState != null && formState.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        _showSuccessDialog();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("تم إرسال الاستبيان بنجاح"),
        content: const Text(
          "شكراً لك على إكمال الاستبيان الطبي. سيتم مراجعة إجاباتك من قبل الفريق الطبي.",
        ),
        actions: [
          CustomButton(
            text: "حسناً",
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to patient home
            },
            type: ButtonType.primary,
            isFullWidth: false,
            width: 100,
          ),
        ],
      ),
    );
  }
}

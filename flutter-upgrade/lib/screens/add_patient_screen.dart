import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // استيراد Firebase Auth
import '../models/patient.dart';
import '../services/database_service.dart';
import 'dynamic_medical_history_screen.dart';


class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _wardController = TextEditingController();
  final _roomController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedGender = 'male';
  String? _selectedDepartment;
  bool _isLoading = false;

  final List<String> _genders = ['male', 'female'];
  final List<String> _departments = [
    'Pediatrics',
    'Internal Medicine',
    'Surgery',
    'Cardiology',
    'General',
  ];

  final DatabaseService _dbService = DatabaseService();

  @override
  void dispose() {
    _nameController.dispose();
    _wardController.dispose();
    _roomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleNextStep() async {
    if (!_formKey.currentState!.validate() || _selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required fields, including department.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final age = _selectedDate != null
        ? DateTime.now().year - _selectedDate!.year
        : 0;

    // الحصول على UID الطبيب الحالي
    // تم إزالة التحقق من تسجيل الدخول للسماح بالانتقال إلى صفحة التاريخ المرضي
    // بعد تسجيل مريض جديد دون الحاجة لتسجيل الدخول.
    final currentUser = FirebaseAuth.instance.currentUser;

    // إنشاء مريض مؤقت بدون ID (سيتم تعيينه من Firestore)
    final newPatient = Patient(
      id: '', // سيتم تحديثه بعد الحفظ في Firestore
      doctorId: currentUser?.uid ?? 'anonymous',
      name: _nameController.text.trim(),
      age: age,
      gender: _selectedGender,
      dateOfBirth: _selectedDate ?? DateTime.now(),
      createdAt: DateTime.now(),
      notes: _notesController.text.trim(),
      department: _selectedDepartment!,
      wardNumber: _wardController.text.trim(),
      roomNumber: _roomController.text.trim(),
    );

    try {
      // حفظ المريض والحصول على ID الحقيقي من Firestore
      print("=== Adding new patient ===");
      final firestorePatientId = await _dbService.addPatient(newPatient);
      print("Patient added successfully with Firestore ID: $firestorePatientId");
      
      if (mounted) {
        // استخدام ID الحقيقي من Firestore
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DynamicMedicalHistoryScreen(
              patient: {
                'id': firestorePatientId, // استخدام ID من Firestore
                'name': newPatient.name,
                'age': newPatient.age,
                'gender': newPatient.gender,
                'department': newPatient.department,
              },
              department: _selectedDepartment!,
            ),
          ),
        );
      }
    } catch (e) {
      print("ERROR adding patient: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Add New Patient'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormCard(
                  title: 'Basic Information',
                  icon: Icons.person,
                  children: [
                    _buildStyledTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      isRequired: true,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Full name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDateField(theme)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildGenderDropdown(theme)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildFormCard(
                  title: 'Hospital Information',
                  icon: Icons.local_hospital,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStyledTextField(
                            controller: _wardController,
                            label: 'Ward No',
                            icon: Icons.domain,
                            isRequired: true,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Ward number is required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStyledTextField(
                            controller: _roomController,
                            label: 'Room No',
                            icon: Icons.meeting_room,
                            isRequired: true,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Room number is required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStyledTextField(
                      controller: _notesController,
                      label: 'Additional Notes',
                      icon: Icons.note_alt_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildFormCard(
                  title: 'Department Selection',
                  icon: Icons.medical_services,
                  children: [
                    Text(
                      'Select Department *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _departments.map((department) {
                        final isSelected = _selectedDepartment == department;
                        return FilterChip(
                          label: Text(department),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedDepartment = department);
                            }
                          },
                          backgroundColor: theme.colorScheme.surface,
                          selectedColor: theme.colorScheme.primary.withValues(alpha: 
                            0.2,
                          ),
                          checkmarkColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleNextStep,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward, size: 20),
                    label: Text(
                      _isLoading
                          ? 'Processing...'
                          : 'Continue to Medical History',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildDateField(ThemeData theme) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date of Birth',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Select Date',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

  Widget _buildGenderDropdown(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
      ),
      padding: const EdgeInsets.only(left: 16.0, right: 12.0),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          items: _genders.map((g) {
            return DropdownMenuItem(
              value: g,
              child: Row(
                children: [
                  Icon(
                    g == 'male' ? Icons.male : Icons.female,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    g == 'male' ? 'Male' : 'Female',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedGender = value);
            }
          },
        ),
      ),
    );
  }
}

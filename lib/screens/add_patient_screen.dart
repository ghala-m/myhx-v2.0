import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../data/departments.dart';
import '../l10n/app_strings.dart';
import '../models/patient.dart';
import '../services/role_service.dart';
import '../utils/department_icons.dart';
import '../services/database_service.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';
import 'history_mode_screen.dart';

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

  String _deptQuery = '';

  List<Department> _visibleDepartments(BuildContext context) {
    final role = context.watch<RoleService>();
    final selected = role.departments;
    var list = role.role.seesAllDepartments || selected.isEmpty
        ? Departments.all
        : Departments.all.where((d) => selected.contains(d.id)).toList();
    final q = _deptQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((d) =>
              d.nameEn.toLowerCase().contains(q) || d.nameAr.contains(q))
          .toList();
    }
    return list;
  }


  final DatabaseService _dbService = DatabaseService();

  @override
  void dispose() {
    _nameController.dispose();
    _wardController.dispose();
    _roomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _age =>
      _selectedDate != null ? DateTime.now().year - _selectedDate!.year : 0;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _handleNextStep() async {
    if (!_formKey.currentState!.validate() || _selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields, including department.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final currentUser = FirebaseAuth.instance.currentUser;

    final newPatient = Patient(
      id: '',
      doctorId: currentUser?.uid ?? 'anonymous',
      name: _nameController.text.trim(),
      age: _age,
      gender: _selectedGender,
      dateOfBirth: _selectedDate ?? DateTime.now(),
      createdAt: DateTime.now(),
      notes: _notesController.text.trim(),
      department: _selectedDepartment!,
      wardNumber: _wardController.text.trim(),
      roomNumber: _roomController.text.trim(),
    );

    try {
      final firestorePatientId = await _dbService.addPatient(newPatient);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HistoryModeScreen(
              patient: newPatient.copyWith(id: firestorePatientId),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('New Patient'),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _stepHeader(theme),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle('Basic information', Icons.person_outline),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _nameController,
                      label: 'Patient name',
                      hint: 'Full name',
                      prefixIcon: Icons.badge_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter the patient name'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      readOnly: true,
                      onTap: _pickDate,
                      label: 'Date of birth',
                      hint: _selectedDate == null
                          ? 'Select date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}  •  $_age yrs',
                      prefixIcon: Icons.cake_outlined,
                      suffixIcon: Icons.calendar_today_outlined,
                      onSuffixTap: _pickDate,
                      validator: (_) =>
                          _selectedDate == null ? 'Please select a date of birth' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Gender', style: AppTypography.titleMedium(context)),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _genderTile('male', 'Male', Icons.male_rounded),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _genderTile('female', 'Female', Icons.female_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle('Department', Icons.apartment_outlined),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search departments…',
                        prefixIcon: Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _deptQuery = v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _visibleDepartments(context)
                          .map(_departmentChip)
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle('Admission details', Icons.hotel_outlined),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _wardController,
                            label: 'Ward',
                            hint: 'A3',
                            prefixIcon: Icons.meeting_room_outlined,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            controller: _roomController,
                            label: 'Room',
                            hint: '12',
                            prefixIcon: Icons.numbers_rounded,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _notesController,
                      label: 'Notes (optional)',
                      hint: 'Anything worth remembering about this patient',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Continue to medical history',
                icon: Icons.arrow_forward_rounded,
                isLoading: _isLoading,
                onPressed: _handleNextStep,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepHeader(ThemeData theme) {
    return AppCard(
      color: theme.colorScheme.primary,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(Icons.person_add_alt_1_rounded,
                color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 1 of 2',
                  style: AppTypography.caption(context)
                      .copyWith(color: theme.colorScheme.onPrimary.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Register the patient',
                  style: AppTypography.titleLarge(context)
                      .copyWith(color: theme.colorScheme.onPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTypography.titleMedium(context)),
      ],
    );
  }

  Widget _genderTile(String value, String label, IconData icon) {
    final theme = Theme.of(context);
    final selected = _selectedGender == value;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: () => setState(() => _selectedGender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.bodyMedium(context).copyWith(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _departmentChip(Department department) {
    final theme = Theme.of(context);
    final arabic = S.of(context).isArabic;
    final selected = _selectedDepartment == department.id;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _selectedDepartment = department.id),
      avatar: Icon(
        DepartmentIcons.resolve(department.icon),
        size: 18,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(department.name(arabic)),
      showCheckmark: false,
    );
  }
}

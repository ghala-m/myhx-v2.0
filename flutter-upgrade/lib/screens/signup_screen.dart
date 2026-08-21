import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String _selectedSpecialty = 'General Medicine';
  String _selectedYear = '1st Year';

  final List<String> _specialties = [
    'General Medicine',
    'Internal Medicine',
    'Pediatrics',
    'Surgery',
    'Cardiology',
    'Neurology',
    'Orthopedics',
    'Dermatology',
    'Psychiatry',
    'Emergency Medicine',
  ];

  final List<String> _years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year',
    '6th Year',
    '7th Year',
    'Intern',
    'Resident',
    'Specialist',
    'Consultant',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  double get _passwordStrength {
    final value = _passwordController.text;
    if (value.isEmpty) return 0;
    var score = 0;
    if (value.length >= 6) score++;
    if (value.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return score / 5;
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        displayName: _nameController.text.trim(),
        specialization: _selectedSpecialty,
        academicYear: _selectedYear,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authService.getErrorMessage(e.code))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Create your account',
                        style: AppTypography.displayMedium(context)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Join myhx and take smarter medical histories.',
                      style: AppTypography.bodyMedium(context),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      controller: _nameController,
                      label: 'Full name',
                      hint: 'Dr. Sara Ahmed',
                      prefixIcon: Icons.person_outline,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email address',
                      hint: 'doctor@hospital.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter your email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _dropdown(
                      label: 'Specialty',
                      icon: Icons.medical_information_outlined,
                      value: _selectedSpecialty,
                      items: _specialties,
                      onChanged: (v) => setState(() => _selectedSpecialty = v!),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _dropdown(
                      label: 'Academic year / level',
                      icon: Icons.school_outlined,
                      value: _selectedYear,
                      items: _years,
                      onChanged: (v) => setState(() => _selectedYear = v!),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'At least 6 characters',
                      prefixIcon: Icons.lock_outline,
                      obscureText: !_isPasswordVisible,
                      suffixIcon: _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      onSuffixTap: () =>
                          setState(() => _isPasswordVisible = !_isPasswordVisible),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter a password';
                        if (v.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _strengthBar(theme),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm password',
                      hint: 'Re-enter your password',
                      prefixIcon: Icons.lock_reset_outlined,
                      obscureText: !_isConfirmPasswordVisible,
                      suffixIcon: _isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      onSuffixTap: () => setState(
                          () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                      validator: (v) => (v != _passwordController.text)
                          ? 'Passwords do not match'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Create account',
                      isLoading: _isLoading,
                      onPressed: _handleSignup,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ',
                            style: AppTypography.bodyMedium(context)),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Sign in'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _strengthBar(ThemeData theme) {
    final strength = _passwordStrength;
    final color = strength < 0.4
        ? AppColors.error
        : strength < 0.8
            ? AppColors.warning
            : AppColors.success;
    final label = strength == 0
        ? 'Password strength'
        : strength < 0.4
            ? 'Weak password'
            : strength < 0.8
                ? 'Good password'
                : 'Strong password';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: strength == 0 ? 0.02 : strength,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTypography.caption(context)),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } on Exception catch (e) {
      if (mounted) {
        final message = e is FirebaseAuthException
            ? authService.getErrorMessage(e.code)
            : 'An unexpected error occurred. Please try again.';
        _showError(message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Welcome back',
                    style: AppTypography.displayLarge(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Sign in to continue taking smarter medical histories.',
                    style: AppTypography.bodyLarge(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildForm(theme),
                  const SizedBox(height: AppSpacing.lg),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(
        Icons.medical_services_rounded,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'doctor@hospital.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your email';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            prefixIcon: Icons.lock_outlined,
            suffixIcon: _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            onSuffixTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            obscureText: !_isPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your password';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Implement forgot password flow
              },
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Sign In',
            isLoading: _isLoading,
            onPressed: _handleLogin,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: AppTypography.bodyMedium(context),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SignupScreen()),
          ),
          child: const Text('Sign Up'),
        ),
      ],
    );
  }
}

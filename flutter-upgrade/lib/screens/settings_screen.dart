import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../utils/locale_provider.dart';
import '../utils/theme_provider.dart';
import '../widgets/app_card.dart';
import '../l10n/app_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  Doctor? _doctorProfile;
  bool _isLoadingProfile = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingProfile = false);
      return;
    }
    try {
      final data = await _databaseService.getDoctorProfile(user.uid);
      if (mounted) {
        setState(() {
          _doctorProfile = data != null ? Doctor.fromJson(data, user.uid) : null;
          _isLoadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(context.tr('logout')),
        content: const Text('Are you sure you want to log out of myhx?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(context.tr('logout')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _authService.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text(context.tr('settings')),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _profileCard(theme),
            const SizedBox(height: AppSpacing.md),
            _sectionLabel('Appearance'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  _tile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark mode',
                    subtitle: 'Easier on the eyes during night shifts',
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                    ),
                  ),
                  _divider(),
                  _tile(
                    icon: Icons.settings_suggest_outlined,
                    title: 'Follow system theme',
                    subtitle: 'Match your device appearance',
                    trailing: Switch(
                      value: themeProvider.themeMode == ThemeMode.system,
                      onChanged: (v) => themeProvider.setThemeMode(
                          v ? ThemeMode.system : ThemeMode.light),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _sectionLabel('Language'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  _languageTile('English', 'en', localeProvider),
                  _divider(),
                  _languageTile('العربية', 'ar', localeProvider),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _sectionLabel('Preferences'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  _tile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Reminders for pending histories',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (v) => setState(() => _notificationsEnabled = v),
                    ),
                  ),
                  _divider(),
                  _tile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy & data',
                    subtitle: 'Patient data stays encrypted in your account',
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                  _divider(),
                  _tile(
                    icon: Icons.info_outline_rounded,
                    title: 'About myhx',
                    subtitle: 'Version 1.1.0',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'myhx',
                      applicationVersion: '1.1.0',
                      applicationLegalese:
                          'Smart medical history taking with clinical AI support.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text(context.tr('logout')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(ThemeData theme) {
    final name = _doctorProfile?.name.isNotEmpty == true
        ? _doctorProfile!.name
        : (FirebaseAuth.instance.currentUser?.displayName ?? 'Doctor');
    final email = _doctorProfile?.email.isNotEmpty == true
        ? _doctorProfile!.email
        : (FirebaseAuth.instance.currentUser?.email ?? '');
    final initials = name.trim().isEmpty
        ? 'D'
        : name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();

    return AppCard(
      child: _isLoadingProfile
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          : Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Text(
                    initials,
                    style: AppTypography.titleLarge(context)
                        .copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTypography.titleMedium(context)),
                      const SizedBox(height: 2),
                      Text(email, style: AppTypography.bodyMedium(context)),
                      if (_doctorProfile != null &&
                          _doctorProfile!.specialty.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: [
                            _pill(_doctorProfile!.specialty, theme),
                            if (_doctorProfile!.year.isNotEmpty)
                              _pill(_doctorProfile!.year, theme),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _pill(String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: AppTypography.caption(context)
            .copyWith(color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.sm),
      child: Text(text.toUpperCase(),
          style: AppTypography.caption(context).copyWith(letterSpacing: 1)),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
      );

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Icon(icon, size: 20, color: theme.colorScheme.primary),
      ),
      title: Text(title, style: AppTypography.titleMedium(context)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: AppTypography.caption(context)),
      trailing: trailing,
    );
  }

  Widget _languageTile(String label, String code, LocaleProvider provider) {
    final selected = provider.locale.languageCode == code;
    final theme = Theme.of(context);
    return ListTile(
      onTap: () => provider.setLocale(Locale(code)),
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Icon(Icons.translate_rounded,
            size: 20, color: theme.colorScheme.primary),
      ),
      title: Text(label, style: AppTypography.titleMedium(context)),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : const Icon(Icons.radio_button_unchecked_rounded),
    );
  }
}

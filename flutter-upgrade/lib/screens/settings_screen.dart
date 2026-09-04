import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/departments.dart';
import '../models/app_role.dart';
import '../models/doctor.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/feedback_service.dart';
import '../services/role_service.dart';
import '../services/translation_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_themes.dart';
import '../utils/app_typography.dart';
import '../utils/locale_provider.dart';
import '../utils/theme_provider.dart';
import '../widgets/app_card.dart';
import '../l10n/app_strings.dart';
import 'question_editor_screen.dart';
import 'role_admin_screen.dart';

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
        title: Text(context.tr('logout')),
        content: const Text('Are you sure you want to log out of myhx?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.tr('logout')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _authService.signOut();
    }
  }

  Future<void> _pickDepartments() async {
    final roles = context.read<RoleService>();
    final arabic = context.read<LocaleProvider>().isArabic;
    final selected = roles.departments.toSet();
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          builder: (ctx, controller) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        arabic ? 'أقسامي' : 'My departments',
                        style: AppTypography.titleMedium(ctx),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(selected),
                      child: Text(context.tr('save')),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    for (final group in Departments.groups.keys) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                        child: Text(group.toUpperCase(),
                            style: AppTypography.caption(ctx)
                                .copyWith(letterSpacing: 1)),
                      ),
                      for (final d in Departments.groups[group]!)
                        CheckboxListTile(
                          value: selected.contains(d.id),
                          title: Text(d.name(arabic)),
                          onChanged: (v) => setSheet(() {
                            v == true ? selected.add(d.id) : selected.remove(d.id);
                          }),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) {
      await roles.setDepartments(result.toList());
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final feedback = context.watch<FeedbackService>();
    final roles = context.watch<RoleService>();
    final arabic = localeProvider.isArabic;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: Text(context.tr('settings')),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _profileCard(theme, roles),
            const SizedBox(height: AppSpacing.md),
            _sectionLabel(arabic ? 'الثيم' : 'Theme'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(arabic ? 'لوحة الألوان' : 'Colour palette',
                      style: AppTypography.titleMedium(context)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final p in AppPalettes.all)
                        _paletteChip(p, themeProvider, arabic),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                          value: ThemeMode.light,
                          icon: const Icon(Icons.light_mode_outlined),
                          label: Text(arabic ? 'فاتح' : 'Light')),
                      ButtonSegment(
                          value: ThemeMode.system,
                          icon: const Icon(Icons.settings_suggest_outlined),
                          label: Text(arabic ? 'النظام' : 'System')),
                      ButtonSegment(
                          value: ThemeMode.dark,
                          icon: const Icon(Icons.dark_mode_outlined),
                          label: Text(arabic ? 'داكن' : 'Dark')),
                    ],
                    selected: {themeProvider.themeMode},
                    onSelectionChanged: (s) {
                      context.read<FeedbackService>().tap();
                      themeProvider.setThemeMode(s.first);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _sectionLabel(arabic ? 'اللغة' : 'Language'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  _languageTile('English', 'en', localeProvider),
                  _divider(),
                  _languageTile('العربية', 'ar', localeProvider),
                  _divider(),
                  _tile(
                    icon: Icons.translate_rounded,
                    title: arabic ? 'الترجمة التلقائية' : 'Automatic translation',
                    subtitle: arabic
                        ? 'الإدخال بالإنجليزية فقط، والعرض بالعربية يُترجم تلقائياً'
                        : 'Data entry is English-only; Arabic is generated automatically',
                    trailing: TextButton(
                      onPressed: () async {
                        await TranslationService.instance.clearCache();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(arabic
                              ? 'تم مسح ذاكرة الترجمة'
                              : 'Translation cache cleared'),
                        ));
                      },
                      child: Text(arabic ? 'مسح الذاكرة' : 'Clear cache'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _sectionLabel(arabic ? 'الأقسام' : 'Departments'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  _tile(
                    icon: Icons.local_hospital_outlined,
                    title: arabic ? 'أقسامي' : 'My departments',
                    subtitle: roles.role.seesAllDepartments
                        ? (arabic
                            ? 'الطلاب يرون جميع الأقسام (${Departments.all.length})'
                            : 'Students see all ${Departments.all.length} departments')
                        : (roles.departments.isEmpty
                            ? (arabic ? 'لم يتم الاختيار بعد' : 'None selected yet')
                            : '${roles.departments.length} selected'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _pickDepartments,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _sectionLabel(arabic ? 'التأثيرات' : 'Effects & feedback'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  _tile(
                    icon: Icons.animation_rounded,
                    title: arabic ? 'التأثيرات البصرية' : 'Motion effects',
                    subtitle: arabic
                        ? 'انتقالات ورسوم متحركة ناعمة'
                        : 'Smooth transitions and animations',
                    trailing: Switch(
                      value: feedback.motionEnabled,
                      onChanged: feedback.setMotion,
                    ),
                  ),
                  _divider(),
                  _tile(
                    icon: Icons.volume_up_outlined,
                    title: arabic ? 'الأصوات' : 'Sounds',
                    subtitle: arabic
                        ? 'أصوات النظام الأساسية عند التفاعل'
                        : 'Basic system sounds on interaction',
                    trailing: Switch(
                      value: feedback.soundEnabled,
                      onChanged: (v) {
                        feedback.setSound(v);
                        if (v) feedback.tap();
                      },
                    ),
                  ),
                  _divider(),
                  _tile(
                    icon: Icons.vibration_rounded,
                    title: arabic ? 'الاهتزاز' : 'Haptics',
                    subtitle: arabic
                        ? 'اهتزاز خفيف عند الإجراءات المهمة'
                        : 'Subtle vibration on key actions',
                    trailing: Switch(
                      value: feedback.hapticsEnabled,
                      onChanged: (v) {
                        feedback.setHaptics(v);
                        if (v) feedback.tap();
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (roles.realRole == AppRole.developer) ...[
              const SizedBox(height: AppSpacing.md),
              _sectionLabel(arabic ? 'أدوات المبرمج' : 'Developer tools'),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  children: [
                    _tile(
                      icon: Icons.quiz_outlined,
                      title: arabic ? 'محرر الأسئلة' : 'Question editor',
                      subtitle: arabic
                          ? 'إضافة أو تعديل أو إخفاء أسئلة كل قسم'
                          : 'Add, edit or hide questions per department',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const QuestionEditorScreen())),
                    ),
                    _divider(),
                    _tile(
                      icon: Icons.admin_panel_settings_outlined,
                      title: arabic ? 'الصلاحيات' : 'Roles & permissions',
                      subtitle: arabic
                          ? 'تعيين طالب / طبيب / مبرمج لأي حساب'
                          : 'Assign student / doctor / developer to any account',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const RoleAdminScreen())),
                    ),
                    _divider(),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(arabic ? 'معاينة كـ' : 'Preview as',
                              style: AppTypography.titleMedium(context)),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            children: [
                              for (final r in AppRole.values)
                                ChoiceChip(
                                  label: Text(r.label(arabic)),
                                  selected: roles.role == r,
                                  onSelected: (_) => roles.setPreviewRole(
                                      r == roles.realRole ? null : r),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _sectionLabel(arabic ? 'التفضيلات' : 'Preferences'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  _tile(
                    icon: Icons.notifications_outlined,
                    title: arabic ? 'الإشعارات' : 'Notifications',
                    subtitle: arabic
                        ? 'تذكير بالتواريخ المرضية غير المكتملة'
                        : 'Reminders for pending histories',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (v) => setState(() => _notificationsEnabled = v),
                    ),
                  ),
                  _divider(),
                  _tile(
                    icon: Icons.privacy_tip_outlined,
                    title: arabic ? 'الخصوصية والبيانات' : 'Privacy & data',
                    subtitle: arabic
                        ? 'بيانات المرضى مشفّرة داخل حسابك'
                        : 'Patient data stays encrypted in your account',
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                  _divider(),
                  _tile(
                    icon: Icons.info_outline_rounded,
                    title: arabic ? 'عن myhx' : 'About myhx',
                    subtitle: 'Version 1.2.0',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'myhx',
                      applicationVersion: '1.2.0',
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
              label: Text(context.tr('logout')),
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

  Widget _paletteChip(
      AppPalette palette, ThemeProvider provider, bool arabic) {
    final selected = provider.palette.id == palette.id;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: () {
        context.read<FeedbackService>().tap();
        provider.setPalette(palette);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 4, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: selected
                ? palette.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                gradient: palette.heroGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(palette.name(arabic),
                style: AppTypography.bodyMedium(context)),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(ThemeData theme, RoleService roles) {
    final name = _doctorProfile?.name.isNotEmpty == true
        ? _doctorProfile!.name
        : (FirebaseAuth.instance.currentUser?.displayName ?? 'Doctor');
    final email = _doctorProfile?.email.isNotEmpty == true
        ? _doctorProfile!.email
        : (FirebaseAuth.instance.currentUser?.email ?? '');
    final initials = name.trim().isEmpty
        ? 'D'
        : name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();
    final arabic = context.watch<LocaleProvider>().isArabic;

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
                    gradient: context.watch<ThemeProvider>().palette.heroGradient,
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
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _pill(roles.role.label(arabic), theme),
                          if (_doctorProfile != null &&
                              _doctorProfile!.specialty.isNotEmpty)
                            _pill(_doctorProfile!.specialty, theme),
                          if (_doctorProfile != null &&
                              _doctorProfile!.year.isNotEmpty)
                            _pill(_doctorProfile!.year, theme),
                        ],
                      ),
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
        child: Divider(
            height: 1, color: Theme.of(context).colorScheme.outlineVariant),
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
      onTap: () {
        context.read<FeedbackService>().tap();
        provider.setLocale(Locale(code));
      },
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

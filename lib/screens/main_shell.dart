import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_role.dart';
import '../services/feedback_service.dart';
import '../services/role_service.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../utils/locale_provider.dart';
import '../widgets/offline_banner.dart';
import 'add_patient_screen.dart';
import 'analytics_screen.dart';
import 'home_tab.dart';
import 'patients_tab.dart';
import 'settings_screen.dart';

/// Root navigation shell: 4 destinations (Home, Patients, Insights,
/// Profile) plus a center action button for starting a new encounter.
/// Replaces the old DashboardScreen, which mixed "dashboard" and "patient
/// list" into two tabs of one screen with no room for anything else.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _homeKey = GlobalKey<HomeTabState>();
  final _patientsKey = GlobalKey<PatientsTabState>();

  void _goToPatients() {
    context.read<FeedbackService>().tap();
    setState(() => _index = 1);
  }

  Future<void> _startNewEncounter() async {
    context.read<FeedbackService>().tap();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddPatientScreen()),
    );
    // Refresh whichever tabs show a patient list so the new one appears
    // without the user needing to manually pull-to-refresh.
    (_homeKey.currentState)?.refresh();
    _patientsKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final roles = context.watch<RoleService>();
    final arabic = context.watch<LocaleProvider>().isArabic;
    final isDoctor = roles.role == AppRole.doctor;

    final pages = [
      HomeTab(key: _homeKey, onSeeAllPatients: _goToPatients),
      PatientsTab(key: _patientsKey),
      const AnalyticsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(child: IndexedStack(index: _index, children: pages)),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(context, isDoctor, arabic),
    );
  }

  Widget _bottomNav(BuildContext context, bool isDoctor, bool arabic) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                icon: Icons.home_rounded,
                label: arabic ? 'الرئيسية' : 'Home',
                index: 0,
              ),
              _navItem(
                icon: Icons.people_alt_rounded,
                label: arabic ? 'المرضى' : 'Patients',
                index: 1,
              ),
              _centerAction(),
              _navItem(
                icon: isDoctor ? Icons.insights_rounded : Icons.school_rounded,
                label: isDoctor
                    ? (arabic ? 'التحليلات' : 'Insights')
                    : (arabic ? 'التعلّم' : 'Learn'),
                index: 2,
              ),
              _navItem(
                icon: Icons.person_rounded,
                label: arabic ? 'حسابي' : 'Profile',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      {required IconData icon, required String label, required int index}) {
    final isSelected = _index == index;
    final theme = Theme.of(context);
    final color =
        isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: () {
          context.read<FeedbackService>().tap();
          setState(() => _index = index);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption(context).copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _centerAction() {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _startNewEncounter,
      customBorder: const CircleBorder(),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add, color: theme.colorScheme.onPrimary, size: 26),
      ),
    );
  }
}

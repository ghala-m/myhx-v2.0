import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../utils/responsive_helper.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../models/doctor.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  Doctor? _doctorProfile;
  bool _isLoadingProfile = true;
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Arabic', 'Spanish', 'French'];

  void _showFeatureNotImplemented() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is not yet implemented.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchDoctorProfile();
  }

  Future<void> _fetchDoctorProfile() async {
    final user = _authService.currentUser;
    if (user != null) {
      final doctorData = await _databaseService.getDoctorProfile(user.uid);
      if (doctorData != null) {
        setState(() {
          _doctorProfile = Doctor.fromJson(doctorData, user.uid);
          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    } else {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ResponsiveHelper.responsiveContainer(
        context,
        centerContent: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                            _isLoadingProfile
                  ? const Center(child: CircularProgressIndicator())
                  : Center(child: _buildProfileSection(theme, _doctorProfile)),
              SizedBox(height: context.spacing(24)),
              _buildSectionHeader('App Settings', theme),
              _buildAppSettings(themeProvider),
              SizedBox(height: context.spacing(24)),
              _buildSectionHeader('About & Legal', theme),
              _buildAboutSection(),
              SizedBox(height: context.spacing(24)),
              _buildSectionHeader('Account', theme),
              _buildAccountSettings(),
              SizedBox(height: context.spacing(24)),
              _buildDisclaimer(theme),
            ],
          ),
        ),
      ),
    );
  }

  // --- كل دوال بناء الواجهة تم نقلها إلى هنا (داخل الكلاس) ---

  Widget _buildDisclaimer(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Disclaimer: This AI analysis is for informational purposes only and is not a substitute for professional medical advice. Always seek the advice of a qualified health provider.',
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onBackground,
        ),
      ),
    );
  }

  Widget _buildProfileSection(ThemeData theme, dynamic _doctor) {
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: context.isMobile ? double.infinity : 500,
      ),
      margin: EdgeInsets.symmetric(horizontal: context.spacing(16)),
      padding: EdgeInsets.all(context.spacing(32)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.borderRadius(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), 
            blurRadius: context.spacing(20), 
            offset: Offset(0, context.spacing(8)),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: colors.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.2),
                      blurRadius: context.spacing(15),
                      offset: Offset(0, context.spacing(5)),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: context.isMobile ? 55 : (context.isTablet ? 65 : 75),
                  backgroundColor: colors.primary.withOpacity(0.15),
                  child: Text(
                    _doctor?.name != null && _doctor!.name.isNotEmpty
                        ? _doctor!.name.split(' ').map((s) => s[0]).join().toUpperCase()
                        : 'DR',
                    style: TextStyle(
                      fontSize: context.fontSize(40), 
                      fontWeight: FontWeight.bold, 
                      color: colors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: context.iconSize(36),
                  height: context.iconSize(36),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary,
                    border: Border.all(color: colors.surface, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withOpacity(0.3),
                        blurRadius: context.spacing(8),
                        offset: Offset(0, context.spacing(2)),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.edit, 
                    color: Colors.white, 
                    size: context.iconSize(20),
                  ),
                ),
              )
            ],
          ),
          SizedBox(height: context.spacing(24)),
          Text(
            _doctor?.name ?? 'Dr. Name', 
            style: TextStyle(
              fontSize: context.fontSize(26), 
              fontWeight: FontWeight.bold, 
              color: colors.onSurface,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.spacing(8)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing(16), 
              vertical: context.spacing(6),
            ),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius(20)),
            ),
            child: Text(
              _doctor?.specialty != null && _doctor?.year != null
                  ? '${_doctor!.specialty} • ${_doctor!.year}'
                  : 'Specialty • Year', 
              style: TextStyle(
                fontSize: context.fontSize(16), 
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: context.spacing(12)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined, 
                size: context.iconSize(18), 
                color: colors.onSurface.withOpacity(0.6),
              ),
              SizedBox(width: context.spacing(8)),
              Text(
                _doctor?.email ?? 'dr.email@example.com', 
                style: TextStyle(
                  fontSize: context.fontSize(16), 
                  color: colors.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing(28)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showFeatureNotImplemented,
              icon: Icon(Icons.edit_outlined, size: context.iconSize(20)),
              label: Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: context.fontSize(16),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: colors.primary.withOpacity(0.3),
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing(32), 
                  vertical: context.spacing(16),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.borderRadius(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettings(ThemeProvider themeProvider) {
    final colors = Theme.of(context).colorScheme;
    return _buildSettingsCard(
      children: [
        _buildSettingsTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Receive push notifications',
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: (value) => setState(() { _notificationsEnabled = value; }),
            activeColor: colors.primary,
          ),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.dark_mode_outlined,
          title: 'Dark Mode',
          subtitle: themeProvider.themeMode == ThemeMode.dark ? 'Enabled' : 'Disabled',
          trailing: Switch(
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              final newMode = value ? ThemeMode.dark : ThemeMode.light;
              themeProvider.setThemeMode(newMode);
            },
            activeColor: colors.primary,
          ),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.language_outlined,
          title: 'Language',
          subtitle: _selectedLanguage,
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colors.onSurface.withOpacity(0.5)),
          onTap: _showLanguageDialog,
        ),
      ],
    );
  }

  Widget _buildAccountSettings() {
    return _buildSettingsCard(
      children: [
        _buildSettingsTile(
          icon: Icons.lock_outlined,
          title: 'Change Password',
          subtitle: 'Update your password',
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showFeatureNotImplemented,
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.backup_outlined,
          title: 'Data Backup',
          subtitle: 'Backup your data to the cloud',
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showFeatureNotImplemented,
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.logout,
          title: 'Sign Out',
          subtitle: 'Sign out of your account',
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.error),
          titleColor: Theme.of(context).colorScheme.error,
          onTap: _showSignOutDialog,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSettingsCard(
      children: [
        _buildSettingsTile(
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'Get help and contact support',
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showFeatureNotImplemented,
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'Read our privacy policy',
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showFeatureNotImplemented,
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.info_outline,
          title: 'About myhx-',
          subtitle: 'Version 1.0.0',
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'myhx-',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2024 MyHx- Team. All rights reserved.',
              children: [
                const SizedBox(height: 16),
                const Text('myhx- is a smart medical history application designed to assist healthcare professionals.'),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, String? subtitle, Widget? trailing, Color? titleColor, VoidCallback? onTap}) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: titleColor ?? colors.primary),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: titleColor ?? colors.onSurface)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 14, color: colors.onSurface.withOpacity(0.7))) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Theme.of(context).dividerColor, indent: 56);
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _languages.map((language) {
              return RadioListTile<String>(
                title: Text(language),
                value: language,
                groupValue: _selectedLanguage,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (String? value) {
                  setState(() { _selectedLanguage = value!; });
                  Navigator.of(context).pop();
                  _showFeatureNotImplemented();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: Text('Sign Out', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        );
      },
    );
  }
}

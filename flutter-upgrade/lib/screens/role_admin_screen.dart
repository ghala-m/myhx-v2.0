import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_role.dart';
import '../services/role_service.dart';
import '../utils/app_spacing.dart';
import '../widgets/app_card.dart';

/// Developer-only screen: view every account and change its role.
class RoleAdminScreen extends StatefulWidget {
  const RoleAdminScreen({super.key});

  @override
  State<RoleAdminScreen> createState() => _RoleAdminScreenState();
}

class _RoleAdminScreenState extends State<RoleAdminScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<RoleService>().listUsers();
  }

  void _reload() {
    setState(() => _future = context.read<RoleService>().listUsers());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roles = context.read<RoleService>();
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('Roles & permissions'),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final users = snap.data ?? const [];
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final u = users[i];
              final role = AppRoleX.fromId(u['role'] as String?);
              return AppCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${u['displayName'] ?? 'Unnamed'}',
                              style: theme.textTheme.titleSmall),
                          Text('${u['email'] ?? ''}',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    DropdownButton<AppRole>(
                      value: role,
                      underline: const SizedBox.shrink(),
                      items: [
                        for (final r in AppRole.values)
                          DropdownMenuItem(
                              value: r, child: Text(r.label(false))),
                      ],
                      onChanged: (r) async {
                        if (r == null) return;
                        await roles.assignRole('${u['uid']}', r);
                        _reload();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

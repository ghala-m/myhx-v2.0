# Flutter Upgrade — Deprecation Scan Report

Generated for: myhx_app  
Current Flutter SDK constraint: `^3.9.2` (Dart 3.9+)  
Target: latest stable Flutter

## Critical Deprecations Found

### 1. `Color.withOpacity()` is deprecated
**Status:** 🔴 Must fix for Flutter 3.29+  
**Replacement:** `color.withValues(alpha: 0.x)`

**Files affected:**
- `lib/screens/dashboard_screen.dart:130:            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],`
- `lib/screens/dashboard_screen.dart:131:            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1), width: 1),`
- `lib/screens/dashboard_screen.dart:153:                  icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),`
- `lib/screens/dashboard_screen.dart:217:        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],`
- `lib/screens/dashboard_screen.dart:227:                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),`
- `lib/screens/dashboard_screen.dart:237:                    Text('${patient.age} years • ${patient.gender}', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.7))),`
- `lib/screens/dashboard_screen.dart:243:                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),`
- `lib/screens/dashboard_screen.dart:261:    final color = isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);`
- `lib/screens/dashboard_screen.dart:289:          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],`
- `lib/screens/dashboard_screen.dart:324:              Text('Here is your daily summary.', style: TextStyle(fontSize: 16, color: theme.colorScheme.onBackground.withOpacity(0.7))),`
- `lib/screens/dashboard_screen.dart:362:      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],`
- `lib/screens/dashboard_screen.dart:363:      border: Border.all(color: color.withOpacity(0.1), width: 1),`
- `lib/screens/dashboard_screen.dart:373:              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),`
- `lib/screens/dashboard_screen.dart:382:          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w500),`
- `lib/screens/dashboard_screen.dart:414:              color: theme.colorScheme.surface.withOpacity(0.5),`
- `lib/screens/dashboard_screen.dart:419:                Icon(Icons.inbox_outlined, size: 40, color: theme.colorScheme.onSurface.withOpacity(0.5)),`
- `lib/screens/dashboard_screen.dart:423:                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 16),`
- `lib/screens/dashboard_screen.dart:461:          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],`
- `lib/screens/dashboard_screen.dart:462:          border: Border.all(color: color.withOpacity(0.2)),`
- `lib/screens/analysis_result_screen.dart:102:                    style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface.withOpacity(0.7)),`
- `lib/screens/add_patient_screen.dart:240:                          selectedColor: theme.colorScheme.primary.withOpacity(`
- `lib/screens/add_patient_screen.dart:255:                                : theme.colorScheme.outline.withOpacity(0.3),`
- `lib/screens/add_patient_screen.dart:289:                      shadowColor: theme.colorScheme.primary.withOpacity(0.3),`
- `lib/screens/add_patient_screen.dart:319:            color: Colors.black.withOpacity(0.05),`
- `lib/screens/add_patient_screen.dart:325:          color: theme.colorScheme.outline.withOpacity(0.1),`
- `lib/screens/add_patient_screen.dart:337:                  color: theme.colorScheme.primary.withOpacity(0.1),`
- `lib/screens/add_patient_screen.dart:379:            color: theme.colorScheme.outline.withOpacity(0.3),`
- `lib/screens/add_patient_screen.dart:385:            color: theme.colorScheme.outline.withOpacity(0.3),`
- `lib/screens/add_patient_screen.dart:420:          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),`
- `lib/screens/add_patient_screen.dart:440:                      color: theme.colorScheme.onSurface.withOpacity(0.7),`
- `lib/screens/add_patient_screen.dart:452:                          : theme.colorScheme.onSurface.withOpacity(0.5),`
- `lib/screens/add_patient_screen.dart:467:        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),`
- `lib/screens/add_patient_screen.dart:480:          icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface.withOpacity(0.7)),`
- `lib/screens/reports_screen.dart:43:            Icon(Icons.construction, size: 60, color: colors.primary.withOpacity(0.5)),`
- `lib/screens/settings_screen.dart:110:        color: theme.colorScheme.error.withOpacity(0.05),`
- `lib/screens/settings_screen.dart:112:        border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),`
- `lib/screens/settings_screen.dart:158:            color: Colors.black.withOpacity(0.08), `
- `lib/screens/settings_screen.dart:165:          color: colors.outline.withOpacity(0.1),`
- `lib/screens/settings_screen.dart:180:                      color: colors.primary.withOpacity(0.2),`
- `lib/screens/settings_screen.dart:188:                  backgroundColor: colors.primary.withOpacity(0.15),`
- `lib/screens/settings_screen.dart:214:                        color: colors.primary.withOpacity(0.3),`
- `lib/screens/settings_screen.dart:247:              color: colors.primary.withOpacity(0.1),`
- `lib/screens/settings_screen.dart:269:                color: colors.onSurface.withOpacity(0.6),`
- `lib/screens/settings_screen.dart:276:                  color: colors.onSurface.withOpacity(0.7),`
- `lib/screens/settings_screen.dart:298:                shadowColor: colors.primary.withOpacity(0.3),`
- `lib/screens/settings_screen.dart:347:          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colors.onSurface.withOpacity(0.5)),`
- `lib/screens/settings_screen.dart:430:        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],`
- `lib/screens/settings_screen.dart:441:      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 14, color: colors.onSurface.withOpacity(0.7))) : null,`
- `lib/screens/settings_screen.dart:488:              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),`
- `lib/screens/medical_history_screen.dart:421:                  color: Colors.grey.withOpacity(0.3),`
- `lib/screens/all_reports_screen.dart:89:                  color: Colors.black.withOpacity(0.05),`
- `lib/screens/all_reports_screen.dart:134:                          style: TextStyle(color: colors.onSurface.withOpacity(0.7)),`
- `lib/screens/all_reports_screen.dart:156:                          color: colors.onSurface.withOpacity(0.3),`
- `lib/screens/all_reports_screen.dart:166:                            color: colors.onSurface.withOpacity(0.7),`
- `lib/screens/all_reports_screen.dart:174:                          style: TextStyle(color: colors.onSurface.withOpacity(0.5)),`
- `lib/screens/all_reports_screen.dart:217:            color: Colors.black.withOpacity(0.05),`
- `lib/screens/all_reports_screen.dart:242:                      color: colors.primary.withOpacity(0.1),`
- `lib/screens/all_reports_screen.dart:269:                            color: colors.onSurface.withOpacity(0.7),`
- `lib/screens/all_reports_screen.dart:335:                      color: colors.secondary.withOpacity(0.1),`
- `lib/screens/all_reports_screen.dart:352:                      color: colors.onSurface.withOpacity(0.5),`
- `lib/screens/all_reports_screen.dart:364:                    color: colors.primary.withOpacity(0.05),`
- `lib/screens/all_reports_screen.dart:367:                      color: colors.primary.withOpacity(0.2),`
- `lib/screens/patient_record_screen.dart:211:                          Icon(Icons.assignment_late_outlined, size: 60, color: colors.onSurface.withOpacity(0.5)),`
- `lib/screens/patient_record_screen.dart:238:                          Icon(Icons.info_outline, size: 60, color: colors.primary.withOpacity(0.5)),`
- `lib/widgets/dynamic_question_widget.dart:111:                  color: _getPriorityColor().withOpacity(0.1),`
- `lib/widgets/dynamic_question_widget.dart:142:                    color: Colors.red.withOpacity(0.1),`
- `lib/services/share_service.dart:210:                  color: Colors.blue.withOpacity(0.1),`
- `lib/services/share_service.dart:233:                  color: Colors.green.withOpacity(0.1),`
- `lib/services/share_service.dart:256:                  color: Colors.orange.withOpacity(0.1),`

### 2. `ColorScheme.background` / `ColorScheme.onBackground` are deprecated
**Status:** 🔴 Must fix  
**Replacement:**
- `Theme.of(context).colorScheme.background` → `colorScheme.surface`
- `Theme.of(context).colorScheme.onBackground` → `colorScheme.onSurface`

**Files affected:**
- `lib/screens/dashboard_screen.dart:80:      backgroundColor: Theme.of(context).colorScheme.background,`
- `lib/screens/dashboard_screen.dart:322:              Text('Good Morning, Doctor', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground)),`
- `lib/screens/dashboard_screen.dart:324:              Text('Here is your daily summary.', style: TextStyle(fontSize: 16, color: theme.colorScheme.onBackground.withOpacity(0.7))),`
- `lib/screens/dashboard_screen.dart:400:            Text('Recent Patients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground)),`
- `lib/screens/add_patient_screen.dart:131:      backgroundColor: theme.colorScheme.background,`
- `lib/screens/settings_screen.dart:72:      backgroundColor: theme.colorScheme.background,`
- `lib/screens/settings_screen.dart:138:          color: theme.colorScheme.onBackground,`

### 3. `MaterialStateProperty` / `MaterialState` renamed to `WidgetState`
**Status:** 🟡 Check if present  
**Replacement:** `WidgetStateProperty`, `WidgetState`

### 4. `WillPopScope` deprecated
**Replacement:** `PopScope`

### 5. Legacy button classes
**Check:** `FlatButton`, `RaisedButton`, `OutlineButton`

## Code Quality Issues Found

### 6. Unused / misplaced backend files
- `lib/backend/main.py`, `.env`, `requirements.txt` should not be inside `lib/`. Move them to `backend/` at project root.
- `.env` contains secrets and should never be committed.

### 7. Hardcoded Firebase API keys in `lib/firebase_options.dart`
- These are public client keys, which is OK for Firebase, but verify they are restricted to your app domains/bundle IDs in Firebase Console.

### 8. `DynamicQuestionWidget` constructor bug
- `required currentAnswer` is declared but not used as a field. Should be removed or wired to `answer`.

### 9. `print()` statements in production code
- Many `print()` calls in services. Replace with a proper logger (e.g., `logger` package) or remove before release.

### 10. `ScaffoldMessenger` error messages may leak sensitive info
- In `add_patient_screen.dart`, `Text('Error: $e')` shows raw exceptions to users. Use user-friendly messages.

## Recommended Next Steps

1. Run `flutter pub upgrade --major-versions` after updating `pubspec.yaml`.
2. Run `flutter analyze` and fix all deprecation warnings.
3. Test on both Android and iOS simulators.
4. Move backend files out of `lib/`.
5. Add `flutter_lints` rules if not already active.

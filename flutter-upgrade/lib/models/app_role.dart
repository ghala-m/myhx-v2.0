/// Application roles (طالب / طبيب / مبرمج).
enum AppRole { student, doctor, developer }

extension AppRoleX on AppRole {
  String get id => switch (this) {
        AppRole.student => 'student',
        AppRole.doctor => 'doctor',
        AppRole.developer => 'developer',
      };

  String label(bool arabic) => switch (this) {
        AppRole.student => arabic ? 'طالب' : 'Student',
        AppRole.doctor => arabic ? 'طبيب' : 'Doctor',
        AppRole.developer => arabic ? 'مبرمج' : 'Developer',
      };

  /// Students see every department, doctors only their selected ones.
  bool get seesAllDepartments => this != AppRole.doctor;

  /// Only developers can create/edit question banks and change roles.
  bool get canEditQuestions => this == AppRole.developer;
  bool get canManageRoles => this == AppRole.developer;

  static AppRole fromId(String? id) => switch (id) {
        'developer' => AppRole.developer,
        'doctor' => AppRole.doctor,
        _ => AppRole.student,
      };
}

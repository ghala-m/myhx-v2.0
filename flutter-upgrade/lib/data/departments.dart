/// Full hospital department catalogue (أقسام المستشفى).
///
/// Students see every department; doctors can narrow the list down to the
/// departments they actually work in from Settings.
class Department {
  final String id;
  final String nameEn;
  final String nameAr;
  final String icon; // material icon key resolved by [DepartmentIcons]
  final String group; // Medical | Surgical | Diagnostic | Support

  const Department({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.icon,
    required this.group,
  });

  String name(bool arabic) => arabic ? nameAr : nameEn;
}

class Departments {
  Departments._();

  static const List<Department> all = [
    // ---------------- Medical ----------------
    Department(id: 'internal_medicine', nameEn: 'Internal Medicine', nameAr: 'الباطنية', icon: 'medical_services', group: 'Medical'),
    Department(id: 'cardiology', nameEn: 'Cardiology', nameAr: 'القلب', icon: 'favorite', group: 'Medical'),
    Department(id: 'pulmonology', nameEn: 'Pulmonology', nameAr: 'الصدرية', icon: 'air', group: 'Medical'),
    Department(id: 'gastroenterology', nameEn: 'Gastroenterology', nameAr: 'الجهاز الهضمي', icon: 'lunch_dining', group: 'Medical'),
    Department(id: 'nephrology', nameEn: 'Nephrology', nameAr: 'الكلى', icon: 'water_drop', group: 'Medical'),
    Department(id: 'endocrinology', nameEn: 'Endocrinology', nameAr: 'الغدد الصماء', icon: 'science', group: 'Medical'),
    Department(id: 'neurology', nameEn: 'Neurology', nameAr: 'الأعصاب', icon: 'psychology', group: 'Medical'),
    Department(id: 'rheumatology', nameEn: 'Rheumatology', nameAr: 'الروماتيزم', icon: 'accessibility_new', group: 'Medical'),
    Department(id: 'hematology', nameEn: 'Hematology', nameAr: 'أمراض الدم', icon: 'bloodtype', group: 'Medical'),
    Department(id: 'oncology', nameEn: 'Oncology', nameAr: 'الأورام', icon: 'coronavirus', group: 'Medical'),
    Department(id: 'infectious_disease', nameEn: 'Infectious Diseases', nameAr: 'الأمراض المعدية', icon: 'sanitizer', group: 'Medical'),
    Department(id: 'dermatology', nameEn: 'Dermatology', nameAr: 'الجلدية', icon: 'spa', group: 'Medical'),
    Department(id: 'allergy_immunology', nameEn: 'Allergy & Immunology', nameAr: 'الحساسية والمناعة', icon: 'grass', group: 'Medical'),
    Department(id: 'geriatrics', nameEn: 'Geriatrics', nameAr: 'طب المسنين', icon: 'elderly', group: 'Medical'),
    Department(id: 'pediatrics', nameEn: 'Pediatrics', nameAr: 'الأطفال', icon: 'child_care', group: 'Medical'),
    Department(id: 'neonatology', nameEn: 'Neonatology', nameAr: 'حديثي الولادة', icon: 'crib', group: 'Medical'),
    Department(id: 'psychiatry', nameEn: 'Psychiatry', nameAr: 'الطب النفسي', icon: 'self_improvement', group: 'Medical'),
    Department(id: 'family_medicine', nameEn: 'Family Medicine', nameAr: 'طب الأسرة', icon: 'family_restroom', group: 'Medical'),

    // ---------------- Surgical ----------------
    Department(id: 'general_surgery', nameEn: 'General Surgery', nameAr: 'الجراحة العامة', icon: 'healing', group: 'Surgical'),
    Department(id: 'orthopedics', nameEn: 'Orthopedics', nameAr: 'العظام', icon: 'accessible_forward', group: 'Surgical'),
    Department(id: 'neurosurgery', nameEn: 'Neurosurgery', nameAr: 'جراحة المخ والأعصاب', icon: 'psychology_alt', group: 'Surgical'),
    Department(id: 'cardiothoracic', nameEn: 'Cardiothoracic Surgery', nameAr: 'جراحة القلب والصدر', icon: 'monitor_heart', group: 'Surgical'),
    Department(id: 'vascular', nameEn: 'Vascular Surgery', nameAr: 'جراحة الأوعية', icon: 'timeline', group: 'Surgical'),
    Department(id: 'urology', nameEn: 'Urology', nameAr: 'المسالك البولية', icon: 'wc', group: 'Surgical'),
    Department(id: 'obgyn', nameEn: 'Obstetrics & Gynaecology', nameAr: 'النساء والولادة', icon: 'pregnant_woman', group: 'Surgical'),
    Department(id: 'ent', nameEn: 'ENT', nameAr: 'الأنف والأذن والحنجرة', icon: 'hearing', group: 'Surgical'),
    Department(id: 'ophthalmology', nameEn: 'Ophthalmology', nameAr: 'العيون', icon: 'visibility', group: 'Surgical'),
    Department(id: 'plastic_surgery', nameEn: 'Plastic Surgery', nameAr: 'التجميل', icon: 'auto_fix_high', group: 'Surgical'),
    Department(id: 'pediatric_surgery', nameEn: 'Pediatric Surgery', nameAr: 'جراحة الأطفال', icon: 'child_friendly', group: 'Surgical'),
    Department(id: 'dentistry', nameEn: 'Dentistry & Maxillofacial', nameAr: 'الأسنان والوجه والفكين', icon: 'sentiment_satisfied', group: 'Surgical'),

    // ---------------- Acute & critical ----------------
    Department(id: 'emergency', nameEn: 'Emergency Medicine', nameAr: 'الطوارئ', icon: 'emergency', group: 'Acute'),
    Department(id: 'icu', nameEn: 'Intensive Care (ICU)', nameAr: 'العناية المركزة', icon: 'monitor_heart', group: 'Acute'),
    Department(id: 'anesthesia', nameEn: 'Anaesthesia', nameAr: 'التخدير', icon: 'masks', group: 'Acute'),

    // ---------------- Diagnostic & support ----------------
    Department(id: 'radiology', nameEn: 'Radiology', nameAr: 'الأشعة', icon: 'radar', group: 'Diagnostic'),
    Department(id: 'laboratory', nameEn: 'Laboratory', nameAr: 'المختبر', icon: 'biotech', group: 'Diagnostic'),
    Department(id: 'pathology', nameEn: 'Pathology', nameAr: 'علم الأمراض', icon: 'science', group: 'Diagnostic'),
    Department(id: 'physiotherapy', nameEn: 'Physiotherapy', nameAr: 'العلاج الطبيعي', icon: 'fitness_center', group: 'Support'),
    Department(id: 'nutrition', nameEn: 'Nutrition', nameAr: 'التغذية', icon: 'restaurant', group: 'Support'),
    Department(id: 'pharmacy', nameEn: 'Pharmacy', nameAr: 'الصيدلة', icon: 'medication', group: 'Support'),
  ];

  static List<String> get groups =>
      all.map((d) => d.group).toSet().toList(growable: false);

  static Department? byId(String? id) {
    if (id == null) return null;
    for (final d in all) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Best-effort match from a free-text department string (English or Arabic).
  static Department? match(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final t = text.toLowerCase().trim();
    for (final d in all) {
      if (d.id == t ||
          t.contains(d.nameEn.toLowerCase()) ||
          d.nameEn.toLowerCase().contains(t) ||
          text.contains(d.nameAr)) {
        return d;
      }
    }
    return null;
  }

  static List<Department> byGroup(String group) =>
      all.where((d) => d.group == group).toList(growable: false);
}

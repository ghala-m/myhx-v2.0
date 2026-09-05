/// Specialty-specific history templates (قوالب حسب التخصص).
///
/// Each template is a focused checklist of the questions that matter for that
/// specialty, so the doctor doesn't walk the full generic questionnaire.
class SpecialtyTemplate {
  final String id;
  final String nameEn;
  final String nameAr;
  final String icon; // material icon code point name, resolved in the UI
  final List<TemplateQuestion> questions;

  const SpecialtyTemplate({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.icon,
    required this.questions,
  });

  String name(bool arabic) => arabic ? nameAr : nameEn;
}

class TemplateQuestion {
  final String id;
  final String en;
  final String ar;
  final String type; // text | textarea | boolean | select | number
  final List<String> options;
  final bool critical;

  const TemplateQuestion({
    required this.id,
    required this.en,
    required this.ar,
    this.type = 'text',
    this.options = const [],
    this.critical = false,
  });

  String label(bool arabic) => arabic ? ar : en;
}

class SpecialtyTemplates {
  static const List<SpecialtyTemplate> all = [
    SpecialtyTemplate(
      id: 'cardiology',
      nameEn: 'Cardiology',
      nameAr: 'القلب',
      icon: 'favorite',
      questions: [
        TemplateQuestion(
          id: 'chest_pain',
          en: 'Chest pain — site, radiation, character',
          ar: 'ألم الصدر — الموقع، الانتشار، الطبيعة',
          type: 'textarea',
          critical: true,
        ),
        TemplateQuestion(
          id: 'exertional',
          en: 'Worse on exertion?',
          ar: 'يزداد مع المجهود؟',
          type: 'boolean',
          critical: true,
        ),
        TemplateQuestion(
          id: 'dyspnoea',
          en: 'Dyspnoea (NYHA class)',
          ar: 'ضيق النفس (تصنيف NYHA)',
          type: 'select',
          options: ['I', 'II', 'III', 'IV'],
        ),
        TemplateQuestion(
          id: 'orthopnoea',
          en: 'Orthopnoea / PND',
          ar: 'ضيق نفس عند الاستلقاء / ليلي',
          type: 'boolean',
        ),
        TemplateQuestion(
          id: 'palpitations',
          en: 'Palpitations / syncope',
          ar: 'خفقان / إغماء',
          type: 'boolean',
          critical: true,
        ),
        TemplateQuestion(
          id: 'risk_factors',
          en: 'Risk factors (HTN, DM, smoking, family history)',
          ar: 'عوامل الخطر (ضغط، سكري، تدخين، تاريخ عائلي)',
          type: 'textarea',
        ),
      ],
    ),
    SpecialtyTemplate(
      id: 'internal_medicine',
      nameEn: 'Internal Medicine',
      nameAr: 'الباطنية',
      icon: 'medical_services',
      questions: [
        TemplateQuestion(
          id: 'presenting',
          en: 'Presenting complaint and duration',
          ar: 'الشكوى الرئيسية ومدتها',
          type: 'textarea',
          critical: true,
        ),
        TemplateQuestion(
          id: 'weight_loss',
          en: 'Unintentional weight loss',
          ar: 'نقص وزن غير مقصود',
          type: 'boolean',
          critical: true,
        ),
        TemplateQuestion(
          id: 'fever',
          en: 'Fever / night sweats',
          ar: 'حمى / تعرق ليلي',
          type: 'boolean',
        ),
        TemplateQuestion(
          id: 'chronic',
          en: 'Chronic conditions and current medications',
          ar: 'الأمراض المزمنة والأدوية الحالية',
          type: 'textarea',
        ),
      ],
    ),
    SpecialtyTemplate(
      id: 'pediatrics',
      nameEn: 'Pediatrics',
      nameAr: 'الأطفال',
      icon: 'child_care',
      questions: [
        TemplateQuestion(
          id: 'birth',
          en: 'Birth history (term, mode, complications)',
          ar: 'تاريخ الولادة (الأوان، الطريقة، المضاعفات)',
          type: 'textarea',
        ),
        TemplateQuestion(
          id: 'feeding',
          en: 'Feeding and growth',
          ar: 'التغذية والنمو',
          type: 'textarea',
        ),
        TemplateQuestion(
          id: 'vaccines',
          en: 'Immunisations up to date?',
          ar: 'التطعيمات محدّثة؟',
          type: 'boolean',
          critical: true,
        ),
        TemplateQuestion(
          id: 'milestones',
          en: 'Developmental milestones',
          ar: 'مراحل النمو التطورية',
          type: 'textarea',
        ),
        TemplateQuestion(
          id: 'wet_nappies',
          en: 'Reduced wet nappies / poor oral intake',
          ar: 'قلة التبول / ضعف الرضاعة',
          type: 'boolean',
          critical: true,
        ),
      ],
    ),
    SpecialtyTemplate(
      id: 'surgery',
      nameEn: 'Surgery',
      nameAr: 'الجراحة',
      icon: 'healing',
      questions: [
        TemplateQuestion(
          id: 'pain_socrates',
          en: 'Pain — SOCRATES',
          ar: 'الألم — تحليل SOCRATES',
          type: 'textarea',
          critical: true,
        ),
        TemplateQuestion(
          id: 'bowel',
          en: 'Bowel habit change / vomiting',
          ar: 'تغير عادة الإخراج / قيء',
          type: 'boolean',
          critical: true,
        ),
        TemplateQuestion(
          id: 'previous_surgery',
          en: 'Previous surgeries and anaesthesia issues',
          ar: 'عمليات سابقة ومشاكل التخدير',
          type: 'textarea',
        ),
        TemplateQuestion(
          id: 'fasting',
          en: 'Last oral intake',
          ar: 'آخر أكل أو شرب',
          type: 'text',
        ),
      ],
    ),
    SpecialtyTemplate(
      id: 'neurology',
      nameEn: 'Neurology',
      nameAr: 'الأعصاب',
      icon: 'psychology',
      questions: [
        TemplateQuestion(
          id: 'headache',
          en: 'Headache — onset, severity, thunderclap?',
          ar: 'الصداع — البداية، الشدة، مفاجئ شديد؟',
          type: 'textarea',
          critical: true,
        ),
        TemplateQuestion(
          id: 'weakness',
          en: 'Focal weakness / numbness',
          ar: 'ضعف أو تنميل موضعي',
          type: 'boolean',
          critical: true,
        ),
        TemplateQuestion(
          id: 'seizure',
          en: 'Seizure activity / loss of consciousness',
          ar: 'تشنجات / فقدان وعي',
          type: 'boolean',
          critical: true,
        ),
        TemplateQuestion(
          id: 'vision',
          en: 'Visual or speech disturbance',
          ar: 'اضطراب في الرؤية أو النطق',
          type: 'boolean',
        ),
      ],
    ),
    SpecialtyTemplate(
      id: 'obgyn',
      nameEn: 'Obstetrics & Gynaecology',
      nameAr: 'النساء والولادة',
      icon: 'pregnant_woman',
      questions: [
        TemplateQuestion(
          id: 'lmp',
          en: 'Last menstrual period',
          ar: 'آخر دورة شهرية',
          type: 'text',
          critical: true,
        ),
        TemplateQuestion(
          id: 'gravida',
          en: 'Gravida / Para',
          ar: 'عدد الحمول / الولادات',
          type: 'text',
        ),
        TemplateQuestion(
          id: 'bleeding',
          en: 'Vaginal bleeding or discharge',
          ar: 'نزيف أو إفرازات',
          type: 'boolean',
          critical: true,
        ),
        TemplateQuestion(
          id: 'contraception',
          en: 'Contraception history',
          ar: 'تاريخ وسائل منع الحمل',
          type: 'textarea',
        ),
      ],
    ),
  ];

  static SpecialtyTemplate? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Best-effort match from the free-text department stored on a patient.
  static SpecialtyTemplate? forDepartment(String? department) {
    if (department == null) return null;
    final d = department.toLowerCase();
    for (final t in all) {
      if (d.contains(t.id.split('_').first) ||
          d.contains(t.nameEn.toLowerCase()) ||
          department.contains(t.nameAr)) {
        return t;
      }
    }
    return null;
  }
}

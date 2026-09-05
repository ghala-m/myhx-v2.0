import '../models/patient.dart';

/// Structured output of a clinical reasoning pass.
class ClinicalAnalysis {
  final String riskLevel; // Urgent | High | Medium | Low
  final int confidencePercent;
  final List<DifferentialItem> differential;
  final List<RedFlag> redFlags;
  final List<String> recommendedWorkup;
  final List<String> recommendations;
  final SoapNote soapNote;
  final DateTime generatedAt;

  ClinicalAnalysis({
    required this.riskLevel,
    required this.confidencePercent,
    required this.differential,
    required this.redFlags,
    required this.recommendedWorkup,
    required this.recommendations,
    required this.soapNote,
    required this.generatedAt,
  });

  bool get isUrgent => riskLevel == 'Urgent' || riskLevel == 'High';

  Map<String, dynamic> toJson() => {
        'risk_level': riskLevel,
        'confidence': '$confidencePercent%',
        'differential_diagnosis':
            differential.map((d) => d.toJson()).toList(growable: false),
        'red_flags': redFlags.map((f) => f.toJson()).toList(growable: false),
        'recommended_workup': recommendedWorkup,
        'recommendations': recommendations,
        'soap_note': soapNote.toJson(),
        'analysis_timestamp': generatedAt.toIso8601String(),
      };

  factory ClinicalAnalysis.fromJson(Map<String, dynamic> json) {
    return ClinicalAnalysis(
      riskLevel: json['risk_level'] as String? ?? 'Low',
      confidencePercent: int.tryParse(
              (json['confidence'] as String? ?? '0').replaceAll('%', '')) ??
          0,
      differential: ((json['differential_diagnosis'] as List<dynamic>?) ?? [])
          .whereType<Map>()
          .map((e) => DifferentialItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      redFlags: ((json['red_flags'] as List<dynamic>?) ?? [])
          .whereType<Map>()
          .map((e) => RedFlag.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      recommendedWorkup:
          List<String>.from(json['recommended_workup'] as List? ?? const []),
      recommendations:
          List<String>.from(json['recommendations'] as List? ?? const []),
      soapNote: SoapNote.fromJson(
          Map<String, dynamic>.from(json['soap_note'] as Map? ?? const {})),
      generatedAt: DateTime.tryParse(json['analysis_timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class DifferentialItem {
  final String diagnosis;
  final double probability; // 0..1
  final String rationale;
  final List<String> supportingFindings;

  DifferentialItem({
    required this.diagnosis,
    required this.probability,
    required this.rationale,
    this.supportingFindings = const [],
  });

  int get percent => (probability * 100).clamp(0, 100).round();

  Map<String, dynamic> toJson() => {
        'diagnosis': diagnosis,
        'probability': probability,
        'rationale': rationale,
        'supporting_findings': supportingFindings,
      };

  factory DifferentialItem.fromJson(Map<String, dynamic> json) =>
      DifferentialItem(
        diagnosis: json['diagnosis'] as String? ?? '',
        probability: (json['probability'] as num? ?? 0).toDouble(),
        rationale: json['rationale'] as String? ?? '',
        supportingFindings:
            List<String>.from(json['supporting_findings'] as List? ?? const []),
      );
}

class RedFlag {
  final String label;
  final String severity; // critical | warning
  final String action;

  RedFlag({required this.label, required this.severity, required this.action});

  bool get isCritical => severity == 'critical';

  Map<String, dynamic> toJson() =>
      {'label': label, 'severity': severity, 'action': action};

  factory RedFlag.fromJson(Map<String, dynamic> json) => RedFlag(
        label: json['label'] as String? ?? '',
        severity: json['severity'] as String? ?? 'warning',
        action: json['action'] as String? ?? '',
      );
}

class SoapNote {
  final String subjective;
  final String objective;
  final String assessment;
  final String plan;

  SoapNote({
    required this.subjective,
    required this.objective,
    required this.assessment,
    required this.plan,
  });

  Map<String, dynamic> toJson() => {
        'subjective': subjective,
        'objective': objective,
        'assessment': assessment,
        'plan': plan,
      };

  factory SoapNote.fromJson(Map<String, dynamic> json) => SoapNote(
        subjective: json['subjective'] as String? ?? '',
        objective: json['objective'] as String? ?? '',
        assessment: json['assessment'] as String? ?? '',
        plan: json['plan'] as String? ?? '',
      );

  String toPlainText() => 'S: $subjective\n\nO: $objective\n\n'
      'A: $assessment\n\nP: $plan';
}

/// Clinical reasoning engine: differential diagnosis, red-flag detection and
/// automatic SOAP note generation from a completed medical history.
///
/// The knowledge base below is deterministic and offline-capable so the app
/// keeps working without a network connection. If a remote model endpoint is
/// configured it can be layered on top of [analyze] later.
class ClinicalAIService {
  static final ClinicalAIService _instance = ClinicalAIService._internal();
  factory ClinicalAIService() => _instance;
  ClinicalAIService._internal();

  // ------------------------------------------------------------- knowledge

  static const Map<String, List<Map<String, dynamic>>> _differentialMap = {
    'chest pain': [
      {'dx': 'Acute coronary syndrome', 'p': 0.35, 'why': 'Chest pain is the cardinal presentation; must be excluded first.'},
      {'dx': 'Stable / unstable angina', 'p': 0.20, 'why': 'Exertional pattern with relief at rest.'},
      {'dx': 'Pulmonary embolism', 'p': 0.15, 'why': 'Pleuritic pain with dyspnoea and risk factors.'},
      {'dx': 'Gastro-oesophageal reflux', 'p': 0.15, 'why': 'Burning retrosternal pain related to meals.'},
      {'dx': 'Musculoskeletal chest wall pain', 'p': 0.15, 'why': 'Reproducible on palpation, positional.'},
    ],
    'shortness of breath': [
      {'dx': 'Asthma exacerbation', 'p': 0.25, 'why': 'Episodic wheeze with known triggers.'},
      {'dx': 'Acute heart failure', 'p': 0.25, 'why': 'Orthopnoea, oedema, paroxysmal nocturnal dyspnoea.'},
      {'dx': 'Pneumonia', 'p': 0.20, 'why': 'Fever with productive cough and focal findings.'},
      {'dx': 'Pulmonary embolism', 'p': 0.15, 'why': 'Sudden onset dyspnoea with tachycardia.'},
      {'dx': 'COPD exacerbation', 'p': 0.15, 'why': 'Smoking history with chronic sputum production.'},
    ],
    'headache': [
      {'dx': 'Migraine', 'p': 0.35, 'why': 'Unilateral throbbing pain with photophobia and nausea.'},
      {'dx': 'Tension-type headache', 'p': 0.30, 'why': 'Bilateral band-like pressure, stress related.'},
      {'dx': 'Subarachnoid haemorrhage', 'p': 0.10, 'why': 'Thunderclap onset — must be excluded.'},
      {'dx': 'Cluster headache', 'p': 0.10, 'why': 'Severe periorbital pain with autonomic features.'},
      {'dx': 'Sinusitis', 'p': 0.15, 'why': 'Facial pressure with nasal congestion.'},
    ],
    'fever': [
      {'dx': 'Viral upper respiratory infection', 'p': 0.35, 'why': 'Self-limiting fever with coryza.'},
      {'dx': 'Bacterial infection / sepsis source', 'p': 0.25, 'why': 'Focal signs with systemic response.'},
      {'dx': 'Urinary tract infection', 'p': 0.20, 'why': 'Dysuria, frequency, loin pain.'},
      {'dx': 'Influenza / COVID-19', 'p': 0.20, 'why': 'Seasonal, myalgia and dry cough.'},
    ],
    'cough': [
      {'dx': 'Acute bronchitis', 'p': 0.30, 'why': 'Post-viral persistent cough.'},
      {'dx': 'Pneumonia', 'p': 0.25, 'why': 'Fever with purulent sputum and focal crackles.'},
      {'dx': 'Asthma', 'p': 0.20, 'why': 'Nocturnal cough with wheeze.'},
      {'dx': 'Tuberculosis', 'p': 0.10, 'why': 'Chronic cough with weight loss and night sweats.'},
      {'dx': 'GERD-related cough', 'p': 0.15, 'why': 'Worse when supine, no infective features.'},
    ],
    'abdominal pain': [
      {'dx': 'Appendicitis', 'p': 0.25, 'why': 'Migratory RIF pain with anorexia.'},
      {'dx': 'Biliary colic / cholecystitis', 'p': 0.20, 'why': 'RUQ pain after fatty meals.'},
      {'dx': 'Gastritis / peptic ulcer', 'p': 0.20, 'why': 'Epigastric burning related to food.'},
      {'dx': 'Renal colic', 'p': 0.15, 'why': 'Loin-to-groin colicky pain with haematuria.'},
      {'dx': 'Gastroenteritis', 'p': 0.20, 'why': 'Diffuse cramps with diarrhoea.'},
    ],
    'nausea': [
      {'dx': 'Gastroenteritis', 'p': 0.35, 'why': 'Acute onset with diarrhoea.'},
      {'dx': 'Migraine', 'p': 0.20, 'why': 'Associated with headache and photophobia.'},
      {'dx': 'Medication side effect', 'p': 0.20, 'why': 'Temporal relation to a new drug.'},
      {'dx': 'Pregnancy', 'p': 0.25, 'why': 'Consider in any woman of childbearing age.'},
    ],
    'back pain': [
      {'dx': 'Mechanical / muscular back pain', 'p': 0.45, 'why': 'Movement related, no neurology.'},
      {'dx': 'Lumbar disc herniation', 'p': 0.25, 'why': 'Radicular pain with positive straight-leg raise.'},
      {'dx': 'Vertebral compression fracture', 'p': 0.15, 'why': 'Older patient, osteoporosis, sudden onset.'},
      {'dx': 'Pyelonephritis', 'p': 0.15, 'why': 'Fever with costovertebral tenderness.'},
    ],
    'joint pain': [
      {'dx': 'Osteoarthritis', 'p': 0.35, 'why': 'Activity-related pain in weight-bearing joints.'},
      {'dx': 'Rheumatoid arthritis', 'p': 0.25, 'why': 'Symmetrical small-joint pain with morning stiffness.'},
      {'dx': 'Gout', 'p': 0.20, 'why': 'Acute monoarthritis of the first MTP joint.'},
      {'dx': 'Septic arthritis', 'p': 0.20, 'why': 'Hot swollen joint with fever — emergency.'},
    ],
    'dizziness': [
      {'dx': 'Benign paroxysmal positional vertigo', 'p': 0.35, 'why': 'Brief positional vertigo.'},
      {'dx': 'Orthostatic hypotension', 'p': 0.25, 'why': 'On standing, medication related.'},
      {'dx': 'Anaemia', 'p': 0.20, 'why': 'Fatigue with pallor.'},
      {'dx': 'Posterior circulation stroke', 'p': 0.20, 'why': 'With focal neurology — exclude urgently.'},
    ],
  };

  /// Symptom / answer keywords that must never be missed.
  static const List<Map<String, String>> _redFlagRules = [
    {'match': 'crushing chest pain', 'label': 'Crushing central chest pain', 'severity': 'critical', 'action': 'Immediate ECG and troponin; activate ACS pathway.'},
    {'match': 'chest pain', 'label': 'Chest pain', 'severity': 'warning', 'action': 'ECG within 10 minutes; risk-stratify for ACS.'},
    {'match': 'thunderclap', 'label': 'Thunderclap headache', 'severity': 'critical', 'action': 'Urgent non-contrast CT head to exclude SAH.'},
    {'match': 'worst headache', 'label': 'Worst headache of life', 'severity': 'critical', 'action': 'Urgent CT head; consider lumbar puncture.'},
    {'match': 'shortness of breath at rest', 'label': 'Dyspnoea at rest', 'severity': 'critical', 'action': 'Oxygen saturation, ABG and urgent chest imaging.'},
    {'match': 'haemoptysis', 'label': 'Coughing up blood', 'severity': 'critical', 'action': 'Chest imaging; exclude PE and malignancy.'},
    {'match': 'hemoptysis', 'label': 'Coughing up blood', 'severity': 'critical', 'action': 'Chest imaging; exclude PE and malignancy.'},
    {'match': 'weight loss', 'label': 'Unintentional weight loss', 'severity': 'warning', 'action': 'Screen for malignancy, TB and thyroid disease.'},
    {'match': 'night sweats', 'label': 'Night sweats', 'severity': 'warning', 'action': 'Consider TB, lymphoma and endocarditis.'},
    {'match': 'syncope', 'label': 'Syncope', 'severity': 'critical', 'action': 'ECG, postural blood pressure, cardiac monitoring.'},
    {'match': 'loss of consciousness', 'label': 'Loss of consciousness', 'severity': 'critical', 'action': 'Neurological and cardiac assessment.'},
    {'match': 'confusion', 'label': 'New confusion', 'severity': 'critical', 'action': 'Check glucose, sepsis screen, CT head.'},
    {'match': 'neck stiffness', 'label': 'Neck stiffness with fever', 'severity': 'critical', 'action': 'Treat as meningitis until proven otherwise.'},
    {'match': 'bloody stool', 'label': 'Rectal bleeding', 'severity': 'warning', 'action': 'FBC, consider urgent lower GI referral.'},
    {'match': 'melena', 'label': 'Melaena', 'severity': 'critical', 'action': 'Upper GI bleed pathway; group and save.'},
    {'match': 'vomiting blood', 'label': 'Haematemesis', 'severity': 'critical', 'action': 'Resuscitate; urgent endoscopy referral.'},
    {'match': 'severe abdominal pain', 'label': 'Severe abdominal pain', 'severity': 'critical', 'action': 'Exclude perforation, ischaemia and AAA.'},
    {'match': 'bladder', 'label': 'Bladder dysfunction with back pain', 'severity': 'critical', 'action': 'Exclude cauda equina — urgent MRI.'},
    {'match': 'saddle', 'label': 'Saddle anaesthesia', 'severity': 'critical', 'action': 'Cauda equina syndrome — emergency MRI.'},
    {'match': 'suicidal', 'label': 'Suicidal ideation', 'severity': 'critical', 'action': 'Immediate risk assessment and mental health referral.'},
  ];

  static const Map<String, List<String>> _workupMap = {
    'chest pain': ['12-lead ECG', 'Troponin', 'Chest X-ray', 'Lipid profile'],
    'shortness of breath': ['Pulse oximetry', 'Chest X-ray', 'BNP', 'D-dimer if PE suspected'],
    'headache': ['Blood pressure', 'Neurological examination', 'CT head if red flags'],
    'fever': ['FBC with differential', 'CRP', 'Urinalysis', 'Blood cultures if septic'],
    'cough': ['Chest X-ray', 'Sputum culture', 'Peak flow / spirometry'],
    'abdominal pain': ['FBC, U&E, LFT, lipase', 'Urine dipstick', 'Abdominal ultrasound', 'Pregnancy test'],
    'back pain': ['Neurological examination', 'Urinalysis', 'MRI if red flags'],
    'joint pain': ['ESR/CRP', 'Uric acid', 'Rheumatoid factor / anti-CCP', 'Joint aspiration if hot joint'],
    'dizziness': ['Postural blood pressure', 'FBC', 'ECG', 'Dix-Hallpike manoeuvre'],
    'nausea': ['U&E', 'Pregnancy test', 'Medication review'],
  };

  // --------------------------------------------------------------- analysis

  Future<ClinicalAnalysis> analyze({
    required List<String> symptoms,
    Patient? patient,
    Map<String, dynamic> answers = const {},
    String? chiefComplaint,
  }) async {
    // Small delay keeps the UI transition natural; the engine itself is local.
    await Future.delayed(const Duration(milliseconds: 600));
    return analyzeSync(
      symptoms: symptoms,
      patient: patient,
      answers: answers,
      chiefComplaint: chiefComplaint,
    );
  }

  ClinicalAnalysis analyzeSync({
    required List<String> symptoms,
    Patient? patient,
    Map<String, dynamic> answers = const {},
    String? chiefComplaint,
  }) {
    final normalized = symptoms.map((s) => s.toLowerCase().trim()).toList();
    final haystack = _buildHaystack(normalized, answers, chiefComplaint);

    final differential = _buildDifferential(normalized);
    final redFlags = _detectRedFlags(haystack);
    final workup = _buildWorkup(normalized, redFlags);
    final risk = _riskLevel(redFlags, patient?.age, normalized);
    final confidence = _confidence(differential, normalized.length);
    final recommendations = _recommendations(risk, redFlags);
    final soap = _buildSoapNote(
      patient: patient,
      chiefComplaint: chiefComplaint,
      symptoms: symptoms,
      answers: answers,
      differential: differential,
      redFlags: redFlags,
      workup: workup,
      recommendations: recommendations,
      risk: risk,
    );

    return ClinicalAnalysis(
      riskLevel: risk,
      confidencePercent: confidence,
      differential: differential,
      redFlags: redFlags,
      recommendedWorkup: workup,
      recommendations: recommendations,
      soapNote: soap,
      generatedAt: DateTime.now(),
    );
  }

  String _buildHaystack(
    List<String> symptoms,
    Map<String, dynamic> answers,
    String? chiefComplaint,
  ) {
    final buffer = StringBuffer()
      ..writeAll(symptoms, ' ')
      ..write(' ')
      ..write(chiefComplaint?.toLowerCase() ?? '');
    answers.forEach((_, value) {
      if (value == null) return;
      buffer.write(' ${value.toString().toLowerCase()}');
    });
    return buffer.toString();
  }

  List<DifferentialItem> _buildDifferential(List<String> symptoms) {
    final scores = <String, double>{};
    final rationales = <String, String>{};
    final support = <String, List<String>>{};

    for (final symptom in symptoms) {
      final key = _differentialMap.keys.firstWhere(
        (k) => symptom.contains(k) || k.contains(symptom),
        orElse: () => '',
      );
      if (key.isEmpty) continue;

      for (final entry in _differentialMap[key]!) {
        final dx = entry['dx'] as String;
        final p = entry['p'] as double;
        scores[dx] = (scores[dx] ?? 0) + (scores.containsKey(dx) ? p * 0.6 : p);
        rationales[dx] = entry['why'] as String;
        support.putIfAbsent(dx, () => []).add(symptom);
      }
    }

    if (scores.isEmpty) return const [];

    final total = scores.values.fold<double>(0, (a, b) => a + b);
    final items = scores.entries
        .map((e) => DifferentialItem(
              diagnosis: e.key,
              probability: total == 0 ? 0 : e.value / total,
              rationale: rationales[e.key] ?? '',
              supportingFindings: support[e.key] ?? const [],
            ))
        .toList()
      ..sort((a, b) => b.probability.compareTo(a.probability));

    return items.take(5).toList();
  }

  List<RedFlag> _detectRedFlags(String haystack) {
    final found = <String, RedFlag>{};
    for (final rule in _redFlagRules) {
      if (haystack.contains(rule['match']!)) {
        found[rule['label']!] = RedFlag(
          label: rule['label']!,
          severity: rule['severity']!,
          action: rule['action']!,
        );
      }
    }
    return found.values.toList()
      ..sort((a, b) => (b.isCritical ? 1 : 0).compareTo(a.isCritical ? 1 : 0));
  }

  List<String> _buildWorkup(List<String> symptoms, List<RedFlag> redFlags) {
    final workup = <String>{};
    for (final symptom in symptoms) {
      final key = _workupMap.keys.firstWhere(
        (k) => symptom.contains(k) || k.contains(symptom),
        orElse: () => '',
      );
      if (key.isNotEmpty) workup.addAll(_workupMap[key]!);
    }
    if (redFlags.any((f) => f.isCritical)) {
      workup.add('Full set of observations (NEWS2)');
    }
    return workup.take(8).toList();
  }

  String _riskLevel(List<RedFlag> flags, int? age, List<String> symptoms) {
    if (flags.any((f) => f.isCritical)) return 'Urgent';
    if (flags.isNotEmpty) return 'High';

    var level = 'Low';
    if (symptoms.length >= 4) level = 'Medium';
    if (age != null) {
      if (age > 70 && level == 'Medium') return 'High';
      if (age > 70 && level == 'Low') return 'Medium';
      if (age < 2) return 'High';
    }
    return level;
  }

  int _confidence(List<DifferentialItem> differential, int symptomCount) {
    if (differential.isEmpty) return 35;
    final top = differential.first.probability;
    final base = 45 + (top * 40) + (symptomCount.clamp(0, 5) * 3);
    return base.clamp(35, 95).round();
  }

  List<String> _recommendations(String risk, List<RedFlag> flags) {
    final recs = <String>[];
    switch (risk) {
      case 'Urgent':
        recs.addAll([
          'Escalate now — senior review and emergency care pathway',
          'Continuous monitoring of vital signs',
          'Do not discharge before red flags are excluded',
        ]);
        break;
      case 'High':
        recs.addAll([
          'Same-day clinical review',
          'Complete the recommended workup before discharge',
          'Safety-net advice with clear return criteria',
        ]);
        break;
      case 'Medium':
        recs.addAll([
          'Review within 24–48 hours',
          'Monitor symptoms and document progression',
          'Return earlier if symptoms worsen',
        ]);
        break;
      default:
        recs.addAll([
          'Routine follow-up appropriate',
          'Supportive home care measures',
          'Return if symptoms persist beyond one week',
        ]);
    }
    recs.addAll(flags.map((f) => f.action));
    return recs.toSet().take(8).toList();
  }

  SoapNote _buildSoapNote({
    Patient? patient,
    String? chiefComplaint,
    required List<String> symptoms,
    required Map<String, dynamic> answers,
    required List<DifferentialItem> differential,
    required List<RedFlag> redFlags,
    required List<String> workup,
    required List<String> recommendations,
    required String risk,
  }) {
    final who = patient == null
        ? 'Patient'
        : '${patient.name}, ${patient.age}-year-old ${patient.gender.toLowerCase()}';

    final subjective = StringBuffer()
      ..write('$who presenting with '
          '${chiefComplaint?.trim().isNotEmpty == true ? chiefComplaint!.trim() : (symptoms.isEmpty ? 'an unspecified complaint' : symptoms.first)}.');
    if (symptoms.length > 1) {
      subjective.write(' Associated symptoms: ${symptoms.skip(1).join(', ')}.');
    }
    final narrative = answers.entries
        .where((e) =>
            e.value != null &&
            e.value.toString().trim().isNotEmpty &&
            e.value.toString().toLowerCase() != 'no')
        .take(12)
        .map((e) => '${_humanize(e.key)}: ${e.value}')
        .join('; ');
    if (narrative.isNotEmpty) subjective.write(' History: $narrative.');

    final objective = StringBuffer(
        'Structured history completed in myhx. ${answers.length} documented responses.');
    if (patient != null) {
      objective.write(
          ' Location: ${patient.department}, ward ${patient.wardNumber}, room ${patient.roomNumber}.');
    }
    objective.write(
        ' Examination and vital signs to be entered by the attending clinician.');

    final assessment = StringBuffer('Risk level: $risk. ');
    if (differential.isEmpty) {
      assessment.write('Insufficient data for a ranked differential.');
    } else {
      assessment.write('Leading differentials: ');
      assessment.write(differential
          .take(3)
          .map((d) => '${d.diagnosis} (${d.percent}%)')
          .join(', '));
      assessment.write('.');
    }
    if (redFlags.isNotEmpty) {
      assessment
          .write(' Red flags: ${redFlags.map((f) => f.label).join(', ')}.');
    } else {
      assessment.write(' No red flags identified from the recorded history.');
    }

    final plan = StringBuffer();
    if (workup.isNotEmpty) plan.write('Investigations: ${workup.join(', ')}. ');
    plan.write('Management: ${recommendations.take(4).join('; ')}.');

    return SoapNote(
      subjective: subjective.toString(),
      objective: objective.toString(),
      assessment: assessment.toString(),
      plan: plan.toString(),
    );
  }

  String _humanize(String key) => key
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .trim();
}

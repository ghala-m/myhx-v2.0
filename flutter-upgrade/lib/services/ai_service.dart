import 'dart:math';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // Simulated AI analysis - in real app this would call actual AI API
  Future<Map<String, dynamic>> analyzeSymptoms(List<String> symptoms, Map<String, String> patientInfo) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Simple rule-based analysis for demonstration
    final analysis = _performAnalysis(symptoms, patientInfo);
    
    return analysis;
  }

  Map<String, dynamic> _performAnalysis(List<String> symptoms, Map<String, String> patientInfo) {
    final random = Random();
    
    // Define symptom-diagnosis mappings
    final Map<String, List<Map<String, dynamic>>> symptomDiagnosisMap = {
      'chest pain': [
        {'diagnosis': 'Myocardial infarction', 'probability': 0.75},
        {'diagnosis': 'Unstable angina', 'probability': 0.15},
        {'diagnosis': 'Pulmonary embolism', 'probability': 0.08},
        {'diagnosis': 'Anxiety disorder', 'probability': 0.02},
      ],
      'shortness of breath': [
        {'diagnosis': 'Asthma', 'probability': 0.40},
        {'diagnosis': 'Heart failure', 'probability': 0.30},
        {'diagnosis': 'Pulmonary embolism', 'probability': 0.20},
        {'diagnosis': 'Pneumonia', 'probability': 0.10},
      ],
      'headache': [
        {'diagnosis': 'Migraine', 'probability': 0.60},
        {'diagnosis': 'Tension headache', 'probability': 0.25},
        {'diagnosis': 'Cluster headache', 'probability': 0.10},
        {'diagnosis': 'Sinusitis', 'probability': 0.05},
      ],
      'fever': [
        {'diagnosis': 'Viral infection', 'probability': 0.50},
        {'diagnosis': 'Bacterial infection', 'probability': 0.30},
        {'diagnosis': 'Influenza', 'probability': 0.15},
        {'diagnosis': 'COVID-19', 'probability': 0.05},
      ],
      'cough': [
        {'diagnosis': 'Upper respiratory infection', 'probability': 0.45},
        {'diagnosis': 'Bronchitis', 'probability': 0.25},
        {'diagnosis': 'Pneumonia', 'probability': 0.20},
        {'diagnosis': 'Asthma', 'probability': 0.10},
      ],
      'nausea': [
        {'diagnosis': 'Gastroenteritis', 'probability': 0.40},
        {'diagnosis': 'Migraine', 'probability': 0.25},
        {'diagnosis': 'Food poisoning', 'probability': 0.20},
        {'diagnosis': 'Pregnancy', 'probability': 0.15},
      ],
      'back pain': [
        {'diagnosis': 'Muscle strain', 'probability': 0.50},
        {'diagnosis': 'Herniated disc', 'probability': 0.25},
        {'diagnosis': 'Arthritis', 'probability': 0.15},
        {'diagnosis': 'Kidney stones', 'probability': 0.10},
      ],
      'joint pain': [
        {'diagnosis': 'Arthritis', 'probability': 0.60},
        {'diagnosis': 'Fibromyalgia', 'probability': 0.20},
        {'diagnosis': 'Lupus', 'probability': 0.15},
        {'diagnosis': 'Gout', 'probability': 0.05},
      ],
    };

    // Combine diagnoses from all symptoms
    Map<String, double> combinedDiagnoses = {};
    
    for (String symptom in symptoms) {
      final normalizedSymptom = symptom.toLowerCase();
      if (symptomDiagnosisMap.containsKey(normalizedSymptom)) {
        for (var diagnosisData in symptomDiagnosisMap[normalizedSymptom]!) {
          final diagnosis = diagnosisData['diagnosis'] as String;
          final probability = diagnosisData['probability'] as double;
          
          if (combinedDiagnoses.containsKey(diagnosis)) {
            // Increase probability if diagnosis appears for multiple symptoms
            combinedDiagnoses[diagnosis] = combinedDiagnoses[diagnosis]! + (probability * 0.5);
          } else {
            combinedDiagnoses[diagnosis] = probability;
          }
        }
      }
    }

    // Sort diagnoses by probability
    final sortedDiagnoses = combinedDiagnoses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 4 diagnoses
    final topDiagnoses = sortedDiagnoses.take(4).map((entry) {
      return '${entry.key} (${(entry.value * 100).toInt()}%)';
    }).toList();

    // Determine risk level based on symptoms and age
    String riskLevel = 'Low';
    double confidence = 0.70 + (random.nextDouble() * 0.25); // 70-95%
    
    if (symptoms.any((s) => ['chest pain', 'shortness of breath', 'severe headache'].contains(s.toLowerCase()))) {
      riskLevel = 'High';
      confidence = 0.80 + (random.nextDouble() * 0.15); // 80-95%
    } else if (symptoms.any((s) => ['fever', 'persistent cough', 'severe pain'].contains(s.toLowerCase()))) {
      riskLevel = 'Medium';
      confidence = 0.75 + (random.nextDouble() * 0.20); // 75-95%
    }

    // Age-based risk adjustment
    final age = int.tryParse(patientInfo['age'] ?? '0') ?? 0;
    if (age > 65) {
      if (riskLevel == 'Low') riskLevel = 'Medium';
      else if (riskLevel == 'Medium') riskLevel = 'High';
    }

    // Generate recommendations based on risk level and symptoms
    List<String> recommendations = _generateRecommendations(symptoms, riskLevel);

    return {
      'risk_level': riskLevel,
      'confidence': '${(confidence * 100).toInt()}%',
      'differential_diagnosis': topDiagnoses,
      'recommendations': recommendations,
      'analysis_timestamp': DateTime.now().toIso8601String(),
      'patient_factors': {
        'age_group': age < 18 ? 'Pediatric' : age < 65 ? 'Adult' : 'Elderly',
        'gender': patientInfo['gender'] ?? 'Unknown',
      },
    };
  }

  List<String> _generateRecommendations(List<String> symptoms, String riskLevel) {
    List<String> recommendations = [];

    // Risk-based recommendations
    switch (riskLevel) {
      case 'High':
        recommendations.addAll([
          'Immediate medical attention required',
          'Consider emergency department evaluation',
          'Continuous monitoring recommended',
        ]);
        break;
      case 'Medium':
        recommendations.addAll([
          'Schedule appointment within 24-48 hours',
          'Monitor symptoms closely',
          'Return if symptoms worsen',
        ]);
        break;
      case 'Low':
        recommendations.addAll([
          'Schedule routine follow-up',
          'Home care measures appropriate',
          'Return if symptoms persist or worsen',
        ]);
        break;
    }

    // Symptom-specific recommendations
    for (String symptom in symptoms) {
      switch (symptom.toLowerCase()) {
        case 'chest pain':
          recommendations.addAll([
            'ECG recommended',
            'Cardiac enzymes test',
            'Chest X-ray',
          ]);
          break;
        case 'shortness of breath':
          recommendations.addAll([
            'Pulse oximetry',
            'Chest X-ray',
            'Pulmonary function tests if chronic',
          ]);
          break;
        case 'headache':
          recommendations.addAll([
            'Neurological examination',
            'Consider CT scan if severe or sudden onset',
            'Blood pressure check',
          ]);
          break;
        case 'fever':
          recommendations.addAll([
            'Complete blood count',
            'Blood cultures if high fever',
            'Hydration and rest',
          ]);
          break;
        case 'cough':
          recommendations.addAll([
            'Chest X-ray',
            'Sputum culture if productive',
            'Consider bronchodilators if wheezing',
          ]);
          break;
      }
    }

    // Remove duplicates and limit to most important recommendations
    return recommendations.toSet().take(6).toList();
  }

  // Generate medical history questions based on symptoms
  List<Map<String, dynamic>> generateFollowUpQuestions(List<String> symptoms) {
    List<Map<String, dynamic>> questions = [];

    // General questions
    questions.addAll([
      {
        'id': 'duration',
        'question': 'How long have you been experiencing these symptoms?',
        'type': 'multiple_choice',
        'options': ['Less than 24 hours', '1-3 days', '1 week', 'More than 1 week'],
        'required': true,
      },
      {
        'id': 'severity',
        'question': 'How would you rate the severity of your symptoms?',
        'type': 'scale',
        'min': 1,
        'max': 10,
        'required': true,
      },
    ]);

    // Symptom-specific questions
    for (String symptom in symptoms) {
      switch (symptom.toLowerCase()) {
        case 'chest pain':
          questions.addAll([
            {
              'id': 'chest_pain_location',
              'question': 'Where exactly is the chest pain located?',
              'type': 'multiple_choice',
              'options': ['Center', 'Left side', 'Right side', 'All over'],
              'required': true,
            },
            {
              'id': 'chest_pain_radiation',
              'question': 'Does the pain radiate to other areas?',
              'type': 'multiple_choice',
              'options': ['No radiation', 'Left arm', 'Jaw', 'Back', 'Both arms'],
              'required': false,
            },
          ]);
          break;
        case 'headache':
          questions.addAll([
            {
              'id': 'headache_type',
              'question': 'How would you describe the headache?',
              'type': 'multiple_choice',
              'options': ['Throbbing', 'Sharp', 'Dull ache', 'Pressure-like'],
              'required': true,
            },
            {
              'id': 'headache_triggers',
              'question': 'What seems to trigger your headaches?',
              'type': 'multiple_choice',
              'options': ['Stress', 'Certain foods', 'Light', 'No clear trigger'],
              'required': false,
            },
          ]);
          break;
      }
    }

    return questions;
  }
}

